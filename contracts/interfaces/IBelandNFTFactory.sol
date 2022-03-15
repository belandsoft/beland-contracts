// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBelandNFTFactory {
    function isCollectionFromFactory(address nft) external view returns(bool);
}