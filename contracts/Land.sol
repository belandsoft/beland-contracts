// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Land is ERC721, Ownable {
    mapping(address => bool) _minters;
    event MinterUpdate(address _minter, bool _isMinter);
    event MetdataUpdate(uint256 landId, string data);

    mapping(uint256 => string) public metadata;

    modifier onlyMinter() {
        require(_minters[_msgSender()], "Land: only minter");
        _;
    }

    constructor() ERC721("BeLand", "BLAND") {}

    /**
     * @notice Create new Land
     * @param user: address of user
     * @param landId: landId
     */
    function create(address user, uint256 landId) external onlyMinter {
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
            _safeMint(user, landIds[i]);
        }
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        _minters[_minter] = _isMinter;
        emit MinterUpdate(_minter, _isMinter);
    }

    /**
     * @notice set metdata
     * @param landId: id of land
     * @param data: data
     */
    function setMetadata(uint256 landId, string memory data) external {
        require(
            _isApprovedOrOwner(_msgSender(), landId),
            "ERC721: transfer caller is not owner nor approved"
        );
        metadata[landId] = data;
        emit MetdataUpdate(landId, data);
    }
}
