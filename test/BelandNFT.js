const { assert } = require("chai");

const BelandNFTFactory = artifacts.require("./BelandNFTFactory.sol");
const BelandNFT = artifacts.require("./BelandNFT.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");


contract("Beland NFT", ([owner, user]) => {
  beforeEach(async () => {
    this.factory = await BelandNFTFactory.new();
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC");
    this.col = await BelandNFT.at(await this.factory.collections(0));
  });

  it("should create collection", async () => {
    this.factory = await BelandNFTFactory.new();
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC");
    assert.equal(await this.factory.collectionsLength(), 1)
  })

  it("should transfer creatorship", async () => {
    await this.col.transferCreatorship(user);
    assert.equal(await this.col.creator(), user);
  })
  it("should not transfer creatorship", async () => {
    await expectRevert(this.col.transferCreatorship(user, {from: user}), "BelandNFT: only creator or owner");
    await expectRevert(this.col.transferCreatorship("0x0000000000000000000000000000000000000000"), "BelandNFT: new creator is the zero address");
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
    await expectRevert(this.col.addItems([[2, "hash"]], {from: user}), "BelandNFT: only creator");
    await this.col.setEditable(false);
    await expectRevert(this.col.addItems([[2, "hash"]]), "BelandNFT: not editable");
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
    await expectRevert(this.col.editItems([1], [[3, "edit"]], {from: user}), "BelandNFT: only creator");
    await expectRevert(this.col.editItems([1], [[3, "edit"]]), "BelandNFT: item not found");
    await this.col.setEditable(false);
    await expectRevert(this.col.editItems([1], [[3, "edit"]]), "BelandNFT: not editable");
    await this.col.setEditable(true);
    await this.col.setApproved(1);
    await this.col.setMinter(owner, true);
    await this.col.batchCreate(user, [0,0])
    await expectRevert(this.col.editItems([0], [[1, "edit"]]), "BelandNFT: max supply must be greater than total supply");
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
    await expectRevert(this.col.create(user, 0), "BelandNFT: not approved")
    await expectRevert(this.col.batchCreate(user, [0]), "BelandNFT: not approved")
    await this.col.setApproved(1);
    await expectRevert(this.col.create(user, 2), "BelandNFT: item not found")
    await expectRevert(this.col.create(user, 2, {from: user}), "BelandNFT: only minter");
    await expectRevert(this.col.batchCreate(user, [0], {from: user}), "BelandNFT: only minter");
    await this.col.batchCreate(user, [0,0]);
    await expectRevert(this.col.create(user, 0), "BelandNFT: max supply")
  });
});
