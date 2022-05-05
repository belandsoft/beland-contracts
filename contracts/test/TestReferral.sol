// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;



contract TestReferral {
    mapping(address => address) private _referrers;

    function recordReferral(address _user, address _referrer) external {
        if (_referrers[_user] == address(0)) {
            _referrers[_user] = _referrer;
        }
    }

    function getReferrer(address _user) external view returns (address){
        return _referrers[_user];
    }

    function recordReferralCommission(address _referrer, uint256 _commission)
        external {

        }
}