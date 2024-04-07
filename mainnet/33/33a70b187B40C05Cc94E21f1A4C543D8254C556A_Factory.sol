// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Buffer is Initializable, ReentrancyGuard {
    uint256 public totalReceived;
    uint256 private totalAmount;
    struct ShareData {
        uint256 shareAmount;
        uint256 lastBlockNumber;
        uint256 withdrawn;
    }

    address public curator;
    uint256 private totalOwnersFee;
    uint256 private totalCreatorsFee;
    uint256 private totalPartnersFee;
    uint256 public royaltyFee;

    mapping(address => ShareData) public _shareData;
    uint256 public totalShares;
    uint256 public totalSharesOfPartners;
    mapping(uint256 => address) private partnersGroup;
    uint256 private partnersGroupLength = 0;
    mapping(uint256 => address) private creatorsGroup;
    uint256 private creatorsGroupLength = 0;
    mapping(uint256 => uint256) private creatorPairInfo;
    mapping(uint256 => address) private ownersGroup;
    uint256 private ownersGroupLength = 0;

    //////////
    mapping(uint256 => uint256) public shareDetails;
    uint256 private shareDetailLength = 0;
    mapping(uint256 => uint256) public partnerShareDetails;
    address private deadAddress = 0x0000000000000000000000000000000000000000;
    uint256 private totalCntOfContent = 0;
    //////////

    address public marketWallet; // wallet address for market fee

    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }

    event UpdateCreatorPairsCheck(bool updated);
    event UpdateCreatorsGroupCheck(bool updateGroup);
    event UpdateFeeCheck(uint256 feePercent);
    event WithdrawnCheck(address to, uint256 amount);
    event UpdateSharesCheck(uint256[] share, uint256[] partnerShare);

    function initialize(
        address _owner,
        address _curator, // address for curator
        address[] memory _partnersGroup, // array of address for partners group
        address[] memory _creatorsGroup, // array of address for creators group
        uint256[] calldata _shares, // array of share percentage for every group
        uint256[] calldata _partnerShare, // array of share percentage for every members of partners group
        address _marketWallet
    ) public payable initializer {
        curator = _curator;

        for (uint256 i = 0; i < _partnersGroup.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    partnersGroup[j] != _partnersGroup[i],
                    "Partner address is repeated, please check again."
                );
            }
            partnersGroup[i] = _partnersGroup[i];
            partnersGroupLength++;
        }
        for (uint256 i = 0; i < _creatorsGroup.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    creatorsGroup[j] != _creatorsGroup[i],
                    "Creator address is repeated, please check again."
                );
            }
            creatorsGroup[i] = _creatorsGroup[i];
            creatorsGroupLength++;
        }
        require(_shares.length == 7, "Please input shares info correctly.");
        for (uint256 i = 0; i < _shares.length - 1; i++) {
            //////////
            totalShares += _shares[i];
            shareDetails[i] = _shares[i];
            shareDetailLength++;
            //////////
        }
        require(totalShares > 0, "Sum of share percentages must be greater than 0.");
        require(
            _partnersGroup.length == _partnerShare.length,
            "Please input partner group shares information correctly."
        );
        for (uint256 i = 0; i < _partnerShare.length; i++) {
            totalSharesOfPartners += _partnerShare[i];
            //////////
            partnerShareDetails[i] = _partnerShare[i];
            //////////
        }
        marketWallet = _marketWallet;
        owner = _owner;
        royaltyFee = 10;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    receive() external payable {
        totalReceived += msg.value;
        totalAmount += msg.value;
    }

    // Get the last block number
    function getBlockNumber(address account) external view returns (uint256) {
        return _shareData[account].lastBlockNumber;
    }

    function updateFeePercent(uint256 _royaltyFee) public onlyOwner {
        require(
            _royaltyFee < 20,
            "Your royalty percentage is set as over 20%."
        );
        royaltyFee = _royaltyFee;
        emit UpdateFeeCheck(royaltyFee);
    }

    function updateCreatorsGroupMint(address[] calldata _creatorsGroup) external onlyOwner {
        uint256 tmp = totalCreatorsFee / _creatorsGroup.length;
        for (uint256 i = 0; i < _creatorsGroup.length; i++) {
            _shareData[_creatorsGroup[i]].shareAmount += tmp;
        }
        totalCreatorsFee = 0;
        emit UpdateCreatorsGroupCheck(true);
    }

    // update creator pair info of creators addresses and tokenIDs of same lengths
    function updateCreatorsGroup(address[] calldata _creatorsGroup, uint256[] calldata _numOfTokens) external onlyOwner {
        require(
            _creatorsGroup.length == _numOfTokens.length,
            "Please input the creators info and tokenIDs as same length."
        );

        creatorsGroupLength = _creatorsGroup.length;
        for (uint256 i = 0; i < creatorsGroupLength; i++) {
            totalCntOfContent += _numOfTokens[i];
            creatorPairInfo[i] = totalCntOfContent;
            creatorsGroup[i] = _creatorsGroup[i];
            _shareData[_creatorsGroup[i]].shareAmount += totalCreatorsFee / _creatorsGroup.length;
        }
        totalCreatorsFee = 0;
        emit UpdateCreatorsGroupCheck(true);
    }

    function updateOwners(address[] calldata _owners) external onlyOwner {
        require(totalOwnersFee > 0 && shareDetails[5] > 0, "No need to update now, please update the owners list later.");
        ownersGroupLength = _owners.length;
        uint256 tmp = totalOwnersFee / ownersGroupLength;
        for (uint256 i = 0; i < ownersGroupLength; i++) {
            ownersGroup[i] = _owners[i];
            _shareData[_owners[i]].shareAmount += tmp;
        }
        totalOwnersFee = 0;
    }

    function updateRoyaltyPercentage(uint256[] calldata _share, uint256[] calldata _partnerShare) external onlyOwner {
        require(_share.length == shareDetailLength + 1, "Please input share info correctly");
        require(_partnerShare.length == partnersGroupLength, "Please input partners share info correctly");

        uint256 totalTmp = 0;
        uint256 partnersTmp = 0;

        for (uint256 i =0; i < _share.length - 1; i++) {
            shareDetails[i] = _share[i];
            totalTmp += _share[i];
        }

        for (uint256 i = 0; i < _partnerShare.length; i++) {
            partnerShareDetails[i] = _partnerShare[i];
            partnersTmp += _partnerShare[i];
        }

        require(totalTmp > 0, "Please input valid share info. Sum of them must be greater than 0.");
        totalShares = totalTmp;
        totalSharesOfPartners = partnersTmp;

        emit UpdateSharesCheck(_share, _partnerShare);
    }

    // Withdraw
    function withdraw(
        address account, // address to ask withdraw
        address[] calldata sellerAddresses, // array of sellers address
        uint256[] calldata tokenIDs, // array of tokenIDs to be sold
        uint256[] calldata prices // array of prices of NFTs to be sold
    ) external nonReentrant {
        _shareData[account].lastBlockNumber = block.number;
        uint256 index = 0;
        uint256 i = 0;
        for (i = 0; i < tokenIDs.length; i++) {
            for (index = 0; index < creatorsGroupLength; index++) {
                if (tokenIDs[i] < creatorPairInfo[index]) {
                    break;
                }
            }
            _shareData[creatorsGroup[index]].shareAmount += shareDetails[3] * prices[i] * royaltyFee / 100 / totalShares;
            if (sellerAddresses[i] != deadAddress) {
                _shareData[sellerAddresses[i]].shareAmount += shareDetails[4] * prices[i] * royaltyFee / 100 / totalShares;
            }
        }

        if (totalAmount > 0) {
            totalOwnersFee += (totalAmount * shareDetails[5]) / totalShares;
            _shareData[curator].shareAmount += (totalAmount * shareDetails[0]) / totalShares;
            totalPartnersFee += (totalAmount * shareDetails[1]) / totalShares;
            totalCreatorsFee += (totalAmount * shareDetails[2]) / totalShares;
            totalAmount = 0;
        }

        if (totalCreatorsFee > 0 && creatorsGroupLength > 0) {
            for (i = 0; i < creatorsGroupLength; i++) {
                _shareData[creatorsGroup[i]].shareAmount += totalCreatorsFee / creatorsGroupLength;
            }
            totalCreatorsFee = 0;
        }

        if (totalOwnersFee > 0 && ownersGroupLength > 0) {
            for (i = 0; i < ownersGroupLength; i++) {
                _shareData[ownersGroup[i]].shareAmount += totalOwnersFee / ownersGroupLength;
            }
            totalOwnersFee = 0;
        }

        if (totalPartnersFee > 0) {
            for (i = 0; i < partnersGroupLength; i++) {
                _shareData[partnersGroup[i]].shareAmount += totalPartnersFee * partnerShareDetails[i] / totalSharesOfPartners;
            }
            totalPartnersFee = 0;
        }
        
        if (_shareData[account].shareAmount > 0) {
            _transfer(account, _shareData[account].shareAmount);
            _shareData[account].withdrawn += _shareData[account].shareAmount;
            _shareData[account].shareAmount = 0;
        }
        emit WithdrawnCheck(account, _shareData[account].shareAmount);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Buffer.sol";

contract Factory {
    event ContractDeployed(
        address indexed owner,
        address indexed group,
        string title
    );
    address public immutable implementation;

    constructor() {
        implementation = address(new Buffer());
    }

    function genesis(
        string memory title,
        address _owner,
        address _curator,
        address[] memory _partnersGroup,
        address[] memory _creatorsGroup,
        uint256[] calldata _shares,
        uint256[] calldata _partnerShare,
        address _marketWallet
    ) external returns (address) {
        address payable clone = payable(
            ClonesUpgradeable.clone(implementation)
        );
        Buffer buffer = Buffer(clone);
        buffer.initialize(
            _owner,
            _curator,
            _partnersGroup,
            _creatorsGroup,
            _shares,
            _partnerShare,
            _marketWallet
        );
        emit ContractDeployed(msg.sender, clone, title);
        return clone;
    }
}