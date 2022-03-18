// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BelandNFT.sol";

interface IBelandNFT {
    function initialize(
        string memory _name,
        string memory _symbol,
        address creator
    ) external;
}

contract BelandNFTFactory is Ownable {
    bytes32 public constant INIT_CODE_NFT_HASH =
        keccak256(abi.encodePacked(type(BelandNFT).creationCode));
    address[] public collections;
    mapping(address => bool) public isCollectionFromFactory;
    string public baseURI;
    mapping(string => mapping(string => mapping(address => address))) getCollection;

    event CollectionCreated(
        address indexed nft,
        string name,
        string symbol,
        address creator
    );

    function create(string memory _name, string memory _symbol)
        external
        returns (address nft)
    {
        require(getCollection[_name][_symbol][_msgSender()] == address(0), 'BelandNFTFactory: COLLECTION_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(BelandNFT).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_name, _symbol, _msgSender())
        );
        assembly {
            nft := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBelandNFT(nft).initialize(_name, _symbol, _msgSender());
        Ownable(nft).transferOwnership(owner());
        collections.push(nft);
        isCollectionFromFactory[nft] = true;
        getCollection[_name][_symbol][_msgSender()] = nft;
        emit CollectionCreated(nft, _name, _symbol, _msgSender());
    }

    /**
     * @notice Get the amount of collections deployed
     * @return amount of collections deployed
     */
    function collectionsLength() external view returns (uint256) {
        return collections.length;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}
