const { assert, use } = require("chai");

const BelandNFTFactory = artifacts.require("./BelandNFTFactory.sol");
const BelandNFT = artifacts.require("./BelandNFT.sol");
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");
const BelandNFTPresale = artifacts.require("./BelandNFTPresale.sol");
const TestReferral = artifacts.require("./test/TestReferral.sol");
const TestErc20 = artifacts.require("./TestErc20.sol");

contract(
  "BelandNFTPresale",
  ([owner, user, treasury, nftTreasury, referrer]) => {
    beforeEach(async () => {
      this.factory = await BelandNFTFactory.new();
      await this.factory.setBaseURI("beland.io/");
      await this.factory.create("ABC", "ABC");
      this.usdt = await TestErc20.new();
      this.nft = await BelandNFT.at(await this.factory.collections(0));
      this.referral = await TestReferral.new();
      this.presale = await BelandNFTPresale.new(
        this.factory.address,
        treasury,
        this.referral.address
      );
      await this.usdt.mint(3000, { from: user });
      await this.usdt.approve(this.presale.address, 3000, { from: user });
      await this.nft.setMinter(this.presale.address, true);
      await this.nft.setApproved(true);
    });

    async function createPresale() {
      await this.nft.addItems([[2, "hash"]]);
      await this.presale.addPresale(
        this.nft.address,
        0,
        this.usdt.address,
        1000,
        nftTreasury
      );
    }

    it("should add presale", async () => {
      await createPresale.bind(this)();
      const presale = await this.presale.presales(this.nft.address, 0);
      assert.equal(presale[0], true);
      assert.equal(presale[1], this.usdt.address);
      assert.equal(presale[2], 1000);
      assert.equal(presale[3], nftTreasury);
      assert.equal(presale[4], true);
    });

    it("should not add presale", async () => {
      const correctData = [
        this.nft.address,
        0,
        this.usdt.address,
        100,
        nftTreasury,
      ];

      let cases = [];
      const correct = [...correctData, "", owner];
      cases.push([...correct]);
      cases[0][3] = 0;
      cases[0][5] = "BelandNFTPresale: pricePerUnit must be greater zero";

      cases.push([...correct]);
      cases[1][4] = "0x0000000000000000000000000000000000000000";
      cases[1][5] = "BelandNFTPresale: zero treasury";

      cases.push([...correct]);
      cases[2][0] = this.usdt.address;
      cases[2][5] = "BelandNFTPresale: invalid nft";

      cases.push([...correct]);
      cases[3][6] = user;
      cases[3][5] = "BelandNFTPresale: only creator";

      for (var i = 0; i < cases.length; i++) {
        await expectRevert(
          this.presale.addPresale(...cases[i].slice(0, 5), {
            from: cases[i][6],
          }),
          cases[i][5]
        );
      }
      await this.nft.setApproved(false);
      await expectRevert(
        this.presale.addPresale(...correctData),
        "BelandNFTPresale: not approved"
      );
      
      await this.nft.setApproved(true);
      await this.nft.addItems([[2, "hash"]]);
      await this.presale.addPresale(...correctData);
      await this.presale.buy(this.nft.address, 0, 2, referrer, { from: user });
      await expectRevert(
        this.presale.addPresale(...correctData),
        "BelandNFTPresale: not editable"
      );
    });

    it("Should cancel presale", async () => {
      await createPresale.bind(this)();
      await this.presale.cancelPresale(this.nft.address, 0);
    });

    it("SHOULD NOT cancel presale", async () => {
      await createPresale.bind(this)();
      await this.presale.buy(this.nft.address, 0, 1, referrer, { from: user });
      await expectRevert(
        this.presale.cancelPresale(this.nft.address, 0),
        "BelandNFTPresale: not editable"
      );
      await expectRevert(
        this.presale.cancelPresale(this.nft.address, 0, { from: user }),
        "BelandNFTPresale: only creator"
      );
      await expectRevert(
        this.presale.cancelPresale(this.nft.address, 1, { from: user }),
        "BelandNFTPresale: not found"
      );
    });

    it("Should buy", async () => {
      await createPresale.bind(this)();
      await this.presale.buy(this.nft.address, 0, 2, referrer, { from: user });

      assert.equal(await this.nft.ownerOf(1), user);
      assert.equal(await this.nft.ownerOf(2), user);
      assert.equal(await this.usdt.balanceOf(user), 1000);
      assert.equal(await this.usdt.balanceOf(treasury), 20); // 1%
      assert.equal(await this.usdt.balanceOf(referrer), 20); // 1%
      assert.equal(await this.usdt.balanceOf(nftTreasury), 1960); // 98%
    });

    it("should not buy", async () => {
      await createPresale.bind(this)();
      await expectRevert(
        this.presale.buy(this.nft.address, 0, 3, referrer, { from: user }),
        "BelandNFT: max supply"
      );

      await expectRevert(
        this.presale.buy(this.nft.address, 1, 3, referrer, { from: user }),
        "BelandNFTPresale: presale not found"
      );
    });
  }
);
