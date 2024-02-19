// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface IERC721Collection {
    function COLLECTION_HASH() external view returns (bytes32);

    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }

    struct Item {
        string rarity;
        uint256 maxSupply; // max supply
        uint256 totalSupply; // current supply
        uint256 price;
        address beneficiary;
        string metadata;
        string contentHash; // used for safe purposes
    }


    function issueTokens(address[] calldata _beneficiaries, uint256[] calldata _itemIds) external;
    function setApproved(bool _value) external;
    /// @dev For some reason using the Struct Item as an output parameter fails, but works as an input parameter
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        bool _shouldComplete,
        bool _isApproved,
        address _rarities,
        ItemParam[] memory _items
    ) external;
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
    function getItem(uint256 _itemId) external view returns (Item memory);
}