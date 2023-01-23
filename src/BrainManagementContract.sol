// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BrainManagementContract {
    uint256 public count;

    mapping(uint256 => uint256) public rewardsPerSecond;

    function setRewardsPerSecond(uint256 value) public {
        rewardsPerSecond[count] = value;
        count++;
    }
}
