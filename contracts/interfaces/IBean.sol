// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBean {
    function mint(address account, uint256 amount) external;
}