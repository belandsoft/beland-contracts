// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BelandCol.sol";

contract BelandColFactory is Ownable {
    address[] public collections;
    mapping(address => bool) public isCollectionFromFactory;

    event CollectionCreated(address indexed collectionAddr);

    function create(string memory _name, string memory _symbol)
        external
        returns (address)
    {
        BelandCol belandCol = new BelandCol(_name, _symbol, _msgSender());
        address colAddr = address(belandCol);
        Ownable(colAddr).transferOwnership(owner());
        collections.push(colAddr);
        isCollectionFromFactory[colAddr] = true;
        emit CollectionCreated(colAddr);
        return colAddr;
    }

    /**
     * @notice Get the amount of collections deployed
     * @return amount of collections deployed
     */
    function collectionsLength() external view returns (uint256) {
        return collections.length;
    }
}
