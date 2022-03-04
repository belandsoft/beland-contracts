// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ILand {
    function batchCreate(address user, uint256[] memory landIds) external;
}

interface IReferral {
    function recordReferral(address _user, address _referrer) external;

    function getReferrer(address _user) external view returns (address);

    function recordReferralCommission(address _referrer, uint256 _commission)
        external;
}

contract LandPresale is Context {
    using SafeMath for uint256;

    address public treasury;
    address public land;
    address public dealToken;
    uint256 public pricePerLand = 10000 ether;
    uint256 referralCommision = 30; // 0.3%
    address referral;
    uint256 startDate;

    event Buy(uint256[] landIds);

    constructor(
        address _treasury,
        address _land,
        address _dealToken,
        uint256 _pricePerLand,
        address _referral,
        uint256 _referralCommision,
        uint256 _startDate
    ) {
        treasury = _treasury;
        land = _land;
        dealToken = _dealToken;
        referral = _referral;
        referralCommision = _referralCommision;
        pricePerLand = _pricePerLand;
        startDate = _startDate;
    }

    /**
     * @notice Buy buy land
     * @param landIds: ids of the land
     */
    function buy(uint256[] memory landIds, address _referrer) external {
        require(startDate <= block.timestamp, "LandPrelale: not started");
        require(landIds.length > 0, "LandPrelale: invalid landIds");
        _recordReferral(_referrer);
        uint256 qty = landIds.length;
        uint256 discountPercent = _calculateDiscount(qty);
        uint256 price = qty.mul(pricePerLand);
        uint256 discount = price.mul(discountPercent).div(10000);
        uint256 netPrice = price.sub(discount);
        uint256 commission = _payReferralCommission(netPrice);
        netPrice = netPrice.sub(commission);
        IERC20(dealToken).transferFrom(_msgSender(), treasury, netPrice);
        ILand(land).batchCreate(_msgSender(), landIds);
        emit Buy(landIds);
    }

    function _calculateDiscount(uint256 qty) internal pure returns (uint256) {
        if (qty >= 100) {
            return 500; // 5%
        } else if (qty >= 50) {
            return 250; // 2.5%
        } else if (qty >= 10) {
            return 100; // 1%
        }
        return 0;
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
        address referrer = IReferral(referral).getReferrer(_msgSender());
        if (referrer != address(0)) {
            commission = amount.mul(referralCommision).div(10000);
            IERC20(dealToken).transferFrom(_msgSender(), referrer, commission);
        }
    }
}
