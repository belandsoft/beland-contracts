// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILand.sol";
import "../interfaces/IReferral.sol";

contract LandDutchAuction is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant DURATION = 7 days;
    uint256 public startTime;
    uint256 public endTime;
    address public treasury;
    address public dealToken;
    uint256 public referralCommision = 50; // 0.5%;
    address public referral;
    address public nft;
    uint256 startPrice;
    uint256 discountRate;

    event Buy(address user, uint256[] landIds, uint256 price, uint256 netPrice);

    constructor(
        address _nft,
        uint256 _startPrice,
        uint256 _startTime,
        address _treasury,
        address _dealToken,
        address _referral,
        uint256 _discountRate
    ) {
        require(
            _startPrice >= _discountRate * DURATION,
            "Starting price is too low"
        );
        nft = _nft;
        startPrice = _startPrice;
        startTime = _startTime;
        endTime = startTime + DURATION;
        treasury = _treasury;
        dealToken = _dealToken;
        referral = _referral;
        discountRate = _discountRate;
    }

    function buy(
        address user,
        uint256[] memory landIds,
        address _referrer
    ) external {
        require(startTime <= block.timestamp, "LandDutchAuction: not started");
        require(endTime >= block.timestamp, "LandDutchAuction: ended");
        require(landIds.length > 0, "LandDutchAuction: zero landIds");

        uint256 pricePerUnit = getPrice();
        uint256 price = landIds.length.mul(pricePerUnit);
        _recordReferral(_referrer);
        uint256 commission = _payReferralCommission(price);
        uint256 netPrice = price.sub(commission);
        IERC20(dealToken).safeTransferFrom(_msgSender(), treasury, netPrice);
        ILand(nft).batchCreate(user, landIds);
        emit Buy(user, landIds, price, netPrice);
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(startTime);
        uint256 discount = discountRate.mul(timeElapsed);
        return startPrice.sub(discount);
    }

    function _recordReferral(address _referrer) private {
        if (_referrer != address(0) && _referrer != _msgSender()) {
            IReferral(referral).recordReferral(_msgSender(), _referrer);
        }
    }

    function _payReferralCommission(uint256 amount)
        internal
        returns (uint256 commission)
    {
        if (referralCommision > 0) {
            address referrer = IReferral(referral).getReferrer(_msgSender());
            if (referrer != address(0)) {
                commission = amount.mul(referralCommision).div(10000);
                IERC20(dealToken).safeTransferFrom(
                    _msgSender(),
                    referrer,
                    commission
                );
            }
        }
    }
}
