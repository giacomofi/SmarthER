pragma solidity =0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Ownable1 {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }
}

interface IARK420_WETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IVesting {
    function vestPurchase(address user, uint amount) external;
    function vesters(address vester) external returns (bool);
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract ARK420ERC20P2P_V1 is Ownable1 {    
    struct Trade {
        address initiator;
        address proposedAsset;
        uint initialProposedAmount;
        uint proposedAmount;
        address askedAsset;
        bool proposedAssetVest;
        uint initialAskedAmount;
        uint askedAmount;
        uint minTradeAskedAmount;
        uint maxTotalPurchaseAskedAmount;
        uint deadline;
        uint totalReceived;
        address[] rewardWallets;
        uint status; //0: Active, 1: success, 2: canceled, 3: withdrawn
        mapping(address => uint) purchases;
    }

    enum TradeState {
        Active,
        Succeeded,
        Canceled,
        Withdrawn,
        Overdue
    }

    IARK420_WETH public immutable ARK420_WETH;

    uint public supportRewardRate;
    address public supportAddress;

    uint public tradeCount;
    mapping(uint => Trade) public trades;
    mapping(address => uint[]) private _userTrades;

    event NewTrade(address proposedAsset, uint proposedAmount, address askedAsset, bool proposedAssetVest, uint askedAmount, uint deadline, uint minTradeAskedAmount, uint maxTotalPurchaseAskedAmount, address[] rewardWallets, uint tradeId);
    event SupportTrade(uint tradeId, address counterparty, uint amount, uint assetAmount);
    event CancelTrade(uint tradeId);
    event WithdrawOverdueAsset(uint tradeId);

    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed token, address indexed to, uint amount);
    
    constructor(address ark420Weth, address support, uint _supportRewardRate) {
        require(Address.isContract(ark420Weth), "ARK420ERC20P2P_V1: Not contract");
        ARK420_WETH = IARK420_WETH(ark420Weth);
        require(support != address(0), "ARK420ERC20P2P_V1: Zero address");
        supportAddress = support;
        require(_supportRewardRate >= 0 && _supportRewardRate <= 100, "ARK420ERC20P2P_V1: Reward rate should be from 0 to 100");
        supportRewardRate = _supportRewardRate;
    }

    receive() external payable {
        assert(msg.sender == address(ARK420_WETH)); // only accept ETH via fallback from the ARK420_WETH contract
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ARK420ERC20P2P_V1: locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function createTrade(address proposedAsset, uint proposedAmount, address askedAsset, bool proposedAssetVest, uint askedAmount, uint minTradeAskedAmount, uint maxTotalPurchaseAskedAmount, address[] memory rewardWallets, uint deadline) onlyOwner external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "ARK420ERC20P2P_V1: Not contracts");
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, proposedAssetVest, askedAmount, minTradeAskedAmount, maxTotalPurchaseAskedAmount, rewardWallets, deadline);   
    }

    function createTradeETH(address askedAsset, bool proposedAssetVest, uint askedAmount, uint minTradeAskedAmount, uint maxTotalPurchaseAskedAmount, address[] memory rewardWallets, uint deadline) onlyOwner payable external returns (uint tradeId) {
        require(Address.isContract(askedAsset), "ARK420ERC20P2P_V1: Not contract");
        ARK420_WETH.deposit{value: msg.value}();
        tradeId = _createTrade(address(ARK420_WETH), msg.value, askedAsset, proposedAssetVest, askedAmount, minTradeAskedAmount, maxTotalPurchaseAskedAmount, rewardWallets, deadline);   
    }

    function createTradeWithPermit(address proposedAsset, uint proposedAmount, address askedAsset, bool proposedAssetVest, uint askedAmount, uint minTradeAskedAmount, uint maxTotalPurchaseAskedAmount, uint deadline, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) onlyOwner external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "ARK420ERC20P2P_V1: Not contracts");
        IERC20Permit(proposedAsset).permit(msg.sender, address(this), proposedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        address[] memory rewardWallets;
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, proposedAssetVest, askedAmount, minTradeAskedAmount, maxTotalPurchaseAskedAmount, rewardWallets, deadline);   
    }

    function supportTrade(uint tradeId, uint partialAmount) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "ARK420ERC20P2P_V1: not active trade");
        require(partialAmount >= trade.minTradeAskedAmount, "ARK420ERC20P2P_V1: purchase amount lower then min amount");
        uint256 tokenAmount = getCurrentRate(tradeId, partialAmount);
        require(partialAmount > 0 && trade.proposedAmount > 0 && trade.proposedAmount >= tokenAmount, "ARK420ERC20P2P_V1: wrong amount");
        require(trade.purchases[msg.sender] + partialAmount <= trade.maxTotalPurchaseAskedAmount && trade.maxTotalPurchaseAskedAmount > 0, "ARK420ERC20P2P_V1: reached max total purchase amount for trade");

        uint toSupport = partialAmount * supportRewardRate / 100;
        if (supportRewardRate > 0)
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, supportAddress, toSupport);

        if (trade.rewardWallets.length > 0) {
            uint toRewards = partialAmount - toSupport;
            for (uint i = 0; i < trade.rewardWallets.length; i++) {
                TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.rewardWallets[i], toRewards / trade.rewardWallets.length);
            }
        } else TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, partialAmount);

        _supportTrade(tradeId, partialAmount);
    }

    function supportTradeETH(uint tradeId, uint partialAmount) payable external lock {
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "ARK420ERC20P2P_V1: not active trade");
        require(msg.value >= partialAmount, "ARK420ERC20P2P_V1: Not enough ETH sent");
        require(trade.askedAsset == address(ARK420_WETH), "ARK420ERC20P2P_V1: ERC20 trade");

        require(partialAmount >= trade.minTradeAskedAmount, "ARK420ERC20P2P_V1: purchase amount lower then min amount");
        uint256 tokenAmount = getCurrentRate(tradeId, partialAmount);
        require(partialAmount > 0 && trade.proposedAmount > 0 && trade.proposedAmount >= tokenAmount, "ARK420ERC20P2P_V1: wrong amount");
        require(trade.purchases[msg.sender] + partialAmount <= trade.maxTotalPurchaseAskedAmount && trade.maxTotalPurchaseAskedAmount > 0, "ARK420ERC20P2P_V1: reached max total purchase amount for trade");

        uint toSupport = partialAmount * supportRewardRate / 100;
        if (supportRewardRate > 0)
        TransferHelper.safeTransferETH(supportAddress, toSupport);

        if (trade.rewardWallets.length > 0) {
            uint toRewards = partialAmount - toSupport;
            for (uint i = 0; i < trade.rewardWallets.length; i++) {
                TransferHelper.safeTransferETH(trade.rewardWallets[i], toRewards / trade.rewardWallets.length);
            }
        } else TransferHelper.safeTransferETH(trade.initiator, partialAmount);
        
        if (msg.value > partialAmount) TransferHelper.safeTransferETH(msg.sender, msg.value - partialAmount);
        _supportTrade(tradeId, partialAmount);
    }

    function supportTradeWithPermit(uint tradeId, uint partialAmount, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) onlyOwner external lock {
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "ARK420ERC20P2P_V1: not active trade");
        require(partialAmount >= trade.minTradeAskedAmount, "ARK420ERC20P2P_V1: purchase amount lower then min amount");
        uint256 tokenAmount = getCurrentRate(tradeId, partialAmount);
        require(partialAmount > 0 && trade.proposedAmount > 0 && trade.proposedAmount >= tokenAmount, "ARK420ERC20P2P_V1: wrong amount");
        require(trade.purchases[msg.sender] + partialAmount <= trade.maxTotalPurchaseAskedAmount && trade.maxTotalPurchaseAskedAmount > 0, "ARK420ERC20P2P_V1: reached max total purchase amount for trade");

        IERC20Permit(trade.askedAsset).permit(msg.sender, address(this), partialAmount, permitDeadline, v, r, s);

        uint toSupport = partialAmount * supportRewardRate / 100;
        if (supportRewardRate > 0)
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, supportAddress, toSupport);

        if (trade.rewardWallets.length > 0) {
            uint toRewards = partialAmount - toSupport;
            for (uint i = 0; i < trade.rewardWallets.length; i++) {
                TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.rewardWallets[i], toRewards / trade.rewardWallets.length);
            }
        } else TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, partialAmount);

        _supportTrade(tradeId, partialAmount);
    }

    function cancelTrade(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "ARK420ERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline > block.timestamp, "ARK420ERC20P2P_V1: not active trade");
        trade.status = 2;

        if (trade.proposedAsset != address(ARK420_WETH)) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else {
            ARK420_WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferETH(msg.sender, trade.proposedAmount);
        }

        emit CancelTrade(tradeId);
    }

    function withdrawOverdueAsset(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "ARK420ERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline < block.timestamp, "ARK420ERC20P2P_V1: not available for withdrawal");

        if (trade.proposedAsset != address(ARK420_WETH)) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else {
            ARK420_WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferETH(msg.sender, trade.proposedAmount);
        }

        trade.status = 3;

        emit WithdrawOverdueAsset(tradeId);
    }

    function state(uint tradeId) external view returns (TradeState) {
        require(tradeCount >= tradeId && tradeId > 0, "ARK420ERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        if (trade.status == 1) {
            return TradeState.Succeeded;
        } else if (trade.status == 2 || trade.status == 3) {
            return TradeState(trade.status);
        } else if (trade.deadline < block.timestamp) {
            return TradeState.Overdue;
        } else {
            return TradeState.Active;
        }
    }

    function userTrades(address user) external view returns (uint[] memory) {
        return _userTrades[user];
    }

    function userPurchasesForTrade(address user, uint tradeId) external view returns (uint) {
        return trades[tradeId].purchases[user];
    }

    function _createTrade(address proposedAsset, uint proposedAmount, address askedAsset, bool proposedAssetVest, uint askedAmount, uint minTradeAskedAmount, uint maxTotalPurchaseAskedAmount, address[] memory rewardWallets, uint deadline) private returns (uint tradeId) { 
        require(askedAsset != proposedAsset, "ARK420ERC20P2P_V1: asked asset can't be equal to proposed asset");
        require(proposedAmount > 0, "ARK420ERC20P2P_V1: zero proposed amount");
        require(askedAmount > 0, "ARK420ERC20P2P_V1: zero asked amount");
        require(askedAmount > minTradeAskedAmount, "ARK420ERC20P2P_V1: asked amount should be more then min trade amount");
        require(deadline > block.timestamp, "ARK420ERC20P2P_V1: incorrect deadline");
        require(proposedAmount >= askedAmount, "ARK420ERC20P2P_V1: proposed amount should be more or equal asked amount to calculate valid rate");
        require(!proposedAssetVest || proposedAssetVest && IVesting(proposedAsset).vesters(address(this)), "ARK420ERC20P2P_V1: this contract not allowed to vest on proposed asset");

        tradeId = ++tradeCount;
        Trade storage trade = trades[tradeId];
        trade.initiator = msg.sender;
        trade.proposedAsset = proposedAsset;
        trade.initialProposedAmount = proposedAmount;
        trade.proposedAmount = proposedAmount;
        trade.askedAsset = askedAsset;
        trade.proposedAssetVest = proposedAssetVest;
        trade.initialAskedAmount = askedAmount;
        trade.askedAmount = askedAmount;
        trade.deadline = deadline;
        trade.minTradeAskedAmount = minTradeAskedAmount;
        trade.maxTotalPurchaseAskedAmount = maxTotalPurchaseAskedAmount;
        trade.totalReceived = 0;
        trade.rewardWallets = rewardWallets;
        
        _userTrades[msg.sender].push(tradeId);
        
        emit NewTrade(proposedAsset, proposedAmount, askedAsset, proposedAssetVest, askedAmount, deadline, minTradeAskedAmount, maxTotalPurchaseAskedAmount, rewardWallets, tradeId);
    }

    function getCurrentRate(uint256 tradeId, uint256 partialAmount) public view returns(uint256) {
        return trades[tradeId].proposedAmount * partialAmount / trades[tradeId].askedAmount;
    }

    function _supportTrade(uint tradeId, uint partialAmount) private { 
        Trade storage trade = trades[tradeId];

        uint256 tokenAmount = getCurrentRate(tradeId, partialAmount);
        if (trade.proposedAsset != address(ARK420_WETH)) {
            if (trade.proposedAssetVest) IVesting(trade.proposedAsset).vestPurchase(msg.sender, tokenAmount);
            else TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, tokenAmount);
        } else {
            ARK420_WETH.withdraw(tokenAmount);
            TransferHelper.safeTransferETH(msg.sender, tokenAmount);
        }

        trade.totalReceived += partialAmount;
        trade.proposedAmount -= tokenAmount;
        trade.askedAmount -= partialAmount;
        trade.purchases[msg.sender] += partialAmount;

        if (trade.proposedAmount == 0) {
            trade.status = 1;
        }

        emit SupportTrade(tradeId, msg.sender, partialAmount, tokenAmount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "ARK420ERC20P2P_V1: Can't be zero address");
        require(amount > 0, "ARK420ERC20P2P_V1: Should be greater than 0");
        TransferHelper.safeTransferETH(to, amount);
        emit Rescue(to, amount);
    }

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        require(to != address(0), "ARK420ERC20P2P_V1: Can't be zero address");
        require(amount > 0, "ARK420ERC20P2P_V1: Should be greater than 0");
        TransferHelper.safeTransfer(token, to, amount);
        emit RescueToken(token, to, amount);
    }

}