// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IBean.sol";

contract BeanCrowdsale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public bean;
    uint256 public rate;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;
    uint256 public raised;
    uint256 public cap;
    uint256 public discountRate;
    mapping(address => uint256) public buyerRate;
    // list of addresses that can purchase before crowdsale opens
    mapping(address => bool) public whitelist;

    event Buy(address user, uint256 amount, uint256 rate);

    constructor(
        address _bean,
        uint256 _rate,
        uint256 _discountRate,
        uint256 _startPrice,
        uint256 _cap,
        uint256 _startTime,
        uint256 _endTime
    ) {
        bean = _bean;
        rate = _rate;
        startPrice = _startPrice;
        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
        discountRate = _discountRate;
    }

    function addToWhitelist(address buyer) external onlyOwner {
        require(buyer != address(0x0), "BeanCrowdsale: zero address");
        whitelist[buyer] = true;
    }

    // @return true if buyer is whitelisted
    function isWhitelisted(address buyer) public view returns (bool) {
        return whitelist[buyer];
    }

    /**
     * @notice Set Buyer Rate
     * @param _buyer: address of the buyer
     * @param _rate: rate of the buyer
     */
    function setBuyerRate(address _buyer, uint256 _rate) external onlyOwner {
        require(_buyer != address(0x0), "BeanCrowdsale: zero buyer address");
        buyerRate[_buyer] = _rate;
    }

    /**
     * @notice Get Price
     * @param buyer: address of the buyer
     */
    function getPrice(address buyer) public view returns (uint256) {
        if (buyerRate[buyer] > 0) {
            return buyerRate[buyer];
        }

        if (isWhitelisted(buyer)) {
            return discountRate;
        }

        uint256 timeElapsed = block.timestamp.sub(startTime);
        uint256 changePrice = rate.mul(timeElapsed);
        return startPrice.add(changePrice);
    }

    /*
     * @dev Buy token
     */
    function buy(address beneficiary) public payable nonReentrant {
        require(startTime <= block.timestamp, "BeanCrowdsale: not started");
        require(endTime >= block.timestamp, "BeanCrowdsale: ended");
        require(msg.value > 0, "BeanCrowdsale: zero value");
        require(raised.add(msg.value) <= cap, "BeanCrowdsale: max cap");

        uint256 pricePerUnit = getPrice(_msgSender());
        uint256 tokens = msg.value.div(pricePerUnit);

        IBean(bean).mint(beneficiary, tokens);
        raised = raised.add(msg.value);
        emit Buy(beneficiary, tokens, pricePerUnit);
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(
            _msgSender(),
            IERC20(_token).balanceOf(_msgSender())
        );
    }

    function withdrawETH() external onlyOwner {
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }

    receive() external payable {
        buy(msg.sender);
    }
}
