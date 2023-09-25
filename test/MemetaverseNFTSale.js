const { assert } = require("chai");

const MemetaverseNFTFactory = artifacts.require("./MemetaverseNFTFactory.sol");
const MemetaverseNFT = artifacts.require("./MemetaverseNFT.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const MemetaverseNFTSale = artifacts.require("./MemetaverseNFTSale.sol");
const TestReferral = artifacts.require("./test/TestReferral.sol");
const TestErc20 = artifacts.require("./TestErc20.sol");

contract("MemetaverseNFTSale", ([owner, user, treasury, nftTreasury, referrer]) => {
  beforeEach(async () => {
    this.bean = await TestErc20.new();
    await this.bean.mint(3000);
    this.factory = await MemetaverseNFTFactory.new(treasury, this.bean.address, 100);

    await this.bean.approve(this.factory.address, 3000);
    await this.factory.setBaseURI("memetaverse.club/");
    await this.factory.create("ABC", "ABC", [[2, "1", 1000, nftTreasury]], "");

    this.usdt = await TestErc20.new();
    this.nft = await MemetaverseNFT.at(await this.factory.collections(0));
    this.referral = await TestReferral.new();
    this.sale = await MemetaverseNFTSale.new(
      treasury,
      this.usdt.address,
      this.referral.address
    );
    await this.usdt.mint(3000, { from: user });
    await this.usdt.approve(this.sale.address, 3000, { from: user });
    await this.nft.setMinter(this.sale.address, true);
    await this.nft.setApproved(true);
  });

  it("Should buy", async () => {
    await this.sale.buy(this.nft.address, 0, 2, referrer, { from: user });

    assert.equal(await this.nft.ownerOf(1), user);
    assert.equal(await this.nft.ownerOf(2), user);
    assert.equal(await this.usdt.balanceOf(user), 1000);
    assert.equal(await this.usdt.balanceOf(treasury), 20); // 1%
    assert.equal(await this.usdt.balanceOf(referrer), 10); // 0.5%
    assert.equal(await this.usdt.balanceOf(nftTreasury), 1970); // 98.5%
  });

  it("should not buy", async () => {
    await expectRevert(
      this.sale.buy(this.nft.address, 0, 3, referrer, { from: user }),
      "MemetaverseNFT: max supply"
    );

    await expectRevert(
      this.sale.buy(this.nft.address, 5, 3, referrer, { from: user }),
      "revert"
    );
  });
});
