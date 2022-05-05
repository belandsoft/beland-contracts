// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BelandNFT.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBelandNFT.sol";

contract BelandNFTFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant INIT_CODE_NFT_HASH =
        keccak256(abi.encodePacked(type(BelandNFT).creationCode));
    address[] public collections;
    mapping(address => bool) public isCollectionFromFactory;
    string public baseURI;
    mapping(string => mapping(string => mapping(address => address))) getCollection;
    uint256 public creatingFee = 100 ether;
    uint256 public maxCreatingFee = 1000 ether;
    address public treasuryAddr;
    address public quoteToken;

    event CollectionCreated(
        address indexed nft,
        string name,
        string symbol,
        address creator
    );

    event SetCreatingFee(uint256 _creatingFee);
    event SetTreasury(address _treasury);
    event SetQuoteToken(address _token);

    constructor(
        address _treasuryAddr,
        address _quoteToken,
        uint256 _creatingFee
    ) {
        treasuryAddr = _treasuryAddr;
        quoteToken = _quoteToken;
        creatingFee = _creatingFee;
    }

    function setCreatingFee(uint256 _creatingFee) external onlyOwner {
        require(_creatingFee <= maxCreatingFee, "max creating fee");
        creatingFee = _creatingFee;
        emit SetCreatingFee(_creatingFee);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero addr");
        treasuryAddr = _treasury;
        emit SetTreasury(_treasury);
    }

    function setQuoteToken(address _token) external onlyOwner {
        require(_token != address(0), "zero addr");
        quoteToken = _token;
        emit SetQuoteToken(_token);
    }

    function create(
        string memory _name,
        string memory _symbol,
        IBelandNFT.ItemParams[] memory _items,
        string memory _baseURI
    ) external returns (address nft) {
        require(
            getCollection[_name][_symbol][_msgSender()] == address(0),
            "BelandNFTFactory: COLLECTION_EXISTS"
        ); // single check is sufficient

        // pay fee for create collection
        if (creatingFee > 0) {
            uint256 fees = creatingFee.mul(_items.length);
            IERC20(quoteToken).safeTransferFrom(
                _msgSender(),
                treasuryAddr,
                fees
            );
        }

        bytes memory bytecode = type(BelandNFT).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_name, _symbol, _msgSender())
        );
        assembly {
            nft := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBelandNFT(nft).initialize(_name, _symbol, _msgSender(), _baseURI);
        collections.push(nft);
        isCollectionFromFactory[nft] = true;
        getCollection[_name][_symbol][_msgSender()] = nft;
        emit CollectionCreated(nft, _name, _symbol, _msgSender());
        IBelandNFT(nft).addItems(_items);
        Ownable(nft).transferOwnership(owner());
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
