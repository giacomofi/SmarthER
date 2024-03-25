// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";

import {IUZV1Staking} from "./interfaces/IUZV1Staking.sol";
import {IUZV1DAO} from "./interfaces/dao/IUZV1DAO.sol";

import {UZV1ProAccess} from "./membership/UZV1ProAccess.sol";
import {SharedDataTypes} from "./libraries/SharedDataTypes.sol";

/**
 * @title UnizenStaking
 * @author Unizen
 * @notice Unizen staking contract V1 that keeps track of stakes and TVL
 **/
contract UZV1Staking is IUZV1Staking, UZV1ProAccess {
    using SafeMath for uint256;
    /* === STATE VARIABLES === */
    // dao contract
    IUZV1DAO public dao;

    // storage of user stakes
    mapping(address => SharedDataTypes.StakerUser) public stakerUsers;

    // stakeable tokens data
    mapping(address => SharedDataTypes.StakeableToken) public stakeableTokens;

    // all whitelisted tokens
    address[] public activeTokens;

    // zcxht token address
    address public zcxht;

    // combined weight of all active tokens
    // stored to prevent recalculations of the weight
    // for every pool update
    uint256 public combinedTokenWeight;

    function initialize(
        address _zcx,
        uint256 _zcxTokenWeight,
        address _accessToken
    ) public initializer {
        UZV1ProAccess.initialize(_accessToken);
        // setup first stakeable token
        SharedDataTypes.StakeableToken storage _token = stakeableTokens[_zcx];

        // set token data
        _token.weight = _zcxTokenWeight;
        _token.active = true;

        // add token to active list
        activeTokens.push(_zcx);

        // setup helpers for token weight
        combinedTokenWeight = _zcxTokenWeight;
    }

    /* === VIEW FUNCTIONS === */

    /**
     * @dev Helper function to get the current TVL
     *
     * @return array with amounts staked on this contract
     **/
    function getTVLs() external view override returns (uint256[] memory) {
        return getTVLs(block.number);
    }

    /**
     * @dev Helper function to get the TVL on a block.number
     *
     * @return array with amounts staked on this contract
     **/
    function getTVLs(uint256 _blocknumber)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _tvl = new uint256[](activeTokens.length);
        for (uint8 i = 0; i < activeTokens.length; i++) {
            _tvl[i] = _getTVL(_blocknumber, activeTokens[i]);
        }
        return _tvl;
    }

    function _getTVL(uint256 _blocknumber, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 _tvl;
        if (_blocknumber == block.number) {
            // if blocknumber is current block number, we return the last saved TVL
            _tvl = stakeableTokens[_token].totalValueLocked;
        } else {
            _tvl = stakeableTokens[_token].totalValueLockedSnapshots[
                _blocknumber
            ];
            // if we don't find a TVL snapshot, we search in the snapshot array
            if (_tvl == 0) {
                (uint256 _lastSavedBlock, ) = _findLastSavedBlock(
                    stakeableTokens[_token].totalValueLockedKeys,
                    _blocknumber
                );
                if (_lastSavedBlock == 0) {
                    _tvl = 0;
                } else {
                    _tvl = stakeableTokens[_token].totalValueLockedSnapshots[
                        _lastSavedBlock
                    ];
                }
            }
        }
        return _tvl;
    }

    /**
     * @dev used to calculate the users stake of the pool
     * @param _user optional user addres, if empty the sender will be used
     * @param _precision optional denominator, default to 3
     *
     * @return array with the percentage stakes of the user based on TVL of each allowed token
     *  [
     *   weightedAverage,
     *   shareOfUtilityToken,
     *   ShareOfLPToken...
     *  ]
     *
     **/
    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        override
        returns (uint256[] memory)
    {
        // precision is 3 by default
        if (_precision == 0) {
            _precision = 3;
        }

        // default to sender if no user is specified
        if (_user == address(0)) {
            _user = _msgSender();
        }

        uint256 _denominator = 10**(_precision.add(2));

        // for precision rounding
        _denominator = _denominator.mul(10);

        uint256[] memory _shares = new uint256[](activeTokens.length + 1);

        uint256 _sumWeight = 0;
        uint256 _sumShares = 0;

        for (uint256 i = 0; i < activeTokens.length; i++) {
            // calculate users percentage stakes
            uint256 _tokenShare;
            if (stakeableTokens[activeTokens[i]].totalValueLocked > 0) {
                _tokenShare = stakerUsers[_user]
                    .stakedAmount[activeTokens[i]]
                    .mul(_denominator)
                    .div(stakeableTokens[activeTokens[i]].totalValueLocked);
            }

            // check current weight of token
            uint256 _tokenWeight = stakeableTokens[activeTokens[i]].weight;
            // add current token weight to weight sum
            _sumWeight = _sumWeight.add(_tokenWeight);
            // add users current token share to share sum
            _sumShares = _sumShares.add(_tokenShare.mul(_tokenWeight));
            // add users percentage stakes of current token, including precision rounding
            _shares[i + 1] = _tokenShare.add(5).div(10);
        }

        // calculate final weighted average of user stakes
        _shares[0] = _sumShares.div(_sumWeight).add(5).div(10);

        return _shares;
    }

    /**
     * @dev Helper function to get the staked token amount
     *
     * @return uint256 staked amount of token
     **/
    function getUsersStakedAmountOfToken(address _user, address _token)
        external
        view
        override
        returns (uint256)
    {
        if (_token == zcxht) {
            return stakerUsers[_user].zcxhtStakedAmount;
        } else {
            return stakerUsers[_user].stakedAmount[_token];
        }
    }

    /**
     * @dev Helper function to fetch all existing data to an address
     *
     * @return array of token addresses
     * @return array of users staked amount for each token
     * @return ZCXHT staked amount
     **/
    function getUserData(address _user)
        external
        view
        override
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        // init temporary array with token count
        uint256[] memory _userStakes = new uint256[](activeTokens.length);

        // loop through all known tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // get user stakes for active token
            _userStakes[i] = stakerUsers[_user].stakedAmount[activeTokens[i]];
        }

        // return active token stakes
        return (
            activeTokens,
            _userStakes,
            stakerUsers[_user].zcxhtStakedAmount
        );
    }

    /**
     * @dev Creates a list of active tokens, excluding inactive tokens
     *
     * @return address[] array of active stakeable token tokens
     **/
    function getActiveTokens() public view override returns (address[] memory) {
        return activeTokens;
    }

    /**
     * @dev Creates a list of active token weights, excluding inactive tokens
     *
     * @return weights uint256[] array including every active token weight
     * @return combinedWeight uint256 combined weight of all active tokens
     **/
    function getTokenWeights()
        external
        view
        override
        returns (uint256[] memory weights, uint256 combinedWeight)
    {
        // create new memory array at the size of the current token count
        weights = new uint256[](activeTokens.length);
        combinedWeight = combinedTokenWeight;
        // loop through maximum amount of allowed tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // add token to active token list
            weights[i] = stakeableTokens[activeTokens[i]].weight;
        }
    }

    /**
     * @dev  Returns all block number snapshots for an specific user and token
     *
     * @param _user Address of the user
     * @param _token Address of the token
     * @param _startBlock Start block to search for snapshots
     * @param _endBlock End block to search for snapshots
     * @param _claimedBlocks Array of block numbers when the user has claimed
     *
     * @return snapshots snapshoted data grouped by stakes
     **/
    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _claimedBlocks
    )
        external
        view
        override
        returns (SharedDataTypes.StakeSnapshot[] memory snapshots)
    {
        (, uint256 _index) = _findLastSavedBlock(
            stakerUsers[_user].stakedAmountKeys[_token],
            _startBlock
        );

        // read how many snapshots fits in the current startBlock-endBlok period
        uint256 numSnapshots;
        for (
            uint256 i = _index;
            i < stakerUsers[_user].stakedAmountKeys[_token].length &&
                stakerUsers[_user].stakedAmountKeys[_token][i] <= _endBlock;
            i++
        ) {
            numSnapshots++;
        }
        for (uint256 i = 0; i < _claimedBlocks.length; i++) {
            // If the claimed block is inside the period to be calculated...
            if (_claimedBlocks[i] <= _endBlock) {
                numSnapshots++;
            }
        }

        // create the snapshot array
        SharedDataTypes.StakeSnapshot[]
            memory _snapshot = new SharedDataTypes.StakeSnapshot[](
                numSnapshots
            );

        // Add bookmarks for every tranche
        uint256 _iStaked = _index;
        uint256 _iClaimed = 0;
        for (uint256 i = 0; i < _snapshot.length; i++) {
            // calculate start block from stakes
            uint256 _snapshotStakedBlock = (_iStaked <
                stakerUsers[_user].stakedAmountKeys[_token].length &&
                stakerUsers[_user].stakedAmountKeys[_token][_iStaked] <=
                _endBlock)
                ? stakerUsers[_user].stakedAmountKeys[_token][_iStaked]
                : 0;
            uint256 _startSnapshotBlock = (_snapshotStakedBlock > 0 &&
                _snapshotStakedBlock < _startBlock)
                ? _startBlock
                : _snapshotStakedBlock;
            // calculate start block from claims
            uint256 _claimedBlock = (_iClaimed < _claimedBlocks.length)
                ? _claimedBlocks[_iClaimed]
                : 0;
            if (
                (_startSnapshotBlock != 0 &&
                    _startSnapshotBlock <= _claimedBlock) || _claimedBlock == 0
            ) {
                _snapshot[i].startBlock = _startSnapshotBlock;
                _iStaked = _iStaked.add(1);
            } else {
                _snapshot[i].startBlock = _claimedBlock;
                _iClaimed = _iClaimed.add(1);
            }
        }

        // repeat the iteration to calculate endBlock and tokenTVL
        for (uint256 i = 0; i < _snapshot.length; i++) {
            // If this is the last snapshoted block, we get the last reward
            // block. Else, we get the next initial block minus 1
            _snapshot[i].endBlock = (i == numSnapshots.sub(1))
                ? _endBlock
                : _snapshot[i.add(1)].startBlock.sub(1);
            // read staked amount
            _snapshot[i].stakedAmount = _getUserStakeForToken(
                _user,
                _token,
                _snapshot[i].startBlock
            );
            // We read the token TVL at first and last block of this snapshot
            _snapshot[i].startTVL = _getTVL(_snapshot[i].startBlock, _token);
            _snapshot[i].endTVL = _getTVL(_snapshot[i].endBlock, _token);
        }

        return _snapshot;
    }

    /**
     * @dev Helper function to get the current staked tokens of a user
     *
     * @return uint256[] array with amounts for every stakeable token
     **/
    function getUserStakes(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return getUserStakes(_user, block.number);
    }

    /**
     * @dev Helper function to get the staked tokens of a user on a block.number
     *
     * @return uint256[] array with amounts for every stakeable token
     **/
    function getUserStakes(address _user, uint256 _blocknumber)
        public
        view
        override
        returns (uint256[] memory)
    {
        // create in memory array with the size of existing active tokens
        uint256[] memory _userStakes = new uint256[](activeTokens.length);

        // loop through active tokens
        for (uint8 i = 0; i < activeTokens.length; i++) {
            // get user stakes for active token
            _userStakes[i] = _getUserStakeForToken(
                _user,
                activeTokens[i],
                _blocknumber
            );
        }

        // return the data
        return _userStakes;
    }

    /**
     * @dev Get the staked amount of a certain token on a block.number
     *
     * @return _stakedAmount amount of staked amount
     **/
    function _getUserStakeForToken(
        address _user,
        address _token,
        uint256 _blocknumber
    ) internal view returns (uint256) {
        uint256 _stakedAmount;
        if (_blocknumber == block.number) {
            // if blocknumber is current block number, we return the last saved staked amount
            _stakedAmount = stakerUsers[_user].stakedAmount[_token];
        } else {
            _stakedAmount = stakerUsers[_user].stakedAmountSnapshots[_token][
                _blocknumber
            ];
            // if we don't find a staked amount snapshot, we search in the snapshot array
            if (_stakedAmount == 0) {
                (uint256 _lastSavedBlock, ) = _findLastSavedBlock(
                    stakerUsers[_user].stakedAmountKeys[_token],
                    _blocknumber
                );
                if (_lastSavedBlock == 0) {
                    _stakedAmount = 0;
                } else {
                    _stakedAmount = stakerUsers[_user].stakedAmountSnapshots[
                        _token
                    ][_lastSavedBlock];
                }
            }
        }
        return _stakedAmount;
    }

    /* === MUTATING FUNCTIONS === */

    /**
     * @dev  Convenience function to stake zcx token
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function stake(uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _stake(activeTokens[0], _amount);
    }

    /**
     * @dev  Convenience function to stake lp token
     * @param _lpToken Address of token to stake
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function stake(address _lpToken, uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _stake(_lpToken, _amount);
    }

    /**
     * @dev  This allows users to actually add tokens to the staking pool
     *       and take part
     * @param _token Address of token to stake
     * @param _amount Amount of tokens the user wants to stake
     *
     * @return the new amount of tokens staked
     **/
    function _stake(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        require(isAllowedToken(_token), "INVALID_TOKEN");
        // transfer tokens
        SafeERC20.safeTransferFrom(
            IERC20(_token),
            _msgSender(),
            address(this),
            _amount
        );

        address _stakeToken = (_token == zcxht) ? activeTokens[0] : _token; // if stake zcxht, equal to stake zcx

        // get current user data
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[
            _msgSender()
        ];

        // calculate new amount of user stakes
        uint256 _newStakedAmount = _stakerUser.stakedAmount[_stakeToken].add(
            _amount
        );

        uint256 _newTVL = stakeableTokens[_stakeToken].totalValueLocked.add(
            _amount
        );

        // check if holder token is staked
        if (_token == zcxht) {
            _stakerUser.zcxhtStakedAmount = _stakerUser.zcxhtStakedAmount.add(
                _amount
            );
        }

        _saveStakeInformation(
            _msgSender(),
            _stakeToken,
            _newStakedAmount,
            _newTVL
        );

        // shoot event
        emit TVLChange(_msgSender(), _stakeToken, _amount, true);

        // return users new holdings of token
        return _stakerUser.stakedAmount[_stakeToken];
    }

    /**
     * @dev  Convenience function to withdraw utility token
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function withdraw(uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _withdraw(activeTokens[0], _amount);
    }

    /**
     * @dev  Convenience function to withdraw LP tokens
     * @param _lpToken Address of token to withdraw
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function withdraw(address _lpToken, uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return _withdraw(_lpToken, _amount);
    }

    /**
     * @dev  This allows users to unstake their tokens at any point of time
     *       and also leaves it open to the users how much will be unstaked
     * @param _token Address of token to withdraw
     * @param _amount optional value, if empty the total user stake will be used
     **/
    function _withdraw(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        require(_amount > 0, "CAN_NOT_WITHDRAW_ZERO");
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[
            _msgSender()
        ];
        address _stakeToken = _token;
        uint256 _maxWithdrawable;
        if (_stakeToken == zcxht) {
            _stakeToken = activeTokens[0];
            _maxWithdrawable = _stakerUser.zcxhtStakedAmount;
        } else if (_stakeToken == activeTokens[0]) {
            _maxWithdrawable = _stakerUser.stakedAmount[_stakeToken].sub(
                _stakerUser.zcxhtStakedAmount
            );
        } else {
            _maxWithdrawable = _stakerUser.stakedAmount[_stakeToken];
        }
        require(_maxWithdrawable >= _amount, "AMOUNT_EXCEEDS_STAKED_BALANCE");
        SafeERC20.safeTransfer(IERC20(_token), _msgSender(), _amount); // calculate the new user stakes of the token
        uint256 _newStakedAmount = _stakerUser.stakedAmount[_stakeToken].sub(
            _amount
        );
        uint256 _newTVL = stakeableTokens[_stakeToken].totalValueLocked.sub(
            _amount
        );

        // DAO check, if available. Only applies to utility token withdrawals
        if (address(dao) != address(0) && _stakeToken == activeTokens[0]) {
            // get locked tokens of user (active votes)
            uint256 _lockedTokens = dao.getLockedTokenCount(_msgSender());
            // check that the user has enough unlocked tokens
            require(
                _stakerUser.stakedAmount[_stakeToken] >= _lockedTokens,
                "DAO_ALL_TOKENS_LOCKED"
            );
            require(
                _stakerUser.stakedAmount[_stakeToken].sub(_lockedTokens) >=
                    _amount,
                "DAO_TOKENS_LOCKED"
            );
        }

        _saveStakeInformation(
            _msgSender(),
            _stakeToken,
            _newStakedAmount,
            _newTVL
        );

        // check if holder token is withdrawn
        if (_token == zcxht) {
            _stakerUser.zcxhtStakedAmount = _stakerUser.zcxhtStakedAmount.sub(
                _amount
            );
        }
        // shoot event
        emit TVLChange(_msgSender(), _stakeToken, _amount, false);

        return _stakerUser.stakedAmount[_stakeToken];
    }

    /**
     * @dev  Checks if the token is whitelisted and active
     * @param _token address of token to check
     * @return bool Active status of checked token
     **/
    function isAllowedToken(address _token) public view returns (bool) {
        if (_token == address(0)) return false;
        return stakeableTokens[_token].active || _token == zcxht;
    }

    /**
     * @dev  Allows updating the utility token address that can be staked, in case
     *       of a token swap or similar event.
     * @param _token Address of new ERC20 token address
     **/
    function updateStakeToken(address _token) external onlyOwner {
        require(activeTokens[0] != _token, "SAME_ADDRESS");
        // deactive the old token
        stakeableTokens[activeTokens[0]].active = false;
        // cache the old weight
        uint256 weight = stakeableTokens[activeTokens[0]].weight;
        // assign the new address
        activeTokens[0] = _token;
        // update new token data with old settings
        stakeableTokens[activeTokens[0]].weight = weight;
        stakeableTokens[activeTokens[0]].active = true;
    }

    /**
     * @dev  Adds new token to whitelist
     * @param _token Address of new token
     * @param _weight Weight of new token
     **/
    function addToken(address _token, uint256 _weight) external onlyOwner {
        require(_token != address(0), "ZERO_ADDRESS");
        require(isAllowedToken(_token) == false, "EXISTS_ALREADY");

        // add token address to active token list
        activeTokens.push(_token);

        // set token weight
        stakeableTokens[_token].weight = _weight;
        // set token active
        stakeableTokens[_token].active = true;

        // add token weight to maximum weight helper
        combinedTokenWeight = combinedTokenWeight.add(_weight);
    }

    /**
     * @dev  Removes token from whitelist, if no tokens are locked
     * @param _token Address of token to remove
     **/
    function removeToken(address _token) external onlyOwner {
        require(isAllowedToken(_token) == true, "INVALID_TOKEN");
        require(stakeableTokens[_token].active, "INVALID_TOKEN");

        // get token index
        uint256 _idx;
        for (uint256 i = 0; i < activeTokens.length; i++) {
            if (activeTokens[i] == _token) {
                _idx = i;
            }
        }

        // remove token weight from maximum weight helper
        combinedTokenWeight = combinedTokenWeight.sub(
            stakeableTokens[_token].weight
        );

        // reset token weight
        stakeableTokens[_token].weight = 0;

        // remove from active tokens list
        activeTokens[_idx] = activeTokens[activeTokens.length - 1];
        activeTokens.pop();
        // set token inactive
        stakeableTokens[_token].active = false;
    }

    function setHolderToken(address _zcxht) external onlyOwner {
        require(zcxht != _zcxht, "SAME_ADDRESS");
        zcxht = _zcxht;
    }

    /**
     * @dev  Allows to update the weight of a specific token
     * @param _token Address of the token
     * @param _newWeight new token weight
     **/
    function updateTokenWeight(address _token, uint256 _newWeight)
        external
        onlyOwner
    {
        require(_token != address(0), "ZERO_ADDRESS");
        require(_newWeight > 0, "NO_TOKEN_WEIGHT");
        // update token weight
        combinedTokenWeight = combinedTokenWeight
            .sub(stakeableTokens[_token].weight)
            .add(_newWeight);
        stakeableTokens[_token].weight = _newWeight;
    }

    /**
     * @dev  Allows updating the dao address, in case of an upgrade.
     * @param _newDAO Address of the new Unizen DAO contract
     **/
    function updateDAO(address _newDAO) external onlyOwner {
        require(address(dao) != _newDAO, "SAME_ADDRESS");
        dao = IUZV1DAO(_newDAO);
    }

    /* === INTERNAL FUNCTIONS === */

    /**
     * @dev Save staking information after stake or withdraw and make an
     * sanapshot
     *
     * @param _user user that makes the stake/withdraw
     * @param _token token where the stake/withdraw has been made
     * @param _newStakedAmount staked/withdrawn amount of tokens
     * @param _newTVL TVL of the token after the stake/withdraw
     */
    function _saveStakeInformation(
        address _user,
        address _token,
        uint256 _newStakedAmount,
        uint256 _newTVL
    ) internal {
        SharedDataTypes.StakerUser storage _stakerUser = stakerUsers[_user];

        // updated total stake of current user
        _stakerUser.stakedAmountSnapshots[_token][
            block.number
        ] = _newStakedAmount;
        if (
            (_stakerUser.stakedAmountKeys[_token].length == 0) ||
            _stakerUser.stakedAmountKeys[_token][
                _stakerUser.stakedAmountKeys[_token].length - 1
            ] !=
            block.number
        ) {
            _stakerUser.stakedAmountKeys[_token].push(block.number);
        }
        _stakerUser.stakedAmount[_token] = _newStakedAmount;

        // update tvl of token
        stakeableTokens[_token].totalValueLockedSnapshots[
            block.number
        ] = _newTVL;
        if (
            (stakeableTokens[_token].totalValueLockedKeys.length == 0) ||
            stakeableTokens[_token].totalValueLockedKeys[
                stakeableTokens[_token].totalValueLockedKeys.length - 1
            ] !=
            block.number
        ) {
            stakeableTokens[_token].totalValueLockedKeys.push(block.number);
        }
        stakeableTokens[_token].totalValueLocked = _newTVL;
    }

    /**
     * @dev Helper function to get the last saved block number in a block index array
     *
     * @return lastSavedBlock last block number stored in the block index array
     * @return index index of the last block number stored in the block index array
     **/
    function _findLastSavedBlock(
        uint256[] storage _blockKeys,
        uint256 _blockNumber
    ) internal view returns (uint256 lastSavedBlock, uint256 index) {
        uint256 _upperBound = Arrays.findUpperBound(
            _blockKeys,
            _blockNumber.add(1)
        );
        if (_upperBound == 0) {
            return (0, 0);
        } else {
            return (_blockKeys[_upperBound - 1], _upperBound - 1);
        }
    }

    /* === EVENTS === */
    event TVLChange(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool indexed changeType
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SharedDataTypes} from "../libraries/SharedDataTypes.sol";

interface IUZV1Staking {
    /* view functions */
    function getTVLs() external view returns (uint256[] memory);

    function getTVLs(uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        returns (uint256[] memory);

    function getUsersStakedAmountOfToken(address _user, address _token)
        external
        view
        returns (uint256);

    function getUserData(address _user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        );

    function getActiveTokens() external view returns (address[] memory);

    function getTokenWeights()
        external
        view
        returns (uint256[] memory weights, uint256 combinedWeight);

    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _claimedBlocks
    ) external view returns (SharedDataTypes.StakeSnapshot[] memory snapshots);

    function getUserStakes(address _user)
        external
        view
        returns (uint256[] memory);

    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    /* mutating functions */
    function stake(uint256 _amount) external returns (uint256);

    function stake(address _lpToken, uint256 _amount)
        external
        returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function withdraw(address _lpToken, uint256 _amount)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IUZV1DAO {
    /* view functions */
    function getLockedTokenCount(address _user) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title UZProAccess
 * @author Unizen
 * @notice Simple abstract class to add easy checks
 * for pro membership access token
 **/
abstract contract UZV1ProAccess is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    // internal storage of the erc721 token
    IERC721 internal _membershipToken;

    function initialize(address _token) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        _setMembershipToken(_token);
    }

    function membershipToken() public view returns (address) {
        return address(_membershipToken);
    }

    /* === CONTROL FUNCTIONS === */
    /**
     * @dev pause smart contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause smart contract
     */
    function unPause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev  Allows the owner of the contract, to update
     * the used membership token
     * @param _newToken address of the new erc721 token
     **/
    function setMembershipToken(address _newToken) public onlyOwner {
        _setMembershipToken(_newToken);
    }

    function _setMembershipToken(address _newToken) internal {
        if (_newToken == address(0) && address(_membershipToken) == address(0))
            return;

        require(_newToken != address(_membershipToken), "SAME_ADDRESS");
        _membershipToken = IERC721(_newToken);
    }

    /**
     * @dev  Internal function that checks if the users has any
     * membership tokens. Reverts, if none is found.
     * @param _user address of user to check
     **/
    function _checkPro(address _user) internal view {
        if (address(_membershipToken) != address(0)) {
            require(
                _membershipToken.balanceOf(_user) > 0,
                "FORBIDDEN: PRO_MEMBER"
            );
        }
    }

    /* === MODIFIERS === */
    modifier onlyPro(address _user) {
        _checkPro(_user);
        _;
    }

    /* === EVENTS === */
    event MembershipTokenUpdated(address _newTokenAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SharedDataTypes {
    // struct for returning snapshot values
    struct StakeSnapshot {
        // initial block number snapshoted
        uint256 startBlock;
        // end block number snapshoted
        uint256 endBlock;
        // staked amount at initial block
        uint256 stakedAmount;
        // total value locked at start block
        uint256 startTVL;
        // total value locked at end block
        uint256 endTVL;
    }

    // general staker user information
    struct StakerUser {
        // snapshotted stakes of the user per token (token => block.number => stakedAmount)
        mapping(address => mapping(uint256 => uint256)) stakedAmountSnapshots;
        // snapshotted stakes of the user per token keys (token => block.number[])
        mapping(address => uint256[]) stakedAmountKeys;
        // current stakes of the user per token
        mapping(address => uint256) stakedAmount;
        // total amount of holder tokens
        uint256 zcxhtStakedAmount;
    }

    // information for stakeable tokens
    struct StakeableToken {
        // snapshotted total value locked (TVL) (block.number => totalValueLocked)
        mapping(uint256 => uint256) totalValueLockedSnapshots;
        // snapshotted total value locked (TVL) keys (block.number[])
        uint256[] totalValueLockedKeys;
        // current total value locked (TVL)
        uint256 totalValueLocked;
        uint256 weight;
        bool active;
    }

    // POOL DATA

    // data object for a user stake on a pool
    struct PoolStakerUser {
        // saved / withdrawn rewards of user
        uint256 totalSavedRewards;
        // total purchased allocation
        uint256 totalPurchasedAllocation;
        // native address, if necessary
        string nativeAddress;
        // date/time when user has claimed (paid in incubator pools) the reward
        uint256 claimedTime;
        // blocks where the user has claimed the rewards
        uint256[] claimedBlocks;
    }

    // flat data type of stake for UI
    struct FlatPoolStakerUser {
        address[] tokens;
        uint256[] amounts;
        uint256 pendingRewards;
        uint256 totalPurchasedAllocation;
        uint256 totalSavedRewards;
        uint256 claimedTime;
        PoolState state;
        UserPoolState userState;
    }

    // UI information for pool
    // data will be fetched via github token repository
    // blockchain / cAddress being the most relevant values
    // for fetching the correct token data
    struct PoolInfo {
        // token name
        string name;
        // name of blockchain, as written on github
        string blockchain;
        // tokens contract address on chain
        string cAddress;
    }

    // possible states of the reward pool
    enum PoolState {
        pendingStaking,
        staking,
        pendingPayment,
        payment,
        pendingDistribution,
        distribution,
        retired
    }

    // possible states of the reward pool's user
    enum UserPoolState {
        notclaimed,
        claimed,
        rejected,
        missed
    }

    // input data for new reward pools
    struct PoolInputData {
        // total rewards to distribute
        uint256 totalRewards;
        // start block for distribution
        uint256 startBlock;
        // end block for distribution
        uint256 endBlock;
        // erc token address
        address token;
        // pool type
        uint8 poolType;
        // information about the reward token
        PoolInfo tokenInfo;
    }

    struct PoolData {
        PoolState state;
        // pool information for the ui
        PoolInfo info;
        // start block of staking rewards
        uint256 startBlock;
        // end block of staking rewards
        uint256 endBlock;
        // start block of payment period
        uint256 paymentStartBlock;
        // end block of payment period
        uint256 paymentEndBlock;
        // start block of distribution period
        uint256 distributionStartBlock;
        // end block of distribution period
        uint256 distributionEndBlock;
        // total rewards for allocation
        uint256 totalRewards;
        // rewards per block
        uint256 rewardsPerBlock;
        // price of a single payment token
        uint256 rewardTokenPrice;
        // type of the pool
        uint8 poolType;
        // address of payment token
        address paymentToken;
        // address of reward token
        address token;
        // total remaining rewards for allocation (claimed or not claimed)
        // uint256 remainingRewards;
        // total open rewards for allocation (rewards not claimed)
        // uint256 openRewards;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}