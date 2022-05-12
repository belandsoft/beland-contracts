// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface ILand {
    function batchCreate(address user, uint256[] memory landIds) external;
}