// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./SyndicateERC20.sol";
import "./SyntheticSyndicateERC20.sol";
import "../utils/AccessControl.sol";

// import "hardhat/console.sol";

/**
 * @title Syn Swapper
 *
 * @notice A contract to swap sSYNR for an indentical amount of SYNR
 *         The contract must have ssynr.ROLE_TOKEN_DESTROYER and
 *         synr.ROLE_TOKEN_CREATOR roles
 *
 * @author Francesco Sullo
 */
contract SynrSwapper is AccessControl {
  event SynSwapped(address swapper, uint256 amount);

  address public owner;
  SyndicateERC20 public synr;
  SyntheticSyndicateERC20 public ssynr;

  constructor(
    address _superAdmin,
    address _synr,
    address _ssynr
  ) AccessControl(_superAdmin) {
    synr = SyndicateERC20(_synr);
    ssynr = SyntheticSyndicateERC20(_ssynr);
  }

  /**
   * @notice Swaps an amount of sSYNR for an identical amount of SYNR
   *         Everyone can execute it, but it will have effect only if the recipient
   *         has the required roles.
   * @param amount     The amount of token to be swapped
   */
  function swap(uint256 amount) external {
    require(synr.isOperatorInRole(msg.sender, synr.ROLE_TREASURY()), "SYNR: not a treasury");
    ssynr.burn(msg.sender, amount);
    synr.mint(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/AddressUtils.sol";
import "../utils/AccessControl.sol";
import "./ERC20Receiver.sol";

/**
 * @title Syndicate (SYNR) ERC20 token
 *        Original title: Illuvium (ILV) ERC20 token
 *
 * @notice Syndicate is a core ERC20 token powering the game.
 *      It serves as an in-game currency, is tradable on exchanges,
 *      it powers up the governance protocol (Syndicate DAO) and participates in Yield Farming.
 *
 * @dev Token Summary:
 *      - Symbol: SYNR
 *      - Name: Syndicate
 *      - Decimals: 18
 *      - Initial token supply: 9,000,000,000 SYNR
 *      - Maximum final token supply: 10,000,000,000 SYNR
 *          - Up to 1,000,000,000 SYNR may get minted in 3 years period via yield farming
 *      - Mintable: total supply may increase
 *      - Burnable: total supply may decrease
 *
 * @dev ?? Token balances and total supply are effectively 192 bits long, meaning that maximum
 *      possible total supply smart contract is able to track is 2^192 (close to 10^40 tokens)
 *
 * @dev Smart contract doesn't use safe math. All arithmetic operations are overflow/underflow safe.
 *      Additionally, Solidity 0.8.1 enforces overflow/underflow safety.
 *
 * @dev ERC20: reviewed according to https://eips.ethereum.org/EIPS/eip-20
 *
 * @dev ERC20: contract has passed OpenZeppelin ERC20 tests,
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.behavior.js
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.test.js
 *      see adopted copies of these tests in the `test` folder
 *
 * @dev ERC223/ERC777: not supported;
 *      send tokens via `safeTransferFrom` and implement `ERC20Receiver.onERC20Received` on the receiver instead
 *
 * @dev Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) - resolved
 *      Related events and functions are marked with "ISBN:978-1-7281-3027-9" tag:
 *        - event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value)
 *        - event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value)
 *        - function increaseAllowance(address _spender, uint256 _value) public returns (bool)
 *        - function decreaseAllowance(address _spender, uint256 _value) public returns (bool)
 *      See: https://ieeexplore.ieee.org/document/8802438
 *      See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 *
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
contract SyndicateERC20 is AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c;

  /**
   * @notice Name of the token: Syndicate
   *
   * @notice ERC20 name of the token (long name)
   *
   * @dev ERC20 `function name() public view returns (string)`
   *
   * @dev Field is declared public: getter name() is created when compiled,
   *      it returns the name of the token.
   */
  // solhint-disable-next-line
  string public constant name = "Syndicate Token";

  /**
   * @notice Symbol of the token: SYNR
   *
   * @notice ERC20 symbol of that token (short name)
   *
   * @dev ERC20 `function symbol() public view returns (string)`
   *
   * @dev Field is declared public: getter symbol() is created when compiled,
   *      it returns the symbol of the token
   */
  // solhint-disable-next-line
  string public symbol = "SYNR";

  event SymbolUpdated(string _symbol);

  /**
   * @notice Decimals of the token: 18
   *
   * @dev ERC20 `function decimals() public view returns (uint8)`
   *
   * @dev Field is declared public: getter decimals() is created when compiled,
   *      it returns the number of decimals used to get its user representation.
   *      For example, if `decimals` equals `6`, a balance of `1,500,000` tokens should
   *      be displayed to a user as `1,5` (`1,500,000 / 10 ** 6`).
   *
   * @dev NOTE: This information is only used for _display_ purposes: it in
   *      no way affects any of the arithmetic of the contract, including balanceOf() and transfer().
   */
  // solhint-disable-next-line
  uint8 public constant decimals = 18;

  /**
   * @notice Max total supply of the token: initially 70% of that max,
   *      with the potential to grow up to the max during yield farming period (3 years)
   *
   * @dev ERC20 `function totalSupply() public view returns (uint256)`
   *
   * @dev Field is declared public: getter totalSupply() is created when compiled,
   *      it returns the amount of tokens in existence.
   */
  uint256 public maxTotalSupply; // is set up in the constructor

  /**
   * @notice Total supply of the token: initially 70% of maxTotalSupply
   *      with the potential to grow up maxTotalSupply during yield farming period (3 years)
   *
   * @dev ERC20 `function totalSupply() public view returns (uint256)`
   *
   * @dev Field is declared public: getter totalSupply() is created when compiled,
   *      it returns the amount of tokens in existence.
   */
  uint256 public totalSupply; // is set to 700 million * 10^18 in the constructor

  /**
   * @dev A record of all the token balances
   * @dev This mapping keeps record of all token owners:
   *      owner => balance
   */
  mapping(address => uint256) public tokenBalances;

  /**
   * @notice A record of each account's voting delegate
   *
   * @dev Auxiliary data structure used to sum up an account's voting power
   *
   * @dev This mapping keeps record of all voting power delegations:
   *      voting delegator (token owner) => voting delegate
   */
  mapping(address => address) public votingDelegates;

  /**
   * @notice A voting power record binds voting power of a delegate to a particular
   *      block when the voting power delegation change happened
   */
  struct VotingPowerRecord {
    /*
     * @dev block.number when delegation has changed; starting from
     *      that block voting power value is in effect
     */
    uint64 blockNumber;
    /*
     * @dev cumulative voting power a delegate has obtained starting
     *      from the block stored in blockNumber
     */
    uint192 votingPower;
  }

  /**
   * @notice A record of each account's voting power
   *
   * @dev Primarily data structure to store voting power for each account.
   *      Voting power sums up from the account's token balance and delegated
   *      balances.
   *
   * @dev Stores current value and entire history of its changes.
   *      The changes are stored as an array of checkpoints.
   *      Checkpoint is an auxiliary data structure containing voting
   *      power (number of votes) and block number when the checkpoint is saved
   *
   * @dev Maps voting delegate => voting power record
   */
  mapping(address => VotingPowerRecord[]) public votingPowerHistory;

  /**
   * @dev A record of nonces for signing/validating signatures in `delegateWithSig`
   *      for every delegate, increases after successful validation
   *
   * @dev Maps delegate address => delegate nonce
   */
  mapping(address => uint256) public nonces;

  /**
   * @notice A record of all the allowances to spend tokens on behalf
   * @dev Maps token owner address to an address approved to spend
   *      some tokens on behalf, maps approved address to that amount
   * @dev owner => spender => value
   */
  mapping(address => mapping(address => uint256)) public transferAllowances;

  /**
   * @notice Enables ERC20 transfers of the tokens
   *      (transfer by the token owner himself)
   * @dev Feature FEATURE_TRANSFERS must be enabled in order for
   *      `transfer()` function to succeed
   */
  uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

  /**
   * @notice Enables ERC20 transfers on behalf
   *      (transfer by someone else on behalf of token owner)
   * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
   *      `transferFrom()` function to succeed
   * @dev Token owner must call `approve()` first to authorize
   *      the transfer on behalf
   */
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

  /**
   * @dev Defines if the default behavior of `transfer` and `transferFrom`
   *      checks if the receiver smart contract supports ERC20 tokens
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is enabled the transfers do not
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `unsafeTransferFrom`
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is disabled (default) the transfers
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `safeTransferFrom`
   */
  uint32 public constant FEATURE_UNSAFE_TRANSFERS = 0x0000_0004;

  /**
   * @notice Enables token owners to burn their own tokens,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by token owner
   */
  uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

  /**
   * @notice Enables approved operators to burn tokens on behalf of their owners,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by approved operator
   */
  uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

  /**
   * @notice Enables delegators to elect delegates
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegate()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS = 0x0000_0020;

  /**
   * @notice Enables delegators to elect delegates on behalf
   *      (via an EIP712 signature)
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegateWithSig()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS_ON_BEHALF = 0x0000_0040;

  /**
   * @notice Token creator is responsible for creating (minting)
   *      tokens to an arbitrary address
   * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
   *      (calling `mint` function)
   */
  uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

  /**
   * @notice Token destroyer is responsible for destroying (burning)
   *      tokens owned by an arbitrary address
   * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
   *      (calling `burn` function)
   */
  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  /**
   * @notice ERC20 receivers are allowed to receive tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled addresses having
   *      `ROLE_ERC20_RECEIVER` permission are allowed to receive tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_RECEIVER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_RECEIVER is a shortening for ROLE_UNSAFE_ERC20_RECEIVER
   */
  uint32 public constant ROLE_ERC20_RECEIVER = 0x0004_0000;

  /**
   * @notice ERC20 senders are allowed to send tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled senders having
   *      `ROLE_ERC20_SENDER` permission are allowed to send tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_SENDER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_SENDER is a shortening for ROLE_UNSAFE_ERC20_SENDER
   */
  uint32 public constant ROLE_ERC20_SENDER = 0x0008_0000;

  uint32 public constant ROLE_WHITE_LISTED_SPENDER = 0x0010_0000;

  /**
   * @notice White listed treasury can swap sSYNR to receive SYNR
   * @dev Role ROLE_TREASURY can get SYNR in exchange for sSYNR
   */
  uint32 public constant ROLE_TREASURY = 0x0020_0000;

  /**
   * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
   * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
   *      which can be also obtained as `ERC20Receiver(address(0)).onERC20Received.selector`
   */
  // solhint-disable-next-line
  bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

  /**
   * @notice EIP-712 contract's domain typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /**
   * @notice EIP-712 delegation struct typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)");

  /**
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @dev ERC20 `event Transfer(address indexed _from, address indexed _to, uint256 _value)`
   *
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @dev ERC20 `event Approval(address indexed _owner, address indexed _spender, uint256 _value)`
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _value amount of tokens granted to transfer on behalf
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev Fired in mint() function
   *
   * @param _by an address which minted some tokens (transaction sender)
   * @param _to an address the tokens were minted to
   * @param _value an amount of tokens minted
   */
  event Minted(address indexed _by, address indexed _to, uint256 _value);

  /**
   * @dev Fired in burn() function
   *
   * @param _by an address which burned some tokens (transaction sender)
   * @param _from an address the tokens were burnt from
   * @param _value an amount of tokens burnt
   */
  event Burnt(address indexed _by, address indexed _from, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Transfer event, but also logs an address which executed transfer
   *
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @param _by an address which performed the transfer
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Approve event, but also logs old approval value
   *
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _oldValue previously granted amount of tokens to transfer on behalf
   * @param _value new granted amount of tokens to transfer on behalf
   */
  event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value);

  /**
   * @dev Notifies that a key-value pair in `votingDelegates` mapping has changed,
   *      i.e. a delegator address has changed its delegate address
   *
   * @param _of delegator address, a token owner
   * @param _from old delegate, an address which delegate right is revoked
   * @param _to new delegate, an address which received the voting power
   */
  event DelegateChanged(address indexed _of, address indexed _from, address indexed _to);

  /**
   * @dev Notifies that a key-value pair in `votingPowerHistory` mapping has changed,
   *      i.e. a delegate's voting power has changed.
   *
   * @param _of delegate whose voting power has changed
   * @param _fromVal previous number of votes delegate had
   * @param _toVal new number of votes delegate has
   */
  event VotingPowerChanged(address indexed _of, uint256 _fromVal, uint256 _toVal);

  /**
   * @dev Deploys the token smart contract,
   *      assigns initial token supply to the address specified
   *
   * @param _initialHolder owner of the initial token supply
   * @param _maxTotalSupply max token supply without decimals
   * @param _superAdmin the contract admin (Gnosis Safe 0x8e75AEe46961019A66A88670ec18f022B8ef815E)
   */
  constructor(
    address _initialHolder,
    uint256 _maxTotalSupply,
    address _superAdmin
  ) AccessControl(_superAdmin) {
    // verify initial holder address non-zero (is set)
    require(_initialHolder != address(0), "_initialHolder not set (zero address)");
    require(_maxTotalSupply >= 10e9, "_maxTotalSupply less than minimum accepted amount");

    maxTotalSupply = _maxTotalSupply * 10**18;
    // mint initial supply
    mint(_initialHolder, (maxTotalSupply * 9) / 10);
  }

  // ===== Start: ERC20/ERC223/ERC777 functions =====

  /**
   * @notice Gets the balance of a particular address
   *
   * @dev ERC20 `function balanceOf(address _owner) public view returns (uint256 balance)`
   *
   * @param _owner the address to query the the balance for
   * @return balance an amount of tokens owned by the address specified
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    // read the balance and return
    return tokenBalances[_owner];
  }

  /**
   * @notice Transfers some tokens to an external address or a smart contract
   *
   * @dev ERC20 `function transfer(address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner (an address which has a
   *      positive token balance tracked by this smart contract)
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * self address or
   *          * smart contract which doesn't support ERC20
   *
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    // just delegate call to `transferFrom`,
    // `FEATURE_TRANSFERS` is verified inside it
    return transferFrom(msg.sender, _to, _value);
  }

  function updateSymbol(string memory _symbol) external {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");
    symbol = _symbol;
    // fire an event
    emit SymbolUpdated(_symbol);
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev ERC20 `function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    // depending on `FEATURE_UNSAFE_TRANSFERS` we execute either safe (default)
    // or unsafe transfer
    // if `FEATURE_UNSAFE_TRANSFERS` is enabled
    // or receiver has `ROLE_ERC20_RECEIVER` permission
    // or sender has `ROLE_ERC20_SENDER` permission
    if (
      isFeatureEnabled(FEATURE_UNSAFE_TRANSFERS) ||
      isOperatorInRole(_to, ROLE_ERC20_RECEIVER) ||
      isSenderInRole(ROLE_ERC20_SENDER)
    ) {
      // we execute unsafe transfer - delegate call to `unsafeTransferFrom`,
      // `FEATURE_TRANSFERS` is verified inside it
      unsafeTransferFrom(_from, _to, _value);
    }
    // otherwise - if `FEATURE_UNSAFE_TRANSFERS` is disabled
    // and receiver doesn't have `ROLE_ERC20_RECEIVER` permission
    else {
      // we execute safe transfer - delegate call to `safeTransferFrom`, passing empty `_data`,
      // `FEATURE_TRANSFERS` is verified inside it
      safeTransferFrom(_from, _to, _value, "");
    }

    // both `unsafeTransferFrom` and `safeTransferFrom` throw on any error, so
    // if we're here - it means operation successful,
    // just return true
    return true;
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev Inspired by ERC721 safeTransferFrom, this function allows to
   *      send arbitrary data to the receiver on successful token transfer
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20Receiver interface
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @param _data [optional] additional data with no specified format,
   *      sent in onERC20Received call to `_to` in case if its a smart contract
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) public {
    // first delegate call to `unsafeTransferFrom`
    // to perform the unsafe token(s) transfer
    unsafeTransferFrom(_from, _to, _value);

    // after the successful transfer - check if receiver supports
    // ERC20Receiver and execute a callback handler `onERC20Received`,
    // reverting whole transaction on any error:
    // check if receiver `_to` supports ERC20Receiver interface
    if (AddressUtils.isContract(_to)) {
      // if `_to` is a contract - execute onERC20Received
      bytes4 response = ERC20Receiver(_to).onERC20Received(msg.sender, _from, _value, _data);

      // expected response is ERC20_RECEIVED
      require(response == ERC20_RECEIVED, "invalid onERC20Received response");
    }
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev In contrast to `safeTransferFrom` doesn't check recipient
   *      smart contract to support ERC20 tokens (ERC20Receiver)
   * @dev Designed to be used by developers when the receiver is known
   *      to support ERC20 tokens but doesn't implement ERC20Receiver interface
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   */
  function unsafeTransferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public {
    // if `_from` is equal to sender, require transfers feature to be enabled
    // otherwise require transfers on behalf feature to be enabled
    require(
      (_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)) ||
        (_from != msg.sender && (isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF) || isSenderInRole(ROLE_WHITE_LISTED_SPENDER))),
      _from == msg.sender ? "transfers are disabled" : "transfers on behalf are disabled"
    );
    // non-zero source address check - Zeppelin
    // obviously, zero source address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    // since for zero value transfer transaction succeeds otherwise
    require(_from != address(0), "SYNR: transfer from the zero address"); // Zeppelin msg

    // non-zero recipient address check
    require(_to != address(0), "SYNR: transfer to the zero address"); // Zeppelin msg

    // sender and recipient cannot be the same
    require(_from != _to, "sender and recipient are the same (_from = _to)");

    // sending tokens to the token smart contract itself is a client mistake
    require(_to != address(this), "invalid recipient (transfer to the token smart contract itself)");

    // according to ERC-20 Token Standard, https://eips.ethereum.org/EIPS/eip-20
    // "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
    if (_value == 0) {
      // emit an ERC20 transfer event
      emit Transfer(_from, _to, _value);

      // don't forget to return - we're done
      return;
    }

    // no need to make arithmetic overflow check on the _value - by design of mint()

    // in case of transfer on behalf
    if (_from != msg.sender) {
      // read allowance value - the amount of tokens allowed to transfer - into the stack
      uint256 _allowance = transferAllowances[_from][msg.sender];

      // verify sender has an allowance to transfer amount of tokens requested
      require(_allowance >= _value, "SYNR: transfer amount exceeds allowance"); // Zeppelin msg

      // update allowance value on the stack
      _allowance -= _value;

      // update the allowance value in storage
      transferAllowances[_from][msg.sender] = _allowance;

      // emit an improved atomic approve event
      emit Approved(_from, msg.sender, _allowance + _value, _allowance);

      // emit an ERC20 approval event to reflect the decrease
      emit Approval(_from, msg.sender, _allowance);
    }

    // verify sender has enough tokens to transfer on behalf
    require(tokenBalances[_from] >= _value, "SYNR: transfer amount exceeds balance"); // Zeppelin msg

    // perform the transfer:
    // decrease token owner (sender) balance
    tokenBalances[_from] -= _value;

    // increase `_to` address (receiver) balance
    tokenBalances[_to] += _value;

    // move voting power associated with the tokens transferred
    __moveVotingPower(votingDelegates[_from], votingDelegates[_to], _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, _to, _value);

    // emit an ERC20 transfer event
    emit Transfer(_from, _to, _value);
  }

  /**
   * @notice Approves address called `_spender` to transfer some amount
   *      of tokens on behalf of the owner
   *
   * @dev ERC20 `function approve(address _spender, uint256 _value) public returns (bool success)`
   *
   * @dev Caller must not necessarily own any tokens to grant the permission
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens spender `_spender` is allowed to
   *      transfer on behalf of the token owner
   * @return success true on success, throws otherwise
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    // non-zero spender address check - Zeppelin
    // obviously, zero spender address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    require(_spender != address(0), "SYNR: approve to the zero address"); // Zeppelin msg

    // if transfer on behave is not allowed, then approve is also not allowed, unless it's white listed
    require(
      isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF) || isOperatorInRole(_spender, ROLE_WHITE_LISTED_SPENDER),
      "SYNR: spender not allowed"
    );

    // read old approval value to emmit an improved event (ISBN:978-1-7281-3027-9)
    uint256 _oldValue = transferAllowances[msg.sender][_spender];

    // perform an operation: write value requested into the storage
    transferAllowances[msg.sender][_spender] = _value;

    // emit an improved atomic approve event (ISBN:978-1-7281-3027-9)
    emit Approved(msg.sender, _spender, _oldValue, _value);

    // emit an ERC20 approval event
    emit Approval(msg.sender, _spender, _value);

    // operation successful, return true
    return true;
  }

  /**
   * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
   *
   * @dev ERC20 `function allowance(address _owner, address _spender) public view returns (uint256 remaining)`
   *
   * @dev A function to check an amount of tokens owner approved
   *      to transfer on its behalf by some other address called "spender"
   *
   * @param _owner an address which approves transferring some tokens on its behalf
   * @param _spender an address approved to transfer some tokens on behalf
   * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
   *      of token owner `_owner`
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // read the value from storage and return
    return transferAllowances[_owner][_spender];
  }

  // ===== End: ERC20/ERC223/ERC777 functions =====

  // ===== Start: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  /**
   * @notice Increases the allowance granted to `spender` by the transaction sender
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to increase by is zero or too big and causes arithmetic overflow
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to increase by
   * @return success true on success, throws otherwise
   */
  function increaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value and arithmetic overflow check on the allowance
    require(currentVal + _value > currentVal, "zero value approval increase or arithmetic overflow");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal + _value);
  }

  /**
   * @notice Decreases the allowance granted to `spender` by the caller.
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to decrease by is zero or is bigger than currently allowed value
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to decrease by
   * @return success true on success, throws otherwise
   */
  function decreaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value check on the allowance
    require(_value > 0, "zero value approval decrease");

    // verify allowance decrease doesn't underflow
    require(currentVal >= _value, "SYNR: decreased allowance below zero");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal - _value);
  }

  // ===== End: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  // ===== Start: Minting/burning extension =====

  /**
   * @dev Mints (creates) some tokens to address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `mintTo` function, allowing
   *      to specify an address to mint tokens to
   * @dev Requires sender to have `ROLE_TOKEN_CREATOR` permission
   *
   * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint192
   *
   * @param _to an address to mint tokens to
   * @param _value an amount of tokens to mint (create)
   */
  function mint(address _to, uint256 _value) public {
    // check if caller has sufficient permissions to mint tokens
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "insufficient privileges (ROLE_TOKEN_CREATOR required)");

    // non-zero recipient address check
    require(_to != address(0), "SYNR: mint to the zero address"); // Zeppelin msg

    // non-zero _value and arithmetic overflow check on the total supply
    // this check automatically secures arithmetic overflow on the individual balance
    require(totalSupply + _value > totalSupply, "zero value mint or arithmetic overflow");

    // uint192 overflow check (required by voting delegation)
    require(totalSupply + _value <= type(uint192).max, "total supply overflow (uint192)");

    require(totalSupply + _value <= maxTotalSupply, "reached total max supply");

    // perform mint:
    // increase total amount of tokens value
    totalSupply += _value;

    // increase `_to` address balance
    tokenBalances[_to] += _value;

    // create voting power associated with the tokens minted
    __moveVotingPower(address(0), votingDelegates[_to], _value);

    // fire a minted event
    emit Minted(msg.sender, _to, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, address(0), _to, _value);

    // fire ERC20 compliant transfer event
    emit Transfer(address(0), _to, _value);
  }

  /**
   * @dev Burns (destroys) some tokens from the address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `burnFrom` function, allowing
   *      to specify an address to burn tokens from
   * @dev Requires sender to have `ROLE_TOKEN_DESTROYER` permission
   *
   * @param _from an address to burn some tokens from
   * @param _value an amount of tokens to burn (destroy)
   */
  function burn(address _from, uint256 _value) public {
    // check if caller has sufficient permissions to burn tokens
    // and if not - check for possibility to burn own tokens or to burn on behalf
    if (!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
      // if `_from` is equal to sender, require own burns feature to be enabled
      // otherwise require burns on behalf feature to be enabled
      require(
        (_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)) ||
          (_from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF)),
        _from == msg.sender ? "burns are disabled" : "burns on behalf are disabled"
      );

      // in case of burn on behalf
      if (_from != msg.sender) {
        // read allowance value - the amount of tokens allowed to be burnt - into the stack
        uint256 _allowance = transferAllowances[_from][msg.sender];

        // verify sender has an allowance to burn amount of tokens requested
        require(_allowance >= _value, "SYNR: burn amount exceeds allowance"); // Zeppelin msg

        // update allowance value on the stack
        _allowance -= _value;

        // update the allowance value in storage
        transferAllowances[_from][msg.sender] = _allowance;

        // emit an improved atomic approve event
        emit Approved(msg.sender, _from, _allowance + _value, _allowance);

        // emit an ERC20 approval event to reflect the decrease
        emit Approval(_from, msg.sender, _allowance);
      }
    }

    // at this point we know that either sender is ROLE_TOKEN_DESTROYER or
    // we burn own tokens or on behalf (in latest case we already checked and updated allowances)
    // we have left to execute balance checks and burning logic itself

    // non-zero burn value check
    require(_value != 0, "zero value burn");

    // non-zero source address check - Zeppelin
    require(_from != address(0), "SYNR: burn from the zero address"); // Zeppelin msg

    // verify `_from` address has enough tokens to destroy
    // (basically this is a arithmetic overflow check)
    require(tokenBalances[_from] >= _value, "SYNR: burn amount exceeds balance"); // Zeppelin msg

    // perform burn:
    // decrease `_from` address balance
    tokenBalances[_from] -= _value;

    // decrease total amount of tokens value
    totalSupply -= _value;

    // destroy voting power associated with the tokens burnt
    __moveVotingPower(votingDelegates[_from], address(0), _value);

    // fire a burnt event
    emit Burnt(msg.sender, _from, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, address(0), _value);

    // fire ERC20 compliant transfer event
    emit Transfer(_from, address(0), _value);
  }

  // ===== End: Minting/burning extension =====

  // ===== Start: DAO Support (Compound-like voting delegation) =====

  /**
   * @notice Gets current voting power of the account `_of`
   * @param _of the address of account to get voting power of
   * @return current cumulative voting power of the account,
   *      sum of token balances of all its voting delegators
   */
  function getVotingPower(address _of) public view returns (uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // lookup the history and return latest element
    return history.length == 0 ? 0 : history[history.length - 1].votingPower;
  }

  /**
   * @notice Gets past voting power of the account `_of` at some block `_blockNum`
   * @dev Throws if `_blockNum` is not in the past (not the finalized block)
   * @param _of the address of account to get voting power of
   * @param _blockNum block number to get the voting power at
   * @return past cumulative voting power of the account,
   *      sum of token balances of all its voting delegators at block number `_blockNum`
   */
  function getVotingPowerAt(address _of, uint256 _blockNum) public view returns (uint256) {
    // make sure block number is not in the past (not the finalized block)
    require(_blockNum < block.number, "not yet determined"); // Compound msg

    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if voting power history for the account provided is empty
    if (history.length == 0) {
      // than voting power is zero - return the result
      return 0;
    }

    // check latest voting power history record block number:
    // if history was not updated after the block of interest
    if (history[history.length - 1].blockNumber <= _blockNum) {
      // we're done - return last voting power record
      return getVotingPower(_of);
    }

    // check first voting power history record block number:
    // if history was never updated before the block of interest
    if (history[0].blockNumber > _blockNum) {
      // we're done - voting power at the block num of interest was zero
      return 0;
    }

    // `votingPowerHistory[_of]` is an array ordered by `blockNumber`, ascending;
    // apply binary search on `votingPowerHistory[_of]` to find such an entry number `i`, that
    // `votingPowerHistory[_of][i].blockNumber <= _blockNum`, but in the same time
    // `votingPowerHistory[_of][i + 1].blockNumber > _blockNum`
    // return the result - voting power found at index `i`
    return history[__binaryLookup(_of, _blockNum)].votingPower;
  }

  /**
   * @dev Reads an entire voting power history array for the delegate specified
   *
   * @param _of delegate to query voting power history for
   * @return voting power history array for the delegate of interest
   */
  function getVotingPowerHistory(address _of) public view returns (VotingPowerRecord[] memory) {
    // return an entire array as memory
    return votingPowerHistory[_of];
  }

  /**
   * @dev Returns length of the voting power history array for the delegate specified;
   *      useful since reading an entire array just to get its length is expensive (gas cost)
   *
   * @param _of delegate to query voting power history length for
   * @return voting power history array length for the delegate of interest
   */
  function getVotingPowerHistoryLength(address _of) public view returns (uint256) {
    // read array length and return
    return votingPowerHistory[_of].length;
  }

  /**
   * @notice Delegates voting power of the delegator `msg.sender` to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @param _to address to delegate voting power to
   */
  function delegate(address _to) public {
    // verify delegations are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS), "delegations are disabled");
    // delegate call to `__delegate`
    __delegate(msg.sender, _to);
  }

  /**
   * @notice Delegates voting power of the delegator (represented by its signature) to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
   *      see https://eips.ethereum.org/EIPS/eip-712
   *
   * @param _to address to delegate voting power to
   * @param _nonce nonce used to construct the signature, and used to validate it;
   *      nonce is increased by one after successful signature validation and vote delegation
   * @param _exp signature expiration time
   * @param v the recovery byte of the signature
   * @param r half of the ECDSA signature pair
   * @param s half of the ECDSA signature pair
   */
  function delegateWithSig(
    address _to,
    uint256 _nonce,
    uint256 _exp,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    // verify delegations on behalf are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS_ON_BEHALF), "delegations on behalf are disabled");

    // build the EIP-712 contract domain separator
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));

    // build the EIP-712 hashStruct of the delegation message
    bytes32 hashStruct = keccak256(abi.encode(DELEGATION_TYPEHASH, _to, _nonce, _exp));

    // calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));

    // recover the address who signed the message with v, r, s
    address signer = ecrecover(digest, v, r, s);

    // perform message integrity and security validations
    require(signer != address(0), "invalid signature"); // Compound msg
    require(_nonce == nonces[signer], "invalid nonce"); // Compound msg
    require(block.timestamp < _exp, "signature expired"); // Compound msg

    // update the nonce for that particular signer to avoid replay attack
    nonces[signer]++;

    // delegate call to `__delegate` - execute the logic required
    __delegate(signer, _to);
  }

  /**
   * @dev Auxiliary function to delegate delegator's `_from` voting power to the delegate `_to`
   * @dev Writes to `votingDelegates` and `votingPowerHistory` mappings
   *
   * @param _from delegator who delegates his voting power
   * @param _to delegate who receives the voting power
   */
  function __delegate(address _from, address _to) private {
    // read current delegate to be replaced by a new one
    address _fromDelegate = votingDelegates[_from];

    // read current voting power (it is equal to token balance)
    uint256 _value = tokenBalances[_from];

    // reassign voting delegate to `_to`
    votingDelegates[_from] = _to;

    // update voting power for `_fromDelegate` and `_to`
    __moveVotingPower(_fromDelegate, _to, _value);

    // emit an event
    emit DelegateChanged(_from, _fromDelegate, _to);
  }

  /**
   * @dev Auxiliary function to move voting power `_value`
   *      from delegate `_from` to the delegate `_to`
   *
   * @dev Doesn't have any effect if `_from == _to`, or if `_value == 0`
   *
   * @param _from delegate to move voting power from
   * @param _to delegate to move voting power to
   * @param _value voting power to move from `_from` to `_to`
   */
  function __moveVotingPower(
    address _from,
    address _to,
    uint256 _value
  ) private {
    // if there is no move (`_from == _to`) or there is nothing to move (`_value == 0`)
    if (_from == _to || _value == 0) {
      // return silently with no action
      return;
    }

    // if source address is not zero - decrease its voting power
    if (_from != address(0)) {
      // read current source address voting power
      uint256 _fromVal = getVotingPower(_from);

      // calculate decreased voting power
      // underflow is not possible by design:
      // voting power is limited by token balance which is checked by the callee
      uint256 _toVal = _fromVal - _value;

      // update source voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_from, _fromVal, _toVal);
    }

    // if destination address is not zero - increase its voting power
    if (_to != address(0)) {
      // read current destination address voting power
      uint256 _fromVal = getVotingPower(_to);

      // calculate increased voting power
      // overflow is not possible by design:
      // max token supply limits the cumulative voting power
      uint256 _toVal = _fromVal + _value;

      // update destination voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_to, _fromVal, _toVal);
    }
  }

  /**
   * @dev Auxiliary function to update voting power of the delegate `_of`
   *      from value `_fromVal` to value `_toVal`
   *
   * @param _of delegate to update its voting power
   * @param _fromVal old voting power of the delegate
   * @param _toVal new voting power of the delegate
   */
  function __updateVotingPower(
    address _of,
    uint256 _fromVal,
    uint256 _toVal
  ) private {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if there is an existing voting power value stored for current block
    if (history.length != 0 && history[history.length - 1].blockNumber == block.number) {
      // update voting power which is already stored in the current block
      history[history.length - 1].votingPower = uint192(_toVal);
    }
    // otherwise - if there is no value stored for current block
    else {
      // add new element into array representing the value for current block
      history.push(VotingPowerRecord(uint64(block.number), uint192(_toVal)));
    }

    // emit an event
    emit VotingPowerChanged(_of, _fromVal, _toVal);
  }

  /**
   * @dev Auxiliary function to lookup an element in a sorted (asc) array of elements
   *
   * @dev This function finds the closest element in an array to the value
   *      of interest (not exceeding that value) and returns its index within an array
   *
   * @dev An array to search in is `votingPowerHistory[_to][i].blockNumber`,
   *      it is sorted in ascending order (blockNumber increases)
   *
   * @param _to an address of the delegate to get an array for
   * @param n value of interest to look for
   * @return an index of the closest element in an array to the value
   *      of interest (not exceeding that value)
   */
  function __binaryLookup(address _to, uint256 n) private view returns (uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_to];

    // left bound of the search interval, originally start of the array
    uint256 i = 0;

    // right bound of the search interval, originally end of the array
    uint256 j = history.length - 1;

    // the iteration process narrows down the bounds by
    // splitting the interval in a half oce per each iteration
    while (j > i) {
      // get an index in the middle of the interval [i, j]
      uint256 k = j - (j - i) / 2;

      // read an element to compare it with the value of interest
      VotingPowerRecord memory cp = history[k];

      // if we've got a strict equal - we're lucky and done
      if (cp.blockNumber == n) {
        // just return the result - index `k`
        return k;
      }
      // if the value of interest is bigger - move left bound to the middle
      else if (cp.blockNumber < n) {
        // move left bound `i` to the middle position `k`
        i = k;
      }
      // otherwise, when the value of interest is smaller - move right bound to the middle
      else {
        // move right bound `j` to the middle position `k - 1`:
        // element at position `k` is bigger and cannot be the result
        j = k - 1;
      }
    }

    // reaching that point means no exact match found
    // since we're interested in the element which is not bigger than the
    // element of interest, we return the lower bound `i`
    return i;
  }
}

// ===== End: DAO Support (Compound-like voting delegation) =====

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/ERC20.sol";
import "../utils/AccessControl.sol";

contract SyntheticSyndicateERC20 is ERC20("Synthetic Syndicate Token", "sSYNR"), AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62;

  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  uint32 public constant ROLE_WHITE_LISTED_RECEIVER = 0x0004_0000;

  constructor(address _superAdmin) AccessControl(_superAdmin) {}

  /**
   * @notice Must be called by ROLE_TOKEN_CREATOR addresses.
   *
   * @param recipient address to receive the tokens.
   * @param amount number of tokens to be minted.
   */
  function mint(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "sSYNR: insufficient privileges (ROLE_TOKEN_CREATOR required)");
    _mint(recipient, amount);
  }

  /**
   * @param amount number of tokens to be burned.
   */
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  /**
   * @notice Must be called by ROLE_TOKEN_DESTROYER addresses (SynrSwapper)
   *         Can burn only tokens owned by ROLE_WHITE_LISTED_RECEIVER address
   * @param recipient address to burn the tokens.
   * @param amount number of tokens to be burned
   */
  function burn(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_DESTROYER), "sSYNR: insufficient privileges (ROLE_TOKEN_DESTROYER required)");
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    _burn(recipient, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    super._transfer(sender, recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "hardhat/console.sol";

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessControl {
  /**
   * @notice Access manager is responsible for assigning the roles to users,
   *      enabling/disabling global features of the smart contract
   * @notice Access manager can add, remove and update user roles,
   *      remove and update global features
   *
   * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
   * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
   */
  uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

  /**
   * @dev Bitmask representing all the possible permissions (super admin role)
   * @dev Has all the bits are enabled (2^256 - 1 value)
   */
  // solhint-disable-next-line
  uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

  /**
   * @notice Privileged addresses with defined roles/permissions
   * @notice In the context of ERC20/ERC721 tokens these can be permissions to
   *      allow minting or burning tokens, transferring on behalf and so on
   *
   * @dev Maps user address to the permissions bitmask (role), where each bit
   *      represents a permission
   * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
   *      represents all possible permissions
   * @dev Zero address mapping represents global features of the smart contract
   */
  mapping(address => uint256) public userRoles;

  /**
   * @dev Fired in updateRole() and updateFeatures()
   *
   * @param _by operator which called the function
   * @param _to address which was granted/revoked permissions
   * @param _requested permissions requested
   * @param _actual permissions effectively set
   */
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

  /**
   * @notice Creates an access control instance,
   *      setting contract creator to have full privileges
   */
  constructor(address _superAdmin) {
    userRoles[_superAdmin] = FULL_PRIVILEGES_MASK;
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

  /**
   * @notice Retrieves globally set of features enabled
   *
   * @dev Auxiliary getter function to maintain compatibility with previous
   *      versions of the Access Control List smart contract, where
   *      features was a separate uint256 public field
   *
   * @return 256-bit bitmask of the features enabled
   */
  function features() public view returns (uint256) {
    // according to new design features are stored in zero address
    // mapping of `userRoles` structure
    return userRoles[address(0)];
  }

  /**
   * @notice Updates set of the globally enabled features (`features`),
   *      taking into account sender's permissions
   *
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   * @dev Function is left for backward compatibility with older versions
   *
   * @param _mask bitmask representing a set of features to enable/disable
   */
  function updateFeatures(uint256 _mask) public {
    // delegate call to `updateRole`
    updateRole(address(0), _mask);
  }

  /**
   * @notice Updates set of permissions (role) for a given user,
   *      taking into account sender's permissions.
   *
   * @dev Setting role to zero is equivalent to removing an all permissions
   * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
   *      copying senders' permissions (role) to the user
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   *
   * @param operator address of a user to alter permissions for or zero
   *      to alter global features of the smart contract
   * @param role bitmask representing a set of permissions to
   *      enable/disable for a user specified
   */
  function updateRole(address operator, uint256 role) public {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");

    // evaluate the role and reassign it
    userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

    // fire an event
    emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
  }

  /**
   * @notice Determines the permission bitmask an operator can set on the
   *      target permission set
   * @notice Used to calculate the permission bitmask to be set when requested
   *     in `updateRole` and `updateFeatures` functions
   *
   * @dev Calculated based on:
   *      1) operator's own permission set read from userRoles[operator]
   *      2) target permission set - what is already set on the target
   *      3) desired permission set - what do we want set target to
   *
   * @dev Corner cases:
   *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
   *        `desired` bitset is returned regardless of the `target` permission set value
   *        (what operator sets is what they get)
   *      2) Operator with no permissions (zero bitset):
   *        `target` bitset is returned regardless of the `desired` value
   *        (operator has no authority and cannot modify anything)
   *
   * @dev Example:
   *      Consider an operator with the permissions bitmask     00001111
   *      is about to modify the target permission set          01010101
   *      Operator wants to set that permission set to          00110011
   *      Based on their role, an operator has the permissions
   *      to update only lowest 4 bits on the target, meaning that
   *      high 4 bits of the target set in this example is left
   *      unchanged and low 4 bits get changed as desired:      01010011
   *
   * @param operator address of the contract operator which is about to set the permissions
   * @param target input set of permissions to operator is going to modify
   * @param desired desired set of permissions operator would like to set
   * @return resulting set of permissions given operator will set
   */
  function evaluateBy(
    address operator,
    uint256 target,
    uint256 desired
  ) public view returns (uint256) {
    // read operator's permissions
    uint256 p = userRoles[operator];

    // taking into account operator's permissions,
    // 1) enable the permissions desired on the `target`
    target |= p & desired;
    // 2) disable the permissions desired on the `target`
    target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

    // return calculated result
    return target;
  }

  /**
   * @notice Checks if requested set of features is enabled globally on the contract
   *
   * @param required set of features to check against
   * @return true if all the features requested are enabled, false otherwise
   */
  function isFeatureEnabled(uint256 required) public view returns (bool) {
    // delegate call to `__hasRole`, passing `features` property
    return __hasRole(features(), required);
  }

  /**
   * @notice Checks if transaction sender `msg.sender` has all the permissions required
   *
   * @param required set of permissions (role) to check against
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isSenderInRole(uint256 required) public view returns (bool) {
    // delegate call to `isOperatorInRole`, passing transaction sender
    return isOperatorInRole(msg.sender, required);
  }

  /**
   * @notice Checks if operator has all the permissions (role) required
   *
   * @param operator address of the user to check role for
   * @param required set of permissions (role) to check
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
    // delegate call to `__hasRole`, passing operator's permissions (role)
    return __hasRole(userRoles[operator], required);
  }

  /**
   * @dev Checks if role `actual` contains all the permissions required `required`
   *
   * @param actual existent role
   * @param required required role
   * @return true if actual has required role (all permissions), false otherwise
   */
  function __hasRole(uint256 actual, uint256 required) internal pure returns (bool) {
    // check the bitmask for the role required and return the result
    return actual & required == required;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @author Basil Gorin
 */
library AddressUtils {
  /**
   * @notice Checks if the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *      as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    // a variable to load `extcodesize` to
    uint256 size = 0;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
    // TODO: Check this again before the Serenity release, because all addresses will be contracts.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // retrieve the size of the code at address `addr`
      size := extcodesize(addr)
    }

    // positive size indicates a smart contract address
    return size > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title ERC20 token receiver interface
 *
 * @dev Interface for any contract that wants to support safe transfers
 *      from ERC20 token smart contracts.
 * @dev Inspired by ERC721 and ERC223 token standards
 *
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @dev See https://github.com/ethereum/EIPs/issues/223
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
interface ERC20Receiver {
  /**
   * @notice Handle the receipt of a ERC20 token(s)
   * @dev The ERC20 smart contract calls this function on the recipient
   *      after a successful transfer (`safeTransferFrom`).
   *      This function MAY throw to revert and reject the transfer.
   *      Return of other than the magic value MUST result in the transaction being reverted.
   * @notice The contract address is always the message sender.
   *      A wallet/broker/auction application MUST implement the wallet interface
   *      if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _value amount of tokens which is being transferred
   * @param _data additional data with no specified format
   * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
   */
  function onERC20Received(
    address _operator,
    address _from,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

// Copied from Open Zeppelin

contract ERC20 is IERC20 {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @notice Token creator is responsible for creating (minting)
   *      tokens to an arbitrary address
   * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
   *      (calling `mint` function)
   */
  uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account] - amount;
    _totalSupply = _totalSupply - amount;
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}