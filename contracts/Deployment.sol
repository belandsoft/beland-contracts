// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Deployment {
    using Counters for Counters.Counter;
    Counters.Counter private _deploymentIds;
    mapping(uint256 => address) public deploymentOwner;

    event DeployNew(uint256 deploymentId, string tokenURI);
    event DeploymentRemoved(uint256 deploymentId);

    /**
     * @notice Deploy
     * @param tokenURI: token URI
     */
    function deploy(string memory tokenURI) external {
        _deploymentIds.increment();
        deploymentOwner[_deploymentIds.current()] = msg.sender;
        emit DeployNew(_deploymentIds.current(), tokenURI);
    }

    /**
     * @notice remove deployment by id
     * @param deploymentId: deployment id
     */
    function remove(uint256 deploymentId) external {
        require(
            deploymentOwner[deploymentId] == msg.sender,
            "only deployment owner"
        );
        delete deploymentOwner[deploymentId];
        emit DeploymentRemoved(deploymentId);
    }
}
