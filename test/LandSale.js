const { assert } = require("chai");

const LandSale = artifacts.require("./LandSale.sol");
const Land = artifacts.require("./Land.sol");
const TestReferral = artifacts.require("./test/TestReferral.sol");
const TestErc20 = artifacts.require("./TestErc20.sol");
contract("LandSale", ([owner, user, treasury, referrer]) => {
  beforeEach(async () => {
    this.land = await Land.new();
    this.referral = await TestReferral.new();
    this.usdt = await TestErc20.new();
    this.presale = await LandSale.new(treasury, this.land.address, this.usdt.address, 100, this.referral.address, 100, 0);

    await this.land.setMinter(this.presale.address, true);
    await this.usdt.mint(10000);
    await this.usdt.approve(this.presale.address, 10000);
  });

  function generateLandIds(total) {
      let landIds = [];
      for (var i = 0; i < total; i ++) {
        landIds.push(i + 1);
      }
      return landIds;
  }

  it("Buy: 1", async () => {
    await this.presale.buy([1], referrer);
    assert.equal(await this.usdt.balanceOf(treasury), "99");
    assert.equal(await this.usdt.balanceOf(referrer), "1")
  })

  it("Buy: 1 no referer", async () => {
    await this.presale.buy([1], "0x0000000000000000000000000000000000000000");
    assert.equal(await this.usdt.balanceOf(treasury), "100");
  })

  it("Buy: 10", async () => {
    await this.presale.buy(generateLandIds(10), referrer); // price: 990
    assert.equal(await this.usdt.balanceOf(treasury), "981");
    assert.equal(await this.usdt.balanceOf(referrer), "9")
  })

  it("Buy: 50", async () => {
    await this.presale.buy(generateLandIds(50), referrer); // price: 4875
    assert.equal(await this.usdt.balanceOf(treasury), "4827");
    assert.equal(await this.usdt.balanceOf(referrer), "48")
  })

  it("Buy: 100", async () => {
    await this.presale.buy(generateLandIds(100), referrer); // price: 4875
    assert.equal(await this.usdt.balanceOf(treasury), "9405");
    assert.equal(await this.usdt.balanceOf(referrer), "95")

    assert.equal(await this.land.ownerOf(1), owner);
    assert.equal(await this.land.ownerOf(100), owner);
  })
});
