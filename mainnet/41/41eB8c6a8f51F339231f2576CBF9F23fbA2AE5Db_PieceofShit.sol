/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: Unlicensed

/** 
 * Shit on your 'bluechip' and yes we are selling shit Created by SHITLAB
 * Twitter: https://twitter.com/pieceofshit_wtf
*/

pragma solidity 0.8.16;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

contract PieceofShit is IERC20, Auth {
    using SafeMath for uint256;

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string private constant  _name = "PieceofShit";
    string private constant _symbol = "Shitverse";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 1_000_000_000_000 * (10 ** _decimals);
    //max wallet holding of 2% 
    uint256 public _maxTokenForWallet = ( _totalSupply * 2 ) / 100;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isFeeExcludeForAddress;
    mapping (address => bool) limitTxExclude;
            
    uint256 public buyTotalTax = 2;
    uint256 public sellTotalTax = 2;
    uint256 private feeDenominator = 100;

    address payable public marketingWallet = payable(0x53da52fe90ab2FEb8aC53FB49d2300F1f3e26F18);

    IDEXRouter public router;
    address public pair;

    bool private tradingOpen;
    bool private isLimitBuyEnable = true;
    bool private isMaxWalletEnable = true;
    uint256 private maxTokenToBuy = ( _totalSupply * 1 ) / 100;
    uint256 public amountTokenSwapForMarketting = ( _totalSupply * 1 ) / 1000;
    
    bool private inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        limitTxExclude[msg.sender] = true;

        isFeeExcludeForAddress[msg.sender] = true;
        isFeeExcludeForAddress[marketingWallet] = true;       

        _balances[msg.sender] = _totalSupply;
    
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(!authorizations[sender] && !authorizations[recipient]){ 
            require(tradingOpen, "Trading not yet enabled.");
        }
        
        // max wallet code
        if (isMaxWalletEnable && !authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxTokenForWallet,"Total Holding is currently limited, you can not buy that much.");
        }
        
        // Checks max transaction limit
        if(isLimitBuyEnable) checkTxLimit(sender, amount);

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }      

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= amountTokenSwapForMarketting;
    
        bool shouldSwapBack = (overMinTokenBalance && recipient==pair && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ swapBack(amountTokenSwapForMarketting); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= maxTokenToBuy || limitTxExclude[sender], "TX Limit Exceeded");
    }
 
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExcludeForAddress[sender] || isFeeExcludeForAddress[recipient]) &&  (sender == pair || recipient == pair) );
   }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 transferFeeRate = recipient == pair ? sellTotalTax : buyTotalTax;
        uint256 feeAmount;
        feeAmount = amount.mul(transferFeeRate).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);   

        return amount.sub(feeAmount);
    }

    function swapBack(uint256 amount) internal swapping {
        swapTokenForMarketting(amount);
    }
    
    function swapTokenForMarketting(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            marketingWallet,
            block.timestamp
        );
    }

    function swapTokenManual() public onlyOwner {

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= amountTokenSwapForMarketting;
    
        bool shouldSwapBack = (overMinTokenBalance && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ 
            swapTokenForMarketting(amountTokenSwapForMarketting);
         }
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }    
  
    function setIsFeeExcludeForAddress(address holder, bool exempt) external onlyOwner {
        isFeeExcludeForAddress[holder] = exempt;
    }

    function setFeeTax (uint256 _buyTotalTax, uint256 _sellTotalTax) external onlyOwner {
        buyTotalTax = _buyTotalTax;
        sellTotalTax = _sellTotalTax;
    }

    function setMaxTokenBuy (uint256 _percent) external onlyOwner {
        maxTokenToBuy = ( _totalSupply * _percent ) / 100;
    }
  
    function manualSendBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingWallet).transfer(contractETHBalance);
    }

    function manualBurnToken(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }
    
    function getCirSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    } 

    function removeAllAboutLimit() external onlyOwner {
        isLimitBuyEnable = false;
        isMaxWalletEnable = false;
    }

    function updateSwapAmount (uint256 amount) external onlyOwner {
        require (amount <= _totalSupply.div(100), "can't exceed 1%");
        amountTokenSwapForMarketting = amount * 10 ** 9;
    } 

    function setPercentMaxWallet(uint256 maxWallPercent) external onlyOwner() {
        _maxTokenForWallet = (_totalSupply * maxWallPercent ) / 100;
    }

    function setLimitExcludeForAddress(address holder, bool exempt) external authorized {
        limitTxExclude[holder] = exempt;
    }

}