// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Scene is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event DeployNew(uint256 sceneId, string tokenURI);

    constructor() public ERC721("Scene", "SCE") {}

    /**
     * @notice Create Scene
     * @param user: address of owner
     * @param tokenURI: token URI
     */
    function create(address user, string memory tokenURI) external {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    /**
     * @notice Create Scene
     * @param sceneId: id of scene
     * @param tokenURI: token URI
     */
    function deploy(uint256 sceneId, string memory tokenURI) {
        require(
            _isApprovedOrOwner(_msgSender(), sceneId),
            "ERC721: deploy caller is not owner nor approved"
        );
        _setTokenURI(sceneId, tokenURI);
        emit DeployNew(sceneId, tokenURI);
    }
}
