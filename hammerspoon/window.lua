local prefix = require("prefix")

hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
prefix.bind('', 'g', function() hs.grid.show() end)

hs.hints.hintCharacters = 'asdfgqwertzxcvb12345'
prefix.bind('', 'w', function() hs.hints.windowHints() end)
