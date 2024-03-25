// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

// KKKKKKKKKKKKKKKKKKKKKKKKXXXNNNNNNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKXXXNXXNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxddxk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKko:;;;::::::cok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNNNXXKKKKKKKKKKKKKK
// XKKKKKKKKKKKKKKKKKKKKKKKKkc',cdkO00Okdc,..;ldolllllllcccccclodxkO0KKKKKKKKKKKKKXXXXXKKKKKKKKKKKKKKKK
// XKKKKKKKKKKKKKKKKKKKKKKkc',ok00Oxoc;;;;,.....':lloooooooolllc::;,;;coxkO0KKKKKKKXKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKOl''lk0Oxl;,,codl;';cllc:dOOOOOOOOOOOOO00Okxdl:;,'',;:oxO0KKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKK0o,'cx0Od:',cdOkl,'cdOOO0OOOOOOOOOOOOOOOOOOOOOOOOOkxolc:;,';cd0KKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKO:.;xO0kc.,lk00Ol.;xOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOO0OOkdl;.,d0KKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKO:.:k0Ox,.:k0000x,'xOOOOOxolcclxO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOd,.:odkKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKK0c.;k00d,.lO0000Oc.lOOOdc,',:c:,';:lkOOOOOOOOOOOOOOOOOOOOOOOOOOOd;;o;.'cOKKKKKKKKKKK
// KKKKKKKKKKKKKKK0l.;x00x,.oO00000x,,xOo;.,lOXWMWXx,..,dOOOOOOOOOOOOOOOOOOOOOOOOOd';KW0l'.c0KKKKKKKKKK
// KKKKKKKKKKKKKK0l.,x00O:.lO00000k;'okl.'dXWMMMMMMMKk:.;x0OOOOOOOOOOOOOOOOOOOOOOOl.;KMMNx.'kKKKKKKKKKK
// KKKKKKKKKKKKXKo.,x000x,;k00000Oc.ckl.'xWMMMMMMMMMMM0,.lOOOOOOOOOOOOkkxkkkOOOOO0x,.c0WWx.;OKKKKKKKKKK
// KKKKKKKKKKXXKo.,dO000OodO0000x:.:kd'.cXMNOd0MMMMMMMX:.cOOOOOOOkoc:;,,,,,,;:dOOOOl..'::''dKKKKKKKKKKK
// KKKXXXXXXXNKl.,x00000000000Oo''lk0o..cXNo..ckKWMMMMK;.cOOOOOkl;:clodxxddolcoOOOOkddoc:,';oOKKKKKKKKK
// KKXXNNNNNNXd.,x00000000000kc.,dOO0d'.'k0;''.'xWMMNKo.'dOOOOOOxkOO0OOOOOOO0OOOOOOOOOO0Okd:.;kKKKKKKKK
// KKXXNNNNNNK:.lO000000000Ox;.;xOOOOOc..,dddooONN0d;'.'oOOOOOOOOOOOOOOOOOOxoxOOOOOOxxOOOO0Oc.:OXXXKKKK
// KKKXXXNNXNK:.l00000000Od:'.:kOOOOOOkl'..':ccc:;...':dOOOOOOOOOOOOOOOOOOOx:,oOOOkc;oOOOOO0d''kNXXXXXK
// KKKKKXXXNNXl.:O000000Ol...,x0OOOOOOOOxc;'.....';lxkOOOOOOOOOOOOOOOOOOOOOOOllkO0xcdOOOOOO0x,.xNNNNNXX
// KKKKKKKXXXNx.,k00000Ol....cOOOOOOOOOOO0OkxdoodxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0k,.dNNNNNNX
// KKKKKKKKKKXk''x00000x,.'.,x0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOO0000OOOOOOO0x,.dNNNNNNX
// KKKKKKKKKKXk'.d00000d'...lOOOOOOOOOOOOOOOOOOOOOOOOOOOOxo:;;;:cdkOO0OOOOOOkxolccccldxkO00Ol.;ONNNXNNN
// KKKKKKKKKKXO;.o000O0o...,x0OOOOOOOOOOOOOOOOOOOkkkxdl:;'.,ll,,:;,;:looolc;,..,cl,....';:c;.;OXXNNNNNN
// KKKKKKKKKKK0c.lO000k;...cOOOOOOOOOOOOOOOOOdc;,,''......:dxdd0XKOxolllllod:..';,..........lKNNNNNNNNN
// KKKKKKKKKKKKo.;k00Oc...'d0OOOOOOOOOOOOOOx:..............oKXXXXXXXXXXXXXXXk,.............,ONXNNNNNNNN
// KKKKKKKKKKKKO;.o0Oc.''.:kOOOOOOOOOOOOOOOl:clccccccccccc:;:kXXXXXXXXXXXXXXXx'.:lllllooo;.cKNNXNNNNNNN
// KKKKKKKKKKKKKd''c,.:c.'dOOOOOOOOOOOOOOOOOOOOOO00O0000000k:,xXXXKxlxKXXXXXKOkc,lOOOOO0x,.dXNNNXXXXXXX
// KKKKKKKKKKKKKKxc:lo:'.,okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0d'cKXXd;l:c0XXXKx:d0l.ckOOOx;.c0KKXXXXKKKKK
// KKKKKKKKKKKKKKKKKk;.;;'.';lkOOOOOOOOOOOOOOOOOOOOOOOOOOOO0o.cKXKlcKk;oXXXXkokXO;.lOkl''lOKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKk,.:oooc;..'cdkO0OOOOOOOOOOOOOOOOkxxdxxkx;.dXX0coNK::0XXXXXXXXo.':,.:kKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKx,.;ooooool:,'.,:loxkOOOOOOOOOOOOd:,,,,,,'.c0XXO:dNK::KXXXXXXXXx'.;lk0KKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKx'.;oooooooooolc:,''',;:clodxxkkOOOkkkkxxo',kXXXKdlol:dXXXXXXXXXd..:kKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKd'.:oooooooooooooooollc;;,'''''',,,;;;;:::;.cKXXXXXKOO0XXXXXXXXXk,.'.'o0KKKKKKKKKKKKKKK
// KKKKKKKKKKKKo..:ooooooooooooooooooooooooollccc:::;;;;;,'.lKXXXXXXXXXXXXXXXXX0:.;lc'.c0KKKKKKKKKKKKKK
// KKKKKKKKKKKo..:oooooooooooooooooooooooooooooooooooooooo;.cKXXXXXXXXXXXXKkk0Xd.'lool'.c0KKKKKKKKKKKKK
// KKKKKKKKKKd'.:ooooooooooooooooooooooooooooooooooooooooo:.,kXXXXXXXXXXXOllococ.,ccooc'.oKKKKKKKKKKKKK
// KKKKKKKKKx'.;ooooooooooooooooooooooo:,colllooooooooooool,.:0XXXXXXXXXXolKNo;:...'loo:.,xKKKKKKKKKKKK
// KKKKKKKK0c.'coooooooooooool:;;;:lool'.,;;;,,;looooooooool'.c0XXXXXXXXXd:OWx:dc...;lol,.:0KKKKKKKKKKK
// KKKKKKKKO:.,loooooooooooc;,,;;'.:ooc..:lllc:'';loooooooooc'.c0XXXXXXXX0::xl:OO;...coo:.'xKKKKKKKKKKK
// KKKKKKKXO;.;oooooooooool,,clll;.,oo:..:lllllc;.'coooooooooc.'kXXXXXXXXXO:';xXXx'..;ool'.lKKKXXXXXKKK

contract KevinKaijuz is ERC721Enum {
  using Strings for uint256;

  uint256 public constant SUPPLY = 7777;
  uint256 public constant MAX_MINT_PER_TX = 10;
  uint256 public freeSupply = 555;
  uint256 public price = 0.00777 ether;
  
  address private constant addressOne = 0xF27a3f8823c47e35E863dF2F853895fb5741994E;
  address private constant addressTwo = 0x6E39Ff2fD5CEDEf3F4968843ce2a05cD9f6aD4D0;


  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("KevinKaijuz", "KKJ") {
    owner = msg.sender;
  }

  modifier mintOpen() {
    require(!pauseMint, "mint paused");
    _;
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  /** INTERNAL */ 

  function _onlyOwner() private view {
    require(msg.sender == owner, "onlyOwner");
  }

  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  /** Mint NFT */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max10perTX"
    );
    require(
      currentSupply + amountPurchase <= SUPPLY,
      "soldout"
    );
    if(currentSupply > freeSupply) {
      require(msg.value >= price * amountPurchase, "not enough eth");
    }
    for (uint8 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }
  
  /** Get tokenURI */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent meow");

    string memory currentBaseURI = _baseURI();

    return (
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : ""
    );
  }

  /** ADMIN SetPauseMint*/

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    pauseMint = _setPauseMint;
  }

  /** ADMIN SetBaseURI*/

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  /** ADMIN SetFreeSupply*/

  function setFreeSupply(uint256 _freeSupply) external onlyOwner {
    freeSupply = _freeSupply;
  }

  /** ADMIN SetPrice*/

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /** ADMIN withdraw*/

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(addressOne, (balance * 32) / 100);
    _withdraw(addressTwo, (balance * 64) / 100);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "ERC721P.sol";
import "IERC721Enumerable.sol";

abstract contract ERC721Enum is ERC721P, IERC721Enumerable {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721P)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256 tokenId)
  {
    require(index < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (owner == _owners[i]) {
        if (count == index) return i;
        else ++count;
      }
    }
    require(false, "ERC721Enum: owner ioob");
  }

  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    require(0 < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _owners.length;
  }

  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(index < ERC721Enum.totalSupply(), "ERC721Enum: global ioob");
    return index;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "ERC165.sol";

abstract contract ERC721P is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  string private _name;
  string private _symbol;
  address[] internal _owners;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    uint256 count = 0;
    uint256 length = _owners.length;
    for (uint256 i = 0; i < length; ++i) {
      if (owner == _owners[i]) {
        ++count;
      }
    }
    delete length;
    return count;
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721P.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _owners.length && _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721P.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);
    _owners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721P.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    _owners[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721P.ownerOf(tokenId) == from,
      "ERC721: transfer of token that is not own"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721P.ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}