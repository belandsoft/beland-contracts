const { assert } = require("chai");

const BelandColFactory = artifacts.require("./BelandColFactory.sol");
const BelandCoL = artifacts.require("./BelandCol.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");


contract("Beland Collection", ([owner, user]) => {
  beforeEach(async () => {
    this.factory = await BelandColFactory.new();
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC");
    this.col = await BelandCoL.at(await this.factory.collections(0));
  });

  it("should create collection", async () => {
    this.factory = await BelandColFactory.new();
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC");
    assert.equal(await this.factory.collectionsLength(), 1)
  })

  it("should transfer creatorship", async () => {
    await this.col.transferCreatorship(user);
    assert.equal(await this.col.creator(), user);
  })
  it("should not transfer creatorship", async () => {
    await expectRevert(this.col.transferCreatorship(user, {from: user}), "BelandCol: only creator");
    await expectRevert(this.col.transferCreatorship("0x0000000000000000000000000000000000000000"), "BelandCol: new creator is the zero address");
  })

  it("should add item", async () => {
    await this.col.addItems([[2, "hash"]]);
    assert.equal(await this.col.itemsLength(), 1);
    const item = await this.col.items(0);
    assert.equal(item[0], 2);
    assert.equal(item[1], 0);
    assert.equal(item[2], "hash");
  });

  it("should not add item", async () => {
    await expectRevert(this.col.addItems([[2, "hash"]], {from: user}), "BelandCol: only creator");
    await this.col.setEditable(false);
    await expectRevert(this.col.addItems([[2, "hash"]]), "BelandCol: not editable");
  })

  it("should edit item", async () => {
    await this.col.addItems([[2, "hash"]]);
    await this.col.editItems([0], [[3, "edit"]]);
    const item = await this.col.items(0);
    assert.equal(item[0], 3);
    assert.equal(item[1], 0);
    assert.equal(item[2], "edit");
  });

  it("should not edit item", async() => {
    await this.col.addItems([[2, "hash"]]);
    await expectRevert(this.col.editItems([1], [[3, "edit"]], {from: user}), "BelandCol: only creator");
    await expectRevert(this.col.editItems([1], [[3, "edit"]]), "BelandCol: item not found");
    await this.col.setEditable(false);
    await expectRevert(this.col.editItems([1], [[3, "edit"]]), "BelandCol: not editable");
    await this.col.setEditable(true);
    await this.col.setApproved(1);
    await this.col.setMinter(owner, true);
    await this.col.batchCreate(user, [0,0])
    await expectRevert(this.col.editItems([0], [[1, "edit"]]), "BelandCol: max supply must be greater than total supply");
  });

  it("should create nft", async () => {
    await this.col.addItems([[2, "hash"]]);
    await this.col.setApproved(1);
    await this.col.setMinter(owner, true);
    await this.col.create(user, 0);

    const tokenURI = await this.col.tokenURI(1);
    assert.equal(
      tokenURI.toString(),
      `beland.io/${this.col.address.toLowerCase()}/1`
    );

    const item = await this.col.itemOfToken(1);
    assert.equal(item[0], 2);
    assert.equal(item[1], 1);
    assert.equal(item[2], "hash");
  });

  it("should not create nft", async () => {
    await this.col.addItems([[2, "hash"]]);
    await this.col.setMinter(owner, true);
    await expectRevert(this.col.create(user, 0), "BelandCol: not approved")
    await expectRevert(this.col.batchCreate(user, [0]), "BelandCol: not approved")
    await this.col.setApproved(1);
    await expectRevert(this.col.create(user, 2), "BelandCol: item not found")
    await expectRevert(this.col.create(user, 2, {from: user}), "BelandCol: only minter");
    await expectRevert(this.col.batchCreate(user, [0], {from: user}), "BelandCol: only minter");
    await this.col.batchCreate(user, [0,0]);
    await expectRevert(this.col.create(user, 0), "BelandCol: max supply")
  });
});
