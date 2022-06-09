// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Lottery_NotPending(uint8 _state);
error Lottery__WrongPrice(address player, uint256 amount);
error Lottery__TransferFailed();
error Lottery_UpkeepNotNeeded();

contract Lottery is VRFConsumerBaseV2, KeeperCompatible {
    enum State {
        OPEN,
        DRAWING,
        FINISHED
    }
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint32 private immutable i_callbckGasLimit;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_interval;

    address private s_recentWinner;
    State private s_state;
    uint256 public s_lastDrawingBlock;
    address payable[] private s_players;

    event TicketBought(address _player);
    event WinnerPicked(address _winner);

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _ticketPrice,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbckGasLimit = _callbackGasLimit;
        i_ticketPrice = _ticketPrice;
        i_interval = _interval;
        s_lastDrawingBlock = block.number;
    }

    function buyTicket() external payable {
        if (s_state != State.OPEN) {
            revert Lottery_NotPending(uint8(s_state));
        }
        if (msg.value != i_ticketPrice) {
            revert Lottery__WrongPrice(msg.sender, msg.value);
        }

        s_players.push(payable(msg.sender));

        emit TicketBought(msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = isDrawingReady();
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if (isDrawingReady()) {
            s_state = State.DRAWING;
            i_vrfCoordinator.requestRandomWords(
                i_keyHash,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbckGasLimit,
                NUM_WORDS
            );
        } else {
            revert Lottery_UpkeepNotNeeded();
        }
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_state = State.OPEN;
        s_players = new address payable[](0);
        s_lastDrawingBlock = block.number;
        s_recentWinner = winner;

        (bool sucess, ) = winner.call{value: address(this).balance}("");
        if (!sucess) {
            revert Lottery__TransferFailed();
        }

        emit WinnerPicked(winner);
    }

    function isDrawingReady() public view returns (bool) {
        bool isOpen = s_state == State.OPEN;
        bool participants = s_players.length > 0;
        bool timePassed = i_interval <= block.number - s_lastDrawingBlock;
        return isOpen && participants && timePassed;
    }

    function getTicketPrice() external view returns (uint256) {
        return i_ticketPrice;
    }

    function getState() external view returns (State) {
        return s_state;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getPlayersNumber() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
