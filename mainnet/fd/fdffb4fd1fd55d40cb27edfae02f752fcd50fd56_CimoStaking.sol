// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./../libs/Ownable.sol";
import "./../contracts/ReentrancyGuard.sol";
import "./../contracts/ERC721Holder.sol";
import "./../interfaces/IUniswapV2Router02.sol";
import "./../libs/SafeERC20.sol";
import "./../interfaces/ICimo.sol";
import "./../interfaces/INFT.sol";

contract CimoStaking is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    //store data of each user in UserInfo
    struct UserInfo {
        uint16 nftBoost; //NFT token multiplier
        uint16 lockTimeBoost; //time lock multiplier - max x3
        uint32 lockedUntil; //lock end in UNIX seconds, used to compute the lockTimeBoost
        uint96 claimableETH; //amount of eth ready to be claimed
        uint112 amount; //amount of staked tokens
        uint112 weightedBalance; //amout of staked tokens * multiplier * nftMultiplier
        uint256 withdrawn; //sum of withdrawn ETH
        uint112 ETHrewardDebt; //ETH debt for each staking session. Session resets upon withdrawal
        address[] NFTContracts; //array of nft contracts (for multiple NFTcontract boost
        uint256[] NFTTokenIDs; //nft id tracker
    }
    // store data of each pool
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint64 allocPoint; // How many allocation points assigned to this pool.
        uint64 lastRewardBlock; // Last reward block.
        uint112 accETHPerShare; // Accumulated ETH rewards
        uint112 weightedBalance; // weightedBalances from all users.
    }

    // helper to track users NFTs
    struct UsersNFTs {
        address NFTContract; // address
        uint256 TokenId; // id of token (NFT)
    }

    uint16 public pointsPerNFT = 150; //amount of bonus points that each NFT gives to staker
    uint256 constant ONE_DAY = 86400; //total seconds in one day
    ICimo public Cimo; // The Cimo token
    address public router; // The uniswap V2 router
    address public WETH; // The WETH token contract
    mapping(address => bool) public isNFTContract; // check if address is NFT contract
    address public TaxDistributor; // address of taxDistributor. Just in case TD transfers the ETH without arbitrary data
    uint256 public ETHPerBlock; // amount of ETH per block
    uint256 public ETHLeftUnshared; // amount of ETH that is not distributed to stakers
    uint256 public ETHLeftUnclaimed; // amount of ETH that is distributed but unclaimed
    uint256 public numdays; // number of days used to calculate rewards. Feed the staking contract with ETH within numdays days

    PoolInfo[] public poolInfo; // pool info storage
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // userinfo storage


    uint256 public totalAllocPoint; // total allocation points
    uint256 public startBlock; // starting block
    bool public isEmergency; //if Emergency users can withdraw their tokens without caring about the locks and rewards


    //events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockTime);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 cimoRWTokenPerBlock);
    event NFTStaked(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event NFTWithdrawn(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event TokensLocked(
        address indexed user,
        uint256 timestamp,
        uint256 lockTime
    );
    event Emergency(uint256 timestamp, bool ifEmergency);

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: LP Token already added");
        _;
    }

    modifier onlyEmergency() {
        require(isEmergency == true, "onlyEmergency: Emergency use only!");
        _;
    }
    mapping(address => bool) public authorized;
    modifier onlyAuthorized() {
        require(authorized[msg.sender] == true, "onlyAuthorized: address not authorized");
        _;
    }

    constructor(ICimo _cimo, address _router) {
        Cimo = _cimo;
        router = _router;
        WETH = IUniswapV2Router02(router).WETH();
        startBlock = type(uint256).max;
        Cimo.approve(router, Cimo.totalSupply());
        //approve staking-router
        numdays = 8;
    }

    /**
    * poolLength
    * Returns total number of pools
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
    * getMultiplier
    * Return reward multiplier over the given _from to _to block.
    */
    function getMultiplier(uint256 _from, uint256 _to)
    public
    pure
    returns (uint256)
    {
        return (_to - _from);
    }

    /**
    * pendingRewards
    * Calculate pending rewards
    */
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 userWeightedAmount = user.weightedBalance;
        uint256 accETHPerShare = pool.accETHPerShare;
        uint256 weightedBalance = pool.weightedBalance;
        uint256 PendingETH;
        if (block.number > pool.lastRewardBlock && weightedBalance != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ETHReward = multiplier * ETHPerBlock * pool.allocPoint / totalAllocPoint;
            accETHPerShare = accETHPerShare + ETHReward * 1e12 / weightedBalance;
            PendingETH = (userWeightedAmount * accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
        }
        return (PendingETH);
    }

    /**
    * getUsersNFTs
    * Return array of contracts and ids of users staked NFTs
    */
    function getUsersNFTs(uint256 _pid, address _user)
    public
    view
    returns (address[] memory, uint256[] memory)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 nftCount = user.NFTContracts.length;

        address[] memory _nftContracts = new address[](nftCount);
        uint256[] memory _nftTokenIds = new uint256[](nftCount);

        for (uint256 i = 0; i < nftCount; i++) {
            _nftContracts[i] = user.NFTContracts[i];
            _nftTokenIds[i] = user.NFTTokenIDs[i];
        }

        return (_nftContracts, _nftTokenIds);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    //Receive ETH from the tax splitter contract. triggered on a value transfer with .call("arbitraryData").
    fallback() external payable {
        ETHLeftUnshared += msg.value;
        updateETHRewards();
    }

    //Receive ETH sent through .send, .transfer, or .call(""). These wont be taken into account in the rewards.
    receive() external payable {
        require(msg.sender != TaxDistributor);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.weightedBalance;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = uint64(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 ETHReward = multiplier * ETHPerBlock * pool.allocPoint / totalAllocPoint;

        ETHLeftUnclaimed = ETHLeftUnclaimed + ETHReward;
        ETHLeftUnshared = ETHLeftUnshared - ETHReward;
        pool.accETHPerShare = uint112(pool.accETHPerShare + ETHReward * 1e12 / lpSupply);
        pool.lastRewardBlock = uint64(block.number);
    }

    // Deposit tokens for rewards.
    function deposit(uint256 _pid, uint256 _amount, uint256 lockTime) public nonReentrant {
        _deposit(msg.sender, _pid, _amount, lockTime);
    }

    // Withdraw unlocked tokens.
    function withdraw(uint32 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockedUntil < block.timestamp, "withdraw: Tokens locked, if you're trying to claim your rewards use the deposit function");
        require(user.amount >= _amount && _amount > 0, "withdraw: not good");
        updatePool(_pid);
        if (user.weightedBalance > 0) {
            _addToClaimable(_pid, msg.sender);
            if (user.claimableETH > 0) {
                safeETHTransfer(msg.sender, user.claimableETH);
                user.withdrawn += user.claimableETH;
                user.claimableETH = 0;
            }
        }
        user.amount = uint112(user.amount - _amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        updateUserWeightedBalance(_pid, msg.sender);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw unlocked tokens without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant onlyEmergency {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.weightedBalance -= user.weightedBalance;
        user.amount = 0;
        user.weightedBalance = 0;
        user.ETHrewardDebt = 0;
        user.claimableETH = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
    * addLiquidityNoFeeAndStake
    * take $CIMO and ETH and add it to liquidity. Return unspent ETH.
    */
    function addLiquidityNoFeeAndStake(uint256 amountTokensIn, uint256 amountETHMin, uint256 amountTokenMin, uint256 lockTime) public payable nonReentrant {
        ICimo.LiquidityETHParams memory params;
        UserInfo storage user = userInfo[0][msg.sender];
        require(msg.value > 0);
        require((lockTime >= 0 && lockTime <= 90 * ONE_DAY && user.lockedUntil <= lockTime + block.timestamp), "addLiquidityNoFeeAndStake : Lock out of range");
        updatePool(0);
        if (user.weightedBalance > 0) {
            _addToClaimable(0, msg.sender);
        }
        Cimo.transferFrom(msg.sender, address(this), amountTokensIn);
        params.pair = address(poolInfo[0].lpToken);
        params.to = address(this);
        params.amountTokenMin = amountTokenMin;
        params.amountETHMin = amountETHMin;
        params.amountTokenOrLP = amountTokensIn;
        params.deadline = block.timestamp;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        (, uint256 ETHUsed, uint256 numLiquidityAdded) = _uniswapV2Router.addLiquidityETH{value : msg.value}(
            address(Cimo),
            params.amountTokenOrLP,
            params.amountTokenMin,
            params.amountETHMin,
            params.to,
            block.timestamp
        );

        payable(msg.sender).transfer(msg.value - ETHUsed);
        user.amount += uint112(numLiquidityAdded);
        if (lockTime > 0) {
            lockTokens(msg.sender, 0, lockTime);
        } else {
            updateUserWeightedBalance(0, msg.sender);
        }
        emit Deposit(msg.sender, 0, numLiquidityAdded, lockTime);
    }

    // Reinvest users rewards. Only works for token staking
    function reinvestETHRewards(uint256 amountOutMin) public nonReentrant {
        UserInfo storage user = userInfo[1][msg.sender];
        updatePool(1);
        uint256 ETHPending = (user.weightedBalance * poolInfo[1].accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
        require(ETHPending > 0);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(Cimo);
        if (ETHPending > ETHLeftUnclaimed) {
            ETHPending = ETHLeftUnclaimed;
        }
        uint256 balanceBefore = Cimo.balanceOf(address(this));
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: ETHPending}(
            amountOutMin,
                path,
                address(this),
                block.timestamp
        );

        uint256 amountSwapped = Cimo.balanceOf(address(this)) - balanceBefore;
        user.amount += uint112(amountSwapped);
        user.claimableETH = 0;
        user.withdrawn += ETHPending;
        updateUserWeightedBalance(1, msg.sender);
        emit Deposit(msg.sender, 1, amountSwapped, 0);
    }

    // Withdraw previously staked NFT, loosing the rewards boost
    function withdrawNFT(uint256 _pid, address NFTContract, uint256 tokenID) public nonReentrant {
        address sender = msg.sender;
        uint256 NFTIndex;
        bool tokenFound;
        uint256 length = userInfo[_pid][sender].NFTContracts.length;
        updatePool(_pid);
        _addToClaimable(_pid, sender);
        for (uint256 i; i < userInfo[_pid][sender].NFTContracts.length; i++) {
            if (userInfo[_pid][sender].NFTContracts[i] == NFTContract) {
                if (userInfo[_pid][sender].NFTTokenIDs[i] == tokenID) {
                    tokenFound = true;
                    NFTIndex = i;
                    break;
                }
            }
        }
        require(tokenFound == true, "withdrawNFT, token not found");
        userInfo[_pid][sender].nftBoost -= uint16(pointsPerNFT);
        userInfo[_pid][sender].NFTContracts[NFTIndex] = userInfo[_pid][sender].NFTContracts[length - 1];
        userInfo[_pid][sender].NFTContracts.pop();
        userInfo[_pid][sender].NFTTokenIDs[NFTIndex] = userInfo[_pid][sender].NFTTokenIDs[length - 1];
        userInfo[_pid][sender].NFTTokenIDs.pop();
        updateUserWeightedBalance(_pid, sender);
        INFT(NFTContract).safeTransferFrom(address(this), sender, tokenID);
        emit NFTWithdrawn(sender, NFTContract, tokenID);
    }
    // Stake NFTs, giving the user a bonus point boost defined in pointsPerNFT
    function boostWithNFT(uint256 _pid, address NFTContract, uint256 tokenID) public nonReentrant {
        require(msg.sender == tx.origin, "boostWithNFT : Deposit from contract disabled");
        require(isNFTContract[NFTContract], "boostWithNFT: incorrect contract address");
        require(userInfo[_pid][msg.sender].amount > 0, "boostWithNFT: Requires staked tokens");
        updatePool(_pid);
        _addToClaimable(_pid, msg.sender);
        INFT(NFTContract).safeTransferFrom(msg.sender, address(this), tokenID);
        userInfo[_pid][msg.sender].NFTContracts.push(NFTContract);
        userInfo[_pid][msg.sender].NFTTokenIDs.push(tokenID);
        userInfo[_pid][msg.sender].nftBoost += uint16(pointsPerNFT);
        updateUserWeightedBalance(_pid, msg.sender);
        emit NFTWithdrawn(msg.sender, NFTContract, tokenID);
    }

    function addToClaimable(uint256 _pid, address sender) public nonReentrant {
        require(userInfo[_pid][sender].weightedBalance > 0);
        updatePool(_pid);
        _addToClaimable(_pid, sender);
    }

    function depositFor(address sender, uint256 _pid, uint256 amount, uint256 lockTime    ) public onlyAuthorized {
        _deposit(sender, _pid, amount, lockTime);
    }

    //add new pool. LP staking should be 0, token staking 1
    function add(uint64 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint64 lastRewardBlock = uint64(block.number > startBlock ? block.number : startBlock);
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accETHPerShare : 0,
        weightedBalance : 0
        }));
    }

    // add nft contract to array
    function addNFTContract(address NFTcontract) public onlyOwner {
        isNFTContract[NFTcontract] = true;
    }

    // change taxDistributor address
    function setTaxDistributor(address _TaxDistributor) public onlyOwner {
        TaxDistributor = _TaxDistributor;
    }

    // change router address
    function setRouter(address _router) public onlyOwner {
        router = _router;
    }

    // transfer non-CIMO tokens that were sent to staking contract by accident
    function rescueToken(address tokenAddress) public onlyOwner {
        require(!poolExistence[IERC20(tokenAddress)], "rescueToken : wrong token address");
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, bal);
    }

    // update pool allocation points
    function set(uint256 _pid, uint64 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // start rewards
    function startRewards() public onlyOwner {
        require(startBlock > block.number, "startRewards: rewards already started");
        startBlock = block.number;
        for (uint256 i; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardBlock = uint64(block.number);
        }
    }

    // check if emergency mode is enabled
    function emergency(bool _isEmergency) public onlyOwner {
        isEmergency = _isEmergency;
        emit Emergency(block.timestamp, _isEmergency);
    }

    // authorize the address
    function authorize(address _address) public onlyOwner {
        authorized[_address] = true;
    }

    // unauthorize the address
    function unauthorize(address _address) public onlyOwner {
        authorized[_address] = false;
    }

    // set new interval for rewards
    function setnumdays(uint256 _days) public onlyOwner {
        require(_days > 0 && _days < 14);
        numdays = _days;
    }

    // deposit tokens to pool >1
    // if lockTime set lock the tokens
    function _deposit(address sender, uint256 _pid, uint256 _amount, uint256 lockTime) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];
        updatePool(_pid);
        if (user.weightedBalance > 0) {
            if (_amount == 0 && lockTime == 0) {
                uint256 ETHPending = (user.weightedBalance * pool.accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
                if (ETHPending > 0) {
                    safeETHTransfer(sender, ETHPending);
                    user.withdrawn += ETHPending;
                    user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;
                }
                user.claimableETH = 0;
            } else {
                _addToClaimable(_pid, sender);
            }
        }
        if (_amount > 0) {
            require(
                (lockTime >= 0 && lockTime <= 90 * ONE_DAY && user.lockedUntil <= lockTime + block.timestamp),
                "deposit : Lock out of range or previously locked tokens are locked longer than new desired lock"
            );
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = uint112(user.amount + _amount);
            if (lockTime == 0) {
                updateUserWeightedBalance(_pid, sender);
            }
        }

        if (lockTime > 0) {
            lockTokens(sender, _pid, lockTime);
        }
        if (user.lockedUntil < block.timestamp) {
            updateUserWeightedBalance(_pid, sender);
        }
        emit Deposit(sender, _pid, _amount, lockTime);
    }

    //Lock tokens up to 90 days for rewards boost, (max rewards = x3, rewards increase linearly with lock time)
    function lockTokens(address sender, uint256 _pid, uint256 lockTime) internal {
        UserInfo storage user = userInfo[_pid][sender];
        require(user.amount > 0, "lockTokens: No tokens to lock");
        require(user.lockedUntil <= block.timestamp + lockTime, "lockTokens: Tokens already locked");
        require(lockTime >= ONE_DAY, "lockTokens: Lock time too short");
        require(lockTime <= 90 * ONE_DAY, "lockTokens: Lock time too long");
        user.lockedUntil = uint32(block.timestamp + lockTime);
        user.lockTimeBoost = uint16((2 * 1000 * lockTime) / (90 * ONE_DAY));
        // 0 - 2000
        updateUserWeightedBalance(_pid, sender);
        emit TokensLocked(sender, block.timestamp, lockTime);
    }

    // calculate and update the user weighted balance
    function updateUserWeightedBalance(uint256 _pid, address _user) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 poolBalance = pool.weightedBalance - user.weightedBalance;
        if (user.lockedUntil < block.timestamp) {
            user.lockTimeBoost = 0;
        }

        user.weightedBalance = (user.amount * (1000 + user.lockTimeBoost + user.nftBoost) / 1000);

        pool.weightedBalance = uint112(poolBalance + user.weightedBalance);
        user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;
    }

    function updateETHRewards() internal {
        massUpdatePools();
        ETHPerBlock = ETHLeftUnshared / (6400 * numdays);
    }

    function _addToClaimable(uint256 _pid, address sender) internal {
        UserInfo storage user = userInfo[_pid][sender];
        PoolInfo storage pool = poolInfo[_pid];

        uint256 ETHPending = (user.weightedBalance * pool.accETHPerShare / 1e12) - user.ETHrewardDebt;
        if (ETHPending > 0) {
            user.claimableETH += uint96(ETHPending);
            user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;
        }
    }

    function safeETHTransfer(address _to, uint256 _amount) internal {
        if (_amount > ETHLeftUnclaimed) {
            _amount = ETHLeftUnclaimed;
        }
        payable(_to).transfer(_amount);
        ETHLeftUnclaimed -= _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";

interface INFT is IERC721 {
	function getMultiplierForTokenID(uint256 _tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

interface ICimo is IERC20 {
    struct LiquidityETHParams {
        address pair;
        address to;
        uint256 amountTokenOrLP;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Address.sol";
import "./../interfaces/IERC20.sol";

// SafeERC20 (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol)
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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./../interfaces/IERC721Receiver.sol";

contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ReentrancyGuard (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Context.sol";

// Ownable (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)

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
pragma solidity ^0.8.7;

//
// IERC20 (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Address (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
pragma solidity ^0.8.7;

// Context (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol) 
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
pragma solidity ^0.8.7;

import "./IERC165.sol";

// IERC721(https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol)
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
pragma solidity ^0.8.7;

// IERC721Receiver(https://github.com/binodnp/openzeppelin-solidity/blob/master/contracts/token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// IERC165(https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol)

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