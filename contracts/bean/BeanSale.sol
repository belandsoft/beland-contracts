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

contract BeanSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public pricePerBean;
    address public bean;

    event Buy(address user, uint256 amount);

    constructor(address _bean, uint256 _pricePerBean) {
        bean = _bean;
        pricePerBean = _pricePerBean;
    }

    function buy(uint256 amount) external payable nonReentrant {
        uint256 value = pricePerBean.mul(amount);
        TransferHelper.safeTransferETH(owner(), value);
        IERC20(bean).safeTransfer(_msgSender(), amount);
        if (msg.value > value) {
            TransferHelper.safeTransferETH(_msgSender(), msg.value.sub(value));
        }
        emit Buy(_msgSender(), amount);
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(
            _msgSender(),
            IERC20(_token).balanceOf(_msgSender())
        );
    }

    function withdrawETH(address _token) external onlyOwner {
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }
}
