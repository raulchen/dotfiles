local prefix = require("prefix")

hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
prefix.bind('', 'g', function() hs.grid.show() end)
