// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IBean {
    function mint(address user, uint256 amount) external;
}

contract BeanCrowdsale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public bean;
    uint256 public rate;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;

    event Buy(address user, uint256 amount, uint256 price);

    constructor(
        address _bean,
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice
    ) {
        bean = _bean;
        rate = _rate;
        startPrice = _startPrice;
        startTime = _startTime;
        endTime = _endTime;
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(startTime);
        uint256 changePrice = rate.mul(timeElapsed);
        return startPrice.add(changePrice);
    }

    function buy(uint256 amount) external payable nonReentrant {
        require(startTime <= block.timestamp, "BeanCrowdsale: not started");
        require(endTime >= block.timestamp, "BeanCrowdsale: ended");
        require(amount > 0, "BeanCrowdsale: zero amount");

        uint256 pricePerUnit = getPrice();
        uint256 price = pricePerUnit.mul(amount);
        IERC20(bean).safeTransfer(_msgSender(), amount);
        if (msg.value > price) {
            TransferHelper.safeTransferETH(_msgSender(), msg.value.sub(price));
        }
        emit Buy(_msgSender(), amount, price);
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
}
