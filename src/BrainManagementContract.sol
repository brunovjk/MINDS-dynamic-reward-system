// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 0x85c4c7489c6BBed971406E9C28B96a947c07305C
contract BrainManagementContract {
    uint256 public count;

    mapping(uint256 => uint256) public rewardsPerSecond;

    function setRewardsPerSecond(uint256 value) public {
        rewardsPerSecond[count] = value;
        count++;
    }
}
