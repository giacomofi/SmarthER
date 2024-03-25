// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure4DigitLib {
    function S1() public pure returns (string memory) {
        return
            "011111110101111111010111111101011111110100000000000111111101011111110101111111010000000000000000000001111111010111111101000000000000000000000000000000011111101101111110110111111011011111101100000000000111111011011111101101111110110000000000000000000001111110110111111011000000000000000000000000000000011111011101111101110111110111011111011100000000000111110111011111011101111101110000000000000000000001111101110111110111000000000000000000000000000000011110111101111011110111101111011110111100000000000111101111011110111101111011110000000000000000000001111011110111101111000000000000000000000000000000001111110100111111010011111101001111110100000000000011111101001111110100111111010000000000000000000000111111010011111101000000000000000000000000000000001111101100111110110011111011001111101100000000000011111011001111101100111110110000000000000000000000111110110011111011000000000000000000000000000000001111011100111101110011110111001111011100000000000011110111001111011100111101110000000000000000000000111101110011110111000000000000000000000000000000001110111100111011110011101111001110111100000000000011101111001110111100111011110000000000000000000000111011110011101111000000000000000000000000000000000111110100011111010001111101000111110100000000000001111101000111110100011111010000000000000000000000011111010001111101000000000000000000000000000000000111101100011110110001111011000111101100000000000001111011000111101100011110110000000000000000000000011110110001111011000000000000000000000000000000000111011100011101110001110111000111011100000000000001110111000111011100011101110000000000000000000000011101110001110111000000000000000000000000000000000110111100011011110001101111000110111100000000000001101111000110111100011011110000000000000000000000011011110001101111000000000000000000000000000000000011110100001111010000111101000011110100000000000000111101000011110100001111010000000000000000000000001111010000111101000000000000000000000000000000000011101100001110110000111011000011101100000000000000111011000011101100001110110000000000000000000000001110110000111011000000000000000000000000000000000011011100001101110000110111000011011100000000000000110111000011011100001101110000000000000000000000001101110000110111000000000000000000000000000000000010111100001011110000101111000010111100000000000000101111000010111100001011110000000000000000000000001011110000101111000000000000000000000000000000011111100101111110010111111001011111100100000000000111111001011111100101111110010000000000000000000001111110010111111001000000000000000000000000000000011111001101111100110111110011011111001100000000000111110011011111001101111100110000000000000000000001111100110111110011000000000000000000000000000000011110011101111001110111100111011110011100000000000111100111011110011101111001110000000000000000000001111001110111100111000000000000000000000000000000011110001101111000110111100011011110001100000000000111100011011110001101111000110000000000000000000001111000110111100011000000000000000000000000000000011111000101111100010111110001011111000100000000000111110001011111000101111100010000000000000000000001111100010111110001000000000000000000000000000000001111100100111110010011111001001111100100000000000011111001001111100100111110010000000000000000000000111110010011111001000000000000000000000000000000001111001100111100110011110011001111001100000000000011110011001111001100111100110000000000000000000000111100110011110011000000000000000000000000000000001110011100111001110011100111001110011100000000000011100111001110011100111001110000000000000000000000111001110011100111000000000000000000000000000000001110001100111000110011100011001110001100000000000011100011001110001100111000110000000000000000000000111000110011100011000000000000000000000000000000001111000100111100010011110001001111000100000000000011110001001111000100111100010000000000000000000000111100010011110001000000000000000000000000000000000111100100011110010001111001000111100100000000000001111001000111100100011110010000000000000000000000011110010001111001000000000000000000000000000000000111001100011100110001110011000111001100000000000001110011000111001100011100110000000000000000000000011100110001110011000000000000000000000000000000000110011100011001110001100111000110011100000000000001100111000110011100011001110000000000000000000000011001110001100111000000000000000000000000000000000110001100011000110001100011000110001100000000000001100011000110001100011000110000000000000000000000011000110001100011000000000000000000000000000000000111000100011100010001110001000111000100000000000001110001000111000100011100010000000000000000000000011100010001110001000000000000000000000000000000000011100100001110010000111001000011100100000000000000111001000011100100001110010000000000000000000000001110010000111001000000000000000000000000000000000011001100001100110000110011000011001100000000000000110011000011001100001100110000000000000000000000001100110000110011000000000000000000000000000000000010011100001001110000100111000010011100000000000000100111000010011100001001110000000000000000000000001001110000100111000000000000000000000000000000000010001100001000110000100011000010001100000000000000100011000010001100001000110000000000000000000000001000110000100011000000000000000000000000000000000011000100001100010000110001000011000100000000000000110001000011000100001100010000000000000000000000001100010000110001000000000000000000000000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000011111111011111111101111111110111111111010000000000111111101111111110111111111011111111101100000000001111110111111111011111111101111111110111000000000011111011111111101111111110111111111011110000000000000000000011111111011111111101111111110100000000000000000000111111101111111110111111111011000000000000000000001111110111111111011111111101110000000000000000000011111011111111101111111110111100000000000000000000000000000011111111011111111101000000000000000000000000000000111111101111111110110000000000000000000000000000001111110111111111011100000000000000000000000000000011111011111111101111000000000011111110011111111001111111100111111110010000000000111111001111111100111111110011111111001100000000001111100111111110011111111001111111100111000000000000000000001111111001111111100111111110010000000000000000000011111100111111110011111111001100000000000000000000111110011111111001111111100111000000000000000000000000000000111111100111111110010000000000000000000000000000001111110011111111001100000000000000000000000000000011111001111111100111000000000011111100011111110001111111000111111100010000000000111110001111111000111111100011111110001100000000000000000000111111000111111100011111110001000000000000000000001111100011111110001111111000110000000000000000000000000000001111110001111111000100000000000000000000000000000011111000111111100011000000000011111000011111100001111110000111111000010000000000000000000011111000011111100001111110000100000000000000000000000000000011111000011111100001";
    }
}