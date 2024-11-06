// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor() ERC20("USDT Token", "USDT") {
        _mint(msg.sender, 1000000000000000 ether);
    }
}
