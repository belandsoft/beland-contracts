// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICollectionManager {
   function manageCollection(address _forwarder, address _collection, bytes calldata _data) external;
}