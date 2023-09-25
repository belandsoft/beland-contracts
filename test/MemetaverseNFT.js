const { assert } = require("chai");

const MemetaverseNFTFactory = artifacts.require("MemetaverseNFTFactory.sol");
const MemetaverseNFT = artifacts.require("./MemetaverseNFT.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const TestErc20 = artifacts.require("./TestErc20.sol");

contract("Memetaverse NFT", ([owner, user, treasury, saleTreasury]) => {
  beforeEach(async () => {
    this.usdt = await TestErc20.new();
    await this.usdt.mint(3000);

    this.factory = await MemetaverseNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("memetaverse.club/");
    await this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], '');
    this.col = await MemetaverseNFT.at(await this.factory.collections(0));
  });

  it("should create collection", async () => {
    this.factory = await MemetaverseNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("memetaverse.club");
    await this.factory.create("ABC", "ABC", [[1, '1', 100, saleTreasury]], '');
    assert.equal(await this.factory.collectionsLength(), 1);
    assert.equal(await this.usdt.balanceOf(treasury), 200);
    assert.equal(await this.usdt.balanceOf(owner), 2800);
  });

  it("should not create collection", async () => {
    this.factory = await MemetaverseNFTFactory.new(treasury, this.usdt.address, 100);
    await this.usdt.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("memetaverse.club");
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
      "MemetaverseNFT: caller is not creator or owner"
    );
    await expectRevert(
      this.col.transferCreatorship(
        "0x0000000000000000000000000000000000000000"
      ),
      "MemetaverseNFT: new creator is the zero address"
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
      "MemetaverseNFT: caller is not creator or owner"
    );
  });
  
  it("should not edit items", async () => {
    await expectRevert(
      this.col.editItems([0], [[2, "hash", 100, saleTreasury]], { from: user }),
      "MemetaverseNFT: caller is not creator or owner"
    );

    await this.col.setApproved(true)
    await expectRevert(
      this.col.editItems([0], [[2, "hash", 100, saleTreasury]]),
      "MemetaverseNFT: not editable"
    );
  })

  it("should edit items", async () => {
    await this.col.editItems([0], [[5, "hash1", 200, user]])
    const item = await this.col.items(0);
    assert.equal(item[0], 5);
    assert.equal(item[1], 0);
    assert.equal(item[2], "hash1");
    assert.equal(item[3], 200);
    assert.equal(item[4], user);
  })


  it("should create nft", async () => {
    await this.col.addItems([[2, "hash", 100, saleTreasury]]);
    await this.col.setApproved(1);
    await this.col.setMinter(owner, true);
    await this.col.create(user, 1);

    const tokenURI = await this.col.tokenURI(1);
    assert.equal(
      tokenURI.toString(),
      `memetaverse.club/${this.col.address.toLowerCase()}/1`
    );

    const item = await this.col.itemOfToken(1);
    assert.equal(item[0], 2);
    assert.equal(item[1], 1);
    assert.equal(item[2], "hash");
  });

  it("should not create nft", async () => {
    await this.col.addItems([[2, "hash", 100, saleTreasury]]);
    await this.col.setMinter(owner, true);
    await expectRevert(this.col.create(user, 1), "MemetaverseNFT: not approved");
    await expectRevert(
      this.col.batchCreate(user, 1, 1),
      "MemetaverseNFT: not approved"
    );
    await this.col.setApproved(1);
    await expectRevert(this.col.create(user, 2), "MemetaverseNFT: item not found");
    await expectRevert(
      this.col.create(user, 2, { from: user }),
      "MemetaverseNFT: caller is not minter"
    );
    await expectRevert(
      this.col.batchCreate(user, 1, 1, { from: user }),
      "MemetaverseNFT: caller is not minter"
    );
    await this.col.batchCreate(user, 1, 2);
    await expectRevert(this.col.create(user, 1), "MemetaverseNFT: max supply");
  });
});
