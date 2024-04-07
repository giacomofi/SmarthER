// SPDX-License-Identifier: MIT

// 🐸 https://pæpæ.com
// 🐸 https://t.me/paepaecoin
// 🐸 https://twitter/paepaecoin 

// 

pragma solidity 0.8.16;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return (true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {

    address internal owner;

    constructor(address _owner) {owner = _owner;}

    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}

    function isOwner(address account) public view returns (bool) {return account == owner;}

    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}

    function renounceOwnership() public onlyOwner {owner = 0x000000000000000000000000000000000000dEaD; emit OwnershipTransferred(0x000000000000000000000000000000000000dEaD);}

    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
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
        uint deadline) external;
}

contract PaepaeTheDigitalFrogContract is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Paepae";
    string private constant _symbol = "FROIG";

    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 420420696969 * (10 ** _decimals);

    uint256 private _maxTxAmountPercent = 1; 
    uint256 private _maxTransferPercent = 1;
    uint256 private _maxWalletPercent = 1;


    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFees;

    IRouter router;
    address public pair;

    bool private tradingOpen = true;

    uint256 private liqFee = 0;
    uint256 private devFee = 24;
    uint256 private totalFee = 24;
    uint256 private sellFee = 69;
    uint256 private transferFee = 100;
    uint256 private denominator = 100;


    bool private contractSwapEnabled = true;

    uint256 private swapTimes;
    bool private swapping;
    uint256 swapAmount = 3;

    uint256 private swapThreshold = ( _totalSupply * 1000 ) / 100000; //1%
    uint256 private minSwapTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public devWallet = 0x32b283bAA8D76A06A37C5470D72bC054B0812D80; 

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
        
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
        
    }

    function decimals() public pure returns (uint8) {
        
    return _decimals;
    
    }

    function getOwner() external view override returns (address) { 
        
    return owner; 
    
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
        
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {

        return _allowances[owner][spender];
        
    }

    function isCont(address addr) internal view returns (bool) {
        uint size; assembly { size := extcodesize(addr) 
    } 
    return size > 0; 
    
    }

    function excludeFromFees(address _address, bool _enabled) external onlyOwner {
        isExcludedFromFees[_address] = _enabled;
        
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);return true;
    }

    function totalSupply() public view override returns (uint256) {
        
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
        
    }

    function _maxWalletToken() public view returns (uint256) {
        return totalSupply() * _maxWalletPercent / denominator;
        
    }

    function _maxTxAmount() public view returns (uint256) {
        return totalSupply() * _maxTxAmountPercent / denominator;
    }

    function _maxTransferAmount() public view returns (uint256) {
        return totalSupply() * _maxTransferPercent / denominator;
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > uint256(0), "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }


    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkIfTradingIsAllowed(sender, recipient);
        checkMaxWalletLimit(sender, recipient, amount); 
        swapbackCounters(sender, recipient);
        checkTxLimit(sender, recipient, amount); 
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function updateFees(uint256 _liq, uint256 _dev, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liqFee = _liq;
        devFee = _dev;
        totalFee = _total;
        sellFee = _sell;
        transferFee = _trans;
    
    }

    function updateLimits(uint256 _buy, uint256 _trans, uint256 _wallet) external onlyOwner {
        _maxTxAmountPercent = _buy;
        _maxTransferPercent = _trans;
        _maxWalletPercent = _wallet;
       
       
    }
 
    function updateDevWallet(address newDevWallet) external onlyOwner{
        	devWallet = newDevWallet;

    }


   

    function removeLimits() external onlyOwner {
        _maxTxAmountPercent = totalSupply();
        _maxTransferPercent = totalSupply();
        _maxWalletPercent = totalSupply();
    }

    function commenceTrade() external onlyOwner {
        tradingOpen = true;
        
        }


    function checkIfTradingIsAllowed(address sender, address recipient) internal view {
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]){require(tradingOpen, "tradingAllowed");}
    }
    
    function checkMaxWalletLimit(address sender, address recipient, uint256 amount) internal view {
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken(), "Exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient) internal {
        if(recipient == pair && !isExcludedFromFees[sender]){swapTimes += uint256(1);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(sender != pair){require(amount <= _maxTransferAmount() || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount() || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded");
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {

        uint256 _denominator = (liqFee.add(1).add(devFee)).mul(2);

        uint256 tokensToAddLiquidityWith = tokens.mul(liqFee).div(_denominator);

        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liqFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liqFee);

        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 remainingBalance = address(this).balance;

        if(remainingBalance > uint256(0)){payable(devWallet).transfer(remainingBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            devWallet,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && contractSwapEnabled && tradingOpen && aboveMin && !isExcludedFromFees[sender] && recipient == pair && swapTimes >= swapAmount && aboveThreshold;
    }

    function updateSwapTrheshold(uint256 _newSwapTreshold) external onlyOwner{
        swapThreshold = _totalSupply.mul(_newSwapTreshold).div(uint256(100000)); 
    }


    function updateMinSwapTokensAmount(uint256 _newMinSwapTokensAtAmount) external onlyOwner{
        minSwapTokenAmount = _totalSupply.mul(_newMinSwapTokensAtAmount).div(uint256(100000));
    }
    

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFromFees[sender] && !isExcludedFromFees[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}