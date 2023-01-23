// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {AutomationRegistryInterface, State, Config} from "./AutomationRegistryInterface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 *Interface to register a custom logic Upkeep that uses a compatible contract.
 */
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

/**
 * Interface to interact with BRAINManagementUpgradeable
 */
interface IBrainManagementContract {
    function setRewardsPerSecond(uint256 value) external;
}

/**
 * It was decided to put everything in a single file, but we can
 * divide it into other contracts and libraries.
 */
contract MINDSDynamicRewardSystem is
    ChainlinkClient,
    AutomationCompatibleInterface
{
    using Chainlink for Chainlink.Request;
    /**
     * Contract interface that we will send new calculated rewardsPerSecond
     */
    IBrainManagementContract private immutable brainManagementContract;
    /**
     * Chainlink Registrar and Registry Address
     */
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;
    /**
     * Values ​​we are updating automatically
     */
    int256 public performance;
    uint256 public rewardsPerSecond;
    bool public requestFulFilled;
    /**
     * Variable type used to calculate reward per percentage
     */
    struct RewardsCoordinates {
        int256 percentageChange;
        uint256 reward;
    }
    /**
     * Current system table coordinates (spreadsheet table)
     */
    RewardsCoordinates[] public rewardsTable;
    /**
     * Interval at which the update will be performed
     */
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    /**
     * Chainlink Any API values
     */
    bytes32 private jobId;
    uint256 private fee;
    /**
     * Make sure last Upkeeps have balance
     */
    uint256 public firstUpkeepID;
    string private nameFirstUpkeep;

    uint256 public secondUpkeepID;
    string private nameSecondUpkeep;
    /**
     * This is the maximum amount of gas that your transaction
     * requires to execute on chain.
     */

    uint32 internal gasLimitFirstUpkeep;
    uint32 internal gasLimitSecondUpkeep;
    /**
     * This field is required. You must have LINK before you
     * can use the Chainlink Automation service.
     * The minimum amount is 5 LINK.
     */

    uint96 internal amountFirstUpkeep;
    uint96 internal amountSecondUpkeep;
    /**
     * Tracks the state of our machine.
     */
    bool public automationRunning;
    uint256[] public upkeepsToWithdraw;

    event AutomationRunning(
        uint256 indexed firstUpkeepID,
        uint256 indexed secondUpkeepID
    );
    event TurnedOffAutomation(
        uint256 indexed firstUpkeepID,
        uint256 indexed secondUpkeepID
    );
    event RequestLastPriceChange(bytes32 indexed requestID);
    event Fulfilled(
        int256 indexed performance,
        uint256 indexed rewardsPerSecond
    );
    event SendRewardsPerSecond(uint256 indexed rewardsPerSecond);

    // Mumbai dummy Management Contract 0xCFF58B7Ec9bEAF650DCa1046fAAC1A28fa317Dec
    constructor(address brainManagementContractAddress) {
        /**
         * THIS IS AN PROTOTYPE CONTRACT THAT USES HARDCODED VALUES FOR TESTING.
         * DO NOT USE THIS CODE IN PRODUCTION.
         * Values ​​must be passed at deploy time
         */

        /**
         * Automation Constants.
         */
        nameFirstUpkeep = "#1Automation-Update-Performance-and-Reward";
        nameSecondUpkeep = "#2Automation-Send-Rewards-per-Seconds";
        gasLimitFirstUpkeep = 999999;
        gasLimitSecondUpkeep = 999999;
        amountFirstUpkeep = 5000000000000000000;
        amountSecondUpkeep = 5000000000000000000;

        interval = 24 * 60 * 60;
        lastTimeStamp = block.timestamp;

        brainManagementContract = IBrainManagementContract(
            brainManagementContractAddress
        );

        /**
         * Values ​​that vary from each network
         * https://docs.chain.link/any-api/testnet-oracles
         */
        jobId = "fcf4140d696d44b687012232948bdd5d";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // Mumbai
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3); // mumbai

        registrar = (0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d); // Mumbai
        // registrar = (0x9806cf6fBc89aBF286e8140C42174B94836e36F2); // Goleri
        i_registry = AutomationRegistryInterface(
            0x02777053d6764996e594c3E88AF1D58D5363a2e6
        );

        /**
         * It was decided to upload all the table values ​​when ploying the contract.
         * The initial idea was to create a formula to calculate the reward per
         * second, but after some tests it was decided that it would be safer to
         * scan the entire table (Although spending a little more gas) to find the
         * value we need.
         */
        rewardsTable.push(RewardsCoordinates(-10.00 * 10**18, 0.02 * 10**18));
        rewardsTable.push(
            RewardsCoordinates(-9.63 * 10**18, 0.02574545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-9.26 * 10**18, 0.02714545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-8.89 * 10**18, 0.02854545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-8.52 * 10**18, 0.02994545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-8.15 * 10**18, 0.03134545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-7.78 * 10**18, 0.03274545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-7.41 * 10**18, 0.03414545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-7.04 * 10**18, 0.03554545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-6.67 * 10**18, 0.03694545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-6.30 * 10**18, 0.03834545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-5.93 * 10**18, 0.03974545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-5.56 * 10**18, 0.04114545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-5.19 * 10**18, 0.04254545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-4.81 * 10**18, 0.04394545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-4.44 * 10**18, 0.04534545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-4.07 * 10**18, 0.04674545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-3.70 * 10**18, 0.04814545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-3.33 * 10**18, 0.04954545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-2.96 * 10**18, 0.05094545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-2.59 * 10**18, 0.05234545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-2.22 * 10**18, 0.05374545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-1.85 * 10**18, 0.05514545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-1.48 * 10**18, 0.05654545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-1.11 * 10**18, 0.05794545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-0.74 * 10**18, 0.05934545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(-0.37 * 10**18, 0.06074545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(0.00 * 10**18, 0.06214545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(0.556 * 10**18, 0.06354545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(1.111 * 10**18, 0.06494545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(1.67 * 10**18, 0.06634545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(2.22 * 10**18, 0.06774545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(2.78 * 10**18, 0.06914545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(3.33 * 10**18, 0.07054545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(3.89 * 10**18, 0.07194545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(4.44 * 10**18, 0.07334545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(5.00 * 10**18, 0.07474545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(5.56 * 10**18, 0.07614545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(6.11 * 10**18, 0.07754545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(6.67 * 10**18, 0.07894545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(7.22 * 10**18, 0.08034545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(7.78 * 10**18, 0.08174545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(8.33 * 10**18, 0.08314545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(8.89 * 10**18, 0.08454545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(9.44 * 10**18, 0.08594545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(10.00 * 10**18, 0.08734545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(10.56 * 10**18, 0.08874545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(11.11 * 10**18, 0.09014545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(11.67 * 10**18, 0.09154545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(12.22 * 10**18, 0.09294545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(12.78 * 10**18, 0.09434545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(13.33 * 10**18, 0.09574545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(13.89 * 10**18, 0.09714545455 * 10**18)
        );
        rewardsTable.push(
            RewardsCoordinates(14.44 * 10**18, 0.09854545455 * 10**18)
        );
        rewardsTable.push(RewardsCoordinates(15.00 * 10**18, 0.1 * 10**18));
    }

    // ******************************************************** //

    /**
     * Allow withdraw of Link tokens from the contract
     * There is a 50 block delay once an Upkeep has been
     * cancelled before funds can be withdrawn.
     */
    function withdrawLink() public {
        LinkTokenInterface i_link = LinkTokenInterface(chainlinkTokenAddress());
        for (uint256 i = 0; i < upkeepsToWithdraw.length; i++) {
            withdrawUpkeepFunds(upkeepsToWithdraw[i]);
        }
        delete upkeepsToWithdraw;
        require(
            i_link.transfer(msg.sender, i_link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * Check contract's Link token balance
     */
    function contractLinkBalance() public view returns (uint256 balance) {
        LinkTokenInterface i_link = LinkTokenInterface(chainlinkTokenAddress());
        balance = i_link.balanceOf(address(this));
    }

    /**
     * Balance Upkeep
     */
    function getUpkeepBalance(uint256 _upkeepID)
        public
        view
        returns (uint96 balance)
    {
        (, , , balance, , , , ) = i_registry.getUpkeep(_upkeepID);
    }

    /**
     * Add funds to Upkeep
     */
    function fundUpkeep(uint256 _upkeepID, uint96 _amount) public {
        i_registry.addFunds(_upkeepID, _amount);
    }

    /**
     * Cancel Upkeep
     */
    function cancelUpkeep(uint256 _upkeepID) public {
        i_registry.cancelUpkeep(_upkeepID);
    }

    /**
     * Withdraw Upkeep Funds
     * To withdraw funds, the Upkeep administrator have to cancel the
     * Upkeep first. There is a 50 block delay once an Upkeep has been
     * cancelled before funds can be withdrawn.
     */
    function withdrawUpkeepFunds(uint256 _upkeepID) public {
        i_registry.withdrawFunds(_upkeepID, address(this));
    }

    // ******************************************************** //

    /**
     * Calculate RewardsPerSecond according to current percentage change.
     * Return daily rewards in 'per the second' format: value in Wei / 86400
     */
    function calculateRewardsPerSeconds(int256 _performance)
        public
        view
        returns (uint256 _rewardsPerSeconds)
    {
        // The rewards cannot be lower than 0.02 MIND+ per day
        // if ( % < -9.63 ) { r = 0.02}
        if (_performance < rewardsTable[1].percentageChange)
            return _rewardsPerSeconds = rewardsTable[0].reward / 86400;
        // And cannot be higher than 0.1 MIND+ per day
        // if ( % >= 15.00 ) { r = 0.1}
        if (
            _performance >=
            rewardsTable[rewardsTable.length - 1].percentageChange
        )
            return
                _rewardsPerSeconds =
                    rewardsTable[rewardsTable.length - 1].reward /
                    86400;
        // Example, say the rolling percentage is 4.536%. This would equate
        // to index item 36, percent 4.44 (rounded down), and have a reward
        // of 0.07334545455. Divide that number by (60*60*24), multiply that
        // number by 10^18, and that computes to wei per second
        for (uint256 i = 1; i < rewardsTable.length - 1; i++) {
            if (
                rewardsTable[i].percentageChange <= _performance &&
                _performance < rewardsTable[i + 1].percentageChange
            ) return _rewardsPerSeconds = rewardsTable[i].reward / 86400;
        }
    }

    // ******************************************************** //

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestLastPriceChange() public returns (bytes32 requestId) {
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
     * Receive the response in the form of int256
     * We are going to use this function, which is called by a ChainLink node,
     * to update performance and rewardsPerSecond.
     */
    function fulfill(bytes32 _requestId, int256 _lastPriceChange)
        public
        recordChainlinkFulfillment(_requestId)
    {
        performance = performance + _lastPriceChange;
        rewardsPerSecond = calculateRewardsPerSeconds(performance);
        requestFulFilled = true;
        emit Fulfilled(performance, rewardsPerSecond);
    }

    // ******************************************************** //

    /**
     * We need to keep track of the Upkeep ID as your contract will use
     * this to subsequently interact with the Chainlink Automation registry.
     */
    function registerAndPredictID(
        string memory name,
        uint32 gasLimit,
        uint96 amount
    ) public returns (uint256 upkeepID) {
        LinkTokenInterface i_link = LinkTokenInterface(chainlinkTokenAddress());
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            name,
            "0x",
            address(this),
            gasLimit,
            address(this),
            bytes(name),
            amount,
            0,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            amount,
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
     * `checkUpkeep` function contains the logic that will be executed off-chain
     * to see if performUpkeep should be executed.
     * After you register the contract as an upkeep, the Chainlink Automation
     * Network simulates our checkUpkeep off-chain during every block to determine
     * if the contract should perform an action.
     * This cycle repeats until the upkeep is cancelled or runs out of funding.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        // Here we determine that the first automation must be executed
        // every time interval.
        if (keccak256(checkData) == keccak256(bytes(nameFirstUpkeep))) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
            performData = checkData;
        }
        // Here we determine that the second automation should be executed
        // when our request is fulfilled.
        if (keccak256(checkData) == keccak256(bytes(nameSecondUpkeep))) {
            upkeepNeeded = requestFulFilled;
            performData = checkData;
        }
    }

    /**
     * performUpkeep function will be executed on-chain when checkUpkeep returns true
     */
    function performUpkeep(bytes calldata performData) external override {
        // If checkData is equal to "Update ..."
        // Check if it's been 24 hours since the last update,
        // If yes requestLastPriceChange
        if (keccak256(performData) == keccak256(bytes(nameFirstUpkeep))) {
            if ((block.timestamp - lastTimeStamp) > interval) {
                bytes32 requestID = requestLastPriceChange();
                lastTimeStamp = block.timestamp;
                emit RequestLastPriceChange(requestID);
            }
        }
        // If checkData is equal to "Send ..."
        // Check if it was fulfllied
        // If yes setRewardsPerSecond
        if (requestFulFilled) {
            brainManagementContract.setRewardsPerSecond(rewardsPerSecond);
            requestFulFilled = false;
            emit SendRewardsPerSecond(rewardsPerSecond);
        }
    }

    // ******************************************************** //

    /**
     * Chainlink automation allow the protocol to run on autopilot without
     * human intervention to adjust daily rewards.
     * We call this function once, and after just garantee that the last
     * upkeep is alaways funded.
     */
    function initiateAutomation() public {
        require(!automationRunning, "Automation already running");
        firstUpkeepID = registerAndPredictID(
            nameFirstUpkeep,
            gasLimitFirstUpkeep,
            amountFirstUpkeep
        );
        secondUpkeepID = registerAndPredictID(
            nameSecondUpkeep,
            gasLimitSecondUpkeep,
            amountSecondUpkeep
        );
        automationRunning = true;
        emit AutomationRunning(firstUpkeepID, secondUpkeepID);
    }

    /**
     * Turn off machine.
     * We should wait a delay of 50 blocks to withdraw balance from Upkeeps.
     */
    function turnOffAutomation() public {
        require(automationRunning, "Automation already turned off");

        cancelUpkeep(firstUpkeepID);
        cancelUpkeep(secondUpkeepID);

        automationRunning = false;
        emit TurnedOffAutomation(firstUpkeepID, secondUpkeepID);

        upkeepsToWithdraw.push(firstUpkeepID);
        upkeepsToWithdraw.push(secondUpkeepID);

        firstUpkeepID = 0;
        secondUpkeepID = 0;
    }
}
