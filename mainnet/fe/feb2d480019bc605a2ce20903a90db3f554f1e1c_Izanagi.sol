/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}


interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
        
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Izanagi is Context, IERC20, Ownable {
    using Address for address;

    address payable public marketingAddress;
    address payable public devAddress;      
        
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;
    bool public limitsInEffect = true;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 1e15 * 1e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Izanagi";
    string private constant _symbol = "NAGI";
    uint8 private constant _decimals = 9;

    // these values are pretty much arbitrary since they get overwritten for every txn, but the placeholders make it easier to work with current contract.
    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _marketingFee;
    
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    uint256 public _buyTaxFee = 200;
    uint256 public _buyLiquidityFee = 100;
    uint256 public _buyMarketingFee = 400;
    uint256 public _buyDevFee = 200;
    uint256 public _buyBurnFee = 100;

    uint256 public _sellTaxFee = 200;
    uint256 public _sellLiquidityFee = 100;
    uint256 public _sellMarketingFee = 400;
    uint256 public _sellDevFee = 200;
    uint256 public _sellBurnFee = 100;
    
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    
    uint256 public _liquidityTokensToSwap;
    uint256 public _marketingTokensToSwap;
    uint256 public _devTokensToSwap;
    uint256 public _burnTokensToSend;
    
    uint256 public maxTransactionAmount;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    uint256 public maxWallet;
    
    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 70 * 1 gwei; // do not allow over x gwei for launch
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap;

    IDexRouter public dexRouter;
    address public lpPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);
    
    event SetAutomatedMarketMakerPair(address pair, bool value);
    
    event ExcludeFromReward(address excludedAddress);
    
    event IncludeInReward(address includedAddress);
    
    event ExcludeFromFee(address excludedAddress);
    
    event IncludeInFee(address includedAddress);
    
    event SetBuyFee(uint256 marketingFee, uint256 liquidityFee, uint256 reflectFee, uint256 devFee, uint256 burnFee);
    
    event SetSellFee(uint256 marketingFee, uint256 liquidityFee, uint256 reflectFee, uint256 devFee, uint256 burnFee);
    
    event TransferForeignToken(address token, uint256 amount);
    
    event UpdatedMarketingAddress(address marketing);

    event UpdatedDevAddress(address dev);
    
    event OwnerForcedSwapBack(uint256 timestamp);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_dexRouter), true);
        dexRouter = _dexRouter;

        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);
        
        // lowered due to lower initial liquidity amount.
        maxTransactionAmount = _tTotal * 25 / 10000; // 0.25% maxTransactionAmountTxn
        minimumTokensBeforeSwap = _tTotal * 25 / 100000; // 0.025% swap tokens amount
        
        marketingAddress = payable(msg.sender); // Marketing Address
        devAddress = payable(msg.sender); // Dev Address
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        
        emit Transfer(address(0), _msgSender(), _tTotal * 50);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    // remove limits after token is stable - 30-60 minutes
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        gasLimitActive = false;
        transferDelayEnabled = false;
        return true;
    }
    
    // disable Transfer delay
    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        tradingActiveBlock = block.number;
    }
        
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

     // change the minimum amount of tokens to sell from fees
    function updateMinimumTokensBeforeSwap(uint256 newAmount) external onlyOwner{
  	    require(newAmount >= _tTotal * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= _tTotal * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    minimumTokensBeforeSwap = newAmount;
  	}

    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (_tTotal * 2 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.2%");
        maxTransactionAmount = newNum * (10**18);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _isExcludedMaxTransactionAmount[pair] = value;
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
    }
    
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 50);
        gasPriceLimit = gas * 1 gwei;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length + 1 <= 50, "Cannot exclude more than 50 accounts.  Include a previously excluded address.");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inSwapAndLiquify
            ){                

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number && _holderLastTransferTimestamp[to] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // swap and liquify
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(lpPair) > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            automatedMarketMakerPairs[to] &&
            overMinimumTokenBalance
        ) {
            swapBack();
        }

        removeAllFee();
        
        buyOrSellSwitch = TRANSFER;
        
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyMarketingFee + _buyDevFee + _buyBurnFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = BUY;
                }
            } 
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee + _sellMarketingFee + _sellDevFee + _sellBurnFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = SELL;
                }
            }
        }
        
        _tokenTransfer(from, to, amount);
        
        restoreAllFee();
        
    }

    function swapBack() private lockTheSwap {

        if(_burnTokensToSend > 0 && balanceOf(address(this)) >= _burnTokensToSend) {
            _transfer(address(this), address(0xdead), _burnTokensToSend);
        }
        _burnTokensToSend = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap + _marketingTokensToSwap + _devTokensToSwap;
        bool success;

        // prevent overly large contract sells.
        if(contractBalance >= minimumTokensBeforeSwap * 20){
            contractBalance = minimumTokensBeforeSwap * 20;
        }

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
        
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = contractBalance * _liquidityTokensToSwap / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance-(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance-(initialETHBalance);
        
        uint256 ethForMarketing = ethBalance* (_marketingTokensToSwap) / (totalTokensToSwap - (_liquidityTokensToSwap/2));
        uint256 ethForDev = ethBalance * (_devTokensToSwap) / (totalTokensToSwap - (_liquidityTokensToSwap/2));
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _devTokensToSwap = 0;
        
        (success,) = address(devAddress).call{value: ethForDev}("");
        
        if(tokensForLiquidity > 0 && ethForLiquidity > 0){
            addLiquidity(tokensForLiquidity, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        // send remainder to marketing
        (success,) = address(marketingAddress).call{value: address(this).balance}("");
    }
    
    // force Swap back if slippage above 49% for launch.
    function forceSwapBack() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= minimumTokensBeforeSwap, "Can only swap back if threshld is exceeded.");
        swapBack();
        emit OwnerForcedSwapBack(block.timestamp);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount-(tFee)-(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount*(currentRate);
        uint256 rFee = tFee*(currentRate);
        uint256 rLiquidity = tLiquidity*(currentRate);
        uint256 rTransferAmount = rAmount-(rFee)-(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _buyMarketingFee / _liquidityFee;
            _devTokensToSwap += tLiquidity * _buyDevFee / _liquidityFee;
            _burnTokensToSend += tLiquidity * _buyBurnFee / _liquidityFee;
        } else if(buyOrSellSwitch == SELL){
            _liquidityTokensToSwap += tLiquidity * _sellLiquidityFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _sellMarketingFee / _liquidityFee;
            _devTokensToSwap += tLiquidity * _sellDevFee / _liquidityFee;
            _burnTokensToSend += tLiquidity * _sellBurnFee / _liquidityFee;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 10000;
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount * _liquidityFee / 10000;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function setBuyFee(uint256 buyTaxFee, uint256 buyLiquidityFee, uint256 buyMarketingFee, uint256 buyDevFee, uint256 buyBurnFee)
        external
        onlyOwner
    {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyMarketingFee = buyMarketingFee;
        _buyDevFee = buyDevFee;
        _buyBurnFee = buyBurnFee;
        require(_buyTaxFee + _buyLiquidityFee + _buyMarketingFee + _buyDevFee + _buyBurnFee <= 1500, "Must keep buy taxes below 15%");
        emit SetBuyFee(buyMarketingFee, buyLiquidityFee, buyTaxFee, buyDevFee, buyBurnFee);
    }

    function setSellFee(uint256 sellTaxFee, uint256 sellLiquidityFee, uint256 sellMarketingFee, uint256 sellDevFee, uint256 sellBurnFee)
        external
        onlyOwner
    {
        _sellTaxFee = sellTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        _sellDevFee = sellDevFee;
        _sellBurnFee = sellBurnFee;
        require(_sellTaxFee + _sellLiquidityFee + _sellMarketingFee + _sellDevFee + _sellBurnFee <= 2000, "Must keep sell taxes below 20%");
        emit SetSellFee(sellMarketingFee, sellLiquidityFee, sellTaxFee, sellDevFee, sellBurnFee);
    }
    
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "_marketingAddress address cannot be 0");
        _isExcludedFromFee[marketingAddress] = false;
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }
        
    function setDevAddress(address _devAddress) public onlyOwner {
        require(_devAddress != address(0), "_liquidityAddress address cannot be 0");
        devAddress = payable(_devAddress);
        emit UpdatedDevAddress(_devAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    // To receive ETH from dexRouter when swapping
    receive() external payable {}

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
    
    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    // for one-time airdrop feature after contract launch
    function airdropToWallets(address[] memory airdropWallets, uint256[] memory amount) external onlyOwner() {
        require(airdropWallets.length == amount.length, "airdropToWallets:: Arrays must be the same length");
        removeAllFee();
        buyOrSellSwitch = TRANSFER;
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i];
            _tokenTransfer(msg.sender, wallet, airdropAmount);
        }
        restoreAllFee();
    }
}