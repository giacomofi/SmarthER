//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/ServiceInterface.sol";
import "./interfaces/IServiceV21.sol";
import "./interfaces/IMultiNode.sol";
import "./interfaces/IERC1155Preset.sol";
import "./interfaces/StrongNFTBonusLegacyInterface.sol";
import "./interfaces/IStrongPool.sol";
import "./lib/SafeMath.sol";
import "./lib/ERC1155Receiver.sol";

contract StrongNFTBonusV10 {

  using SafeMath for uint256;

  event Staked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);
  event Unstaked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);

  ServiceInterface public CService;
  IERC1155Preset public CERC1155;
  StrongNFTBonusLegacyInterface public CStrongNFTBonus;

  bool public initDone;

  address public serviceAdmin;
  address public superAdmin;

  string[] public nftBonusNames;
  mapping(string => uint256) public nftBonusLowerBound;
  mapping(string => uint256) public nftBonusUpperBound;
  mapping(string => uint256) public nftBonusValue;
  mapping(string => uint256) public nftBonusEffectiveBlock;

  mapping(uint256 => address) public nftIdStakedToEntity;
  mapping(uint256 => uint128) public nftIdStakedToNodeId;
  mapping(uint256 => uint256) public nftIdStakedAtBlock;
  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftId;

  mapping(bytes4 => bool) private _supportedInterfaces;

  mapping(string => uint8) public nftBonusNodesLimit;
  mapping(uint256 => uint8) public nftIdStakedToNodesCount;
  mapping(uint128 => uint256) public nodeIdStakedAtBlock;
  mapping(address => uint256[]) public entityStakedNftIds;

  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedAtBlock;

  mapping(address => bool) private serviceContracts;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedNftId;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedAtBlock;

  event StakedToNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);
  event UnstakedFromNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);

  mapping(address => bool) private serviceUsesTime;
  mapping(address => mapping(string => uint256)) public serviceNftBonusEffectiveAt;
  mapping(address => mapping(string => uint256)) public serviceNftBonusValue;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedAtTimestamp;

  function init(address serviceContract, address nftContract, address strongNFTBonusContract, address serviceAdminAddress, address superAdminAddress) external {
    require(initDone == false, "init done");

    _registerInterface(0x01ffc9a7);
    _registerInterface(
      ERC1155Receiver(0).onERC1155Received.selector ^
      ERC1155Receiver(0).onERC1155BatchReceived.selector
    );

    serviceAdmin = serviceAdminAddress;
    superAdmin = superAdminAddress;
    CService = ServiceInterface(serviceContract);
    CERC1155 = IERC1155Preset(nftContract);
    CStrongNFTBonus = StrongNFTBonusLegacyInterface(strongNFTBonusContract);
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function isNftStaked(uint256 _nftId) external view returns (bool) {
    return nftIdStakedToNodeId[_nftId] != 0 || nftIdStakedToNodesCount[_nftId] > 0;
  }

  function isNftStakedLegacy(uint256 _nftId) external view returns (bool) {
    return CStrongNFTBonus.isNftStaked(_nftId);
  }

  function getStakedNftId(address _entity, uint128 _nodeId, address _serviceContract) public view returns (uint256) {
    bool isEthNode = isEthereumNode(_serviceContract);
    uint256 stakedNftIdNew = entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId];
    uint256 stakedNftId = isEthNode ? entityNodeStakedNftId[_entity][_nodeId] : 0;
    uint256 stakedNftIdLegacy = isEthNode ? CStrongNFTBonus.getStakedNftId(_entity, _nodeId) : 0;

    return stakedNftIdNew != 0 ? stakedNftIdNew : (stakedNftId != 0 ? stakedNftId : stakedNftIdLegacy);
  }

  function getStakedNftIds(address _entity) external view returns (uint256[] memory) {
    return entityStakedNftIds[_entity];
  }

  function getStakedNftBonusName(address _entity, uint128 _nodeId, address _serviceContract) external view returns (string memory) {
    uint256 nftId = getStakedNftId(_entity, _nodeId, _serviceContract);
    return getNftBonusName(nftId);
  }

  function getNftBonusNames() external view returns (string[] memory) {
    return nftBonusNames;
  }

  function getNftNodesLeft(uint256 _nftId) external view returns (uint256) {
    return nftBonusNodesLimit[getNftBonusName(_nftId)] - nftIdStakedToNodesCount[_nftId];
  }

  function getNftBonusName(uint256 _nftId) public view returns (string memory) {
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (_nftId >= nftBonusLowerBound[nftBonusNames[i]] && _nftId <= nftBonusUpperBound[nftBonusNames[i]]) {
        return nftBonusNames[i];
      }
    }

    return "";
  }

  function getBonus(address _entity, uint128 _nodeId, uint256 _from, uint256 _to) external view returns (uint256) {
    return getBonusValue(_entity, _nodeId, _from, _to, 0);
  }

  function getBonusValue(address _entity, uint128 _nodeId, uint256 _from, uint256 _to, uint256 _bonusValue) public view returns (uint256) {
    address serviceContract = msg.sender;
    require(serviceContracts[serviceContract], "service doesnt exist");

    uint256 nftId = getStakedNftId(_entity, _nodeId, serviceContract);
    string memory bonusName = getNftBonusName(nftId);
    if (keccak256(abi.encode(bonusName)) == keccak256(abi.encode(""))) return 0;

    uint256 stakedAt = 0;
    if (serviceUsesTime[serviceContract]) {
      stakedAt = entityServiceNodeStakedAtTimestamp[_entity][serviceContract][_nodeId];
    }
    else {
      stakedAt = entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId] > 0
      ? entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId]
      : (entityNodeStakedAtBlock[_entity][_nodeId] > 0 ? entityNodeStakedAtBlock[_entity][_nodeId] : nftIdStakedAtBlock[nftId]);
    }

    uint256 bonusValue = _bonusValue != 0 ? _bonusValue : serviceNftBonusValue[serviceContract][bonusName] > 0
    ? serviceNftBonusValue[serviceContract][bonusName] : nftBonusValue[bonusName];

    uint256 effectiveAt = serviceNftBonusEffectiveAt[serviceContract][bonusName] > 0
    ? serviceNftBonusEffectiveAt[serviceContract][bonusName] : nftBonusEffectiveBlock[bonusName];

    uint256 startFrom = stakedAt > _from ? stakedAt : _from;
    if (startFrom < effectiveAt) {
      startFrom = effectiveAt;
    }

    if (stakedAt == 0 && keccak256(abi.encode(bonusName)) == keccak256(abi.encode("BRONZE"))) {
      return CStrongNFTBonus.getBonus(_entity, _nodeId, startFrom, _to);
    }

    if (nftId == 0) return 0;
    if (stakedAt == 0) return 0;
    if (effectiveAt == 0) return 0;
    if (startFrom >= _to) return 0;
    if (CERC1155.balanceOf(address(this), nftId) == 0) return 0;

    return _to.sub(startFrom).mul(bonusValue);
  }

  function isNftStaked(address _entity, uint256 _nftId, uint128 _nodeId, address _serviceContract) public view returns (bool) {
    return (isEthereumNode(_serviceContract) && entityNodeStakedNftId[_entity][_nodeId] == _nftId)
    || entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId] == _nftId;
  }

  function isEthereumNode(address _serviceContract) public view returns (bool) {
    return _serviceContract == address(CService);
  }

  //
  // Staking
  // -------------------------------------------------------------------------------------------------------------------

  function stakeNFT(uint256 _nftId, uint128 _nodeId, address _serviceContract) external payable {
    string memory bonusName = getNftBonusName(_nftId);
    require(keccak256(abi.encode(bonusName)) != keccak256(abi.encode("")), "not eligible");
    require(CERC1155.balanceOf(msg.sender, _nftId) != 0
      || (CERC1155.balanceOf(address(this), _nftId) != 0 && nftIdStakedToEntity[_nftId] == msg.sender), "not enough");
    require(nftIdStakedToNodesCount[_nftId] < nftBonusNodesLimit[bonusName], "over limit");
    require(serviceContracts[_serviceContract], "service doesnt exist");
    require(getStakedNftId(msg.sender, _nodeId, _serviceContract) == 0, "already staked");
    if (serviceUsesTime[_serviceContract]) require(IMultiNode(_serviceContract).doesNodeExist(msg.sender, uint(_nodeId)), "node doesnt exist");
    else require(IServiceV21(_serviceContract).doesNodeExist(msg.sender, _nodeId), "node doesnt exist");

    entityServiceNodeStakedNftId[msg.sender][_serviceContract][_nodeId] = _nftId;
    nftIdStakedToEntity[_nftId] = msg.sender;
    nftIdStakedToNodesCount[_nftId] += 1;

    if (serviceUsesTime[_serviceContract]) {
      entityServiceNodeStakedAtTimestamp[msg.sender][_serviceContract][_nodeId] = block.timestamp;
    }
    else {
      entityServiceNodeStakedAtBlock[msg.sender][_serviceContract][_nodeId] = block.number;
    }

    bool alreadyExists = false;
    for (uint8 i = 0; i < entityStakedNftIds[msg.sender].length; i++) {
      if (entityStakedNftIds[msg.sender][i] == _nftId) {
        alreadyExists = true;
        break;
      }
    }
    if (!alreadyExists) {
      entityStakedNftIds[msg.sender].push(_nftId);
    }

    if (CERC1155.balanceOf(address(this), _nftId) == 0) {
      CERC1155.safeTransferFrom(msg.sender, address(this), _nftId, 1, bytes(""));
    }

    emit StakedToNode(msg.sender, _nftId, _nodeId, serviceUsesTime[_serviceContract] ? block.timestamp : block.number, _serviceContract);
  }

  function migrateNFT(address _entity, uint128 _fromNodeId, uint128 _toNodeId, address _toServiceContract) external {
    address fromServiceContract = address(CService);
    uint256 nftId = getStakedNftId(_entity, _fromNodeId, fromServiceContract);

    require(msg.sender == fromServiceContract);
    require(serviceContracts[_toServiceContract], "service doesnt exist");
    require(IServiceV21(_toServiceContract).doesNodeExist(_entity, _toNodeId), "node doesnt exist");
    require(getStakedNftId(_entity, _toNodeId, _toServiceContract) == 0, "already staked");

    bool alreadyExists = false;
    for (uint8 i = 0; i < entityStakedNftIds[_entity].length; i++) {
      if (entityStakedNftIds[_entity][i] == nftId) {
        alreadyExists = true;
        break;
      }
    }

    if (nftId == 0 || !alreadyExists) {
      return;
    }

    entityServiceNodeStakedNftId[_entity][fromServiceContract][_fromNodeId] = 0;
    entityNodeStakedNftId[_entity][_fromNodeId] = 0;

    entityServiceNodeStakedNftId[_entity][_toServiceContract][_toNodeId] = nftId;
    nftIdStakedToEntity[nftId] = _entity;

    entityServiceNodeStakedAtTimestamp[_entity][_toServiceContract][_toNodeId] = block.timestamp;

    emit UnstakedFromNode(_entity, nftId, _fromNodeId, block.number, fromServiceContract);
    emit StakedToNode(_entity, nftId, _toNodeId, serviceUsesTime[_toServiceContract] ? block.timestamp : block.number, _toServiceContract);
  }

  function unstakeNFT(address _entity, uint128 _nodeId, address _serviceContract) external {
    uint256 nftId = getStakedNftId(_entity, _nodeId, _serviceContract);

    require(msg.sender == _serviceContract);
    require(serviceContracts[_serviceContract], "service doesnt exist");
    if (nftId == 0) return;

    entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId] = 0;
    nftIdStakedToNodeId[nftId] = 0;

    if (isEthereumNode(_serviceContract)) {
      entityNodeStakedNftId[_entity][_nodeId] = 0;
    }

    if (nftIdStakedToNodesCount[nftId] > 0) {
      nftIdStakedToNodesCount[nftId] -= 1;
    }

    if (nftIdStakedToNodesCount[nftId] == 0) {
      nftIdStakedToEntity[nftId] = address(0);

      for (uint8 i = 0; i < entityStakedNftIds[_entity].length; i++) {
        if (entityStakedNftIds[_entity][i] == nftId) {
          _deleteIndex(entityStakedNftIds[_entity], i);
          break;
        }
      }

      CERC1155.safeTransferFrom(address(this), _entity, nftId, 1, bytes(""));
    }

    emit UnstakedFromNode(_entity, nftId, _nodeId, block.number, _serviceContract);
  }

  function unStakeNFT(uint256 _nftId, uint128 _nodeId, uint256 _blockNumber, address _serviceContract, uint256 _claimedTotal, bytes memory _signature) external payable {
    require(isNftStaked(msg.sender, _nftId, _nodeId, _serviceContract), "wrong node");
    require(nftIdStakedToEntity[_nftId] != address(0), "not staked");
    require(nftIdStakedToEntity[_nftId] == msg.sender, "not staker");
    require(serviceContracts[_serviceContract], "service doesnt exist");

    bool hasNodeExpired = serviceUsesTime[_serviceContract]
      ? IMultiNode(_serviceContract).hasNodeExpired(msg.sender, uint(_nodeId))
      : (IServiceV21(_serviceContract).isNodeOverDue(msg.sender, _nodeId)
        || IServiceV21(_serviceContract).hasNodeExpired(msg.sender, _nodeId));

    if (!hasNodeExpired) {
      if (serviceUsesTime[_serviceContract]) IMultiNode(_serviceContract).claim{value : msg.value}(_nodeId, _blockNumber, address(0));
      else IServiceV21(_serviceContract).claim{value : msg.value}(_nodeId, _blockNumber, false, _claimedTotal, _signature);
    }

    entityServiceNodeStakedNftId[msg.sender][_serviceContract][_nodeId] = 0;
    nftIdStakedToNodeId[_nftId] = 0;

    if (isEthereumNode(_serviceContract)) {
      entityNodeStakedNftId[msg.sender][_nodeId] = 0;
    }

    if (nftIdStakedToNodesCount[_nftId] > 0) {
      nftIdStakedToNodesCount[_nftId] -= 1;
    }

    if (nftIdStakedToNodesCount[_nftId] == 0) {
      nftIdStakedToEntity[_nftId] = address(0);

      for (uint8 i = 0; i < entityStakedNftIds[msg.sender].length; i++) {
        if (entityStakedNftIds[msg.sender][i] == _nftId) {
          _deleteIndex(entityStakedNftIds[msg.sender], i);
          break;
        }
      }

      CERC1155.safeTransferFrom(address(this), msg.sender, _nftId, 1, bytes(""));
    }

    emit UnstakedFromNode(msg.sender, _nftId, _nodeId, _blockNumber, _serviceContract);
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function updateServiceBonus(string memory _name, uint256 _value, uint256 _effectiveAt, address _serviceContract) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    serviceNftBonusValue[_serviceContract][_name] = _value;
    serviceNftBonusEffectiveAt[_serviceContract][_name] = _effectiveAt;
  }

  function updateBonusLimits(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint8 _nodesLimit) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function updateBonus(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _value, uint256 _block, uint8 _nodesLimit) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusValue[_name] = _value;
    nftBonusEffectiveBlock[_name] = _block != 0 ? _block : block.number;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function updateContracts(address _nftContract) external {
    require(msg.sender == superAdmin, "not admin");
    CERC1155 = IERC1155Preset(_nftContract);
  }

  function addServiceContract(address _contract, bool _useTime) external {
    require(msg.sender == superAdmin, "not admin");
    serviceContracts[_contract] = true;
    serviceUsesTime[_contract] = _useTime;
  }

  function removeServiceContract(address _contract) external {
    require(msg.sender == superAdmin, "not admin");
    serviceContracts[_contract] = false;
    serviceUsesTime[_contract] = false;
  }

  function updateServiceAdmin(address newServiceAdmin) external {
    require(msg.sender == superAdmin, "not admin");
    serviceAdmin = newServiceAdmin;
  }

  //
  // ERC1155 support
  // -------------------------------------------------------------------------------------------------------------------

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }

  function _deleteIndex(uint256[] storage array, uint256 index) internal {
    uint256 lastIndex = array.length.sub(1);
    uint256 lastEntry = array[lastIndex];
    if (index == lastIndex) {
      array.pop();
    } else {
      array[index] = lastEntry;
      array.pop();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ServiceInterface {
  function claimingFeeNumerator() external view returns(uint256);

  function claimingFeeDenominator() external view returns(uint256);

  function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

  function getNodeId(address entity, uint128 nodeId) external view returns (bytes memory);

  function getReward(address entity, uint128 nodeId) external view returns (uint256);

  function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) external view returns (uint256);

  function hasNodeExpired(address _entity, uint _nodeId) external view returns (bool);

  function isEntityActive(address entity) external view returns (bool);

  function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IServiceV21 {
  function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

  function hasNodeExpired(address entity, uint128 nodeId) external view returns (bool);

  function isNodeOverDue(address entity, uint128 nodeId) external view returns (bool);

  function claim(uint128 nodeId, uint blockNumber, bool toStrongPool, uint256 claimedTotal, bytes memory signature) external payable returns (uint);

  // @deprecated
  function isEntityActive(address entity) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IMultiNode {
  function doesNodeExist(address entity, uint nodeId) external view returns (bool);

  function hasNodeExpired(address entity, uint nodeId) external view returns (bool);

  function claim(uint nodeId, uint timestamp, address toStrongPool) external payable returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Preset {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function getOwnerIdByIndex(address owner, uint256 index) external view returns (uint256);

    function getOwnerIdIndex(address owner, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface StrongNFTBonusLegacyInterface {
  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);

  function getStakedNftId(address _entity, uint128 _nodeId) external view returns (uint256);

  function isNftStaked(uint256 _nftId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrongPool {
  function mineFor(address miner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "../interfaces/IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "./IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}