// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract AssetsImp10 {

  string internal constant C_DEAD_PLANT = "<g transform='translate(-312,0)'><g id='g-u-deadplant'><path id='g-u-shadow-14' fill='#1d1d1b' d='M478.81,623.77c-7.14-3.26-18.02-1.8-24.26,3.26s-5.51,11.83,1.63,15.09s18.02,1.8,24.26-3.26s5.51-11.83-1.63-15.09' opacity='0.3' style='mix-blend-mode:multiply'/><g id='g-u-group-c2-s12'><path id='g-s-path260' fill='var(--c2b)' stroke='#1d1d1b' stroke-linejoin='round' d='M481.65,612.66l-34.98-.51l2.18,22.78c-.1,2.3,1.41,4.62,4.52,6.37c6.01,3.38,15.77,3.38,21.74,0c3.28-1.85,3.98-4.84,4.4-6.77l2.13-21.86Z'/><path id='g-s-path261' fill='var(--c2b)' stroke='#1d1d1b' stroke-linejoin='round' d='M481.47,610.61l-.16-.48c0,0-.01-.04-.02-.05-.7-1.78-2.28-3.47-4.74-4.85-6.85-3.85-17.96-3.85-24.76,0-2.51,1.42-4.09,3.17-4.74,5.01c0,.02-.02.04-.02.06l-.02.06c-1.03,3.1.6,6.44,4.86,8.84c6.85,3.85,17.96,3.85,24.76,0c4.12-2.33,5.73-5.55,4.84-8.58Z'/></g><path id='g-s-path262' fill='#1d1d1b' stroke='#1d1d1b' stroke-linejoin='round' d='M464.16,610.61c4.1,0,7.95.8,10.83,2.25c1.29.65,2.3,1.39,3.02,2.19.83-.92,1.27-1.91,1.27-2.93c0-1.9-1.53-3.72-4.29-5.11-2.88-1.45-6.73-2.25-10.83-2.25s-7.93.8-10.8,2.25c-2.72,1.38-4.22,3.18-4.22,5.07c0,1.02.44,2.01,1.27,2.92.71-.78,1.69-1.51,2.94-2.15c2.86-1.45,6.69-2.25,10.8-2.25Z'/><path id='g-s-path263' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M451.28,615.83c.6.49,1.32.95,2.16,1.37c2.88,1.45,6.73,2.25,10.83,2.25s7.93-.8,10.8-2.25c.81-.41,1.5-.85,2.08-1.33v0c.32-.26.61-.53.86-.81-.72-.8-1.73-1.54-3.02-2.19-2.88-1.45-6.73-2.25-10.83-2.25s-7.93.8-10.8,2.25c-1.26.64-2.24,1.37-2.94,2.15.25.28.54.55.86.81v0Z'/><path id='g-s-path264' fill='#432918' stroke='#1d1d1b' stroke-miterlimit='10' d='M468.96,613.92v0c.87-2.75,1.75-5.47,3.13-8.22.74-1.38,1.58-2.97,3.12-3.8c1.69-.75,3.62-.84,5.24-1.12c1.86-.22,3.55-.57,5.33-.84c3.42-.27,5.48,3.24,6.65,5.72.65,1.38,1.27,2.7,1.65,4.2.77,3.12.19,6.1.16,8.73-.02,1.33.09,2.62.42,3.86.77,2.73.98,5.62,1.47,8.36.44,3.5,2.69,5.94,6.16,6.58.72.22,1.46,1.41,1.46,1.41-7.96-1.08-8.84-4.59-10.15-11.78-.52-2.83-1.77-5.52-1.77-8.4-.1-2.95.22-5.67-.53-8.02-.38-1.21-1.04-2.41-1.64-3.52-.88-1.46-1.7-3.14-3.15-3.63-.37-.1-.86.11-1.23.18-2.61.69-6.05,1.1-8.18,1.86-1.86,2.62-2.67,6.34-3.58,9.69'/><path id='g-s-path265' fill='#432918' stroke='#1d1d1b' stroke-miterlimit='10' d='M459.18,615.04v0c.04-3.57-2.72-6.85-2.94-10.74-.09-5.18,1.36-10.35,4.87-14.29c1.42-1.39,3.12-2.19,4.51-3.76c3.34-3.57,6.58-7.92,8.38-12.47c1.05-2.67,2.5-4.8,3.91-7.04c1.11-1.78,3.12-4.55,3.99-6.42c0,0-.11,2.5-.75,3.79c0,0-1.9,3.42-1.9,3.42-1.22,2.27-2.53,4.61-3.23,6.88-.36,1.33-.91,2.63-1.48,3.83-2.55,4.99-5.45,9.9-9.94,13.47-.29.22-.55.51-.8.78-2.34,3.03-3.29,7.54-2.94,11.34.41,2.16,1.82,4.41,2.74,6.68.54,1.35,1.1,2.92,1.04,4.92'/><path id='g-s-path266' fill='#432918' stroke='#1d1d1b' stroke-miterlimit='10' d='M463.12,617.49v0c.21-3.47.96-6.14,1.78-9.3.85-2.66,1.49-5.89,3.26-8.02c2.56-2.82,6.12-4.19,8.41-7.08.17-.2.43-.94.65-1.56.86-2.49,1.88-5.91,3.03-8.27c1.04-2.09,2.43-4.69,4.85-5.21c2.55-.49,4.63,1.97,5.48,4.24c1.18,3.68,2.88,8.68,4.17,12.31.38,1.02.98,2.74,1.43,3.71c0,0,.04.08.04.08s-1.97-2.46-2.35-3.37c-1.05-2.52-3.69-9.34-4.7-11.98-5.03-8.54-7.69,5.54-8.77,9.69-1.03,5.33-6.56,7.31-9.21,11.15-1.33,4.19-2.34,9.22-2.42,13.61'/><path id='g-s-path267' fill='#432918' stroke='#1d1d1b' stroke-miterlimit='10' d='M455.33,617.23v0c.02-.49-.1-.87-.3-1.14-.19-.29-.53-.35-.37-.4.07-.04.2-.18.18-.22c0-.09-.16.29-.23.66-.95,8.12.3,17.22-2.77,25.26-.6,1.57-1.76,3.13-3.22,4.11-1.21.99-2.35,2.06-3.48,3.14-1.52,1.46-5.22,3.81-5.22,3.81c2.66-3.28,5.39-6.54,8.44-9.47c2.23-3.07,2.07-7.67,2.21-11.46.24-5.28-.95-10.6-.56-16.11.95-7.59,10.52-5.11,10.89,1.48'/><path id='g-s-path268' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M479.59,567.47c.09,1.58-.85,3.02-.82,4.52.02,1.28.72.63,1.24,1.34.42.56.2,2.55.42,3.31.18.62.51,1.66,1.06,2.04.94-.81.7-2.97.86-4.1s.7-2.36-.74-2.48c-.02-1.28-.6-3.56-2.02-4.63Z'/><path id='g-s-path269' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M491.62,591.01c-.54,1.07-.83,2.05-.96,3.26-.16,1.49.23,1.16.82,2.07.81,1.27-.21,3.17.43,4.52.31.65,1.13,1.1,1.7,1.54-.36-2.06.16-4.23-.22-6.23-.27-1.41-.14-4.71-1.77-5.16Z'/><path id='g-s-path270' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M491.62,621.63c-1.18.31-2.67,1.62-3.76,2.27-.28.17-1.23.68-1.29,1.02-.07.45.47.58.61.95.41,1.07-.58,1.8-1.03,2.83-.53,1.19-1.26,2.98-1.16,4.32c2.42-1.16,5.57-3.03,5.49-6.1c1.96,1.74,1.63-4.48,1.14-5.29Z'/><path id='g-s-path271' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M451.99,645.9c.13,1.22,1.2,2.89,1.68,4.06.12.3.48,1.32.82,1.43.44.14.65-.38,1.03-.46c1.12-.24,1.69.84,2.64,1.45c1.1.7,2.75,1.7,4.09,1.8-.79-2.57-2.16-5.97-5.2-6.35c2.01-1.68-4.18-2.29-5.06-1.93Z'/><path id='g-s-path272' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M453.83,630.46c-.3.81-.14,2.21-.2,3.1-.02.23-.1.99.07,1.16.23.23.53-.04.8.03.78.2.81,1.06,1.23,1.74.48.79,1.22,1.94,2.03,2.42.3-1.87.49-4.46-1.32-5.65c1.8-.44-1.94-2.76-2.61-2.8Z'/><path id='g-s-path273' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M493.37,635.33c-.79.34-1.7,1.42-2.39,1.99-.18.15-.79.6-.79.85c0,.32.39.36.53.6.4.7-.21,1.32-.42,2.09-.24.89-.56,2.22-.35,3.14c1.57-1.07,3.57-2.72,3.18-4.86c1.56,1,.66-3.3.23-3.82Z'/><path id='g-s-path274' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M498.2,629.52c.68,1.01,2.42,1.99,3.39,2.79.25.21,1.05.93,1.39.87.45-.08.39-.64.7-.89.87-.74,1.89-.05,3.01.03c1.3.1,3.23.2,4.46-.34-1.9-1.89-4.71-4.25-7.58-3.15.99-2.43-4.76-.05-5.37.68Z'/><path id='g-s-path275' fill='#432918' stroke='#1d1d1b' stroke-linejoin='round' d='M447.36,640.52c-.54.8-1.91,1.57-2.67,2.2-.2.16-.82.74-1.1.69-.36-.06-.31-.5-.55-.7-.69-.58-1.49-.04-2.38.03-1.03.08-2.55.16-3.52-.26c1.5-1.49,3.72-3.35,5.98-2.49-.78-1.92,3.76-.04,4.24.54Z'/></g></g>";
  string internal constant C_WATERMELON = "<g transform='translate(-312,0)'><g id='g-u-watermellon'><g id='g-u-c-mellon'><path id='g-u-shadow-18' fill='#1d1d1b' d='M448.3,605.68c-6.01,3.94-2.54,6.84,2.86,5.23c3.11-.93,30.31-8.85,38.38-18.61s-12.95-9.95-19.52-6.76-21.72,20.13-21.72,20.13Z' opacity='0.3' style='mix-blend-mode:multiply'/><path id='g-s-path276' fill='#23633a' d='M458.4,559.54c-11.19-2.54-25.16-1.02-29.98,6.87s-8.34,20.91,1.17,32.03s26.33,9.95,29.69,8.92s19.45-5.85,20.77-17.7-2.34-25.74-21.65-30.13Z'/><path id='g-s-path277' fill='#61b240' d='M445.9,579.05c-1.92,1.09-3.76,2.32-5.59,3.56-2.42,1.63-4.88,3.3-6.76,5.54c15.15-4.02,31.27-3.37,46.4-7.36-.29-2.04-.8-4.07-1.57-6.01-10.85-2.71-22.74-1.25-32.48,4.27Z'/><path id='g-s-path278' fill='#61b240' d='M439.82,571.01c-3.64,4.05-6.79,9.72-6.91,15.3.87-.28,1.05-1.71,1.42-2.5.58-1.21,1.34-2.34,2.26-3.31c1.94-2.05,4.47-3.41,6.82-4.97c3.57-2.37,6.78-5.28,10.5-7.41c4.82-2.75,10.42-4.07,15.96-3.84-3-2.04-6.78-3.68-11.49-4.75-.14-.03-.29-.06-.43-.09-.76.32-1.52.62-2.27.93-5.94,2.45-11.58,5.85-15.88,10.63Z'/><path id='g-s-path279' fill='#61b240' d='M445.98,605.4c-5.44-4.16-11.16-8.71-13.38-15.19-.72.1-1,.99-1.03,1.72-.09,2.96,1.38,5.74,3.06,8.17c1.06,1.54,2.22,3.02,3.21,4.6c3.9,1.87,8.02,2.76,11.64,3.1-1.23-.69-2.38-1.55-3.5-2.41Z'/><path id='g-s-path280' fill='#61b240' d='M431.94,586.09c.11-5.52-.2-10.87,2.22-15.83c2.62-5.36,7.54-9.11,12.95-11.83-2.26.06-4.47.3-6.57.74-1.51.95-3.11,1.8-4.46,2.96-1.91,1.64-3.24,3.83-4.54,5.99-.83,1.38-1.67,2.77-2.23,4.28-1.72,4.62-.15,9.63,2.63,13.7Z'/><path id='g-s-path281' fill='#61b240' d='M476.23,590.3c-7.02-.79-14.1.23-21.15.71s-14.38.37-20.83-2.52c-.48.57-.41,1.47,0,2.1.4.63,1.06,1.06,1.72,1.42c2.15,1.18,4.51,1.93,6.87,2.59c9.68,2.69,19.75,3.95,29.79,3.74c1.07-.02,2.14-.06,3.21-.06c2.01-2.14,3.55-4.71,4.08-7.77-1.21.08-2.49-.08-3.68-.21Z'/><path id='g-s-path282' fill='#61b240' d='M423.63,581.19c-.08,1.49-.03,3.01.17,4.54c1.89,1.5,4.03,1.5,6.06,2.14-2.26-1.12-4.64-3.91-6.23-6.68Z'/><path id='g-s-path283' fill='#61b240' d='M430.69,597.93c-.38-2.91-.75-5.92.09-8.73-1.95,1.16-2.62,3.6-3.86,5.52.75,1.26,1.62,2.5,2.67,3.72.45.52.92,1.01,1.4,1.48-.12-.66-.21-1.33-.29-1.99Z'/><path id='g-s-path284' fill='#61b240' d='M427.21,584.38c1.01,1.42,2.76,2.6,4.42,2.08-4.44-5.13-5.91-12.74-3.43-19.06.29-.73.63-1.43,1.01-2.11-.28.36-.56.72-.8,1.11-1.99,3.26-3.75,7.39-4.48,11.89c1.11,1.77,2.43,4.91,3.28,6.08Z'/><path id='g-s-path285' fill='#61b240' d='M424.93,588.28c-.24-.06-.47-.13-.71-.21.29,1.23.68,2.47,1.2,3.7.34-.46.77-.87,1.24-1.19c1.22-.82,2.68-1.17,4.1-1.51-1.97,0-3.94-.27-5.84-.78Z'/><path id='g-s-path286' fill='#23633a' stroke='#000' stroke-linecap='round' stroke-linejoin='round' d='M431.49,586.3c-2.02-.22-1.61,2.49-.73,3.51s1.9,1.32,2.78,0-.73-3.36-2.05-3.51Z'/><path id='g-s-path287' fill='none' stroke='#000' stroke-linecap='round' stroke-linejoin='round' d='M458.4,559.54c-11.19-2.54-25.16-1.02-29.98,6.87s-8.34,20.91,1.17,32.03s26.33,9.95,29.69,8.92s19.45-5.85,20.77-17.7-2.34-25.74-21.65-30.13Z'/></g><g id='g-u-c-slice'><g id='g-u-shadow-19'><path id='g-s-path288' fill='#1d1d1b' d='M462.31,616.09c8.34,3.86,50.29-12.4,46.04-21.36-2.53-5.35-21.68,1.97-28.16,3.66-6.8,1.77-12.61,9.64-16.02,13.22s-1.87,4.48-1.87,4.48Z' opacity='0.3' style='mix-blend-mode:multiply'/></g><path id='g-s-path289' fill='#b7eab2' stroke='#1d1d1b' stroke-linejoin='round' d='M502.71,582.03c-.68,5.94-4.3,25.98-22.14,27.42-17.96,1.45-27.38-8.12-28.59-22.6-1.23.46-2.07.79-2.07.79.75,15.29,8.39,26.28,30.94,24.05c22.56-2.24,24.05-29.08,24.05-29.08l-2.2-.58Z'/><path id='g-s-path290' fill='#f44545' stroke='#000' stroke-miterlimit='10' d='M480.58,609.45c17.83-1.44,21.45-21.48,22.14-27.42l-4.88-1.28-5.22,1.12-6.9-.37c0,0-6.15-.19-7.64-.19s-4.47,1.3-5.03,1.49-4.29.93-4.85.75c-.56-.19-4.85,0-7.27.37-1.67.26-6.23,1.92-8.93,2.94c1.21,14.48,10.63,24.05,28.59,22.6Z'/><path id='g-s-path291' fill='#23633a' stroke='#000' stroke-linecap='round' stroke-linejoin='round' d='M449.93,587.64c.75,4.85,4.72,15.51,9.93,18.68s13.74,6.49,21.01,5.37c0,0-20.94,5.51-30.3-9.03-4.9-7.61-.64-15.01-.64-15.01Z'/><path id='g-s-path292' fill='#c64646' d='M458.03,589.66c-2.37,1.09-2.83,4.72-1.11,5.4s3.09.34,4.89,3.52s5.23,3.34,7.2,2.66s1.8-2.74,4.2-1.2s5.66,3.77,7.98,2.4s2.49-3.6,4.97-4.37s4.03,1.03,5.66-1.8s1.11-4.29,3.43-5.4s3.86-.86,4.29-2.92.77-3.26,0-3.52-2.57.34-3.86,1.89-4.55,3.34-6.18,3-3.34-.69-4.89.77-5.57,2.23-7.03,2.06-2.32-1.46-5.32,0-4.72,1.89-5.57.94-1.97-3.6-4.2-2.92-3.34-1.03-4.46-.51Z'/><path id='g-s-path293' fill='#1d1d1b' d='M473.53,596.89c-.05-.4-.18-.78-.38-1.13-.14-.24-.48-.34-.72-.19-.06.04-.11.09-.15.14-.11.09-.17.23-.18.38c0,.36,0,.72,0,1.09v.54c0,.25,0,.51.19.69.22.22.54.27.81.11.2-.11.34-.34.39-.56.08-.35.09-.72.05-1.08Z'/><path id='g-s-path294' fill='#1d1d1b' d='M480.43,593.32c-.21-.18-.55-.22-.75,0-.16.18.15,2,.43,2.61.09.19.34.28.53.25.22-.03.37-.18.44-.38.31-.85.03-1.89-.65-2.48Z'/><path id='g-s-path295' fill='#1d1d1b' d='M491.35,590.58c-1.06,0-1.52,2.09-.67,2.63c1.13.45,1.72-2.48.67-2.63Z'/><path id='g-s-path296' fill='#1d1d1b' d='M487.12,594.37c-.07-.27-.13-.55-.2-.82-.03-.13-.13-.25-.24-.32-.07-.04-.16-.06-.25-.06-.07-.01-.15-.01-.22.01-.13.04-.25.12-.32.24s-.1.27-.05.41c.09.27.17.55.26.82.04.13.12.25.24.32.11.07.28.09.41.05s.25-.12.32-.24c.07-.13.09-.26.05-.41Z'/><path id='g-s-path297' fill='#1d1d1b' d='M476.86,598.68c-.07-.27-.13-.55-.2-.82-.03-.13-.13-.25-.24-.32-.07-.04-.16-.06-.25-.06-.07-.01-.15-.01-.22.01-.13.04-.25.12-.32.24s-.1.27-.05.41c.09.27.17.55.26.82.04.13.12.25.24.32.11.07.28.09.41.05s.25-.12.32-.24c.07-.13.09-.26.05-.41Z'/><path id='g-s-path298' fill='#1d1d1b' d='M484.4,594.78c-.09-.09-.24-.16-.37-.15-.14,0-.28.05-.37.15-.1.11-.14.23-.15.37-.02.34-.05.67-.07,1.01c0,.13.07.28.15.37s.24.16.37.15c.14,0,.28-.05.37-.15.1-.11.14-.23.15-.37.02-.34.05-.67.07-1.01c0-.13-.07-.28-.15-.37Z'/><path id='g-s-path299' fill='#1d1d1b' d='M463.46,595.19c-.91-2.07-1.78,2.17-.54,2.29.82-.17.67-1.67.54-2.29Z'/><path id='g-s-path300' fill='#1d1d1b' d='M462.5,593.53c-.03-.12-.13-.26-.24-.32-.12-.06-.27-.1-.41-.05-.13.04-.25.12-.32.24-.03.05-.05.1-.08.15-.02.03-.05.04-.07.08-.17.34-.33.67-.5,1.01-.06.13-.09.27-.05.41.03.12.13.26.24.32.12.06.27.1.41.05.13-.04.25-.12.32-.24.21-.41.43-.83.64-1.24.07-.13.09-.27.05-.41Z'/><path id='g-s-path301' fill='#1d1d1b' d='M498.26,588.06c0,0-.04-.08-.06-.13c0,0,0,0,0,0s0-.01,0-.02c-.16-.42-.38-.81-.67-1.16-.08-.1-.25-.15-.37-.15s-.28.06-.37.15c-.09.1-.16.23-.15.37c0,.02,0,.04,0,.06c0,.1,0,.19.06.28.2.33.4.66.6.99.14.23.42.32.66.22.23-.1.39-.37.31-.62Z'/></g></g></g>";
  string internal constant C_GRAMOPHONE = "<g transform='translate(-312,0)'><g id='g-u-gramophone'><g id='g-u-gramophone-grp' transform='translate(-11.637146 77.559265)'><path id='g-u-shadow' fill='#1d1d1b' d='M501.57 500.01 438.85 536.19 501.57 575.22 564.27 536.19 501.57 500.01z' opacity='0.3' style='mix-blend-mode:multiply'/><g id='g-u-c-grammophone-base-a'><path id='g-u-shadow-2' fill='#1d1d1b' d='M501.57 500.01 438.85 536.19 501.57 575.22 564.27 536.19 501.57 500.01z' opacity='0.3' style='mix-blend-mode:multiply'/><path id='g-u-polygon-c3b-s12' fill='var(--c3b)' stroke='#1d1d1b' stroke-linecap='square' stroke-linejoin='round' d='M480.75 483.33 418.03 519.52 480.75 558.55 543.45 519.51 480.75 483.33z'/><path id='g-u-polygon-c3b-s13' fill='var(--c3b)' stroke='#1d1d1b' stroke-linejoin='round' d='M418.03 549.05 418.03 519.52 480.75 558.55 480.75 589.25 418.03 549.05z'/><path id='g-u-polygon-c3l-s15' fill='var(--c3l)' stroke='#1d1d1b' stroke-linejoin='round' d='M425.7 544.86 425.7 533.32 473.08 562.81 473.08 575.22 425.7 544.86z'/><path id='g-u-polygon-c3l-s16' fill='var(--c3l)' stroke='#1d1d1b' stroke-miterlimit='10' d='M543.45 519.51 543.45 549.05 480.75 589.25 480.75 558.55 543.45 519.51z'/></g><g id='g-u-c-record-2'><g id='g-s-g21' style='isolation:isolate'><path id='g-s-path317' fill='#221e1f' stroke='#000' stroke-miterlimit='10' d='M509.16,504c-15.3-8.83-40.11-8.83-55.31,0s-15.12,23.2.18,32.04c15.3,8.83,40.11,8.83,55.31,0s15.12-23.2-.18-32.04'/></g><g id='g-s-g22' style='isolation:isolate'><path id='g-s-path318' fill='#ebebeb' stroke='#000' stroke-miterlimit='10' d='M487.76,514.92c-3.35-1.93-8.78-1.93-12.11,0s-3.31,5.08.04,7.01s8.78,1.93,12.11,0s3.31-5.08-.04-7.01'/></g></g><g id='g-u-group-c3-s12'><path id='g-u-pa17' fill='url(#g-u-pa17-fill-c3-s12)' stroke='#1d1d1b' stroke-linecap='square' stroke-linejoin='round' d='M484.12,512.73v5.28c0,.69-1.07,1.26-2.4,1.26s-2.4-.56-2.4-1.26v-5.28'/><path id='g-u-pa18' fill='var(--c3b)' stroke='#171d35' stroke-linecap='square' stroke-linejoin='round' d='M481.73,511.47c1.32,0,2.4.56,2.4,1.26s-1.07,1.26-2.4,1.26-2.4-.56-2.4-1.26s1.07-1.26,2.4-1.26'/></g><g id='g-u-c-handle'><path id='g-s-path319' fill='#9b9b9a' stroke='#000' stroke-miterlimit='10' d='M521.28,562c-.89-.5-.78-1.12-.78-1.89v-12.37c.03-1.42-.24-2.92-1.85-3.91l-1.85-1.04-.18-.1c0,0,0,0,0,0-.08-.04-.17-.05-.29-.03-.31.07-.72.39-1.03.93-.18.31-.28.61-.32.87-.05.35.02.62.18.72c0,0,.16.1.16.1l1.82,1.01c.44.28.48.98.47,1.38v12.44c0,0-.01,0-.01,0c0,.86.02,3.18,1.77,4.09c0,0,.32.19.32.19l6.7,3.89v-3.32L521.27,562v0'/><path id='g-u-path-c5l-s1' fill='var(--c5l)' stroke='#000' stroke-miterlimit='10' d='M534.1,567.21l-9.37-4.78-.38-.17c-.75-.32-1.85.5-2.47,1.86s-.53,2.75.22,3.1l9.74,4.94l2.27-4.95Z'/><ellipse id='g-u-ellipse-c5l-s1' fill='var(--c5l)' stroke='#000' stroke-miterlimit='10' rx='2.72' ry='1.49' transform='matrix(.41755-.908654 0.908654 0.41755 532.938725 569.69257)'/></g><g id='g-u-c-horn'><g id='g-u-gro-c5-s1'><path id='g-u-pa19' fill='url(#g-u-pa19-fill-c5-s1)' stroke='#000' stroke-miterlimit='10' d='M474.67,427.15c-1.22.08-2.36.32-3.53.54-7.81,1.81-14.97,4.55-22.39,7.41c0,0,12.92,23.2,12.92,23.2c13.52-23.39,24.45-19.26,27.03-14.81c7.15,12.33-5.14,19.08-9.81,26-4.15,5.68-5.29,13.44-4.39,20.03c0,0,.69,1.08,2.54.86s1.84-1.06,1.84-1.06c.09-7.88,3.36-14.38,9.82-18.91c8.38-5.87,12.94-12.93,12.87-23.18-.11-15.71-14.04-20.83-26.89-20.07Z'/></g><g id='g-u-group-c5-s12' style='isolation:isolate'><path id='g-s-path320' fill='var(--c5b)' stroke='#000' stroke-miterlimit='10' d='M429.38,408.79c-1.99-1.15-3.85-1.18-5.07-.07l-.31.27c-1.18,1.06-2.94.99-4.75-.06-.97-.56-1.94-1.39-2.85-2.47l-.43-.52c-.95-1.13-1.98-2.02-3.02-2.62-.89-.51-1.78-.81-2.62-.87-1.83-.12-3.15.93-3.63,2.89l-.12.48c-.68,2.72-3.1,3.48-5.84,1.89-.15-.09-.3-.18-.45-.28l-.49-.32c-.16-.11-.32-.21-.48-.3-1.82-1.05-3.53-1.16-4.76-.31-1.35.94-1.92,2.88-1.56,5.34l.08.61c.52,3.63-1.13,5.93-3.9,5.49l-.46-.08c-1.88-.31-3.32.57-3.95,2.39-.62,1.83-.34,4.33.78,6.88l.28.62c1.65,3.76,1.29,7.29-.84,8.4l-.36.18c-1.44.76-2.16,2.58-1.96,4.97.21,2.4,1.29,5.04,2.99,7.23l.42.54c2.49,3.22,3.49,7.38,2.37,9.86l-.18.41c-.76,1.7-.63,4.13.36,6.69s2.7,4.87,4.68,6.33l.48.35c2.92,2.15,5.09,6.19,5.18,9.62v.57c.06,2.33,1.02,4.97,2.64,7.26c1.11,1.57,2.42,2.81,3.75,3.58.6.35,1.21.6,1.81.75l.47.11c.56.14,1.12.37,1.68.7c2.26,1.3,4.37,3.99,5.39,7.03l.21.63c.86,2.57,2.48,4.97,4.43,6.57.45.37.9.68,1.35.94c1.5.86,2.95,1.1,4.13.64l.38-.14c1.13-.45,2.51-.2,3.88.6s2.75,2.14,3.87,3.88l.37.58c1.18,1.82,2.63,3.27,4.13,4.13.45.26.9.47,1.35.61c1.95.65,3.57.12,4.46-1.44l.21-.38c1.03-1.85,3.16-2.09,5.41-.79.56.32,1.12.74,1.68,1.25l.47.43c.6.54,1.2.99,1.8,1.34c1.33.77,2.64,1.04,3.76.76c1.62-.42,2.59-1.95,2.66-4.21l.02-.55c.1-3.32,2.29-4.85,5.21-3.62l.48.2c1.98.83,3.69.49,4.69-.92c1.01-1.41,1.15-3.69.41-6.25l-.18-.63c-1.11-3.77-.09-6.76,2.42-7.09l.42-.06c1.7-.23,2.8-1.6,3.01-3.76.22-2.16-.48-4.79-1.92-7.21l-.36-.59c-2.12-3.57-2.45-7.49-.78-9.34l.28-.3c1.12-1.26,1.42-3.43.81-5.96-.61-2.54-2.04-5.07-3.92-6.93l-.46-.45c-2.76-2.75-4.39-6.93-3.86-9.96l.09-.51c.36-2.05-.2-4.65-1.53-7.13-1.22-2.27-2.92-4.13-4.73-5.17-.17-.1-.33-.18-.5-.27l-.49-.24c-.14-.07-.28-.14-.42-.22-2.77-1.6-5.19-5.13-5.84-8.64l-.12-.61c-.47-2.5-1.78-5.09-3.61-7.07-.84-.91-1.73-1.64-2.61-2.15-1.04-.6-2.08-.91-3.03-.87l-.44.02c-.9.04-1.88-.26-2.84-.81-1.81-1.04-3.57-3-4.74-5.42l-.3-.62c-1.22-2.52-3.06-4.62-5.06-5.78'/></g><ellipse id='g-u-ellipse-c5b-s1' fill='var(--c5b)' stroke='#000' stroke-miterlimit='10' rx='20.28' ry='33.87' transform='matrix(.855093-.518475 0.518475 0.855093 432.163475 461.237456)'/><g id='g-u-group-c5-s13'><ellipse id='g-s-ellipse13' fill='url(#g-s-ellipse13-fill-c5-s13)' stroke='#000' stroke-miterlimit='10' rx='12.94' ry='21.62' transform='matrix(.855093-.518475 0.518475 0.855093 436.076888 461.230219)'/></g></g></g></g></g>";
  string internal constant C_AZTECL_A = "<g id='C-AztecL-A' class='gss-109' clip-path='url(#clippath-1)' transform='translate(-234 -365)'><path d='m682.4 390.5 18.7 34.1-.2-44.8-18.5 10.7m-39 22.5 19 34 .5-.3 18.6-55.7-38 22m-39 22.5 19 34 .4-.4 18.7-55.6-38 22m-39 22.5 18.9 34 .5-.4 18.6-55.6-38 22m-39 22.4 19 34 .5-.3 18.6-55.6-38 22m-39 22.4 18.9 34 .5-.3 18.6-55.6-38 22m-39 22.4 19 34 .5-.3 18.6-55.6-38 21.9m-39 22.5 19 34 .4-.3 18.7-55.7-38 22m-39 22.5 18.9 34 .5-.4 18.6-55.6-38 22m-39 22.4 19 34 .5-.3L370 571l-38 22m-39 22.4 19 34 .4-.3 18.7-55.6-38 22m-39 22.4 18.9 34 .5-.3 18.6-55.6-38 21.9m-19.2 11 .1 44.9 18.2-55.4-18.3 10.6' class='gss-85'/><path d='M701 379.8v44.8l.6-.3v1.3l-.1-46-.5.2M234.4 649.2V694l.6-.3-.1-44.8-.5.3' class='gss-95'/><path d='m682 391 18.5 34-37 21.3 18.5-55.2' class='gss-88'/><path d='M701.6 425.6v.4h.2l-.2-.4m-20-34.6-18.7 55.7.6-.4 18.5-55.2 18.5 33.9.6-.4-18.6-34-1 .5'/><path d='m643 413.6 18.8 33.7-37.3 21.5 18.5-55.2' class='gss-88'/><path d='m642.6 413.5.9-.5 18.9 34-.6.3-18.8-33.7-18.5 55.2-.6.3 18.7-55.6'/><path d='m604 436 18.8 33.8-37.2 21.5 18.5-55.3' class='gss-88'/><path d='m603.6 436 1-.5 18.8 34-.6.3-18.7-33.8-18.5 55.3-.6.3 18.6-55.6'/><path d='m565.1 458.5 18.8 33.8-37.2 21.5 18.4-55.3' class='gss-88'/><path d='m564.7 458.5 1-.5 18.8 34-.6.3-18.8-33.8-18.4 55.3-.6.3 18.6-55.6'/><path d='m526.2 481 18.8 33.7-37.3 21.6 18.5-55.3' class='gss-88'/><path d='m525.8 481 .9-.6 18.8 34-.5.3-18.8-33.7-18.5 55.3-.6.3 18.6-55.6'/><path d='m487.3 503.5 18.7 33.7-37.2 21.5 18.5-55.2' class='gss-88'/><path d='m486.8 503.5 1-.6 18.8 34-.6.3-18.7-33.7-18.5 55.2-.6.4 18.6-55.6'/><path d='m448.3 526 18.8 33.7-37.3 21.5 18.5-55.2' class='gss-88'/><path d='m447.9 526 .9-.6 18.9 34-.6.3-18.8-33.7-18.5 55.2-.5.4 18.6-55.7'/><path d='m409.4 548.5 18.7 33.7-37.2 21.5 18.5-55.2' class='gss-88'/><path d='m409 548.4.9-.5 18.8 34-.6.3-18.7-33.7-18.5 55.2-.6.3 18.6-55.6'/><path d='m370.4 571 18.8 33.7-37.3 21.5 18.6-55.3' class='gss-88'/><path d='m370 571 1-.6 18.8 34-.6.3-18.7-33.8-18.5 55.3-.6.3L370 571'/><path d='m331.5 593.4 18.8 33.8-37.3 21.5 18.5-55.3' class='gss-88'/><path d='m331 593.4 1-.5 18.8 34-.5.3-18.8-33.8-18.5 55.3-.6.3 18.6-55.6'/><path d='m292.6 615.9 18.7 33.8-37.2 21.4 18.5-55.2' class='gss-88'/><path d='m292.1 615.9 1-.6 18.8 34-.6.4-18.7-33.8-18.5 55.3-.6.3 18.6-55.6'/><path d='m253.6 638.4 18.8 33.7-36.8 21.3 18-55' class='gss-88'/><path d='m234.5 695.3-.2.5.2-.1v-.4m18.7-57L235 693.8l.6-.3 18-55 18.8 33.7.6-.3-19-34-.8.5'/><path d='m235 694.3 466-269 .1 12-466 269v-12' class='gss-97'/><path d='m234.5 694 .5-.3.6-.3 36.8-21.3.6-.3.5-.3.6-.3 37.2-21.6.6-.3.5-.3.6-.3 37.3-21.5.5-.4.6-.3.5-.3 37.3-21.5.6-.4.5-.3.6-.3 37.2-21.5.6-.3.5-.3.6-.4 37.3-21.5.6-.3.5-.3.6-.4 37.2-21.5.6-.3.5-.3.6-.3 37.3-21.6.5-.3.6-.3.6-.3 37.2-21.5.6-.4.5-.3.6-.3 37.2-21.5.6-.4.5-.3.6-.3 37.3-21.5.6-.3.5-.3.6-.4 37-21.3.6-.4.5-.3V437l-.5.2v-12L235 694.3v12l-.6.3V694'/><path d='M235.2 707 701 438v6.7l-465.8 269V707' class='gss-82'/><path d='m701 444.7-465.8 269V707L701 438v6.6m-466.6 262v8.2L701.9 445v-8.2h-.1l-.6.3-466 269.1-.6.3'/><path d='m235 635.3 465.8-269v12.8L235 648v-12.8' class='gss-82'/><path d='m700.9 379-466 269v-12.7l466-269v12.8M234.2 634.9v14.4h.2l.5-.4 18.3-10.5.9-.6 38-22 1-.5 38-22 .9-.4 38-22 1-.5 38-22 .9-.5 38-22 .9-.5 38-22 1-.5 38-22 .9-.5 38-22 1-.5 38-22 .9-.5 38-22 .9-.5 38-22 1-.5 18.5-10.6.5-.4V365L234.2 634.9'/></g>";

  function getAssetFromID(uint assetID) external pure returns (string memory) {
    if (assetID == 6028) {
      return C_DEAD_PLANT;
    } else if (assetID == 6029) {
      return C_WATERMELON;
    } else if (assetID == 6030) {
      return C_GRAMOPHONE;
    } else if (assetID == 6031) {
      return C_AZTECL_A;
    } else {
      return "";
    }
  }
}