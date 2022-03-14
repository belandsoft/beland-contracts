// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BelandCol is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool public isApproved = false;
    bool public isEditable = true;
    address public creator;
    mapping(address => bool) _minters;

    struct ItemParams {
        uint256 maxSupply; // max supply
        string tokenURI;
    }

    struct Item {
        uint256 maxSupply; // max supply
        uint256 totalSupply; // current supply
        string tokenURI;
    }

    Item[] public items;
    mapping(uint256 => uint256) public tokenItemMap;

    event MinterUpdate(address _minter, bool _isMinter);
    event Created(address user, uint256 tokenId, uint256 itemId);
    event SetApproved(bool _previousValue, bool _newValue);
    event SetEditable(bool _previousValue, bool _newValue);

    modifier onlyMinter() {
        require(_minters[_msgSender()], "BelandCol: only minter");
        _;
    }

    modifier onlyCreator() {
        require(creator == _msgSender(), "BelandCol: only creator");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _creator
    ) ERC721(_name, _symbol) {
        creator = _creator;
    }

    /**
     * @notice Add new items
     * @param _items: list item params
     */
    function addItems(ItemParams[] memory _items) external onlyCreator {
        require(isEditable, "BelandCol: not editable");
        for (uint256 i = 0; i < _items.length; i++) {
            items.push(
                Item({
                    maxSupply: _items[i].maxSupply,
                    totalSupply: 0,
                    tokenURI: _items[i].tokenURI
                })
            );
        }
    }

    /**
     * @notice edit items
     * @param _indexes: index of items
     * @param  _items: list item params to edit
     */
    function editItems(uint256[] memory _indexes, ItemParams[] memory _items)
        external
        onlyCreator
    {
        require(isEditable, "BelandCol: not editable");
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(items.length > _indexes[i], "BelandCol: item not found");
            Item storage item = items[_indexes[i]];
            require(
                item.totalSupply <= _items[i].maxSupply,
                "BelandCol: invalid max supply"
            );
            item.maxSupply = _items[i].maxSupply;
            item.tokenURI = _items[i].tokenURI;
        }
    }

    /**
     * @notice Create new nft
     * @param user: address of user
     * @param itemIndex: idex of item
     */
    function create(address user, uint256 itemIndex) external onlyMinter {
        require(isApproved, "BelandCol: not approved");
        _create(user, itemIndex);
    }

    function _create(address user, uint256 itemIndex) private {
        require(items.length > itemIndex, "BelandCol: item not found");
        require(
            items[itemIndex].totalSupply < items[itemIndex].maxSupply,
            "BelandCol: max supply"
        );
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);
        tokenItemMap[newTokenId] = itemIndex;
        items[itemIndex].totalSupply++;
        emit Created(user, newTokenId, itemIndex);
    }

    /**
     * @notice batch create nfts
     * @param user: address of user
     * @param itemIndexes: list of item index
     */
    function batchCreate(address user, uint256[] memory itemIndexes)
        external
        onlyMinter
    {
        require(isApproved, "BelandCol: not approved");
        for (uint256 i = 0; i < itemIndexes.length; i++) {
            _create(user, itemIndexes[i]);
        }
    }

    /**
     * @notice Approve a collection
     * @param _value - Value to set
     */
    function setApproved(bool _value) external virtual onlyOwner {
        require(isApproved != _value, "BelandCol: value is the same");
        emit SetApproved(isApproved, _value);
        isApproved = _value;
    }

    /**
     * @notice Set whether the collection can be editable or not.
     * @param _value - Value to set
     */
    function setEditable(bool _value) external onlyOwner {
        require(isEditable != _value, "BelandCol: value is the same");
        emit SetEditable(isEditable, _value);
        isEditable = _value;
    }

    /**
     * @notice Get the amount of items
     */
    function itemsLenth() external view returns (uint256) {
        return items.length;
    }
}
