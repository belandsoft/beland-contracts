// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;
pragma abicoder v2;

import "../interfaces/IERC721Collection.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IReferral.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../common/EIP712.sol";

contract ERC721CollectionSale is Ownable, ReentrancyGuard,EIP712 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public treasury;
    address public dealToken;
    uint256 public feePercent = 100; // 1%
    address public referral;
    uint256 public maxFeePercent = 1000; // 10%;
    uint256 public referralCommisionRate = 50; // 1%

    event Buy(
        address user,
        address indexed nft,
        uint256 itemId,
        uint256 qty,
        uint256 price,
        uint256 netPrice
    );
    event FeePercentUpdated(uint256 feePercent);
    event ReferalUpdated(address referral);
    event ReferralCommisionRateUpdated(uint256 newRate);
    event TreasuryUpdated(address treasury);
    event SetDealToken(address token);

    constructor(address _treasury, address _dealToken, address _referral) EIP712("Memetaverse Collection Sale", "1"){
        treasury = _treasury;
        dealToken = _dealToken;
        referral = _referral;
    }

    function setReferral(address _referral) external onlyOwner {
        require(_referral != address(0), "zero addr");
        referral = _referral;
        emit ReferalUpdated(_referral);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero addr");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setDealToken(address _token) external onlyOwner {
        require(_token != address(0), "zero addr");
        dealToken = _token;
        emit SetDealToken(_token);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= maxFeePercent, "MemetaverseNFTPresale: max fee");
        feePercent = _percent;
        emit FeePercentUpdated(_percent);
    }

    function setReferralCommisionRate(uint256 _percent) external onlyOwner {
        require(_percent <= maxFeePercent, "MemetaverseNFTPresale: max fee");
        referralCommisionRate = _percent;
        emit ReferralCommisionRateUpdated(_percent);
    }

    /**
     * @notice buy nft
     * @param _nft: address of nft
     * @param _qty: quantity
     */
    function buy(
        address _nft,
        uint256 _itemId,
        uint256 _qty,
        address _referrer
    ) external nonReentrant {
        IERC721Collection.Item memory item = IERC721Collection(_nft).getItem(
            _itemId
        );

        uint256 pricePerUnit = item.price;
        uint256 price;
        uint256 netPrice;
        if (pricePerUnit > 0) {
            _recordReferral(_referrer);
            IERC20 quote = IERC20(dealToken);
            // pay commission fee + protocol fee;
            price = pricePerUnit.mul(_qty);
            uint256 refFee = _payReferralCommission(price);
            uint256 protocolFee = price.mul(feePercent).div(10000);
            if (protocolFee > 0) {
                quote.safeTransferFrom(_msgSender(), treasury, protocolFee);
            }
            netPrice = price.sub(refFee).sub(protocolFee);
            quote.safeTransferFrom(_msgSender(), item.beneficiary, netPrice);
        }

        address[] memory beneficiaries = new address[](_qty);
        uint256[] memory items = new uint256[](_qty);

        for (uint256 i = 0; i < _qty; i++) {
            beneficiaries[i] = _msgSender();
            items[i] = _itemId;
        }
        IERC721Collection(_nft).issueTokens(beneficiaries, items);
        emit Buy(_msgSender(), _nft, _itemId, _qty, price, netPrice);
    }

    function _recordReferral(address _referrer) private {
        if (
            _referrer != address(0) &&
            _referrer != _msgSender() &&
            referral != address(0)
        ) {
            IReferral(referral).recordReferral(_msgSender(), _referrer);
        }
    }

    function _payReferralCommission(
        uint256 amount
    ) internal returns (uint256 commission) {
        if (referralCommisionRate > 0 && referral != address(0)) {
            address referrer = IReferral(referral).getReferrer(_msgSender());
            if (referrer != address(0)) {
                commission = amount.mul(referralCommisionRate).div(10000);
                IERC20(dealToken).safeTransferFrom(
                    _msgSender(),
                    referrer,
                    commission
                );
            }
        }
    }
}
