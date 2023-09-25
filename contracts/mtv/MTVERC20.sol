// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MTVERC20 is ERC20 {
    constructor() ERC20("Memetaverse Token", "MTV") {
        _mint(msg.sender, 40000000 ether);
    }
}
