// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IERC721CollectionFactory {
    function createCollection(bytes32 _salt, bytes memory _data) external returns (address addr);
    function transferOwnership(address newOwner) external;
    function isCollectionFromFactory(address _collection) external view returns (bool);
}