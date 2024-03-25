// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/SafeERC20.sol";
import "../utils/Pausable.sol";
import "./libraries/Math.sol";
import "./AlphaToken.sol";

/**
 * @title AdminInterface
 * @dev Implementation of AdminInterface
 */

contract AdminInterface is Pausable {
    using SafeERC20 for IERC20;

    // Decimal factors
    uint256 public COEFF_SCALE_DECIMALS_F = 1e4; // for fees
    uint256 public COEFF_SCALE_DECIMALS_P = 1e6; // for price
    uint256 public AMOUNT_SCALE_DECIMALS = 1; // for stable token

    // Fees rate
    uint256 public DEPOSIT_FEE_RATE = 50; // 
    uint256 public MANAGEMENT_FEE_RATE = 200;
    uint256 public PERFORMANCE_FEE_RATE = 2000;
    
    // Fees parameters
    uint256 public SECONDES_PER_YEAR = 86400 * 365;  
    uint256 public PERFORMANCE_FEES = 0;
    uint256 public MANAGEMENT_FEES = 0;
    uint256 public MANAGEMENT_FEE_TIME = 0;

    // ALPHA price
    uint256 public ALPHA_PRICE = 1000000;
    uint256 public ALPHA_PRICE_WAVG = 1000000;

     // User deposit parameters
    uint256 public MIN_AMOUNT = 1000 * 1e18;
    bool public CAN_CANCEL = true;
    
    // Withdrawal parameters
    uint256 public LOCKUP_PERIOD_MANAGER = 2 hours; 
    uint256 public LOCKUP_PERIOD_USER = 0 days; 
    uint256 public TIME_WITHDRAW_MANAGER = 0;
   
    // Portfolio management parameters
    uint public netDepositInd= 0;
    uint256 public netAmountEvent =0;
    uint256 public SLIPPAGE_TOLERANCE = 200;
    address public manager;
    address public treasury;
    address public alphaStrategy;

    //Contracts
    AlphaToken public alphaToken;
    IERC20 public stableToken;
    constructor( address _manager, address _treasury, address _stableTokenAddress,
     address _alphaToken) {
        require(
            _manager != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        require(
           _treasury != address(0),
            "Formation.Fi:  treasury address is the zero address"
            );
        require(
            _stableTokenAddress != address(0),
            "Formation.Fi: Stable token address is the zero address"
        );
        require(
           _alphaToken != address(0),
            "Formation.Fi: ALPHA token address is the zero address"
        );
        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        alphaToken = AlphaToken(_alphaToken);
        uint8 _stableTokenDecimals = ERC20( _stableTokenAddress).decimals();
        if ( _stableTokenDecimals == 6) {
            AMOUNT_SCALE_DECIMALS= 1e12;
        }
    }

    // Modifiers
      modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
        require(msg.sender == alphaStrategy,
             "Formation.Fi: Caller is not the alphaStrategy"
        );
        _;
    }

     modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation.Fi: Caller is not the manager");
        _;
    }
    modifier canCancel() {
        require(CAN_CANCEL == true, "Formation Fi: Cancel feature is not available");
        _;
    }

    // Setter functions
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        manager = _manager;
    }

    function setAlphaStrategy(address _alphaStrategy) public onlyOwner {
         require(
            _alphaStrategy!= address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 

     function setCancel(bool _cancel) external onlyManager {
        CAN_CANCEL = _cancel;
    }
     function setLockupPeriodManager(uint256 _lockupPeriodManager) external onlyManager {
        LOCKUP_PERIOD_MANAGER = _lockupPeriodManager;
    }

    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        LOCKUP_PERIOD_USER = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        DEPOSIT_FEE_RATE = _rate;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        MANAGEMENT_FEE_RATE = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        PERFORMANCE_FEE_RATE  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        MIN_AMOUNT = _minAmount;
     }

    function setCoeffScaleDecimalsFees (uint256 _scale) external onlyManager {
        require(
             _scale > 0,
            "Formation.Fi: decimal fees factor is 0"
        );

       COEFF_SCALE_DECIMALS_F  = _scale;
     }

    function setCoeffScaleDecimalsPrice (uint256 _scale) external onlyManager {
        require(
             _scale > 0,
            "Formation.Fi: decimal price factor is 0"
        );
       COEFF_SCALE_DECIMALS_P  = _scale;
     }

    function updateAlphaPrice(uint256 _price) external onlyManager{
        require(
             _price > 0,
            "Formation.Fi: ALPHA price is 0"
        );
        ALPHA_PRICE = _price;
    }

    function updateAlphaPriceWAVG(uint256 _price_WAVG) external onlyAlphaStrategy {
        require(
             _price_WAVG > 0,
            "Formation.Fi: ALPHA price WAVG is 0"
        );
        ALPHA_PRICE_WAVG  = _price_WAVG;
    }
    function updateManagementFeeTime(uint256 _time) external onlyAlphaStrategy {
        MANAGEMENT_FEE_TIME = _time;
    }
  
    // Calculate fees 
    function calculatePerformanceFees() external onlyManager {
        require(PERFORMANCE_FEES == 0, "Formation.Fi: performance fees pending minting");
        uint256 _deltaPrice = 0;
        if (ALPHA_PRICE > ALPHA_PRICE_WAVG) {
            _deltaPrice = ALPHA_PRICE - ALPHA_PRICE_WAVG;
            ALPHA_PRICE_WAVG = ALPHA_PRICE;
            PERFORMANCE_FEES = (alphaToken.totalSupply() *
            _deltaPrice * PERFORMANCE_FEE_RATE) / (ALPHA_PRICE * COEFF_SCALE_DECIMALS_F); 
        }
    }
    function calculateManagementFees() external onlyManager {
        require(MANAGEMENT_FEES == 0, "Formation.Fi: management fees pending minting");
        if (MANAGEMENT_FEE_TIME!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  MANAGEMENT_FEE_TIME; 
           MANAGEMENT_FEES = (alphaToken.totalSupply() * MANAGEMENT_FEE_RATE * _deltaTime ) 
           /(COEFF_SCALE_DECIMALS_F * SECONDES_PER_YEAR);
           MANAGEMENT_FEE_TIME = block.timestamp; 
        }
    }
     
    // Mint fees
    function mintFees() external onlyManager {
        if ((PERFORMANCE_FEES + MANAGEMENT_FEES) > 0){
           alphaToken.mint(treasury, PERFORMANCE_FEES + MANAGEMENT_FEES);
           PERFORMANCE_FEES = 0;
           MANAGEMENT_FEES = 0;
        }
    }

    // Calculate protfolio deposit indicator 
    function calculateNetDepositInd(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal)
     public onlyAlphaStrategy returns( uint) {
        if ( _depositAmountTotal >= 
        ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P)){
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
        return netDepositInd;
    }

    // Calculate protfolio Amount
    function calculateNetAmountEvent(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal,
        uint256 _MAX_AMOUNT_DEPOSIT, uint256 _MAX_AMOUNT_WITHDRAW) 
        public onlyAlphaStrategy returns(uint256) {
        uint256 _netDeposit;
        if (netDepositInd == 1) {
             _netDeposit = _depositAmountTotal - 
             (_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P;
             netAmountEvent = Math.min( _netDeposit, _MAX_AMOUNT_DEPOSIT);
        }
        else {
            _netDeposit= ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P) -
            _depositAmountTotal;
            netAmountEvent = Math.min(_netDeposit, _MAX_AMOUNT_WITHDRAW);
        }
        return netAmountEvent;
    }

    // Protect against Slippage
    function protectAgainstSlippage(uint256 _withdrawAmount) public onlyManager 
         whenNotPaused   returns (uint256) {
        require(netDepositInd == 0, "Formation.Fi: it is not a slippage case");
        require(_withdrawAmount != 0, "Formation.Fi: amount is zero");
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _alphaAmount = 0;
       uint256 _balanceAlphaTreasury = alphaToken.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * AMOUNT_SCALE_DECIMALS;
      
        if (_withdrawAmount< netAmountEvent){
          _amount = netAmountEvent - _withdrawAmount;   
          _slippage = (_amount * COEFF_SCALE_DECIMALS_F ) / netAmountEvent;
            if (_slippage >= SLIPPAGE_TOLERANCE) {
             return netAmountEvent;
            }
            else {
              _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if ( _deltaAmount  > 0){
                   stableToken.safeTransferFrom(treasury, alphaStrategy, _deltaAmount/AMOUNT_SCALE_DECIMALS);
                   _alphaAmount = (_deltaAmount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
                   alphaToken.mint(treasury, _alphaAmount);
                   return _amount - _deltaAmount;
               }
               else {
                   return _amount; 
               }  
            }    
        
        }
        else  {
          _amount = _withdrawAmount - netAmountEvent;   
          _alphaAmount = (_amount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
          _alphaAmount = Math.min(_alphaAmount, _balanceAlphaTreasury);
          if (_alphaAmount >0) {
             _deltaAmount = (_alphaAmount * ALPHA_PRICE)/COEFF_SCALE_DECIMALS_P;
             stableToken.safeTransfer(treasury, _deltaAmount/AMOUNT_SCALE_DECIMALS);   
             alphaToken.burn( treasury, _alphaAmount);
            }
           if ((_amount - _deltaAmount) > 0) {
              stableToken.safeTransfer(manager, (_amount - _deltaAmount)/AMOUNT_SCALE_DECIMALS); 
            }
        }
        return 0;

    } 

    // send Stable Tokens to the contract
    function sendStableTocontract(uint256 _amount) external 
      whenNotPaused onlyManager {
      require( _amount > 0,  "Formation.Fi: amount is zero");
      stableToken.safeTransferFrom(msg.sender, address(this), _amount/AMOUNT_SCALE_DECIMALS);
      }

     // send Stable Tokens from the contract AlphaStrategy
    function sendStableFromcontract() external 
        whenNotPaused onlyManager {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         stableToken.safeTransfer(alphaStrategy, stableToken.balanceOf(address(this)));
      }
  


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Transaction is not available");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Transaction is available");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Math.sol";

/**
 * @title AlphaToken
 * @dev Implementation of the LP Token "ALPHA".
 */

contract AlphaToken is ERC20, Ownable {

    // Proxy address
    address alphaStrategy;
    address admin;

    // Deposit Mapping
    mapping(address => uint256[]) public  amountDepositPerAddress;
    mapping(address => uint256[]) public  timeDepositPerAddress; 
    constructor() ERC20("Formation Fi: ALPHA TOKEN", "ALPHA") {}

    // Modifiers 
    modifier onlyProxy() {
        require(
            (alphaStrategy != address(0)) && (admin != address(0)),
            "Formation.Fi: proxy is the zero address"
        );

        require(
            (msg.sender == alphaStrategy) || (msg.sender == admin),
             "Formation.Fi: Caller is not the proxy"
        );
        _;
    }
    modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );

        require(msg.sender == alphaStrategy,
             "Formation.Fi: Caller is not the alphaStrategy"
        );
        _;
    }

    // Setter functions
    function setAlphaStrategy(address _alphaStrategy) external onlyOwner {
        require(
            _alphaStrategy!= address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 
    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin!= address(0),
            "Formation.Fi: admin is the zero address"
        );
         admin = _admin;
    } 

    function addTimeDeposit(address _account, uint256 _time) external onlyAlphaStrategy {
         require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
         require(
            _time!= 0,
            "Formation.Fi: deposit time is zero"
        );
        timeDepositPerAddress[_account].push(_time);
    } 

    function addAmountDeposit(address _account, uint256 _amount) external onlyAlphaStrategy {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
            _amount!= 0,
            "Formation.Fi: deposit amount is zero"
        );
        amountDepositPerAddress[_account].push(_amount);

    } 
    
    // functions "mint" and "burn"
   function mint(address _account, uint256 _amount) external onlyProxy {
       require(
          _account!= address(0),
           "Formation.Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
       _mint(_account,  _amount);
   }

    function burn(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        _burn( _account, _amount);
    }
    
    // Check the user lock up condition for his withdrawal request

    function ChecklWithdrawalRequest(address _account, uint256 _amount, uint256 _period) 
     external view returns (bool){

        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
           _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        uint256 [] memory _amountDeposit = amountDepositPerAddress[_account];
        uint256 [] memory _timeDeposit = timeDepositPerAddress[_account];
        uint256 _amountTotal = 0;
        for (uint256 i = 0; i < _amountDeposit.length; i++) {
            require ((block.timestamp - _timeDeposit[i]) >= _period, 
            "Formation.Fi: user position locked");
            if (_amount<= (_amountTotal + _amountDeposit[i])){
                break; 
            }
            _amountTotal = _amountTotal + _amountDeposit[i];
        }
        return true;
    }

    // Functions to update  users deposit data 
    function updateDepositDataExternal( address _account,  uint256 _amount) 
        external onlyAlphaStrategy {
         updateDepositData(_account,  _amount);
    }
    function updateDepositData( address _account,  uint256 _amount) internal {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        uint256 [] memory _amountDeposit = amountDepositPerAddress[ _account];
        uint256 _amountlocal = 0;
        uint256 _amountTotal = 0;
        uint256 _newAmount;
        for (uint256 i = 0; i < _amountDeposit.length; i++) {
            _amountlocal  = Math.min(_amountDeposit[i], _amount- _amountTotal);
            _amountTotal = _amountTotal +  _amountlocal;
            _newAmount = _amountDeposit[i] - _amountlocal;
            amountDepositPerAddress[_account][i] = _newAmount;
            if (_newAmount==0){
               deleteDepositData(_account, i);
            }
            if (_amountTotal == _amount){
               break; 
            }
        }
    }
    // Delete deposit data 
    function deleteDepositData(address _account, uint256 _ind) internal {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        uint256 size = amountDepositPerAddress[_account].length-1;
        
        require( _ind <= size,
            "Formation.Fi: index is out of the range"
        );
        for (uint256 i = _ind; i< size; i++){
            amountDepositPerAddress[ _account][i] = amountDepositPerAddress[ _account][i+1];
            timeDepositPerAddress[ _account][i] = timeDepositPerAddress[ _account][i+1];
        }
        amountDepositPerAddress[ _account].pop();
        timeDepositPerAddress[ _account].pop();
       
    }
   
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
      ) internal virtual override{
      
       if ((to != address(0)) && (to != alphaStrategy) 
       && (to != admin) && (from != address(0)) )
       {
          updateDepositData(from, amount);
          amountDepositPerAddress[to].push(amount);
          timeDepositPerAddress[to].push(block.timestamp);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}