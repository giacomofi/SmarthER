/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ag, bool _ab, bool _algo) external;
    function setGasPriceLimit(uint256 gas) external;
    function removeSniper(address account) external;
    function removeBlacklisted(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function setBlacklistEnabled(address account, bool enabled) external;
    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external;
}

contract ShibionicInu is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _liquidityHolders;

    uint256 constant private startingSupply = 100_000_000;
    string constant private _name = "SHIBIONIC INU";
    string constant private _symbol = "$SHBNC";
    uint8 constant private _decimals = 18;

    uint256 constant private _tTotal = startingSupply * 10**_decimals;
    uint256 constant private MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    struct Fees {
        uint16 reflect;
        uint16 liquidity;
        uint16 marketing;
        uint16 totalSwap;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 marketing;
        uint16 total;
    }

    Fees public _buyTaxes = Fees({
        reflect: 100,
        liquidity: 100,
        marketing: 500,
        totalSwap: 600
        });

    Fees public _sellTaxes = Fees({
        reflect: 100,
        liquidity: 200,
        marketing: 2000,
        totalSwap: 2200
        });

    Fees public _transferTaxes = Fees({
        reflect: 100,
        liquidity: 100,
        marketing: 500,
        totalSwap: 600
        });

    Ratios public _ratios = Ratios({
        liquidity: 3,
        marketing: 25,
        total: 7
        });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0xC452040b75b108A1c5cE44aAC829d53cd0ca2368)
        });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public contractSwapTimer = 0 seconds;
    uint256 private lastSwap;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    
    uint256 private _maxTxAmount = (_tTotal * 5) / 1000;
    uint256 private _maxWalletSize = (_tTotal * 2) / 100;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    bool lpInitialized = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }
    
    constructor () payable {
        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }
    }

    function initializeLP() public onlyOwner {
        require(!lpInitialized, "Already initialized");

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;

        lpInitialized = true;
    }

    function preInitializeTransfer(address to, uint256 amount) public onlyOwner {
        require(!lpInitialized);
        amount = amount*10**_decimals;
        _finalizeTransfer(msg.sender, to, amount, false, false, false, true);
    }

    function preInitializeTransferMultiple(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]*10**_decimals);
            preInitializeTransfer(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) public onlyOwner {
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            if(account != lpPair){
                _excluded.push(account);
            }
        } else if (!enabled) {
            require(_isExcluded[account], "Account is already included.");
            if (account == lpPair) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
            } else if(_excluded.length == 1) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _rOwned[account] = _tOwned[account] * _getRate();
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!_hasLiqBeenAdded);
        require(initializer != address(this), "Can't be self.");
        antiSnipe = AntiSnipe(initializer);
    }

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabled(account, enabled);
    }

    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabledMultiple(accounts, enabled);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiGas, bool _antiBlock, bool _algo) external onlyOwner {
        antiSnipe.setProtections(_antiSnipe, _antiGas, _antiBlock, _algo);
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 300, "Too low.");
        antiSnipe.setGasPriceLimit(gas);
    }
    
    function setTaxesBuy(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        uint16 check = reflect + liquidity + marketing;
        require(check <= maxBuyTaxes);
        _buyTaxes.reflect = reflect;
        _buyTaxes.liquidity = liquidity;
        _buyTaxes.marketing = marketing;
        _buyTaxes.totalSwap = check - reflect;
    }

    function setTaxesSell(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        uint16 check = reflect + liquidity + marketing;
        require(check <= maxSellTaxes);
        _sellTaxes.reflect = reflect;
        _sellTaxes.liquidity = liquidity;
        _sellTaxes.marketing = marketing;
        _sellTaxes.totalSwap = check - reflect;
    }

    function setTaxesTransfer(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        uint16 check = reflect + liquidity + marketing;
        require(check <= maxTransferTaxes);
        _transferTaxes.reflect = reflect;
        _transferTaxes.liquidity = liquidity;
        _transferTaxes.marketing = marketing;
        _transferTaxes.totalSwap = check - reflect;
    }

    function setRatios(uint16 liquidity, uint16 marketing) external onlyOwner {
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.total = liquidity + marketing;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() public view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor, uint256 time) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        contractSwapTimer = time;
    }

    function setWallets(address payable marketing) external onlyOwner {
        _taxWallets.marketing = payable(marketing);
    }

    function setContractSwapEnabled(bool enabled) external onlyOwner {
        contractSwapEnabled = enabled;
        emit ContractSwapEnabledUpdated(enabled);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(buy || sell){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if(to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (sell) {
            if (!inSwap
                && contractSwapEnabled
            ) {
                if (lastSwap + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                        contractSwap(contractTokenBalance);
                        lastSwap = block.timestamp;
                    }
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) / ratios.total) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }

        amtBalance -= liquidityBalance;
        ratios.total -= ratios.liquidity;
        uint256 marketingBalance = amtBalance;
        if (ratios.marketing > 0) {
            _taxWallets.marketing.transfer(marketingBalance);
        }
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiSnipe(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        tradingEnabled = true;
        swapThreshold = balanceOf(lpPair) / 10000;
        swapAmount = (balanceOf(lpPair) * 15) / 10000;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(_owner).transfer(address(this).balance);
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
        }
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;

        uint256 currentRate;
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee, bool buy, bool sell, bool other) private returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer at this time.");
            }
        }

        ExtraValues memory values = _getValues(from, to, tAmount, takeFee, buy, sell, other);

        _rOwned[from] -= values.rAmount;
        _rOwned[to] += values.rTransferAmount;

        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        }
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee, bool buy, bool sell, bool other) private returns (ExtraValues memory) {
        ExtraValues memory values;
        values.currentRate = _getRate();

        values.rAmount = tAmount * values.currentRate;

        if (_hasLimits(from, to)) {
            bool checked;
            try antiSnipe.checkUser(from, to, tAmount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        if(takeFee) {
            uint256 currentReflect;
            uint256 currentSwap;
            uint256 divisor = masterTaxDivisor;

            if (sell) {
                currentReflect = _sellTaxes.reflect;
                currentSwap = _sellTaxes.totalSwap;
            } else if (buy) {
                currentReflect = _buyTaxes.reflect;
                currentSwap = _buyTaxes.totalSwap;
            } else {
                currentReflect = _transferTaxes.reflect;
                currentSwap = _transferTaxes.totalSwap;
            }

            values.tFee = (tAmount * currentReflect) / divisor;
            values.tSwap = (tAmount * currentSwap) / divisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tSwap);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            if(_isExcluded[address(this)]) {
                _tOwned[address(this)] += values.tSwap;
            }
            emit Transfer(from, address(this), values.tSwap);
        }

        values.rTransferAmount = values.rAmount - (values.rFee + (values.tSwap * values.currentRate));
        return values;
    }

    function _getRate() internal view returns(uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(_isExcluded[lpPair]) {
            if (_rOwned[lpPair] > rSupply || _tOwned[lpPair] > tSupply) return _rTotal / _tTotal;
            rSupply -= _rOwned[lpPair];
            tSupply -= _tOwned[lpPair];
        }
        if(_excluded.length > 0) {
            for (uint8 i = 0; i < _excluded.length; i++) {
                if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return _rTotal / _tTotal;
                rSupply = rSupply - _rOwned[_excluded[i]];
                tSupply = tSupply - _tOwned[_excluded[i]];
            }
        }
        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }
}