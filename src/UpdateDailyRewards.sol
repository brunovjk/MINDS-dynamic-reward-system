// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
     * Chainlink Any API
     */
    int256 public lastPercentageChange;
    bool internal requestedButNotUpdated;
    bool internal updatedButNotSended;
    bytes32 internal jobId;
    uint256 internal fee;

    /**
     * Variable type used to calculate reward per percentage
     */
    struct RewardsTable {
        int256 percentageChange;
        uint256 reward;
    }

    /**
     * Current system table coordinates (spreadsheet table)
     */
    RewardsTable[] internal rewardsTable;

    /**
     * Chainlink Automation
     */
    /**
     * Make sure they are always funded
     * Check balance and add fund using
     * Registry Address	0x02777053d6764996e594c3E88AF1D58D5363a2e6
     * https://docs.chain.link/chainlink-automation/supported-networks/#configurations
     * Registry.getUpkeep(uint256 upkeepID) returns (target address, executeGas uint32, checkData bytes, balance uint96, lastKeeper address, admin address, maxValidBlocknumber uint64, amountSpent uint96)
     * Registry.addFunds(uint256 upkeepID , uint96 amount)
     * Registry.cancelUpkeep(uint256 upkeepID , uint96 amount)
     */
    uint256 internal immutable updateInterval; // Interval to perform Update Reward
    uint256 internal lastUpdateTimeStamp;
    uint256 internal updateUpkeepID; // Upkeep responsible for updating "priceChangePercentage"
    uint256 internal sendUpkeepID; // Upkeep responsible for sending "rewardsPerSeconds"
    bool internal automationRunning; // Monitor whether the machine is turned on
    // Event emitted when machine is turned on
    event AutomationRunning(
        uint256 indexed updateUpkeepID,
        uint256 indexed sendUpkeepID
    );
    // Event emitted when machine is turned off
    event TurnOffAutomation(
        uint256 indexed updateUpkeepID,
        uint256 indexed sendUpkeepID
    );

    LinkTokenInterface public immutable i_link; // Chainlink Token address
    address public immutable registrar; // Chainlink registrar address
    AutomationRegistryInterface public immutable i_registry; // Chainlink registry address
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    /**
     * Contract interface that we will send new calculated rewardsPerSecond
     */
    IBrainManagementContract private immutable brainManagementContract;

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        address brainManagementContractAddress
    ) ConfirmedOwner(msg.sender) {
        /**
         * THIS IS AN PROTOTYPE CONTRACT THAT USES HARDCODED VALUES FOR TESTING.
         * DO NOT USE THIS CODE IN PRODUCTION.
         */
        // setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06); // BNB Chain testnet
        // setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7); // BNB Chain testnet

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // Mumbai
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3); // mumbai

        brainManagementContract = IBrainManagementContract(
            brainManagementContractAddress
        ); // Dummy brain-management smart contract

        jobId = "fcf4140d696d44b687012232948bdd5d"; // GET>int256: https://docs.chain.link/any-api/testnet-oracles
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        updateInterval = 24 * 60 * 60 seconds;
        lastUpdateTimeStamp = block.timestamp;

        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public {
        require(
            i_link.transfer(msg.sender, i_link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * Check contract's Link token balance
     */
    function contractLinkBalance() public view returns (uint256 balance) {
        balance = i_link.balanceOf(address(this));
    }

    /**
     * Calculate RewardsPerSecond according to current percentage change.
     * Return daily rewards in 'per the second' format: value in Wei / 86400
     */
    function calculateCurrentRewardsPerSecond()
        public
        view
        returns (uint256 _rewardsPerSecond)
    {
        // The rewards cannot be lower than 0.02 MIND+ per day
        // if ( % < -9.63 ) { r = 0.02}
        if (lastPercentageChange < rewardsTable[1].percentageChange)
            return _rewardsPerSecond = rewardsTable[0].reward / 86400;
        // And cannot be higher than 0.1 MIND+ per day
        // if ( % >= 15.00 ) { r = 0.1}
        if (
            lastPercentageChange >=
            rewardsTable[rewardsTable.length - 1].percentageChange
        )
            return
                _rewardsPerSecond =
                    rewardsTable[rewardsTable.length - 1].reward /
                    86400;

        for (uint256 i = 1; i < rewardsTable.length - 1; i++) {
            // i = 1; if ( -9.63 <= % < 0.00 ) { r = 0.02574545455 }
            // i = 2; if ( 0.00 <= % < 0.556 ) { r = 0.06214545455 }
            // i = 3; if ( 0.556 <= % < 14.44 ) { r = 0.06354545455 }
            // i = 4; if ( 14.44 <= % < 15.00 ) { r = 0.09854545455 }
            if (
                rewardsTable[i].percentageChange <= lastPercentageChange &&
                lastPercentageChange < rewardsTable[i + 1].percentageChange
            ) return _rewardsPerSecond = rewardsTable[i].reward / 86400;
        }
    }

    /**
     * Receive the response in the form of int256
     * We are going to use this function, which is called by a ChainLink node,
     * to update lastPercentageChange.
     */
    function fulfill(bytes32 _requestId, int256 _priceChangePercentage)
        public
        recordChainlinkFulfillment(_requestId)
    {
        requestedButNotUpdated = false;
        lastPercentageChange = lastPercentageChange + _priceChangePercentage;
        updatedButNotSended = true;
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

        requestedButNotUpdated = true;
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * performUpkeep function will be executed on-chain when checkUpkeep returns true
     */
    function performUpkeep(bytes calldata performData) external {
        // If checkData is equal to "Update ..."
        // Check if it's been 24 hours since the last update,
        // has not been requested yet
        // and it has not been 'updated but not sent'
        // If yes requestUpdate to true
        //      at FulFill Update but Not Send to true and requestUpdate to false
        if (
            keccak256(performData) ==
            keccak256(bytes("Update Rewards Per Second"))
        ) {
            requestPriceChangePercentage();
        }
        // If checkData is equal to "Send ... + sendPerfomData(rewardsPerSecond)"
        // Check if it was updated but not sent
        // If yes send rewardsPerSecond
        (bytes memory sendCheckData, uint256 rewardsPerSecond) = abi.decode(
            performData,
            (bytes, uint256)
        );
        if (
            keccak256(sendCheckData) ==
            keccak256(bytes("Send Rewards Per Second"))
        ) {
            brainManagementContract.setRewardsPerSecond(rewardsPerSecond);
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
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // If checkData is equal to "Update ..."
        // Check if it's been 24 hours since the last update,
        // has not been requested yet
        // and it has not been 'updated but not sent'
        // If yes (performUpkeep("Update ...")
        if (
            keccak256(checkData) ==
            keccak256(bytes("Update Rewards Per Second"))
        ) {
            upkeepNeeded =
                (block.timestamp - lastUpdateTimeStamp) > updateInterval &&
                !requestedButNotUpdated &&
                !updatedButNotSended;
            performData = checkData;
        }

        // If checkData is equal to "Send ..."
        // Check if it was updated but not sent
        // rewardsPerSecond = calculateRewardsPerSecond
        // If yes performUpkeep("Send ... + sendPerfomData(rewardsPerSecond)")

        if (
            keccak256(checkData) == keccak256(bytes("Send Rewards Per Second"))
        ) {
            upkeepNeeded = updatedButNotSended;
            performData = abi.encode(
                checkData,
                calculateCurrentRewardsPerSecond()
            );
        }
    }

    /**
     * You will need to keep track of the Upkeep ID as your contract will use
     * this to subsequently interact with the Chainlink Automation registry.
     */
    function registerAndPredictID(string memory name)
        public
        returns (uint256 upkeepID)
    {
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;
        bytes memory checkData = abi.encode(name);
        bytes memory payload = abi.encode(
            name,
            "0x",
            address(this),
            5 * 10**8,
            address(msg.sender),
            checkData,
            5 * 10**18,
            0,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            5 * 10**18,
            bytes.concat(registerSig, payload)
        );
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
        } else {
            revert("auto-approve disabled");
        }
    }

    /**
     * Chainlink automation allow the protocol to run on autopilot without
     * human intervention to adjust daily rewards.
     * We call this function once, and after just garantee that the last
     * upkeep is alaways funded.
     */
    function initiateAutomaticRewardSystem() public {
        // Ensure that automation has not started.
        // Let there be only one running.
        require(!automationRunning, "Automation is already running");
        // Register Automation responsible for updating Rewards Per Second
        updateUpkeepID = registerAndPredictID("Update Rewards Per Second");
        // Register Automation responsible for sending Rewards Per Second to Brain Manager
        sendUpkeepID = registerAndPredictID("Send Rewards Per Second");
        // Set Automation running to true
        automationRunning = true;
        emit AutomationRunning(updateUpkeepID, sendUpkeepID);
    }
}
