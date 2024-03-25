/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenesisEyes {
    function G_Eyes(uint32 traitId_) public pure returns (string[2] memory) {
        if (traitId_ == 0) return  ["Rainbow Shades","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAKlBMVEVHcEwAAAD/agD///+z/wBi/wD/wwAB/7v/jAAAnf///wD/PAB7AP/QAP8G7/muAAAAAXRSTlMAQObYZgAAADpJREFUKM9jYBjhQBAO4EK8Z2aWh7osTrNQgAudnF4a4mWW3IQQ4YQoUdqAMIo1xMuAoUl7A8MoQAEAejwNmIoYQykAAAAASUVORK5CYII="];
        if (traitId_ == 1) return  ["3D Glasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNRAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAADFBMVEVHcEzy8vL/KgAAmf8fLU1YAAAAAXRSTlMAQObYZgAAACBJREFUGNNjYBhUIBQEHEAs1tD/11aBWQysCBZMdlADAGAgCQuEdLlrAAAAAElFTkSuQmCC"];
        if (traitId_ == 2) return  ["Futuristic Shades","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAFVBMVEVHcEwAAACVAP/VAP//AO7/AGr///9m4e/zAAAAAXRSTlMAQObYZgAAADlJREFUKM9jYBjhQBAO4EJMSiCgppSkABcyBoFkM2MDuAiLi4uLm0uKiwPCKNbQ0ASG0NAAhlGAAgAFFAhn981hAAAAAABJRU5ErkJggg=="];
        if (traitId_ == 3) return  ["Green Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAAB1tQCG0ACj/wD+iMBxAAAAAXRSTlMAQObYZgAAAC5JREFUKM9jYBhJgFEQAaBCQJaQkhIYI9QJKRkLgDBCRNjYRQCEUcwC41FACAAAa6EEJhGfCdEAAAAASUVORK5CYII="];
        if (traitId_ == 4) return  ["Blue Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAAACcbMDg80AoP/7zTkZAAAAAXRSTlMAQObYZgAAAC5JREFUKM9jYBhJgFEQAaBCQJaQkhIYI9QJKRkLgDBCRNjYRQCEUcwC41FACAAAa6EEJhGfCdEAAAAASUVORK5CYII="];
        if (traitId_ == 5) return  ["VR Goggles","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAElBMVEVHcEwAAADY2NigoKD///+DgIA5JW+7AAAAAXRSTlMAQObYZgAAADRJREFUKM9jYBhxQBAMBBACjEZKIGCIEBFWFBQUEXRURIiIAkUcRQSRRBiD0XVhmjwKQAAAIwoE5nncFfcAAAAASUVORK5CYII="];
        if (traitId_ == 6) return  ["Red Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAACzAh/NAyX/ACpp78pwAAAAAXRSTlMAQObYZgAAAC5JREFUKM9jYBhJgFEQAaBCQJaQkhIYI9QJKRkLgDBCRNjYRQCEUcwC41FACAAAa6EEJhGfCdEAAAAASUVORK5CYII="];
        if (traitId_ == 7) return  ["Gold Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAACzmwLNsQP/3QBfWkG2AAAAAXRSTlMAQObYZgAAAC5JREFUKM9jYBhJgFEQAaBCQJaQkhIYI9QJKRkLgDBCRNjYRQCEUcwC41FACAAAa6EEJhGfCdEAAAAASUVORK5CYII="];
        if (traitId_ == 8) return  ["Eyepatch","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAADk4+Hg29v///8FdBp5AAAAAXRSTlMAQObYZgAAACZJREFUKM9jYBjhQBAOBBCCjIKCDMyKTgyoIgxGCig6BRhGATEAAGXZAdrCW2FCAAAAAElFTkSuQmCC"];
        if (traitId_ == 9) return  ["Clear Glasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAElBMVEVHcEwAAADQ7vzK3eb///9jYF72dCgXAAAAAXRSTlMAQObYZgAAACVJREFUKM9jYBjhQBAOBBCCwqoqAiCMEGE0UgRjZJ0CEDwKCAAAMN4CfX4Yh+oAAAAASUVORK5CYII="];
        if (traitId_ == 10) return ["Square Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABZJREFUCNdjYKAF+P//A4gqKECQdAAAE98Er7SdRmQAAAAASUVORK5CYII="];
        if (traitId_ == 11) return ["Black Sunglasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABlJREFUCNdjYKAF+P//A4j6gEQmJDDQGgAANM4Hb7Ah4eEAAAAASUVORK5CYII="];
        if (traitId_ == 12) return ["Square Glasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNRAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAADFBMVEVHcEwAAAC18/////+QnlScAAAAAXRSTlMAQObYZgAAAB1JREFUGNNjYBgUIBQIwXRobmguVCwTCFFlhwgAAPuBBADTcOvTAAAAAElFTkSuQmCC"];
        if (traitId_ == 13) return ["Gold Glasses","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAFVBMVEVHcEy9nTWzlDL578zw5cGCfGv///9EEwjOAAAAAXRSTlMAQObYZgAAADNJREFUKM9jYBjhQElJEAiEgFgBIShiGiYAwggRFdNgoEgwsoizsQAII0SYBAXBeBSgAgCXqQVQYYna9gAAAABJRU5ErkJggg=="];
        if (traitId_ == 14) return ["Sleepy","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABRJREFUCB1joCWYMIEBCBISGOgDAMt8AeFW9txDAAAAAElFTkSuQmCC"];
        if (traitId_ == 15) return ["Crossed","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYKAJWLAARDo4INh0AABMWwMBYDu8PwAAAABJRU5ErkJggg=="];
        if (traitId_ == 16) return ["Eyes1","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNRAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAACVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABVJREFUGNNjYBi0QAIIIUAECIcQAAA/BABZ+EJZbwAAAABJRU5ErkJggg=="];
        if (traitId_ == 17) return ["Eyes2","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNRAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAACVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABtJREFUGNNjYBgUQAAIISAFCCEgBAjRWUMCAACdYwI5a4/O5AAAAABJRU5ErkJggg=="];
        if (traitId_ == 18) return ["Eyes3","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABBJREFUCB1joCV48ICBngAAwiwBwaiB3b0AAAAASUVORK5CYII="];
        if (traitId_ == 19) return ["Eyes4","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNRAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAACVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABdJREFUGNNjYBhkQAAIISAFCNHFhgQAAL8UAQlPAY0bAAAAAElFTkSuQmCC"];
        if (traitId_ == 20) return ["Eyes5","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmBAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABBJREFUCB1joCVwcGCgJwAAOAwAgfARHFsAAAAASUVORK5CYII="];
        if (traitId_ == 21) return ["Eyes6","iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAD1BMVEVHcEwAAADh5OjV1tf///82T/7rAAAAAXRSTlMAQObYZgAAAB5JREFUKM9jYBgFjIKCYIwAzIZOYIwElBQgeBSQDAAzmgG3cUIXsAAAAABJRU5ErkJggg=="];
        return ["",""];
    }
}