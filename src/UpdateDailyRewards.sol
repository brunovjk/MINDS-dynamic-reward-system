// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface IBrainManagementContract {
    function setRewardsPerSecond(uint256 value) external;
}

contract UpdateDailyRewards is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    int256 public lastPercentageChange;

    struct RewardsCoordinates {
        int256 percentageChange;
        int256 reward;
    }
    RewardsCoordinates[] private rewardsTable;

    bytes32 private jobId;
    uint256 private fee;

    IBrainManagementContract private immutable brainManagementContract;

    constructor(address brainManagementContractAddress)
        ConfirmedOwner(msg.sender)
    {
        // setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06); // BNB Chain testnet
        // setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7); // BNB Chain testnet

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // Mumbai
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3); // mumbai
        jobId = "fcf4140d696d44b687012232948bdd5d"; // GET>int256: https://docs.chain.link/any-api/testnet-oracles
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        brainManagementContract = IBrainManagementContract(
            brainManagementContractAddress
        ); // Dummy brain-management smart contract

        /*
         * Table to calculate rewards according to percentage of price change tracking.
         * https://docs.google.com/document/d/1OWWFLzC-qi5yQWTbGCaTOckSxIvRNPev_BiiZfQYJ_Q/edit?usp=sharing
         */
        rewardsTable.push(RewardsCoordinates(-10 * 10**18, 0.02 * 10**18));
        rewardsTable.push(
            RewardsCoordinates(-9.63 * 10**18, 0.02574545455 * 10**18)
        );
        rewardsTable.push(RewardsCoordinates(0, 0.06214545455 * 10**18));
        rewardsTable.push(
            RewardsCoordinates(0.556 * 10**18, 0.06354545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(14.44 * 10**18, 0.09854545455 * 10**18)
        );
        rewardsTable.push(RewardsCoordinates(15.00 * 10**18, 0.1 * 10**18));
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 10 ** 18 (to remove decimal places from data).
     */
    function requestPriceChangePercentage() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", "https://api.coingecko.com/api/v3/coins/biggerminds");
        // Chainlink nodes 1.0.0 and later support this format
        req.add("path", "market_data,price_change_percentage_24h");

        // Multiply the result by 10 ** 18 to remove decimals
        int256 timesAmount = 10**18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Calculate rewards within a specific range.
     */
    function calculateCoordinateY(
        int256 x,
        int256 minX,
        int256 maxX,
        int256 minY,
        int256 maxY
    ) internal pure returns (int256 _y) {
        /**
         * Analyzing the values, we see that all intervals are linear equations:
         * https://docs.google.com/document/d/1OWWFLzC-qi5yQWTbGCaTOckSxIvRNPev_BiiZfQYJ_Q/edit?usp=sharing
         * So we can do this:
         * https://medium.com/not-zero/linear-equation-50a847f58665
         * minY = (a * minX) + b
         * maxY = (a * maxX) + b
         */
        int256 a = (minY - maxY) / (minX - maxX);
        int256 b = ((minY * maxX) - (minX * maxY)) / (maxX - minX);
        _y = (a * x) + b;
    }

    /**
     * Calculate the current percentage change.
     */
    function calculateCurrentPercentageChange(
        int256 _priceChangePercentage,
        int256 _lastPercentageChange
    ) internal pure returns (int256 _currentPercentageChange) {
        _currentPercentageChange =
            _lastPercentageChange +
            _priceChangePercentage;
    }

    /**
     * Calculate RewardsPerSecond according to current percentage change.
     * Return daily rewards in 'per the second' format: value in Wei / 86400
     */
    function calculateRewardsPerSecond(int256 _currentPercentageChange)
        internal
        view
        returns (int256 _rewardsPerSecond)
    {
        // if ( % <= -10.00 ) { r = 0.02}
        if (_currentPercentageChange <= rewardsTable[0].percentageChange)
            return _rewardsPerSecond = rewardsTable[0].reward / 86400;
        // if ( % > 15.00 ) { r = 0.1}
        if (
            _currentPercentageChange >
            rewardsTable[rewardsTable.length - 1].percentageChange
        )
            return
                _rewardsPerSecond =
                    rewardsTable[rewardsTable.length - 1].reward /
                    86400;

        for (uint256 i = 0; i < rewardsTable.length - 2; i++) {
            // i = 0; if ( -10.00 < % <= -9.63 ) { 0.02 < r <= 0.02574545455 }
            // i = 1; if ( -9.63 < % <= 0.00 ) { 0.02574545455 < r <= 0.06214545455 }
            // i = 2; if ( 0.00 < % <= 0.556 ) { 0.06214545455 < r <= 0.06354545455 }
            // i = 3; if ( 0.556 < % <= 14.44 ) { 0.06354545455 < r <= 0.09854545455 }
            // i = 4; if ( 14.44 < % <= 15.00 ) { 0.09854545455 < r <= 0.1 }
            if (
                rewardsTable[i].percentageChange > _currentPercentageChange &&
                _currentPercentageChange <= rewardsTable[i + 1].percentageChange
            )
                return
                    _rewardsPerSecond =
                        calculateCoordinateY(
                            _currentPercentageChange, // x
                            rewardsTable[i].percentageChange, // minX,
                            rewardsTable[i + 1].percentageChange, // maxX,
                            rewardsTable[i].reward, // minY,
                            rewardsTable[i + 1].reward // maxY
                        ) /
                        86400;
        }
    }

    /**
     * Send RewardsPerSecond to Brain Management Contract.
     */
    function sendRewardsPerSecond(int256 rewardsPerSecond) internal {
        brainManagementContract.setRewardsPerSecond(uint256(rewardsPerSecond));
    }

    /**
     * Update percentageChange to be used in the next 24h.
     */
    function updatePriceChangePercentage(int256 _percentageChange) internal {
        lastPercentageChange = _percentageChange;
    }

    /**
     * Receive the response in the form of int256
     * We are going to use this function, which is called by a ChainLink node,
     * to trigger Calculate Rewards and Send Rewards.
     */
    function fulfill(bytes32 _requestId, int256 _priceChangePercentage)
        public
        recordChainlinkFulfillment(_requestId)
    {
        // Calculate current percentage change
        int256 _currentPercentageChange = calculateCurrentPercentageChange(
            _priceChangePercentage,
            lastPercentageChange
        );
        // Calculate current rewardsPerSecond
        int256 _rewardsPerSecond = calculateRewardsPerSecond(
            _currentPercentageChange
        );
        // Send Rewards to Brain Management Contract
        sendRewardsPerSecond(_rewardsPerSecond);
        // Update percentage change to be used in the next 24h
        updatePriceChangePercentage(_currentPercentageChange);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
