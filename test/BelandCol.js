const { assert } = require("chai");

const BelandColFactory = artifacts.require("./BelandColFactory.sol");
const BelandCoL = artifacts.require("./BelandCol.sol");

contract("Beland Collection", ([owner, user]) => {
  beforeEach(async () => {
    this.factory = await BelandColFactory.new();
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC");
    this.col = await BelandCoL.at(await this.factory.collections(0));
  });

  it("should add item", async () => {
    await this.col.addItems([[2, "hash"]]);
    assert.equal(await this.col.itemsLength(), 1);
    const item = await this.col.items(0);
    assert.equal(item[0], 2);
    assert.equal(item[1], 0);
    assert.equal(item[2], "hash");
  });

  it("should edit item", async () => {
    await this.col.addItems([[2, "hash"]]);
    await this.col.editItems([0], [[3, "edit"]]);
    const item = await this.col.items(0);
    assert.equal(item[0], 3);
    assert.equal(item[1], 0);
    assert.equal(item[2], "edit");
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
  });
});
