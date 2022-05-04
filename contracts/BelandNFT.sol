// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libs/String.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IFactory {
    function baseURI() external view returns (string memory);
}

contract BelandNFT is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using String for address;

    bool public isApproved = false;
    address public creator;
    mapping(address => bool) _minters;
    address public factory;
    string public baseURI;

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

    mapping(uint256 => uint256) private _itemOfToken;
    Item[] public items;

    // Events
    event ItemsAdd(ItemParams[] _items);
    event ItemsEdit(uint256[] indexes, ItemParams[] _items);
    event MinterUpdate(address _minter, bool _isMinter);
    event Created(address user, uint256 tokenId, uint256 itemId);
    event SetApproved(bool _previousValue, bool _newValue);
    event SetEditable(bool _previousValue, bool _newValue);
    event CreatorshipTransferred(
        address indexed previousCreator,
        address indexed newCreator
    );

    modifier onlyMinter() {
        require(_minters[_msgSender()], "BelandNFT: only minter");
        _;
    }

    modifier onlyCreator() {
        require(creator == _msgSender(), "BelandNFT: only creator");
        _;
    }

    modifier onlyCreatorOrOwner() {
        require(
            creator == _msgSender() || owner() == _msgSender(),
            "BelandNFT: only creator or owner"
        );
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        string memory _name,
        string memory _symbol,
        address _creator,
        string memory _baseURI
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        creator = _creator;
        factory = _msgSender();
        baseURI = _baseURI;
    }

    function setMinter(address _minter, bool _isMinter) external onlyCreator {
        _minters[_minter] = _isMinter;
        emit MinterUpdate(_minter, _isMinter);
    }

    /**
     * @dev Transfers creatorship of the contract to a new account (`newCreator`).
     * Can only be called by the current creator.
     */
    function transferCreatorship(address newCreator)
        public
        virtual
        onlyCreatorOrOwner
    {
        require(
            newCreator != address(0),
            "BelandNFT: new creator is the zero address"
        );
        _transferCreatorship(newCreator);
    }

    /**
     * @dev Transfers creatorship of the contract to a new account (`newCreator`).
     * Internal function without access restriction.
     */
    function _transferCreatorship(address newCreator) internal virtual {
        address oldCreator = creator;
        creator = newCreator;
        emit CreatorshipTransferred(oldCreator, creator);
    }

    /**
     * @notice Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId - uint256 ID of the token queried
     * @return token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "tokenURI: INVALID_TOKEN_ID");
        string memory base = baseURI;
        if (bytes(base).length == 0) {
            base = IFactory(factory).baseURI();
        }
        return
            string(
                abi.encodePacked(
                    base,
                    "0x",
                    address(this).addressToString(),
                    "/",
                    Strings.toString(_tokenId)
                )
            );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Add new items
     * @param _items: list item params
     */
    function addItems(ItemParams[] memory _items) external onlyOwner {
        for (uint256 i = 0; i < _items.length; i++) {
            items.push(
                Item({
                    maxSupply: _items[i].maxSupply,
                    totalSupply: 0,
                    price: _items[i].price,
                    tokenURI: _items[i].tokenURI,
                    treasury: _items[i].treasury
                })
            );
        }
        emit ItemsAdd(_items);
    }

    /**
     * @notice Create new nft
     * @param user: address of user
     * @param itemIndex: idex of item
     */
    function create(address user, uint256 itemIndex) external onlyMinter {
        require(isApproved, "BelandNFT: not approved");
        _create(user, itemIndex);
    }

    function _create(address user, uint256 itemIndex) private {
        require(items.length > itemIndex, "BelandNFT: item not found");
        require(
            items[itemIndex].totalSupply < items[itemIndex].maxSupply,
            "BelandNFT: max supply"
        );
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);
        _itemOfToken[newTokenId] = itemIndex;
        items[itemIndex].totalSupply++;
        emit Created(user, newTokenId, itemIndex);
    }

    /**
     * @notice batch create nfts
     * @param user: address of user
     * @param itemId: item id
     * @param qty: quantity
     */
    function batchCreate(
        address user,
        uint256 itemId,
        uint256 qty
    ) external onlyMinter {
        require(isApproved, "BelandNFT: not approved");
        for (uint256 i = 0; i < qty; i++) {
            _create(user, itemId);
        }
    }

    /**
     * @notice Approve a collection
     * @param _value - Value to set
     */
    function setApproved(bool _value) external virtual onlyOwner {
        require(isApproved != _value, "BelandNFT: value is the same");
        emit SetApproved(isApproved, _value);
        isApproved = _value;
    }

    /**
     * @notice Get the amount of items
     */
    function itemsLength() external view returns (uint256) {
        return items.length;
    }

    function itemOfToken(uint256 _tokenId) external view returns (Item memory) {
        require(_exists(_tokenId), "tokenURI: INVALID_TOKEN_ID");
        return items[_itemOfToken[_tokenId]];
    }

    function itemPrice(uint256 _itemId) external view returns (uint256) {
        require(items[_itemId].maxSupply > 0, "item not found");
        return items[_itemId].price;
    }
}
