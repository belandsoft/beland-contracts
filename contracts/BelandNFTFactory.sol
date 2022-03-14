// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BelandNFT.sol";

contract BelandNFTFactory is Ownable {
    address[] public collections;
    mapping(address => bool) public isCollectionFromFactory;
    string public baseURI;

    event CollectionCreated(address indexed collectionAddr);

    function create(
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        BelandNFT nft = new BelandNFT(
            _name,
            _symbol,
            _msgSender()
        );
        address nftAddr = address(nft);
        Ownable(nftAddr).transferOwnership(owner());
        collections.push(nftAddr);
        isCollectionFromFactory[nftAddr] = true;
        emit CollectionCreated(nftAddr);
        return nftAddr;
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
