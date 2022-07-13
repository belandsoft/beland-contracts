// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BMTERC20 is ERC20 {
    constructor() ERC20("Beland Token", "BMT") {
        _mint(msg.sender, 40000000 ether);
    }
}
