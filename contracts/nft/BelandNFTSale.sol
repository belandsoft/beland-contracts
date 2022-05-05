// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BelandNFT.sol";
import "../interfaces/IBelandNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IReferral.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BelandNFTSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public factory;
    address public treasury;
    address public quoteToken;
    uint256 public feePercent = 100; // 1%
    address public referral;
    uint256 public maxFeePercent = 1000; // 10%;
    uint256 public referralCommisionRate = 100; // 1%

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
    event SetQuoteToken(address token);

    constructor(
        address _factory,
        address _treasury,
        address _quoteToken,
        address _referral
    ) {
        factory = _factory;
        treasury = _treasury;
        referral = _referral;
        quoteToken = _quoteToken;
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

    function setQuoteToken(address _token) external onlyOwner {
        require(_token != address(0), "zero addr");
        quoteToken = _token;
        emit SetQuoteToken(_token);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= maxFeePercent, "BelandNFTPresale: max fee");
        feePercent = _percent;
        emit FeePercentUpdated(_percent);
    }

    function setReferralCommisionRate(uint256 _percent) external onlyOwner {
        require(_percent <= maxFeePercent, "BelandNFTPresale: max fee");
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
        uint256 itemId,
        uint256 _qty,
        address _referrer
    ) external nonReentrant {
        IBelandNFT.Item memory item = IBelandNFT(_nft).items(itemId);

        uint256 pricePerUnit = item.price;
        uint256 price;
        uint256 netPrice;
        if (pricePerUnit > 0) {
            _recordReferral(_referrer);
            IERC20 quote = IERC20(quoteToken);
            // pay commission fee + protocol fee;
            price = pricePerUnit.mul(_qty);
            uint256 refFee = _payReferralCommission(price);
            uint256 protocolFee = price.mul(feePercent).div(10000);
            if (protocolFee > 0) {
                quote.safeTransferFrom(_msgSender(), treasury, protocolFee);
            }
            netPrice = price.sub(refFee).sub(protocolFee);
            quote.safeTransferFrom(_msgSender(), item.treasury, netPrice);
        }
        IBelandNFT(_nft).batchCreate(_msgSender(), itemId, _qty);
        emit Buy(_msgSender(), _nft, itemId, _qty, price, netPrice);
    }

    function _recordReferral(address _referrer) private {
        if (_referrer != address(0) && _referrer != _msgSender()) {
            IReferral(referral).recordReferral(_msgSender(), _referrer);
        }
    }

    function _payReferralCommission(uint256 amount)
        private
        returns (uint256 commission)
    {
        if (referralCommisionRate > 0) {
            address referrer = IReferral(referral).getReferrer(_msgSender());
            if (referrer != address(0)) {
                commission = amount.mul(referralCommisionRate).div(10000);
                IERC20(quoteToken).safeTransferFrom(
                    _msgSender(),
                    referrer,
                    commission
                );
            }
        }
    }
}
