const { assert } = require("chai");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");

const Land = artifacts.require("./Land.sol");
contract("Land", ([owner, user]) => {
  beforeEach(async () => {
    this.land = await Land.new();
    await this.land.setMinter(owner, 1);
  });

  it("Create", async () => {
    await expectRevert(
      this.land.create(user, 10, { from: user }),
      "Land: only minter"
    );
    await this.land.create(owner, 10, { from: owner });
    await expectRevert(
      this.land.create(owner, 10, { from: owner }),
      "ERC721: token already minted"
    );
  });

  it("Batch Create", async () => {
    await expectRevert(
      this.land.batchCreate(user, [1, 2], { from: user }),
      "Land: only minter"
    );
    await this.land.batchCreate(owner, [1, 2], { from: owner });
    await expectRevert(
      this.land.batchCreate(owner, [1], { from: owner }),
      "ERC721: token already minted"
    );
  });

  it("Metadata: update", async () => {
    await this.land.create(owner, 10, { from: owner });
    await this.land.setMetadata(10, "3434");
    await expectRevert(
      this.land.setMetadata(10, "!212", { from: user }),
      "Land: transfer caller is not owner nor approved"
    );
    assert.equal(await this.land.metadata(10), "3434");
  });

  it("Set minter", async () => {
    await expectRevert(
      this.land.setMinter(owner, 1, { from: user }),
      "Ownable: caller is not the owner"
    );
    await this.land.setMinter(owner, 0);
    await expectRevert(this.land.create(owner, 10), "Land: only minter");
  });
});
