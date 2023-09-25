// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Deployment is Ownable{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    
    Counters.Counter private _deploymentIds;
    mapping(uint256 => address) public deploymentOwner;
    address public treasuryAddress;
    uint256 public fee;
    address public  feeQuoteToken;

    event DeployNew(uint256 deploymentId, string tokenURI);
    event DeploymentRemoved(uint256 deploymentId);
    event FeeUpdated(uint256 fee);
    event TreasuryAddressUpdated(address treasuryAddress);
    event FeeQuoteTokenUpdated(address feeQuoteToken);

    constructor(address _treasuryAddress, uint256 _fee, address _feeQuoteToken) {
        treasuryAddress = _treasuryAddress;
        fee = _fee;
        feeQuoteToken = _feeQuoteToken;
    }


    function setTreasuryAddress(address _treasuryAddress) public onlyOwner() {
        require(treasuryAddress != _treasuryAddress, "not changed");
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressUpdated(_treasuryAddress);
    }

    function setFee(uint256 _fee) public onlyOwner() {
        require(fee != _fee, "not changed");
        fee = _fee;
        emit FeeUpdated(fee);
    }

    function setFeeQuoteToken(address _feeQuoteToken) public onlyOwner() {
        require(feeQuoteToken != _feeQuoteToken, "not changed");
        feeQuoteToken = _feeQuoteToken;
        emit FeeQuoteTokenUpdated(_feeQuoteToken);
    }

    /**
     * @notice Deploy
     * @param tokenURI: token URI
     */
    function deploy(string memory tokenURI) external {
        if (treasuryAddress != address(0) && fee > 0) {
            IERC20(feeQuoteToken).safeTransferFrom(
                _msgSender(),
                treasuryAddress,
                fee
            );
        }

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
