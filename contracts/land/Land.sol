// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Land is ERC721, Ownable {
    uint256 public WIDTH = 300;
    uint256 public HEIGHT = 300;
    string public baseURI;
    mapping(address => bool) _minters;
    mapping(uint256 => address) _tokenOperator;
    mapping(address => mapping(address => bool)) _operatorUpdates;

    event MinterUpdate(address _minter, bool _isMinter);
    event MetadataUpdate(uint256 landId, string data);
    event SetOperator(uint256 tokenId, address operator);
    event SetOperatorUpdates(address owner, address operator, bool approved);

    mapping(uint256 => string) public metadata;

    modifier onlyMinter() {
        require(_minters[_msgSender()], "Land: only minter");
        _;
    }

    modifier onlyOperatorOrTokenOwner(uint256 tokenId) {
        require(
            _isOperator(_msgSender(), tokenId) ||
                _isApprovedOrOwner(_msgSender(), tokenId),
            "Land: only operator or owner"
        );
        _;
    }

    constructor() ERC721("BeLand", "BLAND") {}

    function isOperator(address _operator, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _isOperator(_operator, tokenId);
    }

    function isOperatorUpdates(address owner, address _operator)
        external
        view
        returns (bool)
    {
        return _operatorUpdates[owner][_operator];
    }

    function _isOperator(address _operator, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return
            owner == _operator ||
            _tokenOperator[tokenId] == _operator ||
            _operatorUpdates[owner][_operator];
    }

    /**
     * @notice Create new Land
     * @param user: address of user
     * @param landId: landId
     */
    function create(address user, uint256 landId) external onlyMinter {
        require(landId <= WIDTH * HEIGHT, "Land: landId bigger than limit");
        _safeMint(user, landId);
    }

    /**
     * @notice batch create land
     * @param user: address of user
     * @param landIds: ids of the land
     */
    function batchCreate(address user, uint256[] memory landIds)
        external
        onlyMinter
    {
        for (uint256 i = 0; i < landIds.length; i++) {
            require(
                landIds[i] <= WIDTH * HEIGHT,
                "Land: landId bigger than limit"
            );
            _safeMint(user, landIds[i]);
        }
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        _minters[_minter] = _isMinter;
        emit MinterUpdate(_minter, _isMinter);
    }

    function x(uint256 landId) external view returns (uint256) {
        return landId % WIDTH;
    }

    function y(uint256 landId) external view returns (uint256) {
        return landId / HEIGHT;
    }

    /**
     * @notice set metdata
     * @param landId: id of land
     * @param data: data
     */
    function setMetadata(uint256 landId, string memory data)
        external
        onlyOperatorOrTokenOwner(landId)
    {
        metadata[landId] = data;
        emit MetadataUpdate(landId, data);
    }

    function setOperator(uint256 tokenId, address _operator)
        public
        onlyOperatorOrTokenOwner(tokenId)
    {
        require(_operator != address(0x0), "zero address");
        require(_tokenOperator[tokenId] != _operator, "not change");
        _tokenOperator[tokenId] = _operator;
        emit SetOperator(tokenId, _operator);
    }

    function setOperatorUpdates(address _operator, bool approved) external {
        require(_operator != address(0x0), "zero address");
        require(_operator != _msgSender(), "same sender");
        _operatorUpdates[_msgSender()][_operator] = approved;
        emit SetOperatorUpdates(_msgSender(), _operator, approved);
    }

    function setManyOperator(uint256[] calldata tokenIds, address _operator)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            setOperator(tokenIds[i], _operator);
        }
    }

    function setBaseURI(string calldata __baseURI) external onlyOwner {
        baseURI = __baseURI;
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
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        _tokenOperator[tokenId] = address(0x0);
        emit SetOperator(tokenId, address(0x0));
    }
}
