// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BeanERC20 is ERC20 {
    constructor() ERC20("BEAN Token", "BEAN") {
        _mint(_msgSender(), 100000000 ether);
    }
}
