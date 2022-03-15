// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IBelandNFT.sol";
import "./interfaces/IBelandNFTFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IReferral.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BelandNFTPresale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Presale {
        bool hasExist;
        address quoteToken;
        uint256 pricePerUnit;
        uint256 referralCommisionRate;
        address treasury;
        bool isEditable;
    }

    mapping(address => mapping(uint256 => Presale)) public presales;
    address public factory;
    address public treasury;
    uint256 public feePercent = 100; // 1%
    address public referral;
    uint256 public maxFeePercent = 1000; // 10%;

    event PresaleCreated(address indexed nft, uint256 itemId, Presale);
    event PresaleCancel(address indexed nft, uint256 itemId);
    event Buy(address indexed nft, uint256 itemId, uint256 qty);
    event FeePercentUpdated(uint256 feePercent);
    event ReferalUpdated(address referral);
    event TreasuryUpdated(address treasury);

    constructor(
        address _factory,
        address _treasury,
        address _referral
    ) {
        factory = _factory;
        treasury = _treasury;
        referral = _referral;
    }

    function setReferral(address _referral) external onlyOwner {
        referral = _referral;
        emit ReferalUpdated(_referral);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= maxFeePercent, "BelandNFTPresale: max fee");
        feePercent = _percent;
        emit FeePercentUpdated(_percent);
    }

    /**
     * @notice add presale
     * @param _nft: address of nft
     * @param itemId: item id
     * @param pricePerUnit: price per unit
     * @param referralCommisionRate:  referral commision rate
     * @param _treasury: address of treasury
     */
    function addPresale(
        address _nft,
        uint256 itemId,
        address quoteToken,
        uint256 pricePerUnit,
        uint256 referralCommisionRate,
        address _treasury
    ) external nonReentrant {
        require(
            referralCommisionRate <= maxFeePercent,
            "BelandNFTPresale: max fee percent"
        );
        require(
            pricePerUnit > 0,
            "BelandNFTPresale: pricePerUnit must be greater zero"
        );
        require(_treasury != address(0), "BelandNFTPresale: zero treasury");
        require(
            IBelandNFTFactory(factory).isCollectionFromFactory(_nft),
            "BelandNFTPresale: invalid nft"
        );
        require(
            IBelandNFT(_nft).creator() == _msgSender(),
            "BelandNFTPresale: only creator"
        );
        require(
            !presales[_nft][itemId].hasExist,
            "BelandNFTPresale: presale found"
        );

        presales[_nft][itemId] = Presale({
            quoteToken: quoteToken,
            pricePerUnit: pricePerUnit,
            referralCommisionRate: referralCommisionRate,
            treasury: _treasury,
            hasExist: true,
            isEditable: true
        });

        emit PresaleCreated(_nft, itemId, presales[_nft][itemId]);
    }

    function cancelPresale(address _nft, uint256 itemId) external nonReentrant {
        require(
            presales[_nft][itemId].hasExist,
            "BelandNFTPresale: not found"
        );
        require(
            IBelandNFT(_nft).creator() == _msgSender(),
            "BelandNFTPresale: only creator"
        );
        require(
            presales[_nft][itemId].isEditable,
            "BelandNFTPresale: not editable"
        );
        delete presales[_nft][itemId];
        emit PresaleCancel(_nft, itemId);
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
        Presale memory presale = presales[_nft][itemId];
        require(presale.hasExist, "BelandNFTPresale: presale not found");
        _recordReferral(_referrer);
        IERC20 quote = IERC20(presale.quoteToken);
        // pay commission fee + protocol fee;
        uint256 price = presale.pricePerUnit.mul(_qty);
        uint256 refFee = _payReferralCommission(_nft, itemId, price);
        uint256 protocolFee = price.mul(feePercent).div(10000);
        if (protocolFee > 0) {
            quote.safeTransferFrom(_msgSender(), treasury, protocolFee);
        }
        uint256 netPrice = price.sub(refFee).sub(protocolFee);
        quote.safeTransferFrom(_msgSender(), presale.treasury, netPrice);
        IBelandNFT(_nft).batchCreate(_msgSender(), itemId, _qty);
        if (presale.isEditable) {
            presales[_nft][itemId].isEditable = false;
        }
        emit Buy(_nft, itemId, _qty);
    }

    function _recordReferral(address _referrer) private {
        if (_referrer != address(0) && _referrer != _msgSender()) {
            IReferral(referral).recordReferral(_msgSender(), _referrer);
        }
    }

    function _payReferralCommission(
        address _nft,
        uint256 itemId,
        uint256 amount
    ) internal returns (uint256 commission) {
        Presale memory presale = presales[_nft][itemId];
        if (presale.referralCommisionRate > 0) {
            address referrer = IReferral(referral).getReferrer(_msgSender());
            if (referrer != address(0)) {
                commission = amount.mul(presale.referralCommisionRate).div(
                    10000
                );
                IERC20(presale.quoteToken).safeTransferFrom(
                    _msgSender(),
                    referrer,
                    commission
                );
            }
        }
    }
}
