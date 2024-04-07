/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

/**
TONKOTSU INU
...A new reflective meme token!

  _____ ___  _   _ _  _____ _____ ____  _   _   ___ _   _ _   _ 
 |_   _/ _ \| \ | | |/ / _ \_   _/ ___|| | | | |_ _| \ | | | | |
   | || | | |  \| | ' / | | || | \___ \| | | |  | ||  \| | | | |
   | || |_| | |\  | . \ |_| || |  ___) | |_| |  | || |\  | |_| |
   |_| \___/|_| \_|_|\_\___/ |_| |____/ \___/  |___|_| \_|\___/ 

https://t.me/TonkotsuInu

SPDX-License-Identifier: UNLICENSED
**/
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
}

contract TONKOTSU is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => User) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"Tonkotsu Inu";
    string private constant _symbol = unicode"🍜TONKOTSU";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 6;
    uint256 private _teamFee = 9;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    address payable private _FeeAddress;
    address payable private _marketingWalletAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    uint256 private lastBuy;
    uint256 private buyLimitEnd;
    bool private inSwap = false;
    bool private buyCooldownEnabled = false;
    bool private sellCooldownEnabled = false;
    uint256 private sellCooldownTime = 90 seconds;
    uint256 private buyCooldownTime = 30 seconds;
    uint256 private removeSellCooldownTime = 3600 seconds; // 1 hour
    uint256 private _maxSellAmount = _tTotal;
    uint256 private _maxBuyAmount = _tTotal;
    struct User {
        address userAddress;
        uint256 buy;
        uint256 sell;
    }
    event buyCooldownUpdated(uint buyCooldownTime);
    event sellCooldownUpdated(uint sellCooldownTime);
    event RemoveSellCooldownUpdated(uint removeSellCooldownTime);
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxSellAmountUpdated(uint _maxSellAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable FeeAddress, address payable marketingWalletAddress) {
        _FeeAddress = FeeAddress;
        _marketingWalletAddress = marketingWalletAddress;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[FeeAddress] = true;
        _isExcludedFromFee[marketingWalletAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setBuyCooldownEnabled(bool onoff) external onlyOwner() {
        buyCooldownEnabled = onoff;
    }

    function setSellCooldownEnabled(bool onoff) external onlyOwner() {
        sellCooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
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
        if (from != owner() && to != owner()) {
            if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair, "Ah ah ah! You didn't say the magic word!");
            }
            cooldown[msg.sender] = User(msg.sender,0,0);

            // buy
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                if(buyLimitEnd < block.timestamp) {
                    _maxBuyAmount = _tTotal;
                }
                require(amount <= _maxBuyAmount);
                if(buyCooldownEnabled) {
                    require(cooldown[to].buy < block.timestamp);
                    cooldown[to].buy = block.timestamp + buyCooldownTime;
                    cooldown[to].sell = block.timestamp + sellCooldownTime;
                }
                if(sellCooldownEnabled) {
                    lastBuy = block.timestamp + removeSellCooldownTime;
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if (!inSwap && from != uniswapV2Pair && tradingOpen) {
                if(lastBuy <= block.timestamp) {
                    sellCooldownEnabled = false;
                    _maxSellAmount = 1e12 * 10**9;
                }
                require(amount <= _maxSellAmount);
                if(sellCooldownEnabled) {
                    require(cooldown[from].sell < block.timestamp, "Your transaction cooldown has not expired.");
                    cooldown[from].sell = block.timestamp + sellCooldownTime;
                }
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
		
        _tokenTransfer(from,to,amount,takeFee);
    }




    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _FeeAddress.transfer(amount.div(2));
        _marketingWalletAddress.transfer(amount.div(2));
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        buyCooldownEnabled = true;
        sellCooldownEnabled = true;
        _maxBuyAmount = 3e9 * 10**9;
        _maxSellAmount = 5e9 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        lastBuy = block.timestamp;
        buyLimitEnd = block.timestamp + (3 minutes);
    }

    function manualswap() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function sellCooldown() public view returns (bool, uint) {
        return (sellCooldownEnabled, sellCooldownTime);
    }

    function buyCooldown() public view returns (bool, uint) {
        return (buyCooldownEnabled, buyCooldownTime);
    }

    function sellCooldownRemovalTime() public view returns (uint) {
        return removeSellCooldownTime;
    }

    function lastBuyTime() public view returns (uint256) {
        return lastBuy;
    }

    function showMaxBuyAmount() public view returns (uint) {
        return _maxBuyAmount;
    }

    function showMaxSellAmount() public view returns (uint) {
        return _maxSellAmount;
    }

    function setBuyCooldownTime(uint256 buycooldown) external onlyOwner() {
        require(!tradingOpen, "Trading is already open.");
        require(buycooldown > 0 && buycooldown < 7200, "Must be greater than 0 and less than 2 hours");
        buyCooldownTime = buycooldown * 1 seconds;
    }

    function setSellCooldownTime(uint256 sellcooldown) external onlyOwner() {
        require(!tradingOpen, "Trading is already open.");
        require(sellcooldown > 0 && sellcooldown < 7200, "Must be greater than 0 and less than 2 hours");
        sellCooldownTime = sellcooldown * 1 seconds;
    }

    function setRemoveSellCooldownTime(uint256 nocooldown) external onlyOwner() {
        require(!tradingOpen, "Trading is already open.");
        require(nocooldown > 0 && nocooldown < 14400, "Must be greater than 0 and less than 4 hours");
        removeSellCooldownTime = nocooldown * 1 seconds;
    }

    function setMaxBuyPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxBuyAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function setMaxSellPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent == 100, "Amount must be 100%");
        _maxSellAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxSellAmountUpdated(_maxSellAmount);
    }
}