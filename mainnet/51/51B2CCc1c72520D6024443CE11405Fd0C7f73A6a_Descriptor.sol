// SPDX-License-Identifier: GPL-3.0

/// @title The Wizards NFT descriptor

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IDescriptor} from "./IDescriptor.sol";
import {ISeeder} from "../seeder/ISeeder.sol";
import {NFTDescriptor} from "../libs/NFTDescriptor.sol";
import {MultiPartRLEToSVG} from "../libs/MultiPartRLEToSVG.sol";

contract Descriptor is IDescriptor, Ownable {
    using Strings for uint256;

    // Whether or not new parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Skins (Custom RLE)
    bytes[] public override skins;

    // Clothes (Custom RLE)
    bytes[] public override clothes;

    // Accessories (Custom RLE)
    bytes[] public override accessory;

    // BgItems (orb, staff, etc) (Custom RLE)
    bytes[] public override bgItems;

    // Mouths (Custom RLE)
    bytes[] public override mouths;

    // Eyes (Custom RLE)
    bytes[] public override eyes;

    // Hats (Custom RLE)
    bytes[] public override hats;

    // 1-1 wizards (Custom RLE)
    bytes[] public override oneOfOnes;

    uint256 public lastOneOfOneCount;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, "Parts are locked");
        _;
    }

    /**
     * @notice Get the number of available `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice One of ones count.
     */
    function oneOfOnesCount() external view override returns (uint256) {
        return oneOfOnes.length;
    }

    /**
     * @notice Get the number of available `skins`.
     */
    function skinsCount() external view override returns (uint256) {
        return skins.length;
    }

    /**
     * @notice Get the number of available `clothes`.
     */
    function clothesCount() external view override returns (uint256) {
        return clothes.length;
    }

    /**
     * @notice Get the number of available `accesories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return accessory.length;
    }

    /**
     * @notice Get the number of available `bg items`.
     */
    function bgItemsCount() external view override returns (uint256) {
        return bgItems.length;
    }

    /**
     * @notice Get the number of available `hats`.
     */
    function hatsCount() external view override returns (uint256) {
        return hats.length;
    }

    /**
     * @notice Get the number of available `mouths`.
     */
    function mouthsCount() external view override returns (uint256) {
        return mouths.length;
    }

    /**
     * @notice Get the number of available `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(
        uint8 paletteIndex,
        string[] calldata newColors
    ) external override onlyOwner {
        require(
            palettes[paletteIndex].length + newColors.length <= 256,
            "Palettes can only hold 256 colors"
        );
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Replaces colors in a color palette.
     * @dev This function can only be called by the owner and should only
     * be used administratively to restore proper palette indexes.
     */
    function replacePalette(uint8 paletteIndex, string[] calldata newColors)
        external
        onlyOwner
    {
        require(newColors.length <= 256, "Palettes can only hold 256 colors");

        delete palettes[paletteIndex];
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add skins.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySkins(bytes[] calldata _skins)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _skins.length; i++) {
            _addSkin(_skins[i]);
        }
    }

    /**
     * @notice Batch add hats.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHats(bytes[] calldata _hats)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _hats.length; i++) {
            _addHat(_hats[i]);
        }
    }

    /**
     * @notice Batch add eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add mouths.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMouths(bytes[] calldata _mouths)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _mouths.length; i++) {
            _addMouth(_mouths[i]);
        }
    }

    /**
     * @notice Batch add bg items.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBgItems(bytes[] calldata _bgItems)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _bgItems.length; i++) {
            _addBgItem(_bgItems[i]);
        }
    }

    /**
     * @notice Batch add accessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyAccessories(bytes[] calldata _accessory)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _accessory.length; i++) {
            _addAccessory(_accessory[i]);
        }
    }

    /**
     * @notice Batch add clothes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyClothes(bytes[] calldata _clothes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _clothes.length; i++) {
            _addClothes(_clothes[i]);
        }
    }

    /**
     * @notice Batch add one of one Wizards.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyOneOfOnes(bytes[] calldata _oneOfOnes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        lastOneOfOneCount += _oneOfOnes.length;

        for (uint256 i = 0; i < _oneOfOnes.length; i++) {
            _addOneOfOne(_oneOfOnes[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color)
        external
        override
        onlyOwner
    {
        require(
            palettes[_paletteIndex].length <= 255,
            "Palettes can only hold 256 colors"
        );
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a one of one wizards.
     * @dev This function can only be called by the owner when not locked.
     */
    function addOneOfOne(bytes calldata _oneOfOne)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        lastOneOfOneCount += 1;
        _addOneOfOne(_oneOfOne);
    }

    /**
     * @notice Add a background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addBackground(_background);
    }

    /**
     * @notice Add a skin.
     * @dev This function can only be called by the owner when not locked.
     */
    function addSkin(bytes calldata _skin)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addSkin(_skin);
    }

    /**
     * @notice Add wizard hat.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHat(bytes calldata _hat)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addHat(_hat);
    }

    /**
     * @notice Add a clothes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addClothes(bytes calldata _clothes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addClothes(_clothes);
    }

    /**
     * @notice Add a bg item.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBgItem(bytes calldata _bgItem)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addBgItem(_bgItem);
    }

    /**
     * @notice Add a accessory.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessory(bytes calldata _accessory)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addAccessory(_accessory);
    }

    /**
     * @notice Add a mouth.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMouth(bytes calldata _mouth)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addMouth(_mouth);
    }

    /**
     * @notice Add eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes)
        external
        override
        onlyOwner
        whenPartsNotLocked
    {
        _addEyes(_eyes);
    }

    /**
     * @notice Lock all parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI.
     */
    function dataURI(uint256 tokenId, ISeeder.Seed memory seed)
        public
        view
        override
        returns (string memory)
    {
        string memory wizardId = tokenId.toString();
        string memory name = string(abi.encodePacked("Wizard #", wizardId));

        string memory description = "";
        if (seed.oneOfOne) {
            description = string(
                abi.encodePacked(
                    "Wizard #",
                    wizardId,
                    " is a one of one artpiece and a member of the WizardsDAO"
                )
            );
        } else {
            description = string(
                abi.encodePacked(
                    "Wizard #",
                    wizardId,
                    " is a member of the WizardsDAO"
                )
            );
        }

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        ISeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor
            .TokenURIParams({
                name: name,
                description: description,
                parts: _getPartsForSeed(seed),
                background: backgrounds[seed.background]
            });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(ISeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG
            .SVGParams({
                parts: _getPartsForSeed(seed),
                background: backgrounds[seed.background]
            });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color)
        internal
    {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a single one of one wizard.
     */
    function _addOneOfOne(bytes calldata _oneOfOne) internal {
        oneOfOnes.push(_oneOfOne);
    }

    /**
     * @notice Add a background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a skin.
     */
    function _addSkin(bytes calldata _skin) internal {
        skins.push(_skin);
    }

    /**
     * @notice Add clothes.
     */
    function _addClothes(bytes calldata _clothes) internal {
        clothes.push(_clothes);
    }

    /**
     * @notice Add accessories.
     */
    function _addAccessory(bytes calldata _accessory) internal {
        accessory.push(_accessory);
    }

    /**
     * @notice Add bg items.
     */
    function _addBgItem(bytes calldata _bgItem) internal {
        bgItems.push(_bgItem);
    }

    /**
     * @notice Add a mouth.
     */
    function _addMouth(bytes calldata _mouth) internal {
        mouths.push(_mouth);
    }

    /**
     * @notice Add eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }

    /**
     * @notice Add hat.
     */
    function _addHat(bytes calldata _hat) internal {
        hats.push(_hat);
    }

    /**
     * @notice Get all parts for the passed `seed`.
     */
    function _getPartsForSeed(ISeeder.Seed memory seed)
        internal
        view
        returns (bytes[] memory)
    {
        if (seed.oneOfOne) {
            bytes[] memory _oneOfOneParts = new bytes[](1);
            _oneOfOneParts[0] = oneOfOnes[seed.oneOfOneIndex];
            return _oneOfOneParts;
        }

        bytes[] memory _parts = new bytes[](7);
        _parts[0] = skins[seed.skin];
        _parts[1] = clothes[seed.clothes];
        _parts[2] = eyes[seed.eyes];
        _parts[3] = mouths[seed.mouth];
        _parts[4] = accessory[seed.accessory];
        _parts[5] = bgItems[seed.bgItem];
        _parts[6] = hats[seed.hat];

        return _parts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

/// @title Interface for Descriptor

pragma solidity ^0.8.6;

import { ISeeder } from '../seeder/ISeeder.sol';

interface IDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);    

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;


    function backgrounds(uint256 index) external view returns (string memory);    

    function backgroundCount() external view returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;    

    
    
    function oneOfOnes(uint256 index) external view returns (bytes memory);

    function oneOfOnesCount() external view returns (uint256);

    function addOneOfOne(bytes calldata _oneOfOne) external;

    function addManyOneOfOnes(bytes[] calldata _oneOfOnes) external;    


    function skins(uint256 index) external view returns (bytes memory);

    function skinsCount() external view returns (uint256);

    function addManySkins(bytes[] calldata skins) external;

    function addSkin(bytes calldata skin) external;


    function hats(uint256 index) external view returns (bytes memory);

    function hatsCount() external view returns (uint256);

    function addManyHats(bytes[] calldata hats) external;

    function addHat(bytes calldata hat) external;

    
    function clothes(uint256 index) external view returns (bytes memory);

    function clothesCount() external view returns (uint256);

    function addManyClothes(bytes[] calldata ears) external;

    function addClothes(bytes calldata ear) external;


    function mouths(uint256 index) external view returns (bytes memory);

    function mouthsCount() external view returns (uint256);

    function addManyMouths(bytes[] calldata mouths) external;

    function addMouth(bytes calldata mouth) external;

    
    function eyes(uint256 index) external view returns (bytes memory);

    function eyesCount() external view returns (uint256);

    function addManyEyes(bytes[] calldata eyes) external;

    function addEyes(bytes calldata eye) external;


    function accessory(uint256 index) external view returns (bytes memory);

    function accessoryCount() external view returns (uint256);

    function addManyAccessories(bytes[] calldata noses) external;

    function addAccessory(bytes calldata nose) external;


    function bgItems(uint256 index) external view returns (bytes memory);

    function bgItemsCount() external view returns (uint256);

    function addManyBgItems(bytes[] calldata noses) external;

    function addBgItem(bytes calldata nose) external;


    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        ISeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(ISeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Seeder

pragma solidity ^0.8.6;

import { IDescriptor } from '../descriptor/IDescriptor.sol';

// "Skin", "Cloth", "Eye", "Mouth", "Acc", "Item", "Hat"
interface ISeeder {
    struct Seed {
        uint48 background;
        uint48 skin;
        uint48 clothes;
        uint48 eyes;
        uint48 mouth;
        uint48 accessory;
        uint48 bgItem;
        uint48 hat;
        bool oneOfOne;
        uint48 oneOfOneIndex;
    }

    function generateSeed(uint256 wizardId, IDescriptor descriptor, bool isOneOfOne, uint48 isOneOfOneIndex) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

pragma solidity ^0.8.6;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            MultiPartRLEToSVG.SVGParams({ parts: params.parts, background: params.background }),
            palettes
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

pragma solidity ^0.8.6;

library MultiPartRLEToSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
    }

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="190" height="190" viewBox="0 0 190 190" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     * This is a lookup table that enables very cheap int to string
     * conversions when operating on a set of predefined integers.
     * This is used below to convert the integer length of each rectangle
     * in a 19x19 pixel grid to the string representation of the length
     * in a 190x190 pixel grid, which is the chosen dimension for all Wizards.
     * For example: A length of 3 gets mapped to '30'.
     */    
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        string[20] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190'
        ];
        string memory rects;
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}