/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENCED
/*
    DogeTV
    8% tax on buy and sell, 8% tax on transfers
    starting taxes: 20/25%
    contract dev: @CryptoBatmanBSC
    Telegram:
    https://t.me/dogetvofficial
    Website: 
    https://Dogetv.app 
*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface INFTREWARDS {
    function Deposit(uint256 amount) external returns (bool success);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


contract DogeTV is IERC20, Auth {

    struct DogeTvPackage{
        uint256 price;
        uint256 durationDays;
        uint256 packageID;
        string name;
        bool isOnlySpecial;
    }

    struct SubbedTvPackage{
        uint256 subbedTime;
        uint256 expiration_time;
        uint256 packageID;
        uint256 packageVariant;
        bool wasDiscounted;
        bool isSpecial;
    }

    using SafeMath for uint256;
    // fees. all uint8 for gas efficiency and storage.
    /* @dev   
        all fees are set with 1 decimal places added, please remember this when setting fees.
    */
    uint8 public liquidityFee = 20;
    uint8 public marketingFee = 60;
    uint8 public totalFee = 80;

    uint8 public initialSellFee = 250;
    uint8 public initialBuyFee = 200;

    /*
    @dev:
        these are multipled by 10 so that you can have fractional percents
    */
    uint8 public specialPercentHigh = 20;
    uint8 public specialPercentLow = 16;

    uint8 public discountPercentHigh = 15;
    uint8 public discountPercentLow = 10;


    // denominator. uint 16 for storage efficiency - makes the above fees all to 1 dp.
    uint16 public AllfeeDenominator = 1000;
    
    // trading control;
    bool public canTrade = false;
    uint256 public launchedAt;
    
    
    // tokenomics - uint256 BN but located here fro storage efficiency
    uint256 _totalSupply = 1 * 10**7 * (10 **_decimals); //10 mil
    uint256 public _maxTxAmount = _totalSupply / 100; // 1%
    uint256 public _maxHoldAmount = _totalSupply / 50; // 2%
    uint256 public swapThreshold = _totalSupply / 500; // 0.2%

    //Important addresses    
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // mainnet tether, used to get price;
    //address USDT = 0xF99a0CbEa2799f8d4b51709024454F74eD63a86D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    address public pair;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public pairs;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldExempt;
    mapping (address => bool) isBlacklisted;

    mapping (address => SubbedTvPackage) public userSubs;

    IDEXRouter public router;
    INFTREWARDS public NftStakingContract;


    bool public swapEnabled = true;
    bool inSwap;
    mapping(uint =>  DogeTvPackage) public DtvPackages;
    //DogeTvPackage[] public DtvPackages;
    address[] public subbedUsers;
    uint public totalSubs;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    string constant _name = "Doge-TV";
    string constant _symbol = "$DGTV";
    uint8 constant _decimals = 18;

    bool public initialTaxesEnabled = true;

    constructor (address tokenOwner) Auth(tokenOwner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet Uniswap
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this)); // ETH pair
        pairs[pair] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        isMaxHoldExempt[pair] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[ZERO] = true;
        
        owner = tokenOwner;
        DummyNFT nftctrct = new DummyNFT(address(this), owner);
        NftStakingContract = INFTREWARDS(nftctrct);
        isTxLimitExempt[owner] = true;
        isFeeExempt[owner] = true;
        authorizations[owner] = true;
        isMaxHoldExempt[owner] = true;
        autoLiquidityReceiver = owner;
        marketingFeeReceiver = owner;

        _balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];} 

    
    function getEstimatedTokenForUSDT(uint USDTAmount) public view returns (uint) {
            address[] memory path = new address[](3);
                path[0] = USDT;
                path[1] = router.WETH();
                path[2] = address(this);
            return router.getAmountsOut(USDTAmount, path)[2];
    }
    
    function setBlacklistedStatus(address walletToBlacklist, bool isBlacklistedBool)external authorized{
        isBlacklisted[walletToBlacklist] = isBlacklistedBool;
    }

    function setBlacklistArray(address[] calldata walletToBlacklistArray)external authorized{
        for(uint i = 0; i < walletToBlacklistArray.length; i++){
            isBlacklisted[walletToBlacklistArray[i]] = true;
        }
    }

    function getPackageWithId(uint ID) internal view returns (DogeTvPackage memory package){
                return DtvPackages[ID];
    }

    function subToPackage(uint _packageID, uint durationVariant)external returns(bool success){
            /*
             struct SubbedTvPackage{
                uint256 expiration_time;
                uint256 packageID;
                bool wasDiscounted;
                bool isSpecial;
            }
            */
            DogeTvPackage memory pack = getPackageWithId(_packageID);
            // get the price in token
            uint256 tokenPrice = getEstimatedTokenForUSDT(pack.price);
            
            require(_balances[msg.sender] >= tokenPrice, "DogeTV, You dont have enough token for this");
            uint divisor = 1;
            bool isfree = false;
            bool isDiscounted = false;
            uint256 percentageHeld = ((_balances[msg.sender]*10) / _totalSupply) * 100;
            if(percentageHeld >= discountPercentLow && percentageHeld <= discountPercentHigh){
                divisor = 2;
                isDiscounted = true;
            }
            if(percentageHeld > specialPercentLow){
                isfree = true;
            }
            if(pack.isOnlySpecial){
                require(isfree, "DogeTV: this package is not available to anyone not holding the requirements");
            }
            tokenPrice = tokenPrice / divisor;
            SubbedTvPackage memory packageSubbed;
            if(!isfree){
                require(!pack.isOnlySpecial, "DTV, only high percentage holders can have this package");
                _balances[msg.sender] -= tokenPrice;
                _balances[DEAD] += tokenPrice /2;
                emit Transfer(msg.sender, DEAD, tokenPrice/2);
                _balances[address(NftStakingContract)]+= tokenPrice/2;
                NftStakingContract.Deposit(tokenPrice/2);
                emit Transfer(msg.sender, address(NftStakingContract), tokenPrice/2);
            }
            
            packageSubbed.packageID =  pack.packageID;
            packageSubbed.wasDiscounted = isDiscounted;
            packageSubbed.isSpecial = isfree;
            packageSubbed.subbedTime = block.timestamp;
            packageSubbed.packageVariant = durationVariant;
            packageSubbed.expiration_time = block.timestamp + pack.durationDays * 86400;
            emit PackageSubbed(msg.sender, pack.name);
            userSubs[msg.sender] = packageSubbed;
            subbedUsers.push(msg.sender);
            return true;
    }

    function checkSubs(address user)internal view returns (bool wasdiscounted, bool isSpecial){
        return (userSubs[user].wasDiscounted,userSubs[user].isSpecial );
    }

    function getSubbedUsersLength()external view returns (uint SubbedUsersLength){
        return subbedUsers.length;
    }

    function setNFTContract(INFTREWARDS ctrct)external authorized{
        NftStakingContract = ctrct;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setSwapThresholdDivisor(uint divisor)external authorized {
        require(divisor >= 100, "DogeTV: max sell percent is 1%");
        swapThreshold = _totalSupply / divisor;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    function setmaxholdpercentage(uint256 percentageMul10) external authorized {
        require(percentageMul10 >= 5, "DogeTV, max hold cannot be less than 0.5%"); // cant change percentage below 0.5%, so everyone can hold the percentage
        _maxHoldAmount = _totalSupply * percentageMul10 / 1000; // percentage based on amount
    }
    
    function allowtrading()external authorized {
        canTrade = true;
    }
    
    function addNewPair(address newPair)external authorized{
        pairs[newPair] = true;
        isMaxHoldExempt[newPair] = true;
    }
    
    function removePair(address pairToRemove)external authorized{
        pairs[pairToRemove] = false;
        isMaxHoldExempt[pairToRemove] = false;
    }

    function addTVPackage( uint256 ppvID, uint256 _USDTPriceNoDecimals, uint256 _durationDays, string calldata packName, bool onlyTopHolders) external authorized {
        DogeTvPackage memory packageToAdd;
        packageToAdd.durationDays = _durationDays;
        packageToAdd.packageID = ppvID;
        packageToAdd.name = packName;
        packageToAdd.price = _USDTPriceNoDecimals * 10 ** 18;
        packageToAdd.isOnlySpecial = onlyTopHolders;
        DtvPackages[ppvID] = packageToAdd;
    }

    function changeTvPackagePrice(uint256 _ID, uint256 newPrice) external authorized returns(bool success){
                DtvPackages[_ID].price = newPrice * 10 ** 18;
                return true;
    }

    function removeTvPackage(uint256 _ID) external authorized returns(bool success){
                delete DtvPackages[_ID];
                return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(_totalSupply)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(!canTrade){
            require(sender == owner, "DogeTV, Only owner or presale Contract allowed to add LP"); // only owner allowed to trade or add liquidity
        }
        if(sender != owner && recipient != owner){
            if(!pairs[recipient] && !isMaxHoldExempt[recipient]){
                require (balanceOf(recipient) + amount <= _maxHoldAmount, "DogeTV, cant hold more than max hold dude, sorry");
            }
        }
        
        checkTxLimit(sender, recipient, amount);
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "DogeTV, Sorry bro, youre blacklisted");
        if(!launched() && pairs[recipient]){ require(_balances[sender] > 0); launch(); }
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        _balances[sender] = _balances[sender].sub(amount, "DogeTV, Insufficient Balance");

        if(pairs[recipient]){
            // its a sell
            /*
                struct SubbedTvPackage{
                    uint256 subbedTime;
                    uint256 expiration_time;
                    uint256 packageID;
                    uint256 packageVariant;
                    bool wasDiscounted;
                    bool isSpecial;
                }
            */
            (bool discounted, bool special) = checkSubs(sender);
            if(special){
                if((_balances[sender] * 10 /100) < specialPercentLow){ // theyve crossed the threshold
                    delete userSubs[sender];
                    emit SubWithdrawn(sender);
                }
            }
            if(discounted){
                 if((_balances[sender] * 10 /100) < discountPercentLow){ // theyve crossed the threshold
                     userSubs[sender].expiration_time = userSubs[sender].subbedTime + ((userSubs[sender].expiration_time - userSubs[sender].subbedTime) / 2);
                     if(userSubs[sender].expiration_time >= block.timestamp){
                        delete userSubs[sender];
                        emit SubWithdrawn(sender);
                     }
                }
            }
        }

        uint256 amountReceived = 0;
        if(!shouldTakeFee(sender) || !shouldTakeFee(recipient)){
            amountReceived = amount;
        }else{
            bool isbuy = pairs[sender];
            amountReceived = takeFee(sender, isbuy, amount);
        }

        if(shouldSwapBack(recipient)){ swapBack(); }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;

    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address reciever, uint256 amount) internal view {
        if(sender != owner && reciever != owner){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
    }

    function shouldTakeFee(address endpt) internal view returns (bool) {
        
        return !isFeeExempt[endpt];
    }

    function takeFee(address sender, bool isBuy, uint256 amount) internal returns (uint256) {
        uint fee = totalFee;
        if(initialTaxesEnabled){
            fee = initialSellFee;
            if(isBuy){
                fee = initialBuyFee;
            }
        }

        uint256 feeAmount = amount.mul(fee).div(AllfeeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function setInitialfees(uint8 _initialBuyFeePercentMul10, uint8 _initialSellFeePercentMul10) external authorized {
        if(initialBuyFee >= _initialBuyFeePercentMul10){initialBuyFee = _initialBuyFeePercentMul10;}else{initialTaxesEnabled = false;}
        if(initialSellFee >= _initialSellFeePercentMul10){initialSellFee = _initialSellFeePercentMul10;}else{initialTaxesEnabled = false;}
    }

    // returns any mis-sent tokens to the marketing wallet
    function claimtokensback(IERC20 tokenAddress) external authorized {
        payable(marketingFeeReceiver).transfer(address(this).balance);
        tokenAddress.transfer(marketingFeeReceiver, tokenAddress.balanceOf(address(this)));
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function stopInitialTax()external authorized{
        // this can only ever be called once
        initialTaxesEnabled = false;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 200, "DogeTV, must be higher than 0.5%");
        require(amount > _maxTxAmount, "DogeTV, can only ever increase the tx limit");
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }


    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    /*
    Dev sets the individual buy fees
    */
    function setFees(uint8 _liquidityFeeMul10, uint8 _marketingFeeMul10) external authorized {
        require(_liquidityFeeMul10 + _marketingFeeMul10 <= 80, "DogeTV taxes can never exceed 8%");
        require(_liquidityFeeMul10 + _marketingFeeMul10 <= totalFee, "Dogetv, taxes can only ever change ratio");
        liquidityFee = _liquidityFeeMul10;
        marketingFee = _marketingFeeMul10;
       
        totalFee = _liquidityFeeMul10 + (_marketingFeeMul10) ;
    }

    function setSpecialPackPercentages(uint8 percentLowerMul10, uint8 percentHigherMul10) external authorized {
        
        specialPercentHigh = percentHigherMul10;
        specialPercentLow = percentLowerMul10;
       
    }

    function setDiscountPackPercentages(uint8 percentLowerMul10, uint8 percentHigherMul10) external authorized {
        
        discountPercentHigh = percentHigherMul10;
        discountPercentLow = percentLowerMul10;
       
    }
    
    function swapBack() internal swapping {
        uint256 amountToLiquify = 0;
        if(liquidityFee > 0){
            amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2); // leave some tokens for liquidity addition
        }
        
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify); // swap everything bar the liquidity tokens. we need to add a pair

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp + 100
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        
        uint256 totalETHFee = totalFee - (liquidityFee /2);
        if(totalETHFee > 0){
            uint256 amountETHMarketing = 0;
            if(marketingFee > 0){
                amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
                payable(marketingFeeReceiver).transfer(amountETHMarketing);
            }
            if(amountToLiquify > 0){
                
                uint256 amountETHLiquidity = amountETH - amountETHMarketing;
                router.addLiquidityETH{value: amountETHLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountETHLiquidity, amountToLiquify);
            }
        }
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !inSwap
        && swapEnabled
        && pairs[recipient]
        && _balances[address(this)] >= swapThreshold;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    event AutoLiquify(uint256 amountPairToken, uint256 amountToken);
    event PackageSubbed(address user,string packName);
    event SubWithdrawn(address user);

}

contract DummyNFT is INFTREWARDS {

    address public owner;
    IERC20 public rewardToken;
    uint256 oldBalance;

    function Deposit(uint amount) external override returns (bool success) {
        require(oldBalance + amount == rewardToken.balanceOf(address(this)));
        // reflect the amount here
        oldBalance = rewardToken.balanceOf(address(this));
        return true;

    }

    function claimTokensBack()external {
        require(msg.sender == owner);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        oldBalance = rewardToken.balanceOf(address(this));
    }

     constructor (address rewardsToken, address _owner){
         owner = _owner;
         rewardToken = IERC20(rewardsToken);
     }

}