const { assert } = require("chai");
const { getLastBlockTimestamp } = require("./utils");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");

const BeanCrowdsale = artifacts.require("./BeanCrowdsale.sol");
const TestReferral = artifacts.require("./test/TestReferral.sol");
const BeanERC20 = artifacts.require("./BeanERC20.sol");

contract("BeanCrowdsale", ([owner, user]) => {
  beforeEach(async () => {
    this.bean = await BeanERC20.new();
    this.referral = await TestReferral.new();
    const time = await getLastBlockTimestamp();
    this.sale = await BeanCrowdsale.new(
      this.bean.address,
      10, // rate
      1, // discount rate
      100, // start price
      10000, // cap
      time, // start time
      time + 10000, // end time
    );

    await this.bean.setMinter(this.sale.address, true);
  });

  it("Buy", async () => {
    await this.sale.buy(user, { from: user, value: 2000 });
    const price = await this.sale.getPrice(user);
    assert.equal(await this.bean.balanceOf(user), Math.floor(2000/price));
  });

  it("Add Whitelist", async () => {
    await this.sale.addToWhitelist(user);
    const price = await this.sale.getPrice(user);
    assert.equal(price, 1);
  })

  it("Set Buyer Rate", async () => {
    await this.sale.setBuyerRate(user, 10);
    const price = await this.sale.getPrice(user);
    assert.equal(price, 10);
  })

  it("Should Not Buy", async () => {
    await expectRevert(this.sale.buy(user, { from: user, value: 10001 }), "BeanCrowdsale: max cap");
  });


});
