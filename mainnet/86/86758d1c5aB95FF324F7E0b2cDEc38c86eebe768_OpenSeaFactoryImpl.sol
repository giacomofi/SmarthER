// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC165Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../interfaces/AletheaERC721Spec.sol";
import "../lib/StringUtils.sol";
import "../utils/AccessControl.sol";

/**
 * @title OpenSea ERC721 Factory interface
 *
 * @notice In order to mint items only when they're purchased, OpenSea provides a Factory interface
 *      that is used to define how the items will be minted.
 *      See https://docs.opensea.io/docs/2-custom-item-sale-contract
 *
 * @notice This is a generic factory contract that can be used to mint tokens. The configuration
 *      for minting is specified by an _optionId, which can be used to delineate various
 *      ways of minting.
 *
 * @dev Copy of the OpenSea interface:
 *      https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/IFactoryERC721.sol
 */
interface OpenSeaFactoryERC721 is ERC165 {
	/**
	 * @dev Returns the name of this factory.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the symbol for this factory.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Number of options the factory supports.
	 */
	function numOptions() external view returns (uint256);

	/**
	 * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
	 *      restrict a total supply per option ID (or overall).
	 */
	function canMint(uint256 _optionId) external view returns (bool);

	/**
	 * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
	 *      same structure as the ERC721 metadata.
	 */
	function tokenURI(uint256 _optionId) external view returns (string memory);

	/**
	 * @dev Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
	 */
	function supportsFactoryInterface() external view returns (bool);

	/**
	 * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
	 *      callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
	 *      Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
	 * @param _optionId the option id
	 * @param _toAddress address of the future owner of the asset(s)
	 */
	function mint(uint256 _optionId, address _toAddress) external;
}

/**
 * @dev An OpenSea delegate proxy interface which we use in ProxyRegistry.
 *      We use it to give compiler a hint that ProxyRegistry.proxies() needs to be
 *      converted to the address type explicitly
 */
interface OwnableDelegateProxy {}

/**
 * @dev OpenSea Proxy Registry determines which address (wrapped as OwnableDelegateProxy)
 *      is allowed to mint an option at any given time
 * @dev OpenSea takes care to set it properly when an option is being bought
 */
interface ProxyRegistry {
	/**
	 * @dev Maps owner address => eligible option minter address wrapped as OwnableDelegateProxy
	 */
	function proxies(address) external view returns(OwnableDelegateProxy);
}

/**
 * @title OpenSea ERC721 Factory implementation
 *
 * @notice OpenSea Factory interface implementation, NFT minter contract,
 *      powers the OpenSea sale of the 9,900 personalities of the 10k sale campaign
 *
 * @dev Links to PersonalityPodERC721 smart contract on deployment, allows OpenSea to mint
 *      PersonalityPodERC721 from 101 to 10,000 (both bounds inclusive)
 *
 * @dev Each OpenSea Factory option ID is used to signify the minting of one random type of
 *      Personality Pod
 */
contract OpenSeaFactoryImpl is OpenSeaFactoryERC721, AccessControl {
	/**
	 * @dev OpenSea expects Factory to be "Ownable", that is having an "owner",
	 *      we introduce a fake "owner" here with no authority
	 */
	address public owner;

	/**
	 * @dev NFT ERC721 contract address to mint NFTs from and bind to iNFTs created
	 */
	address public immutable nftContract;

	/**
	 * @dev OpenSea Proxy Registry determines which address is allowed to mint
	 *      an option at any given time
	 * @dev OpenSea takes care to set it to the NFT buyer address when they buy an option
	 */
	address public immutable proxyRegistry;

	/**
	 * @dev Number of options the factory supports,
	 *      options start from zero and end at `options` (exclusive)
	 */
	uint32 private options;

	/**
	 * @dev Base URI is used to construct option URI as
	 *      `base URI + option ID`
	 *
	 * @dev For example, if base URI is https://api.com/option/, then option #1
	 *      will have an URI https://api.com/option/1
	 */
	string public baseURI = "";

	/**
	 * @dev Initialized with the tokenId each optionId should start minting from,
	 *      incremented each time the option is minted
	 *
	 * @dev For each option, [currentTokenId[optionId], tokenIdUpperBound[optionId])
	 *      is the range of token IDs left to be minted
	 *
	 * @dev Maps optionId => next available (current) token ID for an option
	 */
	mapping(uint256 => uint256) public currentTokenId;

	/**
	 * @dev At what tokenId each optionId should end minting at (exclusive)
	 *
	 * @dev For each option, [currentTokenId[optionId], tokenIdUpperBound[optionId])
	 *      is the range of token IDs left to be minted
	 *
	 * @dev Maps optionId => final token ID (exclusive) for an option
	 */
	mapping(uint256 => uint256) public tokenIdUpperBound;

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	uint32 public constant ROLE_MINTER = 0x0001_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      which is used to construct URIs for each option
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @notice OpenSea manager is responsible for registering the factory
	 *      in OpenSea via "Transfer" event mechanism
	 *
	 * @dev Role ROLE_OS_MANAGER allows notifying OpenSea about the contract
	 *      "owner" change via emitting "Transfer" events read by the OpenSea
	 *      (executing `fireTransferEvents` function)
	 */
	uint32 public constant ROLE_OS_MANAGER = 0x0040_0000;

	/**
	 * @dev Fired in mint() when Alethea NFT is created
	 *
	 * @param _by an address which executed the mint function
	 * @param _optionId OpenSea option ID
	 * @param _to an address NFT was minted to
	 */
	event Minted(address indexed _by, uint256 _optionId, address indexed _to);

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev An event caught by the OpenSea for automatic factory registration
	 *      and assigning option "owner" to `to` address defined in the event
	 * @dev See: OpenSea docs and source code examples,
	 *      https://docs.opensea.io/docs/2-custom-sale-contract-viewing-your-sale-assets-on-opensea
	 */
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	/**
	 * @dev Creates/deploys the factory and binds it to NFT smart contract on construction
	 *
	 * @param _nft deployed NFT smart contract address; factory will mint NFTs of that type
	 * @param _proxyRegistry OpenSea proxy registry address
	 * @param _rangeBounds token ID ranges foreach option - the initial `currentTokenId` and `tokenIdUpperBound`
	 */
	constructor(address _nft, address _proxyRegistry, uint32[] memory _rangeBounds) {
		// verify the inputs are set
		require(_nft != address(0), "NFT contract is not set");
		require(_proxyRegistry != address(0), "OpenSea proxy registry is not set");

		// ensure there is at least one option (2 numbers for 1 range)
		require(_rangeBounds.length > 1, "invalid number of options");

		// verify range bound initial element is greater than 100
		require(_rangeBounds[0] > 100, "invalid range bound initial element");

		// verify inputs are valid smart contracts of the expected interfaces
		require(ERC165(_nft).supportsInterface(type(ERC721).interfaceId), "unexpected NFT type");
		require(ERC165(_nft).supportsInterface(type(ERC721Metadata).interfaceId), "unexpected NFT type");
		require(ERC165(_nft).supportsInterface(type(MintableERC721).interfaceId), "unexpected NFT type");

		// verify that range bounds elements increase (monotonically increasing)
		for(uint256 i = 0; i < _rangeBounds.length - 1; i++) {
			// compare current element and next element
			require(_rangeBounds[i] < _rangeBounds[i + 1], "invalid range bounds");
		}

		// assign the NFT address
		nftContract = _nft;
		// assign owner
		owner = msg.sender;
		// assign OpenSea Proxy Registry address
		proxyRegistry = _proxyRegistry;
		// number of options is derived from the range bounds array
		options = uint32(_rangeBounds.length - 1);

		// assign the appropriate start and upper bound for each optionId
		for(uint256 i = 0; i < _rangeBounds.length - 1; i++) {
			currentTokenId[i] = _rangeBounds[i];
			tokenIdUpperBound[i] = _rangeBounds[i + 1];
		}

		// fire events for each option
		fireTransferEvents(address(0), msg.sender);
	}

	/**
	 * @dev Restricted access function which updates base URI for optionIds
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(OpenSeaFactoryERC721).interfaceId;
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function name() public override view returns (string memory) {
		// delegate to super implementation
		return ERC721Metadata(nftContract).name();
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function symbol() public override view returns (string memory) {
		// delegate to super implementation
		return ERC721Metadata(nftContract).symbol();
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function numOptions() public override view returns (uint256) {
		// calculate based on 0-indexed options
		return options;
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function canMint(uint256 _optionId) public override view returns (bool) {
		// check valid optionId, bounds
		return _optionId < options && currentTokenId[_optionId] < tokenIdUpperBound[_optionId];
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function tokenURI(uint256 _optionId) public override view returns (string memory) {
		// concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_optionId, 10));
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function supportsFactoryInterface() public override pure returns (bool) {
		// use ERC165 supportsInterface to return `true`
		return supportsInterface(type(OpenSeaFactoryERC721).interfaceId);
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function mint(uint256 _optionId, address _toAddress) public override {
		// verify the access permission
		require(address(ProxyRegistry(proxyRegistry).proxies(owner)) == msg.sender, "access denied");

		// verify option ID can be minted
		require(canMint(_optionId), "cannot mint");

		// do the mint
		MintableERC721(nftContract).mint(_toAddress, currentTokenId[_optionId]);

		// emit an event before increasing
		emit Minted(msg.sender, currentTokenId[_optionId], _toAddress);

		// increment next tokenId
		currentTokenId[_optionId]++;
	}

	/**
	 * @dev Fires transfer events for each option. Used to change contract "owner"
	 *      See: OpenSea docs and source code examples,
	 *      https://docs.opensea.io/docs/2-custom-sale-contract-viewing-your-sale-assets-on-opensea
	 *
	 * @param _from transfer optionIds from
	 * @param _to transfer optionIds to
	 */
	function fireTransferEvents(address _from, address _to) public {
		// verify the access permission
		require(isSenderInRole(ROLE_OS_MANAGER), "access denied");

		// fire events for each option
		for (uint256 i = 0; i < options; i++) {
			emit Transfer(_from, _to, i);
		}
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use transferFrom so the frontend doesn't have to worry about different method names.
	 */
	function transferFrom(address _from, address _to, uint256 _tokenId) public {
		// simply delegate to `mint`
		mint(_tokenId, _to);
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
	 */
	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		// true if called by contract "owner" which is the token owner itself
		if(owner == _owner && _owner == _operator) {
			return true;
		}

		// lookup the registry
		return owner == _owner && address(ProxyRegistry(proxyRegistry).proxies(_owner)) == _operator;
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
	 */
	function ownerOf(uint256 _tokenId) public view returns (address _owner) {
		// return smart contract "owner"
		return owner;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Alethea Mintable ERC721
 *
 * @notice Defines mint capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 */
interface MintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Alethea Burnable ERC721
 *
 * @notice Defines burn capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

/**
 * @title With Base URI
 *
 * @notice A marker interface for the contracts having the baseURI() function
 *      or public string variable named baseURI
 *      NFT implementations like TinyERC721, or ShortERC721 are example of such smart contracts
 */
interface WithBaseURI {
	/**
	 * @dev Usually used in NFT implementations to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 */
	function baseURI() external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title String Utils Library
 *
 * @dev Library for working with strings, primarily converting
 *      between strings and integer types
 */
library StringUtils {
	/**
	 * @dev Converts a string to unsigned integer using the specified `base`
	 * @dev Throws on invalid input
	 *      (wrong characters for a given `base`)
	 * @dev Throws if given `base` is not supported
	 * @param a string to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return i a number representing given string
	 */
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// convert string into bytes for convenient iteration
		bytes memory buf = bytes(a);

		// iterate over the string (bytes buffer)
		for(uint256 p = 0; p < buf.length; p++) {
			// extract the digit
			uint8 digit = uint8(buf[p]) - 0x30;

			// if digit is greater then 10 - mind the gap
			// see `itoa` function for more details
			if(digit > 10) {
				// remove the gap
				digit -= 7;
			}

			// check if digit meets the base
			require(digit < base);

			// move to the next digit slot
			i *= base;

			// add digit to the result
			i += digit;
		}

		// return the result
		return i;
	}

	/**
	 * @dev Converts a integer to a string using the specified `base`
	 * @dev Throws if given `base` is not supported
	 * @param i integer to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return a a string representing given integer
	 */
	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// for zero input the result is "0" string for any base
		if(i == 0) {
			return "0";
		}

		// bytes buffer to put ASCII characters into
		bytes memory buf = new bytes(256);

		// position within a buffer to be used in cycle
		uint256 p = 0;

		// extract digits one by one in a cycle
		while(i > 0) {
			// extract current digit
			uint8 digit = uint8(i % base);

			// convert it to an ASCII code
			// 0x20 is " "
			// 0x30-0x39 is "0"-"9"
			// 0x41-0x5A is "A"-"Z"
			// 0x61-0x7A is "a"-"z" ("A"-"Z" XOR " ")
			uint8 ascii = digit + 0x30;

			// if digit is greater then 10,
			// fix the 0x3A-0x40 gap of punctuation marks
			// (7 characters in ASCII table)
			if(digit >= 10) {
				// jump through the gap
				ascii += 7;
			}

			// write character into the buffer
			buf[p++] = bytes1(ascii);

			// move to the next digit
			i /= base;
		}

		// `p` contains real length of the buffer now,
		// allocate the resulting buffer of that size
		bytes memory result = new bytes(p);

		// copy the buffer in the reversed order
		for(p = 0; p < result.length; p++) {
			// copy from the beginning of the original buffer
			// to the end of resulting smaller buffer
			result[result.length - p - 1] = buf[p];
		}

		// construct string and return
		return string(result);
	}

	/**
	 * @dev Concatenates two strings `s1` and `s2`, for example, if
	 *      `s1` == `foo` and `s2` == `bar`, the result `s` == `foobar`
	 * @param s1 first string
	 * @param s2 second string
	 * @return s concatenation result s1 + s2
	 */
	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		// an old way of string concatenation (Solidity 0.4) is commented out
/*
		// convert s1 into buffer 1
		bytes memory buf1 = bytes(s1);
		// convert s2 into buffer 2
		bytes memory buf2 = bytes(s2);
		// create a buffer for concatenation result
		bytes memory buf = new bytes(buf1.length + buf2.length);

		// copy buffer 1 into buffer
		for(uint256 i = 0; i < buf1.length; i++) {
			buf[i] = buf1[i];
		}

		// copy buffer 2 into buffer
		for(uint256 j = buf1.length; j < buf2.length; j++) {
			buf[j] = buf2[j - buf1.length];
		}

		// construct string and return
		return string(buf);
*/

		// simply use built in function
		return string(abi.encodePacked(s1, s2));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}