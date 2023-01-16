// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../BrainManagementContract.sol";
import "../UpdateDailyRewards.sol";

contract CalcRewardsPerSecondTest is Test {
    BrainManagementContract public brainManagementContract;
    UpdateDailyRewards public updateDailyRewards;

    function setUp() public {
        brainManagementContract = new BrainManagementContract();
        updateDailyRewards = new UpdateDailyRewards(
            address(brainManagementContract)
        );
    }

    // function testFulfill() public {
    //     updateDailyRewards.fulfill(_requestId, _priceChangePercentage);
    //     assertEq(updateDailyRewards.number(), 1);
    // }

    function testLastPercentageChange() public {
        assertEq(updateDailyRewards.lastPercentageChange(), 0);
    }
}
