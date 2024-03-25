/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

/**

   ________ __    __ ________         ______  __    __ ________        _______  ______ __    __  ______
  |        |  \  |  |        \       /      \|  \  |  |        \      |       \|      |  \  |  \/      \
   \$$$$$$$| $$  | $| $$$$$$$$      |  $$$$$$| $$\ | $| $$$$$$$$      | $$$$$$$\\$$$$$| $$\ | $|  $$$$$$\
     | $$  | $$__| $| $$__          | $$  | $| $$$\| $| $$__          | $$__| $$ | $$ | $$$\| $| $$ __\$$
     | $$  | $$    $| $$  \         | $$  | $| $$$$\ $| $$  \         | $$    $$ | $$ | $$$$\ $| $$|    \
     | $$  | $$$$$$$| $$$$$         | $$  | $| $$\$$ $| $$$$$         | $$$$$$$\ | $$ | $$\$$ $| $$ \$$$$
     | $$  | $$  | $| $$_____       | $$__/ $| $$ \$$$| $$_____       | $$  | $$_| $$_| $$ \$$$| $$__| $$
     | $$  | $$  | $| $$     \       \$$    $| $$  \$$| $$     \      | $$  | $|   $$ | $$  \$$$\$$    $$
      \$$   \$$   \$$\$$$$$$$$        \$$$$$$ \$$   \$$\$$$$$$$$       \$$   \$$\$$$$$$\$$   \$$ \$$$$$$


🔥 The One Ring was forged in the Ethereum Doom by the Dark Lord Sauron. Sauron intended it to be the most powerful weapon for the strongest holder. 🔥

⭕ One Ring's rules ⭕

▶ If you make the biggest buy (in tokens) you will hold the One Ring for one hour, and collect 4% fees (in ETH) the same way marketing does.
‍Once the hour is finished, the counter will be reset and everyone will be able to compete again for the One Ring.
▶ If you sell any tokens at all at any point you are not worthy of the One Ring.
▶ If someone beats your record, they steal you the One Ring.


Website: https://oneringeth.com
Twitter: https://twitter.com/OneringETH
Telegram: https://t.me/OneRingEntry

           ___
         .';:;'.
        /_' _' /\   __
        ;a/ e= J/-'"  '.
        \ ~_   (  -'  ( ;_ ,.
         L~"'_.    -.  \ ./  )
         ,'-' '-._  _;  )'   (
       .' .'   _.'")  \  \(  |
      /  (  .-'   __\{`', \  |
     / .'  /  _.-'   "  ; /  |
    / /    '-._'-,     / / \ (
 __/ (_    ,;' .-'    / /  /_'-._
`"-'` ~`  ccc.'   __.','     \j\L\
                 .='/|\7      
                   ' `
*/

pragma solidity ^0.7.4;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ERC20Interface {
    function balanceOf(address whom) public view virtual returns (uint256);
}

contract OneRing is IERC20 {
    using SafeMath for uint256;

    string constant _name = "ONERING";
    string constant _symbol = "RING";
    uint8 constant _decimals = 18;


    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint256 _totalSupply = 10000 * (10**_decimals);
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor() {
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }
}