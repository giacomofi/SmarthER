// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "contracts/ICryptoPunk.sol";
import "contracts/TicketStorage.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

/**
 * @dev This contract is used to represent BoredLucky raffle. It supports CryptoPunks, ERC721 and ERC1155 NFTs.
 *
 * Raffle relies on Chainlink VRF to draw the winner.
 *
 * Raffle ensures that buyers will get a fair chance of winning (proportional to the number of purchased tickets), or
 * a way to get ETH back if raffle gets cancelled.
 *
 * Raffle can start only after the correct NFT is transferred to the account.
 *
 * Each raffle has an `owner`, the admin account that has the following abilities:
 * - gets ETH after the raffle is completed
 * - gets back the NFT if raffle is cancelled
 * - able to giveaway tickets
 * - able to cancel raffle before it has started (e.g. created with wrong parameters)
 *
 * Raffle gets cancelled if:
 * - not all tickets are sold before `endTimestamp`
 * - `owner` cancels it before start
 * - for some reason we do not have response from Chainlink VRF for one day after we request random number
 *
 * In any scenario, raffle cannot get stuck and users have a fair chance to win or get ETH back.
 *
 * `PullPayments` are used where possible to increase security.
 *
 * The lifecycle of raffle consist of following states:
 * - WaitingForNFT: after raffle is created, it waits for
 * - WaitingForStart: correct NFT is transferred and we wait for `startTimestamp`
 * - SellingTickets: it possible to purchase tickets
 * - WaitingForRNG: all tickets are sold, we wait for Chainlink VRF to send random number
 * - Completed (terminal) -- we know the winner, it can get NFT, raffle owner can get ETH
 * - Cancelled (terminal) -- raffle cancelled, buyers can get back their ETH, owner can get NFT
 */
contract Raffle is Ownable, TicketStorage, ERC1155Holder, ERC721Holder, PullPayment, VRFConsumerBaseV2 {
    event WinnerDrawn(uint16 ticketNumber, address owner);

    enum State {
        WaitingForNFT,
        WaitingForStart,
        SellingTickets,
        WaitingForRNG,
        Completed,
        Cancelled
    }
    State private _state;

    address public immutable nftContract;
    uint256 public immutable nftTokenId;
    enum NFTStandard {
        CryptoPunks,
        ERC721,
        ERC1155
    }
    NFTStandard public immutable nftStandard;

    uint256 public immutable ticketPrice;
    uint256 public immutable startTimestamp;
    uint256 public immutable endTimestamp;

    uint16 private _soldTickets;
    uint16 private _giveawayTickets;
    mapping(address => uint16) private _addressToPurchasedCountMap;

    uint256 private _cancelTimestamp;
    uint256 private _transferNFTToWinnerTimestamp;

    uint256 private _winnerDrawTimestamp;
    uint16 private _winnerTicketNumber;
    address private _winnerAddress;

    VRFCoordinatorV2Interface immutable VRF_COORDINATOR;
    uint64 immutable vrfSubscriptionId;
    bytes32 immutable vrfKeyHash;
    uint256[] public vrfRandomWords;
    uint256 public vrfRequestId;

    uint32 constant VRF_CALLBACK_GAS_LIMIT = 300_000;
    uint16 constant VRF_REQUEST_CONFIRMATIONS = 20;
    uint16 constant VRF_NUM_WORDS = 1;

    constructor(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _nftStandardId,
        uint16 _tickets,
        uint256 _ticketPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint64 _vrfSubscriptionId,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash
    ) TicketStorage(_tickets) VRFConsumerBaseV2(_vrfCoordinator) {
        require(block.timestamp < _startTimestamp, "Start timestamp cannot be in the past");
        require(_endTimestamp > _startTimestamp, "End timestamp must be after start timestamp");
        require(_nftContract != address(0), "NFT contract cannot be 0x0");
        nftStandard = NFTStandard(_nftStandardId);
        require(
            nftStandard == NFTStandard.CryptoPunks || nftStandard == NFTStandard.ERC721 || nftStandard == NFTStandard.ERC1155,
            "Not supported NFT standard"
        );

        nftContract = _nftContract;
        nftTokenId = _nftTokenId;
        ticketPrice = _ticketPrice;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;

        _state = State.WaitingForNFT;
    }

    /**
     * @dev Purchases raffle tickets.
     *
     * If last ticket is sold, triggers {_requestRandomWords} to request random number from Chainlink VRF.
     *
     * Requirements:
     * - must be in SellingTickets state
     * - cannot purchase after `endTimestamp`
     * - cannot purchase 0 tickets
     * - must have correct `value` of ETH
     */
    function purchaseTicket(uint16 count) external payable {
        if (_state == State.WaitingForStart) {
            if (block.timestamp > startTimestamp && block.timestamp < endTimestamp) {
                _state = State.SellingTickets;
            }
        }
        require(_state == State.SellingTickets, "Must be in SellingTickets");
        require(block.timestamp < endTimestamp, "End timestamp must be in the future");
        require(count > 0, "Ticket count must be more than 0");
        require(msg.value == ticketPrice * count, "Incorrect purchase amount (must be ticketPrice * count)");

        _assignTickets(msg.sender, count);
        _soldTickets += count;
        assert(_tickets == _ticketsLeft + _soldTickets + _giveawayTickets);

        _addressToPurchasedCountMap[msg.sender] += count;

        if (_ticketsLeft == 0) {
            _state = State.WaitingForRNG;
            _requestRandomWords();
        }
    }

    struct AddressAndCount {
        address receiverAddress;
        uint16 count;
    }

    /**
     * @dev Giveaway tickets. `owner` of raffle can giveaway free tickets, used for promotion.
     *
     * It is possible to giveaway tickets before start, ensuring that promised tickets for promotions can be assigned,
     * otherwise if raffle is quickly sold out, we may not able to do it in time.
     *
     * If last ticket is given out, triggers {_requestRandomWords} to request random number from Chainlink VRF.
     *
     * Requirements:
     * - must be in WaitingForStart or SellingTickets state
     * - cannot giveaway after `endTimestamp`
     */
    function giveawayTicket(AddressAndCount[] memory receivers) external onlyOwner {
        require(
            _state == State.WaitingForStart || _state == State.SellingTickets,
            "Must be in WaitingForStart or SellingTickets"
        );

        if (_state == State.WaitingForStart) {
            if (block.timestamp > startTimestamp && block.timestamp < endTimestamp) {
                _state = State.SellingTickets;
            }
        }
        require(block.timestamp < endTimestamp, "End timestamp must be in the future");

        for (uint256 i = 0; i < receivers.length; i++) {
            AddressAndCount memory item = receivers[i];

            _assignTickets(item.receiverAddress, item.count);
            _giveawayTickets += item.count;
            assert(_tickets == _ticketsLeft + _soldTickets + _giveawayTickets);
        }

        if (_ticketsLeft == 0) {
            _state = State.WaitingForRNG;
            _requestRandomWords();
        }
    }

    /**
     * @dev After the correct NFT (specified in raffle constructor) is transferred to raffle contract,
     * this method must be invoked to verify it and move raffle into WaitingForStart state.
     *
     * Requirements:
     * - must be in WaitingForNFT state
     */
    function verifyNFTPresenceBeforeStart() external {
        require(_state == State.WaitingForNFT, "Must be in WaitingForNFT");

        if (nftStandard == NFTStandard.CryptoPunks) {
            if (ICryptoPunk(nftContract).punkIndexToAddress(nftTokenId) == address(this)) {
                _state = State.WaitingForStart;
            }
        }
        else if (nftStandard == NFTStandard.ERC721) {
            if (IERC721(nftContract).ownerOf(nftTokenId) == address(this)) {
                _state = State.WaitingForStart;
            }
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            if (IERC1155(nftContract).balanceOf(address(this), nftTokenId) == 1) {
                _state = State.WaitingForStart;
            }
        }
    }

    /**
     * @dev Cancels raffle before it has started.
     *
     * Only raffle `owner` can do it and it is needed in case raffle was created incorrectly.
     *
     * Requirements:
     * - must be in WaitingForNFT or WaitingForStart state
     */
    function cancelBeforeStart() external onlyOwner {
        require(
            _state == State.WaitingForNFT || _state == State.WaitingForStart,
            "Must be in WaitingForNFT or WaitingForStart"
        );

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Cancels raffle if not all tickets were sold.
     *
     * Anyone can call this method after `endTimestamp`.
     *
     * Requirements:
     * - must be in SellingTickets state
     */
    function cancelIfUnsold() external {
        require(
            _state == State.WaitingForStart || _state == State.SellingTickets,
            "Must be in WaitingForStart or SellingTickets"
        );
        require(block.timestamp > endTimestamp, "End timestamp must be in the past");

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Cancels raffle if there is no response from Chainlink VRF.
     *
     * Anyone can call this method after `endTimestamp` + 1 day.
     *
     * Requirements:
     * - must be in WaitingForRNG state
     */
    function cancelIfNoRNG() external {
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");
        require(block.timestamp > endTimestamp + 1 days, "End timestamp + 1 day must be in the past");

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Transfers purchased ticket refund into internal escrow, after that user can claim ETH
     * using {PullPayment-withdrawPayments}.
     *
     * Requirements:
     * - must be in Cancelled state
     */
    function transferTicketRefundIfCancelled() external {
        require(_state == State.Cancelled, "Must be in Cancelled");

        uint256 refundAmount = _addressToPurchasedCountMap[msg.sender] * ticketPrice;
        if (refundAmount > 0) {
            _addressToPurchasedCountMap[msg.sender] = 0;
            _asyncTransfer(msg.sender, refundAmount);
        }
    }

    /**
     * @dev Transfers specified NFT to raffle `owner`. This method is used to recover NFT (including other NFTs,
     * that could have been transferred to raffle by mistake) if raffle gets cancelled.
     *
     * Requirements:
     * - must be in Cancelled state
     */
    function transferNFTToOwnerIfCancelled(NFTStandard nftStandard, address contractAddress, uint256 tokenId) external {
        require(_state == State.Cancelled, "Must be in Cancelled");

        if (nftStandard == NFTStandard.CryptoPunks) {
            ICryptoPunk(contractAddress).transferPunk(address(owner()), tokenId);
        }
        else if (nftStandard == NFTStandard.ERC721) {
            IERC721(contractAddress).safeTransferFrom(address(this), owner(), tokenId);
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(address(this), owner(), tokenId, 1, "");
        }
    }

    /**
     * @dev Transfers raffle NFT to `_winnerAddress` after the raffle has completed.
     *
     * Requirements:
     * - must be in Completed state
     */
    function transferNFTToWinnerIfCompleted() external {
        require(_state == State.Completed, "Must be in Completed");
        assert(_winnerAddress != address(0));

        _transferNFTToWinnerTimestamp = block.timestamp;
        if (nftStandard == NFTStandard.CryptoPunks) {
            ICryptoPunk(nftContract).transferPunk(_winnerAddress, nftTokenId);
        }
        else if (nftStandard == NFTStandard.ERC721) {
            IERC721(nftContract).safeTransferFrom(address(this), _winnerAddress, nftTokenId);
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            IERC1155(nftContract).safeTransferFrom(address(this), _winnerAddress, nftTokenId, 1, "");
        }
    }

    /**
     * @dev Transfers raffle ETHinto internal escrow, after that raffle `owner` can claim it
     * using {PullPayment-withdrawPayments}.
     *
     * Requirements:
     * - must be in Completed state
     */
    function transferETHToOwnerIfCompleted() external {
        require(_state == State.Completed, "Must be in Completed");

        _asyncTransfer(owner(), address(this).balance);
    }

    /**
     * @dev Returns the number of purchased tickets for given `owner`.
     */
    function getPurchasedTicketCount(address owner) public view returns (uint16) {
        return _addressToPurchasedCountMap[owner];
    }

    /**
    * @dev Returns raffle state.
     *
     * If `Completed`, it is possible to use {getWinnerAddress}, {getWinnerDrawTimestamp} and {getWinnerTicketNumber}.
     */
    function getState() public view returns (State) {
        return _state;
    }

    function getCancelTimestamp() public view returns (uint256) {
        return _cancelTimestamp;
    }

    function getTransferNFTToWinnerTimestamp() public view returns (uint256) {
        return _transferNFTToWinnerTimestamp;
    }

    function getWinnerAddress() public view returns (address) {
        return _winnerAddress;
    }

    function getWinnerDrawTimestamp() public view returns (uint256) {
        return _winnerDrawTimestamp;
    }

    function getWinnerTicketNumber() public view returns (uint16) {
        return _winnerTicketNumber;
    }

    /**
     * @dev Chainlink VRF callback function.
     *
     * Returned `randomWords` are stored in `vrfRandomWords`, we determine winner and store all relevant information in
     * `_winnerTicketNumber`, `_winnerDrawTimestamp` and `_winnerAddress`.
     *
     * Requirements:
     * - must have correct `requestId`
     * - must be in WaitingForRNG state
     *
     * Emits a {WinnerDrawn} event.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(vrfRequestId == requestId, "Unexpected VRF request id");
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");

        vrfRandomWords = randomWords;
        _winnerTicketNumber = uint16(randomWords[0] % _tickets);
        _winnerDrawTimestamp = block.timestamp;
        _winnerAddress = findOwnerOfTicketNumber(_winnerTicketNumber);
        _state = State.Completed;
        emit WinnerDrawn(_winnerTicketNumber, _winnerAddress);
    }

    /**
     * @dev Requests random number from Chainlink VRF. Called when last ticked is sold or given out.
     *
     * Requirements:
     * - must be in WaitingForRNG state
     */
    function _requestRandomWords() private {
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");

        vrfRequestId = VRF_COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            VRF_REQUEST_CONFIRMATIONS,
            VRF_CALLBACK_GAS_LIMIT,
            VRF_NUM_WORDS
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev This contract is used to represent `CryptoPunksMarket` and interact with CryptoPunk NFTs.
 */
interface ICryptoPunk {
    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This contract is used to store numbered ticket ranges and their owners.
 *
 * Ticket range is represented using {TicketNumberRange}, a struct of `owner, `from` and `to`. If account `0x1` buys
 * first ticket, then we store it as `(0x1, 0, 0)`, if then account `0x2` buys ten tickets, then we store next record as
 * `(0x2, 1, 10)`. If after that third account `0x3` buys ten tickets, we store it as `(0x3, 11, 20)`. And so on.
 *
 * Storing ticket numbers in such way allows compact representation of accounts who buy a lot of tickets at once.
 *
 * We set 25000 as limit of how many tickets we can support.
 */
abstract contract TicketStorage {
    event TicketsAssigned(TicketNumberRange ticketNumberRange, uint16 ticketsLeft);

    struct TicketNumberRange {
        address owner;
        uint16 from;
        uint16 to;
    }

    uint16 internal immutable _tickets;
    uint16 internal _ticketsLeft;

    TicketNumberRange[] private _ticketNumberRanges;
    mapping(address => uint16) private _addressToAssignedCountMap;
    mapping(address => uint16[]) private _addressToAssignedTicketNumberRangesMap;

    constructor(uint16 tickets) {
        require(tickets > 0, "Number of tickets must be greater than 0");
        require(tickets <= 25_000, "Number of tickets cannot exceed 25_000");

        _tickets = tickets;
        _ticketsLeft = tickets;
    }

    /**
     * @dev Returns total amount of tickets.
     */
    function getTickets() public view returns (uint16) {
        return _tickets;
    }

    /**
     * @dev Returns amount of unassigned tickets.
     */
    function getTicketsLeft() public view returns (uint16) {
        return _ticketsLeft;
    }

    /**
     * @dev Returns {TicketNumberRange} for given `index`.
     */
    function getTicketNumberRange(uint16 index) public view returns (TicketNumberRange memory) {
        return _ticketNumberRanges[index];
    }

    /**
     * @dev Returns how many tickets are assigned to given `owner`.
     */
    function getAssignedTicketCount(address owner) public view returns (uint16) {
        return _addressToAssignedCountMap[owner];
    }

    /**
     * @dev Returns the index of {TicketNumberRange} in `_ticketNumberRanges` that is assigned to `owner`.
     *
     * For example, if `owner` purchased tickets three times ({getAssignedTicketNumberRanges} will return `3`),
     * we can use this method with `index` of 0, 1 and 2, to get indexes of {TicketNumberRange} in `_ticketNumberRanges`.
     */
    function getAssignedTicketNumberRange(address owner, uint16 index) public view returns (uint16) {
        return _addressToAssignedTicketNumberRangesMap[owner][index];
    }

    /**
     * @dev Returns how many {TicketNumberRange} are assigned for given `owner`.
     *
     * Can be used in combination with {getAssignedTicketNumberRange} and {getTicketNumberRange} to show
     * all actual ticket numbers that are assigned to the `owner`.
     */
    function getAssignedTicketNumberRanges(address owner) public view returns (uint16) {
        return uint16(_addressToAssignedTicketNumberRangesMap[owner].length);
    }

    /**
     * @dev Assigns `count` amount of tickets to `owner` address.
     *
     * Requirements:
     * - there must be enough tickets left
     *
     * Emits a {TicketsAssigned} event.
     */
    function _assignTickets(address owner, uint16 count) internal {
        require(_ticketsLeft > 0, "All tickets are assigned");
        require(_ticketsLeft >= count, "Assigning too many tickets at once");

        uint16 from = _tickets - _ticketsLeft;
        _ticketsLeft -= count;
        TicketNumberRange memory ticketNumberRange = TicketNumberRange({
            owner: owner,
            from: from,
            to: from + count - 1
        });
        _ticketNumberRanges.push(ticketNumberRange);
        _addressToAssignedCountMap[owner] += count;
        _addressToAssignedTicketNumberRangesMap[owner].push(uint16(_ticketNumberRanges.length - 1));

        assert(_ticketNumberRanges[_ticketNumberRanges.length - 1].to == _tickets - _ticketsLeft - 1);

        emit TicketsAssigned(ticketNumberRange, _ticketsLeft);
    }

    /**
     * @dev Returns address of the `owner` of given ticket number.
     *
     * Uses binary search on `_ticketNumberRanges` to find it.
     *
     * Requirements:
     * - all tickets must be assigned
     */
    function findOwnerOfTicketNumber(uint16 ticketNumber) public view returns (address) {
        require(ticketNumber < _tickets, "Ticket number does not exist");
        require(_ticketsLeft == 0, "Not all tickets are assigned");

        uint16 ticketNumberRangesLength = uint16(_ticketNumberRanges.length);
        assert(_ticketNumberRanges[0].from == 0);
        assert(_ticketNumberRanges[ticketNumberRangesLength - 1].to == _tickets - 1);

        uint16 left = 0;
        uint16 right = ticketNumberRangesLength - 1;
        uint16 pivot = (left + right) / 2;
        address ownerAddress = address(0);
        while (ownerAddress == address(0)) {
            pivot = (left + right) / 2;
            TicketNumberRange memory ticketNumberRange = _ticketNumberRanges[pivot];
            if (ticketNumberRange.to < ticketNumber) {
                left = pivot + 1;
            } else if (ticketNumberRange.from > ticketNumber) {
                right = pivot - 1;
            } else {
                ownerAddress = ticketNumberRange.owner;
            }
        }

        return ownerAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}