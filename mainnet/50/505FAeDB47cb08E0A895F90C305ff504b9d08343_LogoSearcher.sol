//	SPDX-License-Identifier: MIT
/// @title  Logo Searcher
/// @notice Searcher for client to use
pragma solidity ^0.8.0;

import '../common/LogoModel.sol';

interface ILogoDescriptor {
  function logos(uint256 tokenId) external returns (Model.Logo memory);
  function getTextElement(uint256 tokenId) external view returns (Model.LogoElement memory);
  function getLayers(uint256 tokenId) external view returns (Model.LogoElement[] memory);
}

contract LogoSearcher {
  address public logoDescriptorAddress;
  ILogoDescriptor descriptor;

  constructor(address _address) {
    logoDescriptorAddress = _address;
    descriptor = ILogoDescriptor(_address);
  }

  function getNextConfiguredLogo(uint256 startTokenId, uint256 endTokenId) public view returns (uint256) {
    for (uint i = startTokenId; i <= endTokenId; i++) {
      Model.LogoElement[] memory layers = descriptor.getLayers(i);
      for (uint j; j < layers.length; j++) {
        if (layers[j].contractAddress != address(0x0)) {
          return i;
        }
      }
      Model.LogoElement memory text = descriptor.getTextElement(i);
      if (text.contractAddress != address(0x0)) {
        return i;
      }
    }
    return 0;
  }

  function getPreviousConfiguredLogo(uint256 startTokenId, uint256 endTokenId) public view returns (uint256) {
    for (uint i = startTokenId; i >= endTokenId; i--) {
      Model.LogoElement[] memory layers = descriptor.getLayers(i);
      for (uint j; j < layers.length; j++) {
        if (layers[j].contractAddress != address(0x0)) {
          return i;
        }
      }
      Model.LogoElement memory text = descriptor.getTextElement(i);
      if (text.contractAddress != address(0x0)) {
        return i;
      }
    }
    return 0;
  }
}

//	SPDX-License-Identifier: MIT
/// @notice Definition of Logo model
pragma solidity ^0.8.0;

library Model {

  /// @notice A logo container which holds layers of composable visual onchain assets
  struct Logo {
    uint16 width;
    uint16 height;
    LogoElement[] layers;
    LogoElement text;
  }

  /// @notice A layer of a logo displaying a visual onchain asset
  struct LogoElement {
    address contractAddress;
    uint32 tokenId;
    uint8 translateXDirection;
    uint16 translateX;
    uint8 translateYDirection;
    uint16 translateY;
    uint8 scaleDirection;
    uint8 scaleMagnitude;
  }

  /// @notice Data that can be set by logo owners and can be used in a composable onchain manner
  struct MetaData {
    string key;
    string value;
  }
}