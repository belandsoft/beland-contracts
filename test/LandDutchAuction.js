const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const { assert } = require("chai");
const { mineBlockWithTS, getLastBlockTimestamp } = require("./utils");

const LandDutchAuction = artifacts.require("./LandDutchAuction.sol");
const Land = artifacts.require("./Land.sol");
const TestReferral = artifacts.require("./test/TestReferral.sol");
const TestErc20 = artifacts.require("./TestErc20.sol");
contract("LandDutchAuction", ([owner, user, treasury, referrer]) => {
  beforeEach(async () => {
    this.land = await Land.new();
    this.referral = await TestReferral.new();
    this.usdt = await TestErc20.new();
    this.auction = await LandDutchAuction.new(
      this.land.address,
      10000000,
      Math.floor(new Date().getTime() / 1000),
      treasury,
      this.usdt.address,
      this.referral.address,
      16
    );

    await this.land.setMinter(this.auction.address, true);
    await this.usdt.mint(20000000);
    await this.usdt.approve(this.auction.address, 20000000);
  });

  it("Should buy", async () => {
    await this.auction.buy(user, [1,2], referrer);
    const price = await this.auction.getPrice();
    assert.equal((await this.usdt.balanceOf(owner)).toString(), 20000000 - price * 2);
  })

  it("Should not buy", async () => {
    this.auction = await LandDutchAuction.new(
      this.land.address,
      10000000,
      Math.floor(new Date().getTime() / 1000) + 1000000,
      treasury,
      this.usdt.address,
      this.referral.address,
      16
    );
    await expectRevert(this.auction.buy(user, [1], referrer), "LandDutchAuction: not started")
  })


  it("Should not buy", async () => {
    await this.auction.buy(user, [1], referrer);
    await expectRevert(this.auction.buy(user, [90000000], referrer), "landId bigger than limit")
    await expectRevert(this.auction.buy(user, [1], referrer), "ERC721: token already minted")
    const time = await getLastBlockTimestamp()
    await mineBlockWithTS(time + 604801)
    await expectRevert(this.auction.buy(user, [2], referrer), "LandDutchAuction: ended")
  })

 
});
