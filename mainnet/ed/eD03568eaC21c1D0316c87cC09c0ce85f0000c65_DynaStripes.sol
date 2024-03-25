// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC2981/ERC2981PerTokenRoyalties.sol";
import "./DynaTokenBase.sol";
import "./ColourWork.sol";
import "./StringUtils.sol";
import "./DynaModel.sol";
import "./DynaTraits.sol";

contract DynaStripes is DynaTokenBase, ERC2981PerTokenRoyalties {
    uint16 public constant TOKEN_LIMIT = 1119; // first digits of "dyna" in ascii: (100 121 110 97) --> 1119
    uint16 public constant ROYALTY_BPS = 1000;
    bool private descTraitsEnabled = true;
    uint16 private tokenLimit = 100;
    uint16 private tokenIndex = 0;
    mapping(uint16 => DynaModel.DynaParams) private dynaParamsMapping;
    mapping(uint24 => bool) private usedRandomSeeds;
    uint256 private mintPrice = 0.01 ether;

    constructor() DynaTokenBase("DynaStripes", "DSS") { }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(DynaTokenBase, ERC2981PerTokenRoyalties)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // for OpenSea
    function contractURI() public pure returns (string memory) {
        return "https://www.dynastripes.com/storefront-metadata";
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getTokenLimit() public view returns (uint16) {
        return tokenLimit;
    }
    function setTokenLimit(uint16 _tokenLimit) public onlyOwner {
        if (_tokenLimit > TOKEN_LIMIT) {
            _tokenLimit = TOKEN_LIMIT;
        }
        tokenLimit = _tokenLimit;
    }

    function getDescTraitsEnabled() public view returns (bool) {
        return descTraitsEnabled;
    }
    function setDescTraitsEnabled(bool _enabled) public onlyOwner {
        descTraitsEnabled = _enabled;
    }

    function payOwner(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Amount too high");
        address payable owner = payable(owner());
        owner.transfer(amount);
    }

    receive() external payable { }

    function mintStripes(uint24 _randomSeed, 
                         uint8 _zoom,
                         uint8 _tintRed,
                         uint8 _tintGreen,
                         uint8 _tintBlue,
                         uint8 _tintAlpha,
                         uint8 _rotationMin, 
                         uint8 _rotationMax, 
                         uint8 _stripeWidthMin, 
                         uint8 _stripeWidthMax, 
                         uint8 _speedMin, 
                         uint8 _speedMax) public payable {
        uint16 tokenId = tokenIndex;
        require(tokenId < tokenLimit && tokenId < TOKEN_LIMIT, "Token limit reached");
        require(msg.value >= getMintPrice(), "Not enough ether");
        require(_zoom <= 100, "Zoom invalid");
        require(_tintRed <= 255, "tint red invalid");
        require(_tintGreen <= 255, "tint green invalid");
        require(_tintBlue <= 255, "tint blue invalid");
        require(_tintAlpha < 230, "tint alpha invalid");
        require(_rotationMax <= 180 && _rotationMin <= _rotationMax, "Rotation invalid");
        require(_stripeWidthMin >= 25 && _stripeWidthMax <= 250 && _stripeWidthMin <= _stripeWidthMax, "Stripe width invalid");
        require(_speedMin >= 25 && _speedMax <= 250 && _speedMin <= _speedMax, "Speed value invalid");
        require(_randomSeed < 5000000 && usedRandomSeeds[_randomSeed] == false, "Random seed invalid");

        _safeMint(msg.sender, tokenId);
        _setTokenRoyalty(tokenId, msg.sender, ROYALTY_BPS);
        dynaParamsMapping[tokenId] = DynaModel.DynaParams(_randomSeed, _zoom, _tintRed, _tintGreen, _tintBlue, _tintAlpha, _rotationMin, _rotationMax, _stripeWidthMin, _stripeWidthMax, _speedMin, _speedMax);
        usedRandomSeeds[_randomSeed] = true;

        tokenIndex += 1;
    }

    function banRandomSeeds(uint24[] memory seeds) public onlyOwner {
        for (uint i; i < seeds.length; i++) {
            usedRandomSeeds[seeds[i]] = true;
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(_tokenId), "token ID doesn't exist");
        require(_tokenId < TOKEN_LIMIT, "token ID doesn't exist");

        string memory copyright = string(abi.encodePacked("\"copyright\": \"The owner of this NFT is its legal copyright holder. By selling this NFT, the seller/owner agrees to assign copyright to the buyer. All buyers and sellers agree to payment of royalties to the original minter on sale of the artwork.\""));

        string memory traits = DynaTraits.getTraits(descTraitsEnabled, dynaParamsMapping[uint16(_tokenId)]);
        string memory svg = generateSvg(_tokenId);
        return string(abi.encodePacked("data:text/plain,{\"name\":\"DynaStripes #", StringUtils.uint2str(_tokenId), "\", \"description\":\"on-chain, generative DynaStripes artwork\", ", copyright, ", ", traits, ", \"image\":\"data:image/svg+xml,", svg, "\"}")); 
    }
    
    function generateSvg(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "token ID doesn't exist");
        require(_tokenId < TOKEN_LIMIT, "token ID doesn't exist");

        DynaModel.DynaParams memory dynaParams = dynaParamsMapping[uint16(_tokenId)];
        (string memory viewBox, string memory clipRect) = getViewBoxClipRect(dynaParams.zoom);
        string memory rendering = dynaParams.rotationMin == dynaParams.rotationMax ? "crispEdges" : "auto";
        string memory defs = string(abi.encodePacked("<defs><clipPath id='masterClip'><rect ", clipRect, "/></clipPath></defs>"));
        string memory rects = getRects(dynaParams);

        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='", viewBox, "' shape-rendering='", rendering, "'>", defs, "<g clip-path='url(#masterClip)'>", rects, "</g></svg>"));
    }

    function getViewBoxClipRect(uint _zoom) private pure returns (string memory, string memory) {
        _zoom = _zoom * 20;
        string memory widthHeight = StringUtils.uint2str(1000 + _zoom);

        if (_zoom > 1000) {
            string memory offset = StringUtils.uint2str((_zoom - 1000) / 2);
            string memory viewBox = string(abi.encodePacked("-", offset, " -", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='-", offset, "' y='-", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));
            return (viewBox, clipRect);
        } else {
            string memory offset = StringUtils.uint2str((_zoom == 1000 ? 0 : (1000 - _zoom) / 2));
            string memory viewBox = string(abi.encodePacked(offset, " ", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='", offset, "' y='", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));

            return (viewBox, clipRect);
        }
    }

    function getRects(DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint randomSeed = _dynaParams.randomSeed;
        uint xPos = 0;
        string memory rects = "";

        while ((2000 - xPos) > 0) {

            uint stripeWidth = randomIntFromInterval(randomSeed, _dynaParams.stripeWidthMin, _dynaParams.stripeWidthMax) * 2;
    
            if (stripeWidth > 2000 - xPos) {
                stripeWidth = 2000 - xPos;
            } else if ((2000 - xPos) - stripeWidth < _dynaParams.stripeWidthMin) {
                stripeWidth += (2000 - xPos) - stripeWidth;
            }

            string memory firstColour = getColour(randomSeed + 3, _dynaParams);
            string memory colours = string(abi.encodePacked(firstColour, ";", getColour(randomSeed + 13, _dynaParams), ";", firstColour));
            
            rects = string(abi.encodePacked(rects, "<rect x='", StringUtils.uint2str(xPos), "' y='0' width='", StringUtils.uint2str(stripeWidth), "' height='2000' fill='", firstColour, "' opacity='0.8'", " transform='rotate(",  getRotation(randomSeed + 1, _dynaParams), " 1000 1000)'><animate begin= '0s' dur='", getSpeed(randomSeed + 2, _dynaParams), "ms' attributeName='fill' values='", colours, ";' fill='freeze' repeatCount='indefinite'/></rect>"));
            
            xPos += stripeWidth;
            randomSeed += 100;
        }

        return rects; 
    }

    function getRotation(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint rotation = randomIntFromInterval(_randomSeed, _dynaParams.rotationMin, _dynaParams.rotationMax);
        return StringUtils.smallUintToString(rotation);
    }

    function getSpeed(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint speed = randomIntFromInterval(_randomSeed, _dynaParams.speedMin, _dynaParams.speedMax) * 20;
        return StringUtils.uint2str(speed);
    }

    function getColour(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint red = ColourWork.safeTint(randomIntFromInterval(_randomSeed, 0, 255), _dynaParams.tintRed, _dynaParams.tintAlpha);
        uint green = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 1, 0, 255), _dynaParams.tintGreen, _dynaParams.tintAlpha);
        uint blue = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 2, 0, 255), _dynaParams.tintBlue, _dynaParams.tintAlpha);

        return string(abi.encodePacked("rgb(", StringUtils.smallUintToString(red), ", ", StringUtils.smallUintToString(green), ", ", StringUtils.smallUintToString(blue), ")"));
    }

    // ----- Utils

    function randomIntFromInterval(uint _randomSeed, uint _min, uint _max) private pure returns (uint) {
        if (_max <= _min) {
            return _min;
        }

        uint seed = uint(keccak256(abi.encode(_randomSeed)));
        return uint(seed % (_max - _min)) + _min;
    }
}

// Love you John, Christine, Clara and Lynus! 😁❤️

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        _royalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract DynaTokenBase is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library ColourWork {

    function safeTint(uint colourComponent, uint tintComponent, uint alpha) internal pure returns (uint) {        
        unchecked {
            if (alpha == 0) {
                return uint8(colourComponent);
            }
            uint safelyTinted;

            if (colourComponent <= tintComponent) {
                uint offset = ((tintComponent - colourComponent) * alpha) / 255; 
                safelyTinted = colourComponent + offset;            
            } else {
                uint offset = ((colourComponent - tintComponent) * alpha) / 255; 
                safelyTinted = colourComponent - offset;
            }

            return uint8(safelyTinted);            
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library StringUtils {
    function uint2str(uint _i) internal pure returns (string memory str) {
        unchecked {
            if (_i == 0) {
                return "0";
            }

            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }

            bytes memory bstr = new bytes(length);
            uint k = length;
            j = _i;
            while (j != 0) {
                bstr[--k] = bytes1(uint8(48 + j % 10));
                j /= 10;
            }
            
            str = string(bstr);
        }
    }

    // ONLY TO BE USED FOR 8 BIT INTS! Not specifying type to save gas
    function smallUintToString(uint _i) internal pure returns (string memory) {
        require(_i < 256, "input to big");
        unchecked {
            if (_i == 0) {
                return "0";
            }

            bytes memory bstr;

            if (_i < 10) {
                // 1 byte
                bstr = new bytes(1);

                bstr[0] = bytes1(uint8(48 + _i % 10));

            } else if (_i < 100) {
                // 2 bytes
                bstr = new bytes(2);
                bstr[1] = bytes1(uint8(48 + _i % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 10) % 10));
            } else {
                // greater than 100
                bstr = new bytes(3);
                bstr[2] = bytes1(uint8(48 + _i % 10));
                bstr[1] = bytes1(uint8(48 + (_i / 10) % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 100) % 10));
            }
        return string(bstr);
        }
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library DynaModel {
    struct DynaParams {
        uint24 randomSeed;
        uint8 zoom; // 0 - 100
        uint8 tintRed; // 0 - 255
        uint8 tintGreen; // 0 - 255
        uint8 tintBlue; // 0 - 255
        uint8 tintAlpha; // 0 - 255
        uint8 rotationMin; // 0 - 180
        uint8 rotationMax; // 0 - 180
        uint8 stripeWidthMin; // 25 - 250
        uint8 stripeWidthMax; // 25 - 250
        uint8 speedMin; // 25 - 250 
        uint8 speedMax; // 25 - 250
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DynaModel.sol";
import "./StringUtils.sol";

library DynaTraits {

    function getTraits(bool descTraitsEnabled, DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {

        string memory zoomTraits = string(abi.encodePacked("{\"trait_type\": \"zoom\", \"value\": \"", StringUtils.smallUintToString(dynaParams.zoom), "\"}")); 
        string memory tintColour = string(abi.encodePacked(StringUtils.smallUintToString(dynaParams.tintRed), " ", StringUtils.smallUintToString(dynaParams.tintGreen), " ", StringUtils.smallUintToString(dynaParams.tintBlue), " ", StringUtils.smallUintToString(dynaParams.tintAlpha))); 
        string memory tintTraits = string(abi.encodePacked("{\"trait_type\": \"tint colour\", \"value\": \"", tintColour, "\"}")); 
        string memory rotationTraits = string(abi.encodePacked("{\"trait_type\": \"rotation min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.rotationMin), "\"}, {\"trait_type\": \"rotation max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.rotationMax), "\"}")); 
        string memory widthTraits = string(abi.encodePacked("{\"trait_type\": \"stripe width min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.stripeWidthMin), "\"}, {\"trait_type\": \"stripe width max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.stripeWidthMax), "\"}"));
        string memory speedTraits = string(abi.encodePacked("{\"trait_type\": \"speed min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.speedMin), "\"}, {\"trait_type\": \"speed max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.speedMax), "\"}"));

        if (descTraitsEnabled) {
            string memory descriptiveTraits = getDescriptiveTraits(dynaParams);            
            return string(abi.encodePacked("\"attributes\": [", descriptiveTraits, zoomTraits, ", ", tintTraits, ", ", rotationTraits, ", ", widthTraits, ", ", speedTraits, "]"));
        } else {
            return string(abi.encodePacked("\"attributes\": [", zoomTraits, ", ", tintTraits, ", ", rotationTraits, ", ", widthTraits, ", ", speedTraits, "]"));
        }
    }

    function getDescriptiveTraits(DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {
        string memory form;

        if (dynaParams.rotationMin == dynaParams.rotationMax) {
            if (dynaParams.zoom > 50 && dynaParams.rotationMax % 90 == 0) {
                form = "perfect square";
            } else if ((dynaParams.rotationMax == 45 || dynaParams.rotationMax == 135) && dynaParams.zoom > 91) {
                form = "perfect diamond";
            } else if (dynaParams.zoom <= 50 && dynaParams.rotationMax == 90) {
                form = "horizontal stripes";
            } else if (dynaParams.zoom <= 50 && dynaParams.rotationMax % 180 == 0) {
                form = "vertical stripes";
            } else if (dynaParams.zoom <= 25) {
                form = "diagonal stripes";
            } else {
                form = "rotated square";
            }
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 30 && dynaParams.stripeWidthMin > 200 && dynaParams.zoom < 20) {
            form = "big fat stripes";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin < 30) {
            form = "match sticks";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 130 && dynaParams.zoom < 30) {
            form = "laser beams";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 130 && dynaParams.zoom > 80) {
            form = "birds nest";
        } else if (dynaParams.zoom > 60 && dynaParams.stripeWidthMin > 180 && dynaParams.rotationMax - dynaParams.rotationMin < 30 && dynaParams.rotationMax - dynaParams.rotationMin > 5 && (dynaParams.rotationMin > 160 || dynaParams.rotationMax < 30)) {
            form = "cluttered books";
        } else if (dynaParams.stripeWidthMin > 180 && dynaParams.rotationMax - dynaParams.rotationMin <= 30 && dynaParams.rotationMin > 75 && dynaParams.rotationMax < 105) {
            form = "stacked books";
        } else if (dynaParams.stripeWidthMin > 50 && dynaParams.stripeWidthMax < 150 && dynaParams.rotationMax - dynaParams.rotationMin < 50 && dynaParams.rotationMin > 35 &&  dynaParams.rotationMax < 145 && dynaParams.zoom > 55) {
            form = "broken ladder";
        } else if (dynaParams.stripeWidthMin > 200 && dynaParams.zoom > 70) {
            form = "giant pillars";
        } else if (dynaParams.stripeWidthMin > 70 && dynaParams.zoom < 20 && dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 10) {
            form = "ribbons";
        } else if (dynaParams.stripeWidthMax < 75 && dynaParams.zoom < 20 && dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 10) {
            form = "streamers";
        } else if (dynaParams.stripeWidthMin > 25 && dynaParams.stripeWidthMax < 200 && dynaParams.rotationMax - dynaParams.rotationMin < 15) {
            form = "jittery";
        } else if (dynaParams.stripeWidthMax < 40) {
            form = "twiglets";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMin >= 50 && dynaParams.rotationMax <= 130 && dynaParams.stripeWidthMax - dynaParams.stripeWidthMin >= 150) {
            form = "collapsing";
        } else if (dynaParams.stripeWidthMin > 200 && dynaParams.zoom > 50) {
            form = "blocky";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin > 100 && dynaParams.stripeWidthMax < 150) {
            form = "wild";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 100 && dynaParams.stripeWidthMin > 150) {
            form = "tame";
        } else if (dynaParams.stripeWidthMin > 150) {
            form = "thick";
        } else if (dynaParams.stripeWidthMax < 100) {
            form = "thin";
        } else {
            form = "randomish";
        }

        string memory colourWay; 

        if (dynaParams.tintAlpha > 127) {
            uint difference = 150;
            if (dynaParams.tintAlpha > 200 && dynaParams.tintRed < 50 && dynaParams.tintGreen < 50 && dynaParams.tintBlue < 50) {
                colourWay = "doom and gloom";
            } else if (dynaParams.tintAlpha > 200 && dynaParams.tintRed > 200 && dynaParams.tintGreen > 200 && dynaParams.tintBlue > 200) {
                colourWay = "seen a ghost";
            } else if (dynaParams.tintRed > dynaParams.tintGreen && dynaParams.tintRed - dynaParams.tintGreen >= difference && dynaParams.tintRed > dynaParams.tintBlue && dynaParams.tintRed - dynaParams.tintBlue >= difference) {
                colourWay = "reds";
            } else if (dynaParams.tintGreen > dynaParams.tintRed && dynaParams.tintGreen - dynaParams.tintRed >= difference && dynaParams.tintGreen > dynaParams.tintBlue && dynaParams.tintGreen - dynaParams.tintBlue >= difference) {
                colourWay = "greens";
            } else if (dynaParams.tintBlue > dynaParams.tintRed && dynaParams.tintBlue - dynaParams.tintRed >= difference && dynaParams.tintBlue > dynaParams.tintGreen && dynaParams.tintBlue - dynaParams.tintGreen >= difference) {
                colourWay = "blues";
            } else if (dynaParams.tintRed > dynaParams.tintGreen && dynaParams.tintRed - dynaParams.tintGreen >= difference && dynaParams.tintBlue > dynaParams.tintGreen && dynaParams.tintBlue - dynaParams.tintGreen >= difference) {
                colourWay = "violets";
            } else if (dynaParams.tintRed > dynaParams.tintBlue && dynaParams.tintRed - dynaParams.tintBlue >= difference && dynaParams.tintGreen > dynaParams.tintBlue && dynaParams.tintGreen - dynaParams.tintBlue >= difference) {
                colourWay = "yellows";
            } else if (dynaParams.tintBlue > dynaParams.tintRed && dynaParams.tintBlue - dynaParams.tintRed >= difference && dynaParams.tintGreen > dynaParams.tintRed && dynaParams.tintGreen - dynaParams.tintRed >= difference) {
                colourWay = "cyans";
            } else {
                colourWay = "heavy tint";
            }
        } else if (dynaParams.tintAlpha == 0) {
            colourWay = "super dynamic";
        } else if (dynaParams.tintAlpha < 60) {
            colourWay = "light tint";
        } else {
            colourWay = "medium tint";
        }

        string memory speed;

        if (dynaParams.speedMax <= 25 && dynaParams.tintAlpha < 180) {
            speed = "call the police";
        } else if (dynaParams.speedMin == dynaParams.speedMax && dynaParams.speedMax < 30) {
            speed = "blinking";
        } else if (dynaParams.speedMin == dynaParams.speedMax && dynaParams.speedMax > 200) {
            speed = "slow pulse";
        } else if (dynaParams.speedMin == dynaParams.speedMax) {
            speed = "pulse";        
        } else if (dynaParams.speedMax < 50) {
            speed = "flickering";
        } else if (dynaParams.speedMax < 100) {
            speed = "zippy";
        } else if (dynaParams.speedMin > 200) {
            speed = "pedestrian";
        } else if (dynaParams.speedMin > 150) {
            speed = "sleepy";
        } else {
            speed = "shifting";
        }
        
        string memory descriptiveTraits;

        if (bytes(form).length != 0) {
            string memory formTrait = string(abi.encodePacked("{\"trait_type\": \"form\", \"value\": \"", form, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(formTrait, ", ")); 
        }
        if (bytes(speed).length != 0) {
            string memory speedStringTrait = string(abi.encodePacked("{\"trait_type\": \"speed\", \"value\": \"", speed, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(descriptiveTraits, speedStringTrait, ", ")); 
        }
        if (bytes(colourWay).length != 0) {
            string memory colourWayTrait = string(abi.encodePacked("{\"trait_type\": \"colour way\", \"value\": \"", colourWay, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(descriptiveTraits, colourWayTrait, ", ")); 
        }

        return descriptiveTraits;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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