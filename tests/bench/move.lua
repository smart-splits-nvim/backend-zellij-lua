local bench = require('tests.bench.init')
local zellij = require('smart-splits-backend-zellij-lua.init')

zellij.setup()

bench.setup({ name = 'move.lua' }).run(function(i)
    zellij.move(i % 2 == 0 and 'left' or 'right')
end)
