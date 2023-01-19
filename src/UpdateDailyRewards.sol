// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// Chainlink Automation compatible imports
import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

interface IBrainManagementContract {
    function setRewardsPerSecond(uint256 value) external;
}

contract UpdateDailyRewards is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    /**
     * Variable to track the last percentage change
     */
    int256 public lastPercentageChange;
    /**
     * Variable type used to calculate reward per percentage
     */
    struct RewardsCoordinates {
        int256 percentageChange;
        int256 reward;
    }
    /**
     * Current system table coordinates (spreadsheet table)
     */
    RewardsCoordinates[] private rewardsTable;
    /**
     * Chainlink Any API
     */
    bytes32 private jobId;
    uint256 private fee;
    bool private wasResquested;
    /**
     * Chainlink Automation
     */
    uint256 private immutable interval; // Interval to perform Update Reward
    uint256 private lastUpdatedTimeStamp; // Last time that rewards were updted
    uint256 private lastUpKeepId; // Last upkeep registred. Fund this upkeep to automation keep runing.
    uint32 private gasLimit; // Gas limit to perform upKeep
    uint96 private automateLinkAmount; // Initial amount of Link token to send to the upkeep
    address private immutable registrar; // Chainlink registrar address
    AutomationRegistryInterface private immutable registry; // Chainlink registry address
    bytes4 private registerSig = KeeperRegistrarInterface.register.selector;
    LinkTokenInterface private immutable link; // Chainlink Token address

    /**
     * Contract interface that we will send new calculated rewardsPerSecond
     */
    IBrainManagementContract private immutable brainManagementContract;

    constructor(address brainManagementContractAddress)
        ConfirmedOwner(msg.sender)
    {
        /**
         * THIS IS AN PROTOTYPE CONTRACT THAT USES HARDCODED VALUES FOR TESTING.
         * DO NOT USE THIS CODE IN PRODUCTION.
         */
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
            RewardsCoordinates(-9.63 * 10**18, 0.0257454545454546 * 10**18)
        );
        rewardsTable.push(RewardsCoordinates(0, 0.0621454545454546 * 10**18));
        rewardsTable.push(
            RewardsCoordinates(0.556 * 10**18, 0.0635454545454546 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(14.44 * 10**18, 0.0985454545454545 * 10**18)
        );
        rewardsTable.push(RewardsCoordinates(15.00 * 10**18, 0.1 * 10**18));

        interval = 24 * 60 * 60; // 24 horas em segundos
        lastUpdatedTimeStamp = block.timestamp;
        automateLinkAmount = 5 * 10**18;

        link = LinkTokenInterface(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3); // Mumbai
        registrar = 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3; // Mumbai
        registry = AutomationRegistryInterface(
            0x40193c8518BB267228Fc409a613bDbD8eC5a97b3
        ); // Mumbai

        // registrar = address; // BNB Chain testnet
        // registry = AutomationRegistryInterface(); // MumbaiBNB Chain testnet
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
         * Analyzing the table values ​​found in the README file,
         * all intervals belong to linear equations.
         * We were able to find any 'reward' value within the given range.
         * Two Point Form
         * https://www.cuemath.com/geometry/two-point-form/
         */
        _y = (((maxY - minY) / (maxX - minX)) * (x - maxX)) + maxY;
    }

    /**
     * Calculate the current percentage change.
     */
    function calculateCurrentPercentageChange(
        int256 _lastPercentageChange,
        int256 _priceChangePercentage
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
        public
        view
        returns (int256 _rewardsPerSecond)
    {
        // The rewards cannot be lower than 0.02 MIND+ per day
        // if ( % <= -10.00 ) { r = 0.02}
        if (_currentPercentageChange <= rewardsTable[0].percentageChange)
            return _rewardsPerSecond = rewardsTable[0].reward / 86400;
        // And cannot be higher than 0.1 MIND+ per day
        // if ( % > 15.00 ) { r = 0.1}
        if (
            _currentPercentageChange >
            rewardsTable[rewardsTable.length - 1].percentageChange
        )
            return
                _rewardsPerSecond =
                    rewardsTable[rewardsTable.length - 1].reward /
                    86400;

        for (uint256 i = 0; i < rewardsTable.length - 1; i++) {
            // Must be used with provided rewards structure
            // All intervals are linear.
            // It goes from negative 10% to positive 15%
            // i = 0; if ( -10.00 < % <= -9.63 ) { 0.02 < r <= 0.02574545455 }
            // i = 1; if ( -9.63 < % <= 0.00 ) { 0.02574545455 < r <= 0.06214545455 }
            // i = 2; if ( 0.00 < % <= 0.556 ) { 0.06214545455 < r <= 0.06354545455 }
            // i = 3; if ( 0.556 < % <= 14.44 ) { 0.06354545455 < r <= 0.09854545455 }
            // i = 4; if ( 14.44 < % <= 15.00 ) { 0.09854545455 < r <= 0.1 }
            if (
                _currentPercentageChange > rewardsTable[i].percentageChange &&
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
    function updatePriceChangePercentage(
        int256 _percentageChange,
        uint256 _timestamp
    ) internal {
        lastPercentageChange = _percentageChange;
        lastUpdatedTimeStamp = _timestamp;
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
        updatePriceChangePercentage(_currentPercentageChange, block.timestamp);
        wasResquested = false;
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 10 ** 18 (to remove decimal places from data).
     */
    function requestUpdateDailyRewards() public returns (bytes32 requestId) {
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

        wasResquested = true;
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Chainlink automation allow the protocol to run on autopilot without
     * human intervention to adjust daily rewards.
     * We call this function once, and after just garantee that the last
     * upkeep is alaways funded.
     */
    function initiateAutomaticRewardSystem() public {
        (State memory state, Config memory _c, address[] memory _k) = registry
            .getState();
        uint256 oldNonce = state.nonce;
        bytes memory checkData;
        bytes memory payload = abi.encode(
            "Automatic Reward System",
            "0x",
            address(this),
            gasLimit,
            address(msg.sender),
            checkData,
            automateLinkAmount,
            0,
            address(this)
        );

        link.transferAndCall(
            registrar,
            automateLinkAmount,
            bytes.concat(registerSig, payload)
        );
        (state, _c, _k) = registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(registry),
                        uint32(oldNonce)
                    )
                )
            );
            lastUpKeepId = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    /**
     * checkUpkeep function contains the logic that will be executed off-chain
     * to see if performUpkeep should be executed
     * After you register the contract as an upkeep, the Chainlink Automation
     * Network simulates our checkUpkeep off-chain during every block to determine
     * if the updateInterval time has passed since the last increment (timestamp).
     * This cycle repeats until the upkeep is cancelled or runs out of funding.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded =
            (block.timestamp - lastUpdatedTimeStamp) > interval &&
            !wasResquested;
        // We don't use the checkData in this case.
        // The checkData is defined when the Upkeep was registered.
    }

    /**
     * performUpkeep function will be executed on-chain when checkUpkeep returns true
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (
            (block.timestamp - lastUpdatedTimeStamp) > interval &&
            !wasResquested
        ) {
            requestUpdateDailyRewards();
        }
        // We don't use the performData in this case.
        // The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    /**
     * Check contract's Link token balance
     */
    function contractLinkBalance()
        public
        view
        onlyOwner
        returns (uint256 balance)
    {
        balance = link.balanceOf(address(this));
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
