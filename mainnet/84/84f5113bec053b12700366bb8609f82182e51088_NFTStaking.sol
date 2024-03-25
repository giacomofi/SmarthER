// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

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

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract NFTStaking is Ownable, IERC721Receiver {
    uint256 private _totalStaked;
    uint256 public endTimestamp;
    uint256 public ratePerDay;
    uint256 public tokenDecimals;

    uint8[10000] public ids;

    uint8 private rarityMask = 3;

    mapping(address => uint) kinBonusActiveSince;

    mapping(uint => bool) legendary;

    uint public legendaryMultiplier = 50;

    uint public kinCount = 7;

    mapping(address => uint256) private timeStaked;
    mapping(address => uint256) private lastChecked;
    mapping(address => uint256) private remainingClaims;
    mapping(address => uint256[]) private stakedIds;

    mapping(uint256 => uint256) private experiences;

    mapping(address => uint256) claimedSoFar;

    mapping(uint256 => uint8) private rarityTiers;

    mapping(uint256 => Lock) private locks;

    uint256 public maxLevel = 100;
    uint256 public lockCount;
    uint256 public expRate = 100;
    uint256 public expDecimals = 5;

    mapping(address => bool) private hasStaked;

    uint256 public claimedAmount;

    struct Lock {
        uint256 lockTime;
        uint256 rewardMultiplier;
    }

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
        address owner;
        uint256 lockEndTimestamp;
        uint256 rewardMultiplier;
    }

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    IERC721 public nft;
    IERC20 public token;

    mapping(uint256 => Stake) private vault;

    constructor(
        IERC721 _nft,
        IERC20 _token,
        uint256 duration,
        uint256 rate_,
        uint256 tokenDecimals_
    ) {
        nft = _nft;
        token = _token;
        endTimestamp = block.timestamp + duration;
        ratePerDay = rate_ * 10 ** tokenDecimals_;
        tokenDecimals = tokenDecimals_;
        addLock(30 days, 0);
        addLock(60 days, 15);
        addLock(90 days, 30);
        addLock(120 days, 50);
        rarityTiers[0] = 0;
        rarityTiers[1] = 15;
        rarityTiers[2] = 30;
        rarityTiers[3] = 50;
    }

    function getKin(uint8 value) public pure returns(uint8){
        return value >> 2;
    }

    function getRarityBonus(uint8 value) public view returns(uint8){
        return rarityTiers[value & rarityMask];
    }

    function setToken(address t) external onlyOwner {
        token = IERC20(t);
    }

    function isLegendary(uint tokenId) public view returns(bool) {
        return legendary[tokenId];
    }

    function addLegendary(uint tokenId) external onlyOwner {
        legendary[tokenId] = true;
    }

    function removeLegendary(uint tokenId) external onlyOwner {
        legendary[tokenId] = false;
    }

    function setLegendaryMultiplier(uint newVal) external onlyOwner {
        legendaryMultiplier = newVal;
    }

    // for example a multiplier of 115 = +15% rewards
    function editRarityTierMultiplier(uint256 t, uint8 multiplier)
        external
        onlyOwner
    {
        rarityTiers[t] = multiplier;
    }

    function addLock(
        uint256 lockTime_,
        uint256 rewardMultiplier_
    ) public onlyOwner {
        locks[lockCount] = Lock({
            lockTime: lockTime_,
            rewardMultiplier: rewardMultiplier_
        });
        lockCount++;
    }

    function setMaxLevel(uint256 n) external onlyOwner {
        maxLevel = n;
    }

    function editLock(
        uint256 lockNumber,
        uint256 lockTime_,
        uint256 rewardMultiplier_
    ) external onlyOwner {
        locks[lockNumber] = Lock({
            lockTime: lockTime_,
            rewardMultiplier: rewardMultiplier_
        });
    }

    function stake(uint256[] calldata tokenIds, uint256 lockType_) external {
        hasStaked[msg.sender] = true;
        uint256 tokenId;
        _totalStaked += tokenIds.length;
        Lock memory l = getLockInfo(lockType_);
        bool bonusActive = isKinBonus(msg.sender);
        bool hasStake = stakedIds[msg.sender].length > 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "not your nft");
            require(vault[tokenId].tokenId == 0, "already staked");

            nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp);
            uint256 rarityMultiplier = getRarityBonus(ids[tokenId]);
            uint legendaryMult = legendary[tokenId] ? legendaryMultiplier : 0;
            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint256(tokenId),
                timestamp: getTimestamp(),
                lockEndTimestamp: block.timestamp + l.lockTime,
                rewardMultiplier: ratePerDay * (100 + l.rewardMultiplier + rarityMultiplier + legendaryMult) / 100
            });
            stakedIds[msg.sender].push(tokenId);
        }
        
        if (!hasStake) {
            lastChecked[msg.sender] = block.timestamp;
        }
        if(!bonusActive && isKinBonus(msg.sender)) kinBonusActiveSince[msg.sender] = block.timestamp;
    }

    function _unstakeMany(address account, uint256[] calldata tokenIds)
        internal
    {
        uint256 tokenId;
        _totalStaked -= tokenIds.length;
        uint idx;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner");
            require(
                staked.lockEndTimestamp <= block.timestamp,
                "Nft is still locked"
            );
            delete vault[tokenId];
            for (uint256 ii = 0; ii < stakedIds[account].length; ii++) {
                if (stakedIds[account][ii] == tokenId) idx = ii;
            }
            require(idx < stakedIds[account].length);
            stakedIds[account][idx] = stakedIds[account][stakedIds[account].length-1];
            stakedIds[account].pop();

            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
        }
        if (stakedIds[account].length == 0) {
            timeStaked[msg.sender] += block.timestamp - lastChecked[account];
            lastChecked[account] = block.timestamp;
        }
    }

    function timeSpentStaking(address account) external view  returns(uint t){
        t += timeStaked[account];
        if (stakedIds[account].length > 0 && lastChecked[account] > 0) t += block.timestamp - lastChecked[account];
    }

    function emergencyUnstake(address account, uint256[] calldata tokenIds) external onlyOwner {
        uint256 tokenId;
        _totalStaked -= tokenIds.length;
        uint idx;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            delete vault[tokenId];
            for (uint256 ii = 0; ii < stakedIds[account].length - 1; ii++) {
                if (stakedIds[account][ii] == tokenId) idx = ii;
            }
            require(idx < stakedIds[account].length);
            stakedIds[account][idx] = stakedIds[account][stakedIds[account].length-1];
            stakedIds[account].pop();

            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
        }
    }

    function claim(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function setEndTimestamp(uint256 newTimestamp) external onlyOwner {
        endTimestamp = newTimestamp;
    }

    function update(
        uint8[] calldata data_,
        uint16 from
    ) external onlyOwner {
        for (uint16 i;i<data_.length;i++){
            ids[i+from] = data_[i];
        }
    }
 
    function isKinBonus(address account) public view returns(bool) {
        bool[] memory _kins = new bool[](kinCount);

        for (uint i;i<stakedIds[account].length;i++){
            _kins[getKin(ids[stakedIds[account][i]])] = true;
        }
        uint cnt;
        for (uint i;i<_kins.length;i++){
            if (_kins[i]) cnt++;
        }
        return cnt == kinCount;
    }

    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal {
        uint256 tokenId;
        uint256 earned = remainingClaims[account];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            if (staked.owner != account) continue;
            earned += staked.rewardMultiplier * (block.timestamp - staked.timestamp) / 86400;
            if (isKinBonus(account)) earned += staked.rewardMultiplier * (block.timestamp - kinBonusActiveSince[account]) / 86400;
            kinBonusActiveSince[account] = block.timestamp;
            experiences[tokenId] += expRate * 10 ** expDecimals * (block.timestamp - staked.timestamp) / 86400;
            vault[tokenId].timestamp = getTimestamp();
        }
        if (earned > 0) {
            if (token.balanceOf(address(this)) < earned) {
                remainingClaims[account] = earned;
            } else {
                token.transfer(account, earned);
                claimedSoFar[account] += earned;
                claimedAmount += earned;
                remainingClaims[account] = 0;
            }
        }
        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdrawTokens(address token_, uint256 amount) external onlyOwner {
        if (amount > IERC20(token_).balanceOf(address(this)))
            amount = IERC20(token_).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(token_), owner(), amount);
    }
    // Views

    function getAllLocks() external view returns (Lock[] memory) {
        Lock[] memory _locks = new Lock[](lockCount);
        for (uint256 i = 0; i < lockCount; i++) {
            _locks[i] = locks[i];
        }
        return _locks;
    }

    function stakedOrNot(address account) external view returns(bool) {
        return hasStaked[account];
    }

    function getStakedIds(address account)
        public
        view
        returns (uint256[] memory)
    {
        return stakedIds[account];
    }

    function getMetadata() external view returns (address, address) {
        return (address(nft), address(token));
    }

    function stakeInfo(uint256 tokenId) public view returns (Stake memory) {
        return vault[tokenId];
    }
    function getUserStakeInfo(address account) external view returns (Stake[] memory) {
        uint256[] memory _stakedIds = getStakedIds(account); 
        Stake[] memory s = new Stake[](_stakedIds.length);
        for (uint256 i; i < _stakedIds.length; i++) {
            s[i] = stakeInfo(_stakedIds[i]);
        }
        return s;
    }
    function getRemainingLeft() external view returns (uint256) {
        return remainingClaims[msg.sender];
    }

    function earningInfo(address account)
        external
        view
        returns (uint256 earned)
    {
        uint256 tokenId;
        uint256[] memory tokenIds = getStakedIds(account);
        earned = remainingClaims[account];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            if (staked.owner != account) continue;
            earned += staked.rewardMultiplier * (block.timestamp - staked.timestamp) / 86400;
            if (isKinBonus(account)) earned += staked.rewardMultiplier * (block.timestamp - kinBonusActiveSince[account]) / 86400;
        }
    }

    function getXpEarned(uint256 tokenId_)
        public
        view
        returns (uint256 experience)
    {
        experience += experiences[tokenId_];
        Stake memory staked = vault[tokenId_];
        if (staked.timestamp != 0)
        experience += expRate * 10 ** expDecimals * (block.timestamp - staked.timestamp) / 86400;
    }

    function getTimestamp() private view returns (uint256) {
        return
            block.timestamp > endTimestamp
                ? endTimestamp
                : block.timestamp;
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function getLockInfo(uint256 lockType_) public view returns (Lock memory l) {
        require(lockType_ < lockCount, "Nonexistent locktype");
        l = locks[lockType_];
    }

    function getRarityTierMultiplier(uint256 t) external view returns (uint256) {
        return rarityTiers[t];
    }

    function getLevel(uint256 tokenId) public view returns (uint256 level) {
        uint256 _level = uint256(getXpEarned(tokenId) / 10**expDecimals / 100) + 1;
        return _level > maxLevel ? maxLevel : _level;
    }

    function getProgress(uint256[] calldata tokenIds) external view returns(uint256[] memory) {
        uint256[] memory xps = new uint256[](tokenIds.length);
        for (uint i;i<tokenIds.length;i++){
            xps[i] = getXpEarned(tokenIds[i]);
        }
        return xps;
    }

    function getLevels(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = getStakedIds(account);
        uint256[] memory levels = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            levels[i] = getLevel(tokenIds[i]);
        }
        return levels;
    }

    function getMaxLevel(uint256[] calldata tokenIds)
        external
        view
        returns (uint256, uint256)
    {
        uint256 max;
        uint256 maxId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (getLevel(tokenIds[i]) > max) {
                max = getLevel(tokenIds[i]);
                maxId = tokenIds[i];
            }
        }
        return (maxId, max);
    }

    function getLevels2(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory levels = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            levels[i] = getLevel(tokenIds[i]);
        }
        return levels;
    }

    function farmed(address account) external view returns (uint256 amount) {
        return claimedSoFar[account];
    }

    function grantLevels(uint256[] calldata tokenIds, uint256 level)
        external
        onlyOwner
    {
        for (uint256 i; i < tokenIds.length; i++) {
            experiences[tokenIds[i]] += 100 * 10**expDecimals * level;
        }
    }
}