// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../BrainManagementContract.sol";
import "../MINDSDynamicRewardSystem.sol";

contract CalcRewardsPerSecondTest is Test {
    BrainManagementContract public brainManagementContract;
    MINDSDynamicRewardSystem public updateDailyRewards;

    struct RewardsCoordinates {
        int256 percentageChange;
        uint256 reward;
    }
    RewardsCoordinates[] private rewardsTable;

    function setUp() public {
        // Deploy dummy brain-management smart contract
        brainManagementContract = new BrainManagementContract();
        // Deploy UpdateDailyRewards contract
        updateDailyRewards = new MINDSDynamicRewardSystem(
            address(brainManagementContract)
        );
        // Test #1 When percentage change is -15.00
        rewardsTable.push(RewardsCoordinates(-15 * 10**18, (0.02 * 10**18)));
        // Test #2 When percentage change is -5.00
        rewardsTable.push(
            RewardsCoordinates(-5 * 10**18, (0.04254545455 * 10**18))
        );
        // Test #3 When percentage change is 0.00
        rewardsTable.push(RewardsCoordinates(0, (0.06214545455 * 10**18)));
        // Test #4 When percentage change is 4.536
        rewardsTable.push(
            RewardsCoordinates(4.536 * 10**18, (0.07334545455 * 10**18))
        );
        // Test #5 When percentage change is 25.00
        rewardsTable.push(RewardsCoordinates(25.00 * 10**18, (0.1 * 10**18)));
    }

    /**
     * forge test --match-contract CalcRewardsPerSecondTest -vvv
     */
    function testCalculateRewardsPerSecond() public {
        for (uint256 i = 0; i < rewardsTable.length; i++) {
            uint256 calculatedRewardsPerSecond = updateDailyRewards
                .calculateRewardsPerSecond(rewardsTable[i].percentageChange);
            uint256 expectedRewardsPerSecond = rewardsTable[i].reward / 86400;

            assertEq(calculatedRewardsPerSecond, expectedRewardsPerSecond);
            console.logString(
                "// ******************************************************** //"
            );
            console.logString("Given Percentage:");
            console.logInt(rewardsTable[i].percentageChange);
            console.logString("Calculated reward/second:");
            console.logUint(calculatedRewardsPerSecond);
            console.logString("Expected reward/second:");
            console.logUint(expectedRewardsPerSecond);
        }
    }
}
