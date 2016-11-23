local prefix = require("prefix")
local utils = require("utils")

hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
prefix.bind('', 'g', function() hs.grid.show() end)

hs.hints.hintChars = utils.strToTable('ASDFGQWERTZXCVB12345')
prefix.bind('', 'w', function() hs.hints.windowHints() end)
