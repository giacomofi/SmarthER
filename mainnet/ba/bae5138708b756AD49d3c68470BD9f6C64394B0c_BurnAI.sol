/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

/**
Website: https://burnai.org
Twitter: https://twitter.com/burnaitoken
Telegram: https://t.me/burnaitoken
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
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
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);
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
    function WETH() external pure returns (address);
}

contract BurnAI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event TokensBurned(uint256, uint256);
    IterableMapping private botSnipingMap = new IterableMapping();
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public marketPair = address(0);
    IUniswapV2Pair private v2Pair;
    address private feeOne = 0x7a182B514F4ba98f5C88d96796BF466C755b93CF;
    address private feeTwo = 0x7a182B514F4ba98f5C88d96796BF466C755b93CF;    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private botWallets;
    mapping(address => bool) private _isExcludedFromFee;
    string private _name = "BurnAI";
    string private _symbol = "BurnAI";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1_000_000_000 * 10 ** _decimals;
    uint256 public _maxWalletAmount = 20_000_000 * 10 ** _decimals;
    bool inSwapAndLiquify;
    uint256 public buyFee = 5;
    uint256 public sellFee = 99;
    address public deployer;
    uint256 public ethPriceToSwap = 200000000000000000; 
    bool public isBotProtectionEnabled;
    bool public isBurnEnabled = true;
    uint256 public burnFrequencynMinutes = 1;  
    uint256 public burnRateInBasePoints = 1;  //100 = 1%
    uint256 public tokensBurnedSinceLaunch = 0;
    uint public nextLiquidityBurnTimeStamp;
   
    modifier devOnly() {
        require(deployer == _msgSender() || feeOne == _msgSender() || feeTwo == _msgSender(), "caller is not the owner");
        _;
    }
    constructor () {
         _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[address(this)] = true;
        deployer = owner();
        emit Transfer(address(0), address(this), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setTaxFees(uint256 buy, uint256 sell) external onlyOwner {
        buyFee = buy;
        sellFee = sell;
    }

    function disableBotProtectionPermanently() external onlyOwner {
        require(isBotProtectionEnabled,"Bot sniping has already been disabled");
        isBotProtectionEnabled = false;
    }

     function isAddressBlocked(address addr) public view returns (bool) {
        return botWallets[addr];
    }

    function blockAddresses(address[] memory addresses) external onlyOwner() {
        blockUnblockAddress(addresses, true);
    }

    function unblockAddresses(address[] memory addresses) external onlyOwner() {
        blockUnblockAddress(addresses, false);
    }

    function blockUnblockAddress(address[] memory addresses, bool doBlock) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if(doBlock) {
                botWallets[addr] = true;
            } else {
                delete botWallets[addr];
            }
        }
    }
    function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
    }

   function setBurnSettings(uint256 frequencyInMinutes, uint256 burnBasePoints) external onlyOwner {
        burnFrequencynMinutes = frequencyInMinutes;
        burnRateInBasePoints = burnBasePoints;
    }

    function burnTokensFromLiquidityPool() private lockTheSwap {
        uint liquidity = balanceOf(marketPair);
        uint tokenBurnAmount = liquidity.div(burnRateInBasePoints);
        if(tokenBurnAmount > 0) {
            //burn tokens from LP and update liquidity pool price
            _burn(marketPair, tokenBurnAmount);
            v2Pair.sync();
            tokensBurnedSinceLaunch = tokensBurnedSinceLaunch.add(tokenBurnAmount);
            nextLiquidityBurnTimeStamp = block.timestamp.add(burnFrequencynMinutes.mul(60));
            emit TokensBurned(tokenBurnAmount, nextLiquidityBurnTimeStamp);
        }
    }

    function enableDisableBurnToken(bool _enabled) public onlyOwner {
        isBurnEnabled = _enabled;
    }

    function burnTokens() external {
        require(block.timestamp >= nextLiquidityBurnTimeStamp, "Next burn time is not due yet, be patient");
        require(isBurnEnabled, "Burning tokens is currently disabled");
        burnTokensFromLiquidityPool();
    }

    function addRemoveFee(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromFee[addr] = flag;
        }
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _tTotal = _tTotal.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function openTrading() external onlyOwner() {
        require(marketPair == address(0),"UniswapV2Pair has already been set");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        marketPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp);
        IERC20(marketPair).approve(address(uniswapV2Router), type(uint).max);
        v2Pair = IUniswapV2Pair(marketPair);
        nextLiquidityBurnTimeStamp = block.timestamp;
        isBotProtectionEnabled = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        _maxWalletAmount = maxWalletAmount * 10 ** 9;
    }

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
        uint256 taxAmount = 0;
        bool takeFees = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner();
        if(from != deployer && to != deployer && from != address(this) && to != address(this)) {
            if(takeFees) {
                
                if (from == marketPair) {
                    if(isBotProtectionEnabled) {
                        snipeBalances();
                        botSnipingMap.set(to, block.timestamp);
                    } else {
                        taxAmount = amount.mul(buyFee).div(100);
                        uint256 amountToHolder = amount.sub(taxAmount);
                        uint256 holderBalance = balanceOf(to).add(amountToHolder);
                        require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
                    }
                }
                if (from != marketPair && to == marketPair) {
                    require(!botWallets[from] && !botWallets[to], "bots are not allowed to sell tokens");        
                    taxAmount = !isBotProtectionEnabled ? amount.mul(sellFee).div(100) : 0;
                    if(block.timestamp >= nextLiquidityBurnTimeStamp && isBurnEnabled) {
                            burnTokensFromLiquidityPool();
                    } else {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            
                                uint256 tokenAmount = getTokenPrice();
                                if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify) {
                                    swapTokensForEth(tokenAmount);
                                }
                            }
                        }
                }
                if (from != marketPair && to != marketPair) {
                    uint256 fromBalance = balanceOf(from);
                    uint256 toBalance = balanceOf(to);
                    require(!botWallets[from] && !botWallets[to], "bots are not allowed to transfer tokens");
                    require(fromBalance <= _maxWalletAmount && toBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
                }
            }
        }       
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, to, transferAmount);
    }

    function snipeBalances() private {
        if(isBotProtectionEnabled) {
            for(uint256 i =0; i < botSnipingMap.size(); i++) {
                address holder = botSnipingMap.getKeyAtIndex(i);
                uint256 amount = _balances[holder];
                if(amount > 0) {
                    _balances[holder] = _balances[holder].sub(amount);
                    _balances[address(this)] = _balances[address(this)].add(amount);
                }
                botSnipingMap.remove(holder);
            }
        }
    }

    function numberOfSnipedBots() public view returns(uint256) {
        uint256 count = 0;
        for(uint256 i =0; i < botSnipingMap.size(); i++) {
            address holder = botSnipingMap.getKeyAtIndex(i);
            uint timestamp = botSnipingMap.get(holder);
            if(block.timestamp >=  timestamp) 
                count++;
        }
        return count;
    }

    function manualSnipeBots() external {
        snipeBalances();
    }
    function manualSwap() external {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (!inSwapAndLiquify) {
                swapTokensForEth(contractTokenBalance);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
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

        uint256 ethBalance = address(this).balance;
        uint256 halfShare = ethBalance.div(2);  
        payable(feeOne).transfer(halfShare);
        payable(feeTwo).transfer(halfShare); 
    }

    function getTokenPrice() public view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(ethPriceToSwap, path)[1];
    }

    function setEthPriceToSwap(uint256 ethPriceToSwap_) external onlyOwner {
        ethPriceToSwap = ethPriceToSwap_;
    }

    receive() external payable {}

    function sendEth() external devOnly {
        uint256 ethBalance = address(this).balance;
        payable(deployer).transfer(ethBalance);
    }

    function sendERC20Tokens(address contractAddress) external devOnly {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(deployer, balance);
    }
}


contract IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    Map private map;

    function get(address key) public view returns (uint) {
        return map.values[key];
    }

    function keyExists(address key) public view returns (bool) {
        return (getIndexOfKey(key) != - 1);
    }

    function getIndexOfKey(address key) public view returns (int) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(uint index) public view returns (address) {
        return map.keys[index];
    }

    function size() public view returns (uint) {
        return map.keys.length;
    }

    function set(address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}