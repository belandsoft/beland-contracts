// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IReferral {
    function recordReferral(address _user, address _referrer) external;

    function getReferrer(address _user) external view returns (address);

    function recordReferralCommission(address _referrer, uint256 _commission)
        external;
}