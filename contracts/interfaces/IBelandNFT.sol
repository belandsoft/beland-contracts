// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBelandNFT {
    function creator() external view returns(address);
    function isApproved() external view returns(bool);
    function batchCreate(address user, uint256 itemId, uint256 qty) external;
}