/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
contract DAIKOKU is Context, ERC20Ownable, IERC20 {
    using SafeMath for uint256;
    using Address for address;
    string private constant _name = "DAIKOKU";
    string private constant _symbol = "DAIKOKU";
    uint8 private constant _decimal = 18;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isMaxWalletExclude;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) public isBot;
	mapping(address => bool) public isBoughtEarly;
    address payable private MWaddress;
    address payable private LWaddress;
    address payable private DWaddress;
    address dead = address(0xdead);
    IUniswapV2Router02 public uniV2Router;
    address public uniV2Pair;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e14 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxWallet;
    uint256 private taxTokensMin;
    uint256 private LiqTokens;
    uint256 private MwTokens;
    uint256 private LbTokens;
    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;
    uint256 private gasPriceLimit = 498 * 1 gwei;
    uint256 private _reflectionsTax;
    uint256 private _previousReflectionsTax = _reflectionsTax;
    uint256 private _liquidityTax;
    uint256 private _previousLiquidityTax = _liquidityTax;

    uint256 public buyReflectionsTax = 0;
    uint256 public buyMarketingTax = 5;
    uint256 public buyLandTax = 5;
    uint256 public buyLiquidityTax = 3;

    uint256 public sellReflectionsTax = 0;
    uint256 public sellMarketingTax = 5;
    uint256 public sellLandTax = 5;
    uint256 public sellLiquidityTax = 3;

    uint256 public tradingActiveBlock = 0;
    uint256 public earlyBuyPenaltyStart;
    uint256 public earlyBuyPenaltyEnd;
    uint256 public maxTransactionAmount;
    bool public transferDelayEnabled = false;
    bool public limitsInEffect = false;
    bool public gasLimitActive = false;
    bool private _addLiq = true;
    bool public maxWalletOn = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ExcludeFromFee(address excludedAddress);
    event IncludeInFee(address includedAddress);
    event OwnerForcedSwapBack(uint256 timestamp);
    event BoughtEarly(address indexed sniper);
    event RemovedSniper(address indexed notsnipersupposedly);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
        
    }
    constructor() payable {
        _rOwned[_msgSender()] = _rTotal;
        maxTransactionAmount = _tTotal / 100; 
        _maxWallet = _tTotal * 3 / 100;
        taxTokensMin = _tTotal * 5 / 10000;
        MWaddress = payable(0xb97cD9cAdB2398f47b505E6C0F123eadb6B624ea); 
        LWaddress = payable(0x0b41b33048AeF20D978cd1Fb587157fcdD4Df1a1);
        DWaddress = payable(0x9Fa9a8d943eA6F0db1D8d84610FBB4956224f3B0);
        _isExcluded[dead] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[MWaddress] = true;
        _isExcludedFromFee[LWaddress] = true;
        _isExcludedFromFee[DWaddress] = true;
        _isMaxWalletExclude[address(this)] = true;
        _isMaxWalletExclude[_msgSender()] = true;
        _isMaxWalletExclude[dead] = true;
        _isMaxWalletExclude[MWaddress] = true;
        _isMaxWalletExclude[LWaddress] = true;
        _isMaxWalletExclude[DWaddress] = true;
        _isExcludedMaxTransactionAmount[_msgSender()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[dead] = true;
        _isExcludedMaxTransactionAmount[MWaddress] = true;
        _isExcludedMaxTransactionAmount[LWaddress] = true;
        _isExcludedMaxTransactionAmount[DWaddress] = true;
        addBot(0x41B0320bEb1563A048e2431c8C1cC155A0DFA967);
        addBot(0x91B305F0890Fd0534B66D8d479da6529C35A3eeC);
        addBot(0x7F5622afb5CEfbA39f96CA3b2814eCF0E383AAA4);
        addBot(0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909);
        addBot(0x74BC89a9e831ab5f33b90607Dd9eB5E01452A064);
        addBot(0x1F53592C3aA6b827C64C4a3174523182c52Ece84);
        addBot(0x460545C01c4246194C2e511F166D84bbC8a07608);
        addBot(0x2E5d67a1d15ccCF65152B3A8ec5315E73461fBcd);
        addBot(0xb5aF12B837aAf602298B3385640F61a0fF0F4E0d);
        addBot(0xEd3e444A30Bd440FBab5933dCCC652959DfCB5Ba);
        addBot(0xEC366bbA6266ac8960198075B14FC1D38ea7de88);
        addBot(0x10Bf6836600D7cFE1c06b145A8Ac774F8Ba91FDD);
        addBot(0x44ae54e28d082C98D53eF5593CE54bB231e565E7);
        addBot(0xa3e820006F8553d5AC9F64A2d2B581501eE24FcF);
		addBot(0x2228476AC5242e38d5864068B8c6aB61d6bA2222);
		addBot(0xcC7e3c4a8208172CA4c4aB8E1b8B4AE775Ebd5a8);
		addBot(0x5b3EE79BbBDb5B032eEAA65C689C119748a7192A);
		addBot(0x4ddA45d3E9BF453dc95fcD7c783Fe6ff9192d1BA);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    receive() external payable {}
    function name() public pure override returns (string memory) {
        return _name;
    }
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }
    function decimals() public pure override returns (uint8) {
        return _decimal;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),
        _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount)private view returns (uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            MwTokens += tLiquidity * buyMarketingTax / _liquidityTax;
            LbTokens += tLiquidity * buyLandTax / _liquidityTax;
            LiqTokens += tLiquidity * buyLiquidityTax / _liquidityTax;
        } else if(buyOrSellSwitch == SELL){
            MwTokens += tLiquidity * sellMarketingTax / _liquidityTax;
            LbTokens += tLiquidity * sellLandTax / _liquidityTax;
            LiqTokens += tLiquidity * sellLiquidityTax / _liquidityTax;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionsTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityTax).div(10**2);
    }
    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[from]);
        if (maxWalletOn == true && ! _isMaxWalletExclude[to]) {
            require(balanceOf(to) + amount <= _maxWallet, "Max amount of tokens for wallet reached");
        }
        if(_addLiq == true) {
            IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniV2Router = _uniV2Router;
            uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).getPair(address(this), _uniV2Router.WETH());
            tradingActiveBlock = block.number;
            earlyBuyPenaltyStart = block.timestamp;
            earlyBuyPenaltyEnd = block.timestamp + 72 hours;
            _isMaxWalletExclude[address(uniV2Pair)] = true;
            _isMaxWalletExclude[address(uniV2Router)] = true;
            _isExcludedMaxTransactionAmount[address(uniV2Router)] = true;
            _isExcludedMaxTransactionAmount[address(uniV2Pair)] = true;
            limitsInEffect = true;
            maxWalletOn = true;
            swapAndLiquifyEnabled = true;
            transferDelayEnabled = true;
            _addLiq = false;
        }
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != dead && !inSwapAndLiquify) {
                if(from != owner() && to != uniV2Pair) {
                    for (uint x = 0; x < 2; x++) {
                    if(block.number == tradingActiveBlock + x) {
                        isBoughtEarly[to] = true;
                        emit BoughtEarly(to);
                        }
                    }
                }
                if (gasLimitActive && from == uniV2Pair) {
                    require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                }
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniV2Router) && to != address(uniV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                if (from == uniV2Pair && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }
        uint256 totalTokensToSwap = LiqTokens.add(MwTokens).add(LbTokens);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= taxTokensMin;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(uniV2Pair) > 0 && totalTokensToSwap > 0 && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && to == uniV2Pair && overMinimumTokenBalance) {
            swapTokens();
            }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            buyOrSellSwitch = TRANSFER;
        } else {
            if (from == uniV2Pair) {
                removeAllFee();
                _reflectionsTax = buyReflectionsTax;
                _liquidityTax = buyMarketingTax + buyLandTax + buyLiquidityTax;
                buyOrSellSwitch = BUY;
            } 
            else if (to == uniV2Pair) {
                removeAllFee();
                _reflectionsTax = sellReflectionsTax;
                _liquidityTax = sellMarketingTax + sellLandTax + sellLiquidityTax;
                buyOrSellSwitch = SELL;
                if(isBoughtEarly[from] && earlyBuyPenaltyEnd > block.timestamp){
                    _liquidityTax = _liquidityTax * 2;
                }
            } else {
                require(!isBoughtEarly[from], "Snipers can't transfer tokens to sell cheaper.  DM a Mod.");
                removeAllFee();
                buyOrSellSwitch = TRANSFER;
            }
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapTokens() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = MwTokens + LbTokens + LiqTokens;
        uint256 tokensForLiquidity = LiqTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MwTokens).div(totalTokensToSwap);
        uint256 ethForMetaLand = ethBalance.mul(LbTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForMetaLand);
        MwTokens = 0;
        LbTokens = 0;
        LiqTokens = 0;
        (bool success,) = address(MWaddress).call{value: ethForMarketing}("");
        (success,) = address(LWaddress).call{value: ethForMetaLand}("");
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        if(address(this).balance > 5 * 10**17){
            (success,) = address(DWaddress).call{value: address(this).balance}("");
        }
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            dead,
            block.timestamp
        );
    }
    function removeAllFee() private {
        if (_reflectionsTax == 0 && _liquidityTax == 0) return;

        _previousReflectionsTax = _reflectionsTax;
        _previousLiquidityTax = _liquidityTax;

        _reflectionsTax = 0;
        _liquidityTax = 0;
    }
    function restoreAllFee() private {
        _reflectionsTax = _previousReflectionsTax;
        _liquidityTax = _previousLiquidityTax;
    }
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromMaxWallet(address account) external onlyOwner {
        _isMaxWalletExclude[account] = true;
    }
    function includeInMaxWallet(address account) external onlyOwner {
        _isMaxWalletExclude[account] = false;
    }
    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isMaxWalletExclude[account];
    }
    function excludeFromMaxTransaction(address account) external onlyOwner {
        _isExcludedMaxTransactionAmount[account] = true;
    }
    function includeInMaxTransaction(address account) external onlyOwner {
        _isExcludedMaxTransactionAmount[account] = false;
    }
    function isExcludedFromMaxTransaction(address account) public view returns (bool) {
        return _isExcludedMaxTransactionAmount[account];
    }
    function excludeFromReward(address account) external onlyOwner {
        _isExcluded[account] = true;
    }
    function includeInReward(address account) external onlyOwner {
        _isExcluded[account] = false;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function addBot(address _user) public onlyOwner {
        require(_user != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        require(!isBot[_user]);
        isBot[_user] = true;
    }
	function removeBot(address _user) public onlyOwner {
        require(isBot[_user]);
        isBot[_user] = false;
    }
	function removeSniper(address account) external onlyOwner {
        isBoughtEarly[account] = false;
    }
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 200);
        gasPriceLimit = gas * 1 gwei;
    }
    function enableLimits() external onlyOwner {
        limitsInEffect = true;
        transferDelayEnabled = true;
    }
    function disableLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
    }
    function StartLiqAdd() external onlyOwner {
		_addLiq = true;
	}
	function StopLiqAdd() external onlyOwner {
		_addLiq = false;
	}
    function TaxSwapEnable() external onlyOwner {
        swapAndLiquifyEnabled = true;
    }
    function TaxSwapDisable() external onlyOwner {
        swapAndLiquifyEnabled = false;
    }
    function enableTransferDelay() external onlyOwner {
        transferDelayEnabled = true;
    }
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    function enableGasLimit() external onlyOwner {
        gasLimitActive = true;
    }
    function disableGasLimit() external onlyOwner {
        gasLimitActive = false;
    }
    function enableMaxWallet() external onlyOwner {
        maxWalletOn = true;
    }
    function disableMaxWallet() external onlyOwner {
        maxWalletOn = false;
    }
    function setBuyTax(uint256 _buyLiquidityTax, uint256 _buyReflectionsTax, uint256 _buyMarketingTax, uint256 _buyLandTax) external onlyOwner {
        buyReflectionsTax = _buyReflectionsTax;
        buyMarketingTax = _buyMarketingTax;
        buyLandTax = _buyLandTax;
        buyLiquidityTax = _buyLiquidityTax;
        require(buyLiquidityTax + buyReflectionsTax + buyMarketingTax + buyLandTax <= 20, "Must keep buy taxes below 20%");
    }
    function setSellTax(uint256 _sellLiquidityTax, uint256 _sellReflectionsTax, uint256 _sellMarketingTax, uint256 _sellLandTax) external onlyOwner {
        sellReflectionsTax = _sellReflectionsTax;
        sellMarketingTax = _sellMarketingTax;
        sellLandTax = _sellLandTax;
        sellLiquidityTax = _sellLiquidityTax;
        require(sellLiquidityTax + sellReflectionsTax + sellMarketingTax + sellLandTax <= 20, "Must keep sell taxes below 20%");
    }
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "address cannot be 0");
        _isExcludedFromFee[MWaddress] = false;
        MWaddress = payable(_marketingAddress);
        _isExcludedFromFee[MWaddress] = true;
    }
    function setMetaLandAddress(address _metalandAddress) public onlyOwner {
        require(_metalandAddress != address(0), "address cannot be 0");
        LWaddress = payable(_metalandAddress);
    }
    function forceSwapBack() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= _tTotal * 5 / 10000, "Can only swap back if more than 1% of tokens stuck on contract");
        swapTokens();
        emit OwnerForcedSwapBack(block.timestamp);
    }
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(DWaddress).call{value: address(this).balance}("");
    }
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _tokenTransferNoFee(address sender,address recipient,uint256 amount) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
}