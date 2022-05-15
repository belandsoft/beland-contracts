// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeanERC20 is ERC20, Ownable {
    mapping(address => bool) private _minters;
    event SetMinter(address minter, bool isMinter);

    constructor() ERC20("BEAN Token", "BEAN") {}

    function setMinter(address minter, bool isMinter) external onlyOwner {
        require(_minters[minter] != isMinter, "BeanERC20: same value");
        _minters[minter] = isMinter;
        emit SetMinter(minter, isMinter);
    }

    function mint(address account, uint256 amount) external {
        require(_minters[_msgSender()], "BeanERC20: only minter");
        _mint(account, amount);
    }
}
