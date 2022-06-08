const { assert } = require("chai");
const { getLastBlockTimestamp, mineBlockWithTS } = require("./utils");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

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
      10000, // rate
      5000, // discount rate
      1000, // start price
      10000, // cap
      time, // start time
      time + 10000, // end time
    );

    await this.bean.setMinter(this.sale.address, true);
  });

  it("Buy", async () => {
    await this.sale.buy(user, { from: user, value: 2000 });
    const rate = await this.sale.getRate(user);
    assert.equal((await this.bean.balanceOf(user)).toString(), Math.floor(2000 * rate / 100));
  });

  it("Buy: receive ETH", async () => {
    await web3.eth.sendTransaction({
      from: user,
      to: this.sale.address,
      value: 2000
    });
    const rate = await this.sale.getRate(user);
    assert.equal(await this.bean.balanceOf(user), Math.floor(2000 * rate / 100));
  });

  it("Add Whitelist", async () => {
    await this.sale.addToWhitelist(user);
    const rate = await this.sale.getRate(user);
    assert.equal(rate, 1000);
  })

  it("Set Buyer Rate", async () => {
    await this.sale.setBuyerRate(user, 10);
    const rate = await this.sale.getRate(user);
    assert.equal(rate, 10);
  })

  it("Should Not Buy", async () => {
    await expectRevert(this.sale.buy(user, { from: user, value: 10001 }), "BeanCrowdsale: max cap");
  });

  it("change rate", async() => {
    const currentTime = await getLastBlockTimestamp()
    await mineBlockWithTS(currentTime + 5000);
    const rate = await this.sale.getRate(user);
    assert.equal(Number(rate.toString()) <  7500, true);
  })

});
