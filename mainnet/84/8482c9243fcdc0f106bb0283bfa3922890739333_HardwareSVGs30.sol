// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs30 is IHardwareSVGs, ICategories {
    function hardware_98() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Helm of the Monarch',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h98-a" x1="102.61" x2="102.61" y1="157.45" y2="130.79"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h98-e" x1="117.39" x2="117.39" y1="148.38" y2="135.97"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h98-b" x1="110" x2="110" y1="128.66" y2="112.26"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h98-d" x1="110" x2="110" y1="101.39" y2="134.82"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h98-k" x1="90.94" x2="129.06" xlink:href="#h98-a" y1="110.48" y2="110.48"/><linearGradient gradientUnits="userSpaceOnUse" id="h98-c" x1="91.86" x2="128.14" y1="107.14" y2="107.14"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h98-n" x1="110" x2="110" xlink:href="#h98-b" y1="133.26" y2="101.84"/><linearGradient id="h98-p" x1="70.03" x2="149.97" xlink:href="#h98-c" y1="157.65" y2="157.65"/><linearGradient id="h98-q" x1="70.86" x2="149.14" xlink:href="#h98-a" y1="158.65" y2="158.65"/><linearGradient id="h98-s" x1="94.28" x2="125.73" xlink:href="#h98-c" y1="149.84" y2="149.84"/><linearGradient id="h98-t" x1="95.12" x2="124.89" xlink:href="#h98-a" y1="149.13" y2="149.13"/><linearGradient gradientTransform="scale(-1 1) rotate(-22.51 0 136)" id="h98-u" x1="-111.96" x2="-111.96" xlink:href="#h98-b" y1="125.12" y2="115.86"/><linearGradient gradientTransform="rotate(45 -5.46 158)" id="h98-v" x1="73.3" x2="76.92" xlink:href="#h98-d" y1="74.83" y2="78.46"/><linearGradient gradientTransform="scale(-1 1) rotate(45 0 172)" id="h98-w" x1="-86.14" x2="-89.77" xlink:href="#h98-d" y1="241.98" y2="238.36"/><linearGradient gradientTransform="scale(-1 1) rotate(-22.51 -.02 136)" id="h98-x" x1="-111.95" x2="-111.95" xlink:href="#h98-e" y1="117.4" y2="122.93"/><linearGradient gradientTransform="scale(-1 1) rotate(-22.51 -.02 136)" id="h98-y" x1="-111.95" x2="-111.95" xlink:href="#h98-e" y1="124.17" y2="116.64"/><radialGradient cx="21.66" cy="-.18" gradientUnits="userSpaceOnUse" id="h98-g" r="23.16"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".55" stop-color="#fff"/><stop offset=".64" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><radialGradient cx=".5" cy=".2" id="h98-f" r="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><radialGradient cx=".5" cy=".75" id="h98-j" r="1.1" xlink:href="#h98-f"/><radialGradient cx=".5" cy=".15" id="h98-o" r="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".6" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><symbol id="h98-h" viewBox="0 0 26.96 6.98"><path d="m.92 0 26.04 6.98H0" fill="url(#h98-g)"/></symbol><symbol id="h98-m" viewBox="0 0 26.18 27"><use height="6.98" transform="matrix(.966 .259 -.266 .992 1.85 13.1)" width="26.96" xlink:href="#h98-h"/><use height="6.98" transform="matrix(.866 .5 -.521 .903 6.33 7.22)" width="26.96" xlink:href="#h98-h"/><use height="6.98" transform="rotate(45 3 16.15) scale(1 1.079)" width="26.96" xlink:href="#h98-h"/><use height="6.98" transform="matrix(.5 .866 -.941 .543 19.13 -.14)" width="26.96" xlink:href="#h98-h"/><use height="6.98" transform="matrix(.259 .966 -.985 .264 25.94 -.89)" width="26.96" xlink:href="#h98-h"/></symbol><symbol id="h98-r" viewBox="0 0 2 2.48"><path d="M2 1c0 .55-.23 1.48-1 1.48S0 1.55 0 1a1 1 0 0 1 2 0Z"/><circle cx="1" cy="1" fill="url(#h98-f)" r="1"/></symbol><clipPath id="h98-l"><path d="M129.03 103.55s-.92-1.25-.06-3.89a6.6 6.6 0 0 1-3.89-4.9s-3.61-.8-4.57-3.76c0 0-2.63 0-4.88-3.3a8.76 8.76 0 0 1-5.63-3.26 8.76 8.76 0 0 1-5.63 3.27C102.12 91 99.49 91 99.49 91c-.96 2.97-4.57 3.76-4.57 3.76a6.61 6.61 0 0 1-3.89 4.9c.86 2.64-.06 3.9-.06 3.9 1.56 2.23 5.22 6.94 19.03 6.94s17.47-4.71 19.03-6.95Z" fill="none"/></clipPath><filter id="h98-i"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h98-i)"><path d="M79.47 148.49c-12.98 0-6.97-17.45-2.62-11.14 7.9 11.46 58.06 11.96 66.3 0 4.36-6.3 10.36 11.14-2.62 11.14Z" fill="#282828"/><path d="M143.13 137.35c-3.33 4.46-16.78 6.73-19.16 3.06H95.99c-2.38 3.67-15.83 1.4-19.16-3.06a21.31 21.31 0 0 1 1.5 14.74 63.43 63.43 0 0 0 7.57 10.12 5.86 5.86 0 0 1 8.34 8.21 95.7 95.7 0 0 0 15.74 11.06 95.7 95.7 0 0 0 15.74-11.06 5.86 5.86 0 0 1 8.33-8.2 63.43 63.43 0 0 0 7.59-10.13 21.32 21.32 0 0 1 1.49-14.74Z" fill="url(#h98-j)"/><path d="M95.21 130.79c.93 3.24.8 9.62.8 9.62s8.15 17.04 13.99 17.04V130.8Z" fill="url(#h98-a)"/><path d="M124.79 130.79H110v26.66c5.84 0 13.99-17.04 13.99-17.04s-.13-6.38.8-9.62Z" fill="url(#h98-e)"/><ellipse cx="110" cy="118.1" fill="url(#h98-b)" rx="17.39" ry="19.01"/><ellipse cx="110" cy="118.1" rx="17" ry="16.21" stroke="url(#h98-d)"/><path d="M129.06 106.38H90.94l.77 2.46s2.64 5.73 18.29 5.73 18.29-5.73 18.29-5.73Z" fill="url(#h98-k)"/><g clip-path="url(#h98-l)"><use height="27" transform="matrix(.881 0 0 1.047 87.06 84.4)" width="26.18" xlink:href="#h98-m"/><use height="27" transform="matrix(-.881 0 0 1.047 132.94 84.4)" width="26.18" xlink:href="#h98-m"/></g><path d="M92.28 103.55c1.46 2.24 4.86 6.95 17.72 6.95s16.26-4.71 17.72-6.95" fill="none" stroke="url(#h98-c)"/><path d="m103.03 107.73 1.37 4.24c-.44 6.08-8.14 8.29-8.14 16.07a5.44 5.44 0 0 0 2.64 4.81m-2.32-28.5.7 4c-.87 4.88-6.56 7.67-6.56 11.12s2.65 3.49 2.65 3.49m-1.99-8.61c-.84-3.37-.83-5.76 2.47-9.1v-3.4m23.12 5.88-1.36 4.24c.43 6.08 8.14 8.29 8.14 16.07a5.44 5.44 0 0 1-2.65 4.82m-9.26-19.8-1.84-4.25-1.84 4.25m18.47 9.9s2.65-.03 2.65-3.49-5.69-6.25-6.55-11.13l.7-4m2.73-2.5v3.4c3.3 3.35 3.3 5.74 2.46 9.1" fill="none" stroke="url(#h98-n)"/><path d="M108.61 138.3c-3.75-5.85.3-16.87.3-20.98a11.25 11.25 0 0 0-.95-4.4l2.04-3.51 2.05 3.5a11.25 11.25 0 0 0-.96 4.4c0 4.12 4.05 15.14.3 20.99Zm-8.13-27.26c-.03 7.07-6.81 8.78-6.81 14.72 0 2.28.73 6.4 4.77 7.41a6.32 6.32 0 0 1-2.65-5.23c0-7.78 7.7-9.99 8.14-16.06l-1.34-3.93ZM94.4 107c1.04 4.43-5.57 7.82-5.57 11.34s2.15 5.05 4.01 5.03c0 0-2.53-.45-2.53-3.9s5.69-6.25 6.56-11.14l-.76-3.87Zm-2.17-4.24c-.73 2.85-5.18 6.95-1.36 11.58-.84-3.36-.73-5.76 2.57-9.1v-3.4Zm25.2 5.18-1.35 3.93c.43 6.07 8.14 8.28 8.14 16.06a6.32 6.32 0 0 1-2.64 5.23c4.03-1 4.76-5.13 4.76-7.41 0-5.94-6.78-7.65-6.81-14.72Zm6.48-3.48-.75 3.87c.86 4.89 6.55 7.68 6.55 11.14s-2.53 3.9-2.53 3.9c1.86.02 4-1.5 4-5.03s-6.6-6.91-5.56-11.34Zm2.68-2.63v3.4c3.3 3.35 3.4 5.75 2.56 9.1 3.82-4.62-.62-8.72-1.35-11.56Z" fill="url(#h98-o)"/><path d="M78.48 149.42c-10.6-.49-9.29-14.53-3.67-14.53 4.86 0 4.5 12.45 4.32 16.93a71.82 71.82 0 0 0 6.92 9.29 6.63 6.63 0 0 1 8.5.76 6.54 6.54 0 0 1 .7 8.4A105.12 105.12 0 0 0 110 180.33a105.12 105.12 0 0 0 14.76-10.06 6.54 6.54 0 0 1 .69-8.4 6.63 6.63 0 0 1 8.5-.76 71.82 71.82 0 0 0 6.92-9.29c-.17-4.47-.54-16.93 4.32-16.93 5.62 0 6.93 14.05-3.67 14.54" fill="none" stroke="url(#h98-p)"/><path d="M141.6 148.49c9 0 8.45-12.75 3.47-12.75-4.2 0-3.41 16.35-3.41 16.35a63.43 63.43 0 0 1-7.59 10.12 5.86 5.86 0 0 0-8.34 8.21A95.7 95.7 0 0 1 110 181.48a95.7 95.7 0 0 1-15.74-11.06 5.86 5.86 0 0 0-8.33-8.2 63.43 63.43 0 0 1-7.59-10.13s.8-16.35-3.41-16.35c-4.99 0-5.53 12.75 3.47 12.75" fill="none" stroke="url(#h98-q)"/><use height="2.48" transform="translate(109 112.06)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="translate(101.09 111.08)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="translate(94.21 107.38)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="translate(91 103.23)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="matrix(-1 0 0 1 118.91 111.08)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="matrix(-1 0 0 1 125.79 107.38)" width="2" xlink:href="#h98-r"/><use height="2.48" transform="matrix(-1 0 0 1 129 103.23)" width="2" xlink:href="#h98-r"/><path d="M124.8 141.05a50.1 50.1 0 0 1-14.8 18.4 50.11 50.11 0 0 1-14.8-18.4" fill="none" stroke="#000"/><path d="M125.28 140.83a50.64 50.64 0 0 1-15.07 17.62 55.35 55.35 0 0 1-15.49-17.41" fill="none" stroke="url(#h98-s)"/><path d="M124.43 140.4a48.79 48.79 0 0 1-14.22 17.05 53.51 53.51 0 0 1-14.64-16.83" fill="none" stroke="url(#h98-t)"/><path d="m110 161.23 2.74 1.16 1.07 2.57-1.17 2.81-2.64 2.28-2.64-2.28-1.17-2.8 1.07-2.58 2.74-1.16z" fill="none" stroke="#000"/><path d="m110 160.23 2.74 1.16 1.07 2.57-1.17 2.81-2.64 2.28-2.64-2.28-1.17-2.8 1.07-2.58 2.74-1.16z" fill="none" stroke="url(#h98-u)"/><path d="m110 160.81-.62-.9v-3.96l.62-1v5.86z" fill="url(#h98-v)"/><path d="m110 160.81.62-.9v-3.96l-.62-1v5.86z" fill="url(#h98-w)"/><path d="m110 161.1 2.1.9.8 1.93-.9 2.17-2 1.86-2-1.86-.9-2.17.8-1.92Z" fill="url(#h98-x)" stroke="url(#h98-y)"/></g>'
                    )
                )
            );
    }

    function hardware_99() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Vambraced Arm of the Warrior',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><radialGradient cx=".7" cy=".3" id="h99-a" r="1"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient gradientUnits="userSpaceOnUse" id="h99-b" x1="4.83" x2="4.83" y1="28.77"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -0.03, 0, 8505.41)" gradientUnits="userSpaceOnUse" id="h99-c" x2="10.24" y1="263417.31" y2="263417.31"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="translate(142.76 -4.2) rotate(-0.39)" gradientUnits="userSpaceOnUse" id="h99-d" x1="-131.01" x2="-125.32" y1="39.59" y2="39.59"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4c4c4c"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h99-e" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h99-f" x1="1" x2="0" xlink:href="#h99-e" y1="0" y2="0"/><linearGradient id="h99-g" x1="0" x2="1" xlink:href="#h99-e" y1="0" y2="1"/><linearGradient id="h99-h" x1="0" x2="1" xlink:href="#h99-e" y1="0" y2="0"/><filter id="h99-i" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="translate(208.62 -29.49) rotate(75.37)" gradientUnits="userSpaceOnUse" id="h99-k" x1="111.17" x2="156.07" y1="157.15" y2="122.48"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="translate(472.33 -303.06) rotate(83.15)" id="h99-t" x1="352.24" x2="362.62" xlink:href="#h99-e" y1="423.31" y2="415.3"/><symbol id="h99-x" viewBox="0 0 10.24 2"><polygon fill="url(#h99-c)" points="10.24 0 0 0 2 2 8.24 2 10.24 0"/></symbol><symbol id="h99-w" viewBox="0 0 35.32 74.31"><polygon fill="url(#h99-d)" points="17.86 68.72 12.24 68.77 11.87 3.8 17.49 3.76 17.86 68.72"/><use height="2" transform="matrix(0.55, -0.01, 0.02, 2.77, 12.24, 68.79)" width="10.24" xlink:href="#h99-x"/><polygon fill="url(#h99-e)" points="14.66 3.6 14.66 3.61 14.66 3.6 14.66 3.6"/><polygon fill="url(#h99-f)" points="14.48 5.85 11.89 7.43 5.99 7.01 0 7.67 0 0 5.99 0.67 14.66 0.04 35.32 3.46 35.32 4.41 17.51 7.15 14.48 5.85"/><path d="M14.72,24.27a11.87,11.87,0,0,1-1.28-4.69V3.27H16V19.59A11.83,11.83,0,0,1,14.72,24.27Z" fill="url(#h99-e)"/><polygon fill="url(#h99-h)" points="0 6.93 0 0.83 5.99 1.9 14.66 1.29 35.32 3.5 35.32 4.45 14.66 6.64 5.99 5.98 0 6.93"/></symbol><symbol id="h99-y" viewBox="0 0 27.425 17.897"><path d="M0,8.6845A145.5154,145.5154,0,0,1,17.79,17.129c5.5522,3.14,11.8809-4.0057,8.8477-9.617C21.5087-1.9769,7.07-3.4211,0,8.6845Z" fill="url(#h99-a)"/></symbol></defs><g filter="url(#h99-i)"><path d="M112.1,149.62,88.68,127.31l13.88-20.26c-9-6.67-6.92-10.74-6.92-10.74s-25.11,19.8-22.71,35.11c5.36,9.34,9.39,26.42,23.88,36.52Z" fill="url(#h99-a)"/><polyline fill="none" points="100.71 103.11 75.28 130.84 116.7 168.97" stroke="url(#h99-k)" stroke-width="1.11"/><polyline fill="url(#h99-g)" points="64.825 133.624 76.841 128.092 92.665 126.357 81.182 139.333 64.825 133.624"/><polyline fill="url(#h99-f)" points="92.665 126.357 64.825 133.624 76.308 120.647 92.665 126.357"/><path d="M92.64,126.27a5.67,5.67,0,0,1,3.81,1.65c-10.76,8.28-19.8,16.4-19.8,16.4l-1-7.08s8.41-5.79,17-11m0,0A5.64,5.64,0,0,0,95.16,123c-13.44-2-25.29-4.64-25.29-4.64l2.6,6.67s10.16.94,20.17,1.26" fill="url(#h99-a)"/><path d="M97.8,102c-3.46-4-2.44-8.47,5.25-10.69s8.84,9.49,8.84,9.49" fill="url(#h99-a)"/><use height="74.31" transform="matrix(-0.76, 0.64, -0.64, -0.76, 154.04, 125.86)" width="35.32" xlink:href="#h99-w"/><path d="M97.32,100.88c2.1-4.52,8.15-4.47,10.06-2.29s2.23,3.47,3.51,3.63a1.72,1.72,0,0,0,1.77-.94s3.48,3.36,1.85,5.25c-2.06.3-2.43,1.66-3.72,1.84s-4.9.26-6.7-.66C102,106.64,97.71,103.75,97.32,100.88Z" fill="url(#h99-a)"/><path d="M109.94,89.09s.93-2.43-2-2.78-6,3.32-5,5.91A9.84,9.84,0,0,0,109.94,89.09Z" fill="url(#h99-a)"/><path d="M113.12,91.91s-.06-3.55-3.07-3.28c-2.14,1.85-6.33,2.2-7.15,3.59s-1,3.54,1.9,4.43Z" fill="url(#h99-a)"/><path d="M116.44,94.26c.68-3.12-3.42-2.94-3.42-2.94a22.66,22.66,0,0,0-8.22,5.33,3.09,3.09,0,0,0,2.72,3.43,9.09,9.09,0,0,1,3.48-3Z" fill="url(#h99-a)"/><path d="M119.35,100.1s2.43-5.66-2.91-5.84c-3.21,1.16-5.11,2.41-6,2.71s-2.91,3.11-2.91,3.11a4.64,4.64,0,0,0,5.65.67C115.11,99.7,118.36,98,119.35,100.1Z" fill="url(#h99-a)"/><path d="M120.25,100.56c.15-1.18-3.28-2.88-6.78-.11-2.64,2.1.09,3.39,1,6.08C116.42,102.29,120.09,101.86,120.25,100.56Z" fill="url(#h99-a)"/><path d="M95.64,96.31s-1.39,5.44,6.92,10.74" fill="none" stroke="url(#h99-t)" stroke-width="1.11"/><use height="20.39" transform="matrix(-0.16, 0.99, -0.99, -0.16, 117.42, 146.99)" width="25.95" xlink:href="#h99-y"/><use height="20.39" transform="matrix(-0.16, 0.99, -0.99, -0.16, 120.34, 149.28)" width="25.95" xlink:href="#h99-y"/><use height="20.39" transform="matrix(-0.16, 0.99, -0.99, -0.16, 123.26, 151.58)" width="25.95" xlink:href="#h99-y"/><use height="20.39" transform="matrix(-0.16, 0.99, -0.99, -0.16, 126.19, 153.88)" width="25.95" xlink:href="#h99-y"/><use height="20.39" transform="matrix(-0.16, 0.99, -0.99, -0.16, 129.11, 156.17)" width="25.95" xlink:href="#h99-y"/></g>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}