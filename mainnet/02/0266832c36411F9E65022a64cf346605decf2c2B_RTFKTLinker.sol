// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]

    LINKING CONTRACT V1 by @CardilloSamuel
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Storage.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract RTFKTLinker {
    using ECDSA for bytes32;

    mapping (address => bool) authorizedOwners;
    bool contractInitialized = false;
    uint256 public approvedPendingTime = 72 hours;

    modifier isAuthorizedOwner() {
        require(LinkingStorage.isAuthorizedOwner(msg.sender), "Unauthorized"); 
        _;
    }

    event link(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event unlink(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event transfer(address from, address to, string tagId, uint256 tokenId, address collectionAddress);

    ///////////////////////////
    // SETTER
    ///////////////////////////

    function linkNft(string calldata tagId, uint256 tokenId, address collectionAddress, bytes calldata signature) public {
        require(LinkingStorage.isAuthorizedCollection(collectionAddress), "This collection has not been approved");
        require(_isValidSignature(_hash(collectionAddress, tokenId, tagId), signature), "Invalid signature");

        ERC721 tokenContract = ERC721(collectionAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "You don't own the NFT");
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        _link(tagId, tokenId, collectionAddress, msg.sender);

        emit link(msg.sender, tagId, tokenId, collectionAddress);
    }

    // Work for normal unlinking AND dissaproving linking
    function unlinkNft(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == tokenId, "Token ID doesn't match the link" );
        require(msg.sender == LinkingStorage.linkOwner(collectionAddress, tokenId)[0], "You don't own the link");

        // Remove tokenId, tagId and address of link owner
        _unlink(tagId, tokenId, collectionAddress);

        emit unlink(msg.sender, tagId, tokenId, collectionAddress);
    }

    function approveTransfer(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == tokenId, "Token ID doesn't match the link" );
        require(msg.sender == LinkingStorage.linkOwner(collectionAddress, tokenId)[0], "You don't own the link");
        require(LinkingStorage.linkOwner(collectionAddress, tokenId)[1] != 0x0000000000000000000000000000000000000000, "There is no pending approval");
        require(block.timestamp - LinkingStorage.pendingTimestamp(collectionAddress, tokenId) <= approvedPendingTime, "It has been more than the authorized amount of time.");

        ERC721 tokenContract = ERC721(collectionAddress);
        address nftOwner = tokenContract.ownerOf(tokenId);

        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, nftOwner); // We transfer the link to the current NFT owner
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 1, 0x0000000000000000000000000000000000000000); // No more pending
        LinkingStorage.setPendingTimestamp(collectionAddress, tokenId, 0); // Reset timestamp
        
        emit transfer(msg.sender, nftOwner, tagId, tokenId, collectionAddress);
    }

    ////////////////////////////
    // STORAGE MANAGEMENT 
    ///////////////////////////

    function tagIdToTokenId(string calldata tagId, address collectionAddress) public view returns(uint256) {
        return LinkingStorage.tagIdToTokenId(tagId, collectionAddress);
    }

    function tokenIdtoTagId(address collectionAddress, uint256 tokenId) public view returns(string memory) {
        return LinkingStorage.tokenIdtoTagId(collectionAddress, tokenId);
    }

    function tagIdToCollectionAddress(string calldata tagId) public view returns(address) {
        return LinkingStorage.tagIdToCollectionAddress(tagId);
    }
 
    function linkOwner(address collectionAddress, uint256 tokenId) public view returns(address[2] memory, uint256) {
        return (LinkingStorage.linkOwner(collectionAddress, tokenId), LinkingStorage.pendingTimestamp(collectionAddress, tokenId));
    }

    function setSigner(address newSigner) public isAuthorizedOwner {
        LinkingStorage.setSigner(newSigner);
    }

    function getSigner() public view returns(address) {
        return LinkingStorage.getSigner();
    }

    function toggleAuthorizedOwners(address[] calldata ownersAddress) public isAuthorizedOwner {
        for(uint256 i = 0; i < ownersAddress.length; i++) {
            LinkingStorage.toggleAuthorizedOwner(ownersAddress[i]);
        }
    }

    function toggleAuthorizedCollection(address[] calldata collectionAddress) public isAuthorizedOwner {
        LinkingStorage.toggleAuthorizedCollection(collectionAddress);
    }

    function setLinkOwner(address collectionAddress, uint256 tokenId, address newOwner, uint256 typeOfOwner) public isAuthorizedOwner {
        require(typeOfOwner <= 1 && typeOfOwner >= 0, "You can't choose under 0 or over 1");

        if(typeOfOwner == 1) {
            LinkingStorage.setPendingTimestamp(collectionAddress, tokenId, block.timestamp);
        }

        LinkingStorage.setLinkOwner(collectionAddress, tokenId, typeOfOwner, newOwner);
    }

    function forceUnlink(string calldata tagId, uint256 tokenId, address collectionAddress) public isAuthorizedOwner {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) != 0, "This item is not linked" );

        address previousOwner = LinkingStorage.linkOwner(collectionAddress, tokenId)[0];

        _unlink(tagId, tokenId, collectionAddress);

        emit unlink(previousOwner, tagId, tokenId, collectionAddress);
    }

    function forceLinking(string calldata tagId, uint256 tokenId, address collectionAddress, address newOwner) public isAuthorizedOwner {
        require(LinkingStorage.isAuthorizedCollection(collectionAddress), "This collection has not been approved");
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        _link(tagId, tokenId, collectionAddress, newOwner);

        emit link(newOwner, tagId, tokenId, collectionAddress);
    }

    function setApprovedPendingTime(uint256 newApprovedPendingTime) public isAuthorizedOwner {
        approvedPendingTime = newApprovedPendingTime; // In second
    }
    
    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    function _initContractFallBack() public {
        require(!contractInitialized, "Contract already initialized");
        LinkingStorage.toggleAuthorizedOwner(0x623FC4F577926c0aADAEf11a243754C546C1F98c);
        LinkingStorage.toggleAuthorizedOwner(0xF85a742e9DEBf5715745C69210181E0C2dd5C9eB);
        contractInitialized = true;
    }

    function _link(string calldata tagId, uint256 tokenId, address collectionAddress, address newOwner) internal {
        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, tokenId);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, tagId);
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, newOwner);
    }

    function _unlink(string calldata tagId, uint256 tokenId, address collectionAddress) internal {
        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, 0);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, "");
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, 0x0000000000000000000000000000000000000000);
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 1, 0x0000000000000000000000000000000000000000);
        LinkingStorage.setPendingTimestamp(collectionAddress, tokenId, 0);
    }

    function _isValidSignature(bytes32 digest, bytes calldata signature) internal view returns (bool) {
        return digest.toEthSignedMessageHash().recover(signature) == LinkingStorage.getSigner();
    }

    function _hash(address collectionAddress, uint256 tokenId, string calldata tagId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            msg.sender,
            collectionAddress,
            tokenId,
            stringToBytes32(tagId)
        ));
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

library LinkingStorage {
    bytes32 internal constant NAMESPACE = keccak256("rtfkt.linking.storage");

    struct Storage {
        address signer;
        mapping (address => bool) authorizedCollections;
        mapping (string => mapping (address => uint256) ) tagIdToTokenId; // Tag ID => Contract address => Token ID (0 = no token ID)
        mapping (address => mapping (uint256 => string) ) tokenIdtoTagId; // Contract address => Token ID => Tag ID (null = no tag ID)
        mapping (address => mapping (uint256 => address[2])) linkOwner; // Array of 2 | 0 : current owner, 1 : potential new owner (when pending) | 0x0000000000000000000000000000000000000000 = null
        mapping (string => address) tagIdToCollectionAddress; // Tag ID => Contract address
        mapping (address => bool) authorizedOwners;
        mapping (address => mapping (uint256 => uint256) ) pendingTimestamp;
    }
    
    function getStorage() internal pure returns(Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    ///////////////////////////
    // GETTER
    ///////////////////////////

    function getSigner() internal view returns(address) {
        Storage storage s = getStorage(); 
        return s.signer;
    }

    function isAuthorizedCollection(address collectionAddress) internal view returns(bool) {
        return getStorage().authorizedCollections[collectionAddress];
    }

    function tagIdToTokenId(string calldata tagId, address collectionAddress) internal view returns(uint256) {
        return getStorage().tagIdToTokenId[tagId][collectionAddress];
    }

    function tokenIdtoTagId(address collectionAddress, uint256 tokenId) internal view returns(string memory) {
        return getStorage().tokenIdtoTagId[collectionAddress][tokenId];
    }

    function tagIdToCollectionAddress(string calldata tagId) internal view returns(address) {
        return getStorage().tagIdToCollectionAddress[tagId];
    }

    function linkOwner(address collectionAddress, uint256 tokenId) internal view returns(address[2] memory) {
        return getStorage().linkOwner[collectionAddress][tokenId];
    }

    function isAuthorizedOwner(address potentialOwner) internal view returns(bool) {
        return getStorage().authorizedOwners[potentialOwner];
    }

    function pendingTimestamp(address collectionAddress, uint256 tokenId) internal view returns(uint256) {
        return getStorage().pendingTimestamp[collectionAddress][tokenId];
    }
    
    ///////////////////////////
    // SETTER
    ///////////////////////////

    function setSigner(address _newSigner) internal {
        getStorage().signer = _newSigner;
    }

    function toggleAuthorizedOwner(address potentialOwner) internal {
        getStorage().authorizedOwners[potentialOwner] = !getStorage().authorizedOwners[potentialOwner];
    }

    function toggleAuthorizedCollection(address[] calldata collectionAddress) internal {
        Storage storage s = getStorage();
        for(uint256 i = 0; i < collectionAddress.length; i++) {
            s.authorizedCollections[collectionAddress[i]] = !s.authorizedCollections[collectionAddress[i]];
        }
    }

    function setTagIdToTokenId(string calldata tagId, address collectionAddress, uint256 tokenId) internal {
        getStorage().tagIdToTokenId[tagId][collectionAddress] = tokenId;

        // Managing the tagIdToCollectionAddress[tagId]
        getStorage().tagIdToCollectionAddress[tagId] = (tokenId == 0) ? 0x0000000000000000000000000000000000000000 : collectionAddress;
    }

    function setTokenIdtoTagId(address collectionAddress, uint256 tokenId, string memory tagId) internal {
        getStorage().tokenIdtoTagId[collectionAddress][tokenId] = tagId;
    }

    function setLinkOwner(address collectionAddress, uint256 tokenId, uint256 typeOfOwner, address ownerAddress) internal {
        getStorage().linkOwner[collectionAddress][tokenId][typeOfOwner] = ownerAddress;
    }

    function setPendingTimestamp(address collectionAddress, uint256 tokenId, uint256 timestamp) internal {
        getStorage().pendingTimestamp[collectionAddress][tokenId] = timestamp;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}