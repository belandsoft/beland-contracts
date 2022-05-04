const { assert } = require("chai");

const BelandNFTFactory = artifacts.require("./BelandNFTFactory.sol");
const BelandNFT = artifacts.require("./BelandNFT.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const TestErc20 = artifacts.require("./TestErc20.sol");

contract("Beland NFT", ([owner, user, treasury, saleTreasury]) => {
  beforeEach(async () => {
    this.usdt = await TestErc20.new();
    await this.usdt.mint(3000);

    this.factory = await BelandNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], '');
    this.col = await BelandNFT.at(await this.factory.collections(0));
  });

  it("should create collection", async () => {
    this.factory = await BelandNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], '');
    assert.equal(await this.factory.collectionsLength(), 1);
    assert.equal(await this.usdt.balanceOf(treasury), 200);
    assert.equal(await this.usdt.balanceOf(owner), 2800);
  });

  it("should not create collection", async () => {
    this.factory = await BelandNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("beland.io/");
    await this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], '');
    await expectRevert(this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], ''), "COLLECTION_EXISTS")
    await expectRevert(this.col.initialize("ABC", "ABC", this.factory.address, ''), "transaction: revert Initializable: contract is already initialized")
  });


  it("should transfer creatorship", async () => {
    await this.col.transferCreatorship(user);
    assert.equal(await this.col.creator(), user);
  });
  it("should not transfer creatorship", async () => {
    await expectRevert(
      this.col.transferCreatorship(user, { from: user }),
      "BelandNFT: only creator or owner"
    );
    await expectRevert(
      this.col.transferCreatorship(
        "0x0000000000000000000000000000000000000000"
      ),
      "BelandNFT: new creator is the zero address"
    );
  });

  it("should add item", async () => {
    await this.col.addItems([[2, "hash", 100, saleTreasury]]);
    assert.equal(await this.col.itemsLength(), 2);
    const item = await this.col.items(1);
    assert.equal(item[0], 2);
    assert.equal(item[1], 0);
    assert.equal(item[2], "hash");
  });

  it("should not add item", async () => {
    await expectRevert(
      this.col.addItems([[2, "hash", 100, saleTreasury]], { from: user }),
      "Ownable: caller is not the owner"
    );
  });

  it("should create nft", async () => {
    await this.col.addItems([[2, "hash", 100, saleTreasury]]);
    await this.col.setApproved(1);
    await this.col.setMinter(owner, true);
    await this.col.create(user, 1);

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
    await this.col.addItems([[2, "hash", 100, saleTreasury]]);
    await this.col.setMinter(owner, true);
    await expectRevert(this.col.create(user, 1), "BelandNFT: not approved");
    await expectRevert(
      this.col.batchCreate(user, 1, 1),
      "BelandNFT: not approved"
    );
    await this.col.setApproved(1);
    await expectRevert(this.col.create(user, 2), "BelandNFT: item not found");
    await expectRevert(
      this.col.create(user, 2, { from: user }),
      "BelandNFT: only minter"
    );
    await expectRevert(
      this.col.batchCreate(user, 1, 1, { from: user }),
      "BelandNFT: only minter"
    );
    await this.col.batchCreate(user, 1, 2);
    await expectRevert(this.col.create(user, 1), "BelandNFT: max supply");
  });
});
