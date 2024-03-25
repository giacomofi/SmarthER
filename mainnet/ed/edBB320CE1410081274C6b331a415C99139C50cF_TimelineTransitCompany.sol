//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
8%B%%%%%B%%%%%88%@@@@@@@@@@@@@@@@@%88888888888&&&8&&&&&8&W&W&&&&&&&&&&&&&&W&W&&&&&&&&&888888888888888888888888WW8888&WW&88&W&&&&&&&&&&WWW&&&&&%@@@@@@
888888888888888888888888888888888888888888888&&8&&&&W&88&WMW&&&&&&&&&8&&&&W&W&&&&&&&&&&&&&&&&&&888888888888888&WWWWWMW&[email protected]@@@@@@
888888888888888888888888888888888888888888888&&&W8&M&8&W&8&8%BBBBBBBB88&&WW&W&&&&&&&&&&&&&&&&8&&&&&&&[email protected]@@@@@@
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888&&&&&&W&M8&W&M&&[email protected]@@@@@@@@B8&W&&W&M8&8&&8&&&&&WMWWWWWWWWWWWW&[email protected]@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMW888&&&8&&MMWW&WMW&&M&&8BBBBBBBBBB8&W&WM&MuI[Q88&&&&&W&&&&&&&&&&&WW&8&&&[email protected]@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&WMMMW&&&&&&M&&8BBBBBBBBBB8&W&Wab-x00h&&&&&&&&&&&&&&&&&&&&W&88&&&&&&&88888888888&&&&&&&&&&&888&[email protected]@@@@@@
8888888888888888888888888888888888&&&&&&8888&&&&W&M#MW&M&&[email protected]&W&jvY0000h&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&888888888&WWWWWWWWWWWWWW&[email protected]@@@%%B
888888888888888888888888888888&&&&&&&&&&[email protected]%&&&&M#MW&&&&&&&&&&&&&&&&&Zr0000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88888&WWWWWWWWWWWWWW&88888888888
[email protected]@@@@B8&&&&&&&&&&&8%BBBB8&&&&&&&&&&&&&&&&&&&&&8I|0O000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&&&&&&&&&88888888WW8
BBBBBBBBBB%%%%%%%%%%%@@@@@[email protected]&&&&&&&&&&&&&%BBBBBBBBBBB8&&&%BBBBBBBaL|0000000000aBBBB8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&8&&8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&8%BBBBBBBBBBB&&[email protected]&&&&%%%%%%%%8&&&&&&&&&&&&&&&&&&&&&&&&WWW&&&&&&&&&&&&W&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B88&&&&&&&&&&&&&&%BBBBBBBBB%&&&%B%BBjz0O000000000000aBB%8&&&&&&%BBBBBBBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMWWMMMM8
@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&wr0Yr[(rr|[[|r[[[III[Q&&WWW&&&&&&&8BBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMMMMMMM8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&WWWppmwuI>]rrrrrrrunrrnvvnrrrrr}~~]11Ymppp&&&8B%%&&&&&&&&&&&&&&&&&&8&&W##&&&&&88888&MMMMMMMMMMMW8
@@@@@@@@@@@@@@@@@@@@@@@@BBBBB8&&&&&&&&&&&&&&&&&&W&WWxrx}{|-~I[)rrrrrcC0LCCXvvXJrrrrrrrrrr/(tttjrr&&&&&&&&&&&&&&&&&&&&&&&&&WMM&&&&&&&&&&&&&&&&&&&&&888
@@@@@@@@@@@@@@@@@@@@@@@@[email protected]&&&&&&&&&&&&&&&&&&W)}}lIl[)r[_I[(rrrrr|}0u[[x00x[rrrrrrrrrrrrrrrrrj[[{WW&&&&&&&&&&&&&&&&&&&&&&8&&&&&&&&8888888888888888
@@@@@@@@@@@@@@@@@@@@@BBBBBBBB8&&&&&&&&&&&&&W&&({{{?IIII[)r[_I[)rjrjrjrrrrr([[|rrrrjrrrrrrrrrrrrrrrrj[[1&W&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888888888888
@@@@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&W#d({{{}?lIIIII[)r[_I|jvvvv000000000000000uuvvvvrrrrrrrXJrrrrrj11|dM&&&&&&&&&&&&&&&&&&&8&&&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@[email protected]@@@BB8&&&&&&&&&&&&&&&&&&&W&cj{{{{[?IIIIIII[)rXXc00000OoooooooooooooooO00000JCJrrrrrrrrrrrrrrrtjvWW&&&&&&&&&&&&&&&&&&&&&&&&W&8&MWWW&WW&MM
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&&h}{{{})r}-IIIIIII000000MM#MM##MMMM*WW*######MM#WWW000000rjrrrrrrrrrrrrf[k&&&&&&&&&&&&&&&&&&&&&&&&W&&&W&&W&WW&WW
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&MMWt}{}{}[{r}-IIIIQ00000MM****##**MWWW*WW*M###MWMMWWWWWWW000000rrrrrrrrrrrrr{/&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&&W&&WW8
88888888888888888&&&&&&&&&&&&&&&W&dO}{{)jf[[{r}[?Q00wwqWWW*M****##**#WWW*WM#WWWWWWMWWWWMWWWWWWqww00QvxrrrxJcuurj1Zb&&&&&&&&&&&&&&&&&&8&&&&&MM&&MW&MM&
WWWWWWWWWWWWWWWWWWWWWWWMWWWMMMMMar)}}/rCxt[[1rXU0hhh######*######***#*##*MMWWWWWWWWWWXujXnjjqWWMMooo0LJrrrjCLvUUrttr*W&&&&&&&&&&&&&&&8&&&88&888888888
WWWWWWWWWWWWWWWWWWWWWWMMMMMMMMWj{}{1rrrrrf}[|00m#M########*#########*M*#*#########rrr0000000t][mWW&&Ww00urrrn00Lrrrj{f&&&&&&&&&&&&&&&&&&&&&&&&8888888
8888&&&&&&&&&&&&&&&&&&&&&&&&&&&j}{frrrrrrf[C00#W#MWWWW#*#W*WWWWWWWWMWWWM*MWWWMWMQr000rrjrrrrU00t{WWWWW#0OLrrrrru0nrrrX&&&&&&&&&&&&&&&&[email protected]@@@@@@@@@@B%
%%%%888888888888888888888888&#{1(rrrrrrruz0wpWMMWWWWWW#*#W*WWW*bqqpjjjYLmYQwqqqjY0rrrrnu0XvrrrrJQ1d%&W#Mpw0zurrrrrrrjf1*&&&&&&&&&&&&&&[email protected]@@@@@@@@@@@@@
@@@@@@@@@@BBBBBBBBBBBBBBBBBBYrtjrrrrrrnC0ZoWWWWWM#####*##W*0{jYbwqwM*###*MW8%pYCXurrrJQ0000JurrnvCun&WWWW#aZ0CnrrrrrrrrrX&&&&&&&&&&&&&[email protected]@@@@@@@@@@@
@@@[email protected]@@BBBBBBBBBBBBBBBBBB%YrrC00nrrrn00mMMMMMMMMMMMMMM#M[vMWM#WW##WWWMWWW8%Or0zrrY0000000000rrr0t1WWWWWWWm00nrrrrrLCrrY&&&&&&&&&&&&&[email protected]@@@@@@@[email protected]@@@
888&&&&&&&&&&&&&&&&&&&&&&&#[trrC00urrL00#WWMMWWWWWWWWWMMZ[&MWWMWWWWMMMWWWWW8%J[0zrrrrrrr0crrrrrrr0vxWWWWWWW&#00Lrrrrrrrrt[#&&&&&&&&&&&[email protected]@@@@@@@[email protected]@@@
8&&&&&&&&&&&&&&&&&&&&&&&&kqrrrrrrrrrvLOw#WWWWWWWMWWWWomXOMWWWWWWWWWWWMMMMMW&8mvYurrzJ0LC0LJJJJrrxXjtWWWWWWWW#w0LvrrrrrrrrrZd&&&&&&&&&&[email protected]@@@@@@@@@
8&&&&&&&&&&&&&&&&&&&&&&&WXtrjrrrrrrn00mWWWWWWWWWWMMW{jZMMMM#########MMMMMWWMW#*]|rrrruYC0crrrrrrr[Z#WWWWWWWWWWm00nrrrrrrrr?f&&&&&&&&&&[email protected]@@@@@@@@@@
WWWWWWWWWWWWWWWWWWWWWMMWWYjrrrrrrrC00oMM##MMM#####0I*###*###*Moooo*#*#******#MWQr[rrrrrr0crrrrr)}0aMWWWWWWWWWWW*00CrrrrrrrrY&&&&&&&&&&&&[email protected]@@@@@@@@
MMMMMMWMMMMMMMMMMMMMMMM*[trrrrrrrrC00o#*#######**i1*********o******oo******MM#MMd0[[[rrrrrrr)[[z00aWWWWWWWWWWWW*00Crrrrrrrr(l#&&&&&&&&&&&&[email protected]@@[email protected]@
MMMMMMMMMMMM#M#########*1fruxrrrn00ZMMMMWWWWWWWom1xWWW*MMMMMMMMWWMMMMMqqqdqqbbbWMMwwm|///|/|JwwoMwhoWWWWWWWWWWWWWm00nrruurrt[qk&W&&&&&&&&&&&&&8888888
WWWWWWMMMMMMMMMMMMMM#MM*rrruxrrrn00Z****WWWWWWWZI*MWMW#WM#########*jfjtnXJUXJcjXXXM#Maooaaaa#MMMMMCcMMMMMMMMMMMMWZ00nrruurrjtYn{WWW&&&&&&&&&&&&&&&&&8
&&&&&&&&&&&&&&&&&&&&&&x}rrrrrrrrx00Z****WWWWWMWZI*WM#MW##MMMMMMMMQ[rz00pM*#M*p00zrrZ*##*****####*#Yn###########MMZ00xrrrrrrrrrv0l(MMMMMMMMMMMM&&&&8&8
&&&&&&&&&&&&&W&&&W&&&&x}rrrrrrrC00a#****WWWWWW)jMWWMMM#MM#MMMMMM])r0q#M#M*#Mooooq0rrroooooooo*****oo0h*********###[email protected]@@@@@WMWMMMMMM
&&&&&&&Zu|ru|||vvv/[??}1rrrrrrrC00*WMMWMMMMM#M1jM#MM#MM#MM#kZ0OZ-(v##M##M*#Mo*MWMM0zrb*WMdZmwqpmmmmOc0mpqqpqqZmmmm0cvvruvvvvvrv0000/[email protected]@BBBWMW&[email protected]
&&&&&&&M*0000000000000vrrrxJnrrC00o###########rc###MM#MW#*}jOOv-cU0{zo#MMjfj###MMMamJrm#jJZZwqqmmZZ0IIIi?[[[[-!IIlIIIl~--?|[email protected]&[email protected]@@
WWWWWWWWWWp00000000000vx0000urrC00o###########)j####MM#MLI[+II<[I<[[+llIIrjr[[[[[[[[[[[[[[[IIIl-[[>lII>MMMMMMMMMM_+00zIIIII]0xv00000000c[[email protected]&MM&[email protected]@@
&&&&&&&&&&&&0000000000vx0/{00QrC00*WWWWWMMMMMM(rMMMMMMMWO[]_lI<[I<[[[[[[[rjr[[[[[[[[}[[[[[[[>IIll[[]II>M#MMWMWWWW_+00zIIIIli[rv00000000O0[XBWM&[email protected]@@@
&&&8&&&&&&&&&kw0000000vx0Xc0UXrC00*WWWWWWWWWWMnXWWWWWWMWWMjcZZc[cCqjLM*MMjjjo*oMMMamJrwMjLqqqqpwmmmO[<iilllIIl_-[[?iIl~-??|x0xv0000000O000JvhaW&%BBBB
&&&&&&&&&&&&&&&ow00000vr||/0xtrC00*WWWWWWWMWWWnYWWWWWMMW88Mawqpd(rX8WM*MMM##o*oWMM0zrboWMkqqqqqmmZZO}LwqmmZZZZmmppmYcvr/|||||rv0000000000000JqWWWWW&&
&&&&&&&&&&&&&&&&&&0000vrrrj[trrC00*WWWWWWWWWMWWZI*WWWWMMMMM&8%88rrr0dM*MMM#Mo*oMd0rrrMMWMMMMMWMMWMx1#M#MMWWWWWWWWW*00CrrrrrrrQw&&&&&&&&&&&&&&W&WWW&W&
&&&&&&&&&&&&&&&&&&&p00vrrrrrrrr{1O0ZWWWWWWWMWWWZI*WWMWMMMMMW8888%qrrz0QdMM#MopQ0zrrmMWMMMWMWWWWWWMx1#M#MMMWWWWWWWZ001{rrrrrrrQw&&&&&&&&&&&8&&W&&MM&&8
&&&&&&&&&&&&&&&&&&&&&wO0rrrrrrr((00mWWWWWWWWWWWp{OpWMWWWMMMMMW88888YXXrcJJJJJcrXXzMMMMMMMMMWWWWWWbLY##*MM########Z00|(ruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&#oJurrrrrrn00ZWWWWWWWWWWWWWi1MWWWWWMMMMWMMMMMMMWbbbbbbbbb##########MMMMMMM#rp#MWMMWMMMMMWWMZ00nrruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&&W0vrrrrrrj[U00*WWWWWWWWWWWMa0MWWWWWMMMMMMMMMMMM**########**#######*#**o#Yr###*MW8%%%%%%%W00U[jrrrrrrv0MWWWWWWWWWWWWWWWM&&MM&&8
888888&&&&&&&&&&&&&&&&&W&wQrJQrrrrJ00*WWWWWWWWWWWMWW!(W&WWWWWM*MMMMMMM*&8888M&8&&MMMMMMWW#W##*rpWWMM#MW8%%%%%%BW00CrrrrrrrQqWWWWWWWW&&&&&&&&&&&&MM&88
@@@@@@@@BBBBBBBBB&&&&&%B%pQrjrrrrr)|00mWWWWWWWWWWWWWWomo*WMWMM**MMMMMM*&8888M&8WWMMWWWWWW#WdCXWWWWWW#MW8%%%%%%m00|)rrrrrrrQq###############MMMMMMM&88
@@@@@@@@BBBBBBBBB&&&&&%B%#oCnrrrrrrj|COw*WWWWWWWWWWWWWWamjXx}jJ*#MMMMW*###########**###*#Ujdo*WWWWWW#MW8%%%%&qOC|jrrUYrrnCa#WWWWWWW&&&&&&&&&&&&&&8&88
@@@@@@@@@@BBBBBBB&&&&&%BBB80urrrrrrrrC00#WWWWWWWWWWWWWWrc00O00v[M#WWWWWWWWWWWMWWWM##W##*[QW#M*WWWWWW#MWWW8%%&00CrrrrrrrrvOM&&&&&&&&&&&&&&&&&&WW&&8888
@@@@@@@@@@BBBBBBB&&&&&%BBBBBwQrrrrrrr{(00mWWWWWWWWWWWWWrc0rrr0UrMMW&8888888888WWWWW##r([W#W#M*WWWWWWMW&%&W&m00({rrrrrrrQq&WW&&&&&&&M&&&&&&&&WW&W&8888
@@@@@@@@@@[email protected]&&&&&%BBBB%bmuxrrrrr--vQmoWWWWWWWWWWWWvxtt/(ft/000*###oa#oaaahh0Xrjj#M*##*M#*MWWWMW8&&8&WomQY|)rrrrrxvmdWW&&&&&&W&&&&&&&&&&&&8&88888
@@@@@@@@@@@@BBBBB&&&&&%BBBBBB80urrrrrrj(?10mdWWWWMWWWMMopYYXcYOhaao####oh#ohhhhhM8WWWW#*#WMWWW&&&W8%%&W&dw0j/tjrrrrrru0MW##W&&&W&&&8BBBBBBBB8&8888888
[email protected]@@@@@@BBBBB&&&&&&%BBBBBB%wQrrn00Crj|IJ00*################*MMW&88888888888888WWWWM##&%%%%%%%%%8WWM00C[trrru0nrrQm#WW##W&WW&&[email protected]@@@@@&&&888888
88888%@@@@@@@BBBB&&&&&&&&888&&&&#0nn00Crrf[!_00wWWMMMMMMMMMMMMMM#MWWWM&88WWW88W888WWWW&8%%%%%%%%%8W&Ww00|}rrrrrrrru0o#M#MMMMM&&&[email protected]@[email protected]@@@@@@&&8888888
WWW&88%@[email protected]@@@BB%&&&&&&&&&&&&&&&&Mwzurrrrrf[[]~uX0oooW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWooa0UX1frrrrrrrruzwM&&&&&&&&&&&@@[email protected]@@@@@@&88888888
888W88%[email protected]@@@%&&&&&&&&&&&&&&&&W&&&*hJxrrrf[[{r?-?Q00wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwww00Q/ttrYCJnrrjxJa*&&&&&&&&&&&&&[email protected]@@@@@@@&88888888
WWW888%[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&wLrjf[[1r}-IIIIQ0000OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW00000Q[[}rrrrC00ujrLmMMMMMMMMMMWWWM&&[email protected]@@@@@@@@@888888888
88888888&8&&&&&&&&&&&&&&&&&&&&&&&W&&&W#0nf[[{r}-IIIIIII000000WWWWWWWWWWWWWWWWWWWWWWWWWWW00O000[[[jrrrrrrrrrrn0#WMWWWWWWWW&&&&M&&[email protected]@@@@@@@@B888888888
888888888&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&pQ|/tr}-IIIIIII>>~ccc000000oooooooooooo*oo000000XYY111rrrrrrrrrruvuOp&&WW&&&&&&&&&WW&W&&@@@@@@[email protected]
88888888888&&&&&&&8&&&&&&&&&&&&&&&&&&8%%%8M*kC{-IIIIIII[)r-~I????}|000000000000000||||||tttrrrrrrrrrrrxCkooW&&&WW&&&&&&&&&WW&W&&BBBBBBBB8888888888888
88888888888&&&&&&&&&&&&&&WMMMMMMMW&&&BBBBBBB%&O00x)IIII[)r[_I[)rrrrIIII~[I~[[[[[[[rrrrrrrrrrrrrrrrrx00O&&&&&&&&WW&&&&&&&&&W&&W&&&&&&&&888888888888888
88888888888888&888888&&&W&BBBBBB%MW&&BBBBBBBBB8&WO00!Il[1r[_I])rrrrrrrrrrrrrrrrrrrrrrrYQrrrrrjrrr00O&&&&&&&&&&&&#MMMMMMMMW&&W&&&&&&&88&WM888888888888
&MMWWWWWWMMMMMMMMMMMMMM&W8BBBBBBBM&&&BBBBBBBBBB%&WWWwww|fu|[I[)rrrrrrr0CYYC0YYY0zrrrrrrjrnuuvuwww##*&&&&&&&&&&&&W&&&&##MMMMMMMMMMMMMMMW8&W88888888888
&WMMMMMMMMMM#WMWW8W&&&W&W&BBBBBBBM&&&BBBBBBBBBBBB%&W#*#o*aomcYUJJzrrrr|/tYC0Ynt/frrrrrzJJqhaahMM#M##&&&&&&&&&&&&W&&&&MM&&&&&&&&&&&&&&&&&&&&8&W&&&8888
&WWWWWWWWWWWW&MWW8W&8&W&[email protected]@@@BBM&&&BBBBBBBBBBBBBB%&W#&&#W******b00Yrrrr[[[[|rrrrrY00kMMMMMMMMMM###&&%BBBBBB%&&W&&&&MM&&&&&&&&&8888888888888&&W&8888
&W&&&&&&&&&&&&&&&8&&&&W&[email protected]@@@BBM&&&BBBBBBBBBBBBBBBB%&&&#W******#&&k0000000000000rY0##########W&MW#&%[email protected]%&&W&&&&MW&&&&&&&&&888888888888888888888
&WWWWWMMMMMMMMMMMMMMMMM&W&BBBBBB%M&&&BBBBBBBBBBBBBBBBBB&&M&W####MW&&k0000000000JXvwoWM##M&WW&WW&&WW#&BBBBBBBB%&&W&&&&MW&&&&&&&888888888888888&WW&8888
@@@BBBBBBB%8888888888888&&WWWWWWW&8&&BBBBBBBBBBBBBBBBBB&&WWWWWWWWWWMk0000O000YuCp*WW&MMWMM&MM&WMM&&#&BBBBBBBB%&&W888&MW&&&&&&&&&&&&&WM&&&&&&&&&&&8888
@@@@@@[email protected]%88888888888888&&&&&&&&&&&&BBBBBBBBBBBBBBBBBB&&WMMMMMMMMMMb0000000rX0&WM&&&&M#MM*MMM#MMMMM&[email protected]%&&MWWWWMM&&8888888888&WW888888888888888
@@@@@@@@B888888888888888888888&&&&&&[email protected]@@@BBBBBBBBBBBBB&&M##########b00000Yx0d###M#M&WM#&M*W&##W&&&&&[email protected]@@@B%&8&&&&&&MW88888888888&WW&WWWWWWWWWWWWWW
@@@@@@B%8&&WMMM88&888888888888888&&[email protected]@@@@@@BBBBBBBBBB&&M&&&&&&&&&&h00LCuCw&&&&&&MM&WMM&WMW&#MW&&&&&[email protected]@@@@@B%&&W&&&&&MW888%%%88888&WW888888888888888
@@@@@%88&&8&&88&&8&&&&&&[email protected]@@@@@@@@@@@@@@BBBB&&M&#WWWWWWWWwvuXC*#WM#&&&&#M&&&&&&&&&&&&&&&&&[email protected]@@@@@B%&&[email protected]@@@B88&&&&&&&&&&&&&&&&&&&&
@@@%88&&88&88&W88&&888&#[email protected]@@@@@@@@@@@@@@@@@@@@@&&M&M&&&&&&&&h00b&&&W#W&&##W&MMMMMMMMMMMMMMM#&[email protected]@@@@@B%&&WWWWW8&&[email protected]@@@B8&W8W88888888888&&W888
88888W88&&&WW88&&88888W&[email protected]@@@@@@@@@@@@@@@@@@@@@&&M&#MMMMM#M#####MM#W&&M#M&WM&&8&&&&&&&&&&&&#&[email protected]@@@@@@%&&WW8W&[email protected]@@@B8&W8W88888888888&&W888
&88&&8&&88WW&88&W&&&&&&&8888888888888888888888&&888888&&&M&&&&&&&&&&&&&&&&&&W#M&W#W&&&&&&&&&&&&&&&&#[email protected]@@@@@@%8&&W8W&8%%%@@@@@B8&W8W88888888888&&W888
8&&88WWWW&888888888888888888888888888888888888888888&&&&&MMMMMMMMMMMMMMM####W&&[email protected]@@@@@@%8&&W8W&[email protected]@@@@@@B88W8W88888888888&&W888
8888WWWWWW88&WWWWWWWWWWWWWW&88888888888888888888888888888&8&88888888888&&&&&88&8888&&&&[email protected]@@@@@@%8&&W8W&[email protected]@[email protected]@@@B88W8W88888888888&&8WWW
*/

// Contract by: @backseats_eth

contract TimelineTransitCompany is ERC721A, ERC2981, Ownable {
    using ECDSA for bytes32;

    // There are 9,999 Timelines
    uint256 public constant MAX_SUPPLY = 9_999;

    // The price is 0.088 ETH
    uint256 public price = 0.088 ether;

    // The Merkle tree root of our presale addresses. Cheaper than storing an array of addresses or encrypted addresses on-chain
    bytes32 public presaleMerkleRoot;

    // Tracking if an address minted during pre-sale. Can mint up to 5.
    mapping(address => bool) public presaleMinted;

    // Tracking nonces used to provent botting
    mapping(string => bool) public usedNonces;

    // The address of the private key that creates nonces and signs signatures for mint
    address public systemAddress;

    // The contract or wallet this contract withdraws to.
    address public withdrawAddress;

    // The URI where our metadata can be found
    string public _baseTokenURI;

    // If the team has already minted their reserved allotment.
    bool public teamMinted;

    // An enum and associated variable tracking the state of the mint
    enum MintState {
      CLOSED,
      PRESALE,
      OPEN
    }

    MintState public _mintState;

    // Constructor

    constructor() ERC721A("Timeline Transit Company", "TTC") {}

    // Mint Functions

    /**
    * @notice Must be called from the website, which passes a _merkleProof of the address in with the amount to mint to check if address is on the allow list
    */
    function presaleMint(bytes32[] calldata _merkleProof, uint _amount) external payable {
      require(_mintState == MintState.PRESALE, "Presale closed");
      require(_amount < 5, "Mint 1-4");
      require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");
      require(!presaleMinted[msg.sender], "Already minted");
      require(price * _amount == msg.value, "Wrong ETH amount");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Not on the list");

      presaleMinted[msg.sender] = true;

      _mint(msg.sender, _amount);
    }

    /**
    * @notice Requires a signature from the server to prevent botting
    */
    function publicMint(string calldata _nonce, uint _amount, bytes calldata _signature) external payable {
      require(_mintState == MintState.OPEN, "Mint closed");
      require(msg.sender == tx.origin, "Real users only");
      require(_amount < 21, "Mint 1-20");
      require(totalSupply() + _amount <= MAX_SUPPLY, 'Exceeds max supply');
      require(price * _amount == msg.value, "Wrong ETH amount");
      require(!usedNonces[_nonce], "Nonce already used");

      require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _amount, _nonce)), _signature), "Invalid signature");

      usedNonces[_nonce] = true;

      _mint(msg.sender, _amount);
    }

    /**
    * @dev Returns an array of token IDs owned by `owner`.
    *
    * This function scans the ownership mapping and is O(totalSupply) in complexity.
    * It is meant to be called off-chain.
    *
    * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
    * multiple smaller scans if the collection is large enough to cause
    * an out-of-gas error (10K pfp collections should be fine).
    */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
      unchecked {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        TokenOwnership memory ownership;
        for (uint256 i = 1; tokenIdsIdx != tokenIdsLength; ++i) {
          ownership = _ownerships[i];
          if (ownership.burned) {
            continue;
          }
          if (ownership.addr != address(0)) {
            currOwnershipAddr = ownership.addr;
          }
          if (currOwnershipAddr == owner) {
            tokenIds[tokenIdsIdx++] = i;
          }
        }
        return tokenIds;
      }
    }

    // Internal Functions

    /**
    * @notice Tokens are numbered 1–9,999
    */
    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    /**
    * @notice The baseURI of the collection
    */
    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    /**
    * @notice Checks if the private key that singed the nonce matches the system address of the contract
    */
    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
      require(systemAddress != address(0), "Missing system address");
      bytes32 signedHash = hash.toEthSignedMessageHash();
      return signedHash.recover(signature) == systemAddress;
    }

    /**
    * @notice Allows team to mint timelines to specific addresses for marketing and promotional purposes
    */
    function promoMint(address _to, uint256 _amount) external onlyOwner {
      require(totalSupply() + _amount <= MAX_SUPPLY, 'Exceeds max supply');
      _mint(_to, _amount);
    }

    /**
    * @notice A one-time use function. Reserves 250 for the team for marketing, giveaways, etc.
    */
    function teamMint() external onlyOwner {
      require(!teamMinted, "Already minted");
      require(totalSupply() + 250 <= MAX_SUPPLY, 'Exceeds max supply');

      _mint(msg.sender, 250);
      teamMinted = true;
    }

    // Ownable Functions

    /**
    * @notice Sets the system address that corresponds to the private key signing on the server.
    @dev Ensure that you update the private key on the server between testnet and mainnet deploys and
    that the address used here reflects the correct private key
    */
    function setSystemAddress(address _systemAddress) external onlyOwner {
      systemAddress = _systemAddress;
    }

    /**
    * @notice Sets the withdraw address where funds will be withdrawn to
    */
    function setWithdrawAddress(address _address) external onlyOwner {
      withdrawAddress = _address;
    }

    /**
    * @notice Sets the baseURI where collection assets can be accessed
    */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
      _baseTokenURI = _baseURI;
    }

    /**
    * @notice Sets the merkle root for the presale
    */
    function setPresaleMerkleRoot(bytes32 _root) external onlyOwner {
      presaleMerkleRoot = _root;
    }

    /**
    * @notice Sets the mint state for the contract. Valid values: 0–2
    */
    function setMintState(uint256 status) external onlyOwner {
      require(status <= uint256(MintState.OPEN), "Bad status");
      _mintState = MintState(status);
    }

    /**
    * @notice Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
    */
    function setPrice(uint _newPrice) external onlyOwner {
      price = _newPrice;
    }

    /**
    @notice Sets the contract-wide royalty info
    */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
      _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
    * @notice Boilerplate to support ERC721A and ERC2981
    */
    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
      return super.supportsInterface(interfaceId);
    }

    // Withdraw

    function withdrawFunds() external onlyOwner {
      require(withdrawAddress != address(0), "Missing withdraw address");
      uint balance = address(this).balance;
      (bool sent, ) = payable(withdrawAddress).call{value: balance}("");
      require(sent, "Withdraw failed");
    }

}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";