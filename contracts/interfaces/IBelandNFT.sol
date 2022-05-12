// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBelandNFT {
    struct ItemParams {
        uint256 maxSupply; // max supply
        string tokenURI;
        uint256 price;
        address treasury;
    }

    struct Item {
        uint256 maxSupply; // max supply
        uint256 totalSupply; // current supply
        string tokenURI;
        uint256 price;
        address treasury;
    }
    
    function creator() external view returns(address);
    function isApproved() external view returns(bool);
    function batchCreate(address user, uint256 itemId, uint256 qty) external;
    function itemsLength() external returns (uint256);
    function initialize(
        string memory _name,
        string memory _symbol,
        address _creator,
        string memory _baseURI
    ) external;
    function itemPrice(uint256 _itemId) external view returns (uint256);
    function addItems(ItemParams[] memory _items) external;
    function getItem(uint256 _itemId) external view returns (Item memory);
}