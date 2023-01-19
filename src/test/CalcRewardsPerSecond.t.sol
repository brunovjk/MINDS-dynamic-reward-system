// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../BrainManagementContract.sol";
import "../UpdateDailyRewards.sol";

contract CalcRewardsPerSecondTest is Test {
    BrainManagementContract public brainManagementContract;
    UpdateDailyRewards public updateDailyRewards;

    struct RewardsCoordinates {
        int256 percentageChange;
        int256 reward;
    }
    RewardsCoordinates[] private rewardsTable;

    function setUp() public {
        // Deploy dummy brain-management smart contract
        brainManagementContract = new BrainManagementContract();
        // Deploy UpdateDailyRewards contract
        updateDailyRewards = new UpdateDailyRewards(
            address(brainManagementContract)
        );
        // Test when percentage change is -10.00
        rewardsTable.push(RewardsCoordinates(-10 * 10**18, (0.02 * 10**18)));
        // Test when percentage change is -9.63
        rewardsTable.push(
            RewardsCoordinates(-9.63 * 10**18, (0.0257454545454546 * 10**18))
        );
        // Test when percentage change is 0.00
        rewardsTable.push(RewardsCoordinates(0, (0.0621454545454546 * 10**18)));
        // Test when percentage change is 0.556
        rewardsTable.push(
            RewardsCoordinates(0.556 * 10**18, (0.0635454545454546 * 10**18))
        );
        // Test when percentage change is 14.44
        rewardsTable.push(
            RewardsCoordinates(14.44 * 10**18, (0.0985454545454545 * 10**18))
        );
        // Test when percentage change is 15.00
        rewardsTable.push(RewardsCoordinates(15.00 * 10**18, (0.1 * 10**18)));
        // Test when percentage change is bigger than 15.00
        rewardsTable.push(RewardsCoordinates(25.00 * 10**18, (0.1 * 10**18)));
    }

    /**
     * forge test --match-contract CalcRewardsPerSecondTest -vvvv
     * -vvvv See all tested values
     */
    function testCalculateRewardsPerSecond() public {
        for (uint256 i = 0; i < rewardsTable.length; i++) {
            assertEq(
                updateDailyRewards.calculateRewardsPerSecond(
                    rewardsTable[i].percentageChange
                ),
                rewardsTable[i].reward / 86400
            );
        }
    }
}
