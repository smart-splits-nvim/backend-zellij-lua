local bench = require('tests.bench.init')
local zellij = require('smart-splits-backend-zellij-lua.init')

zellij.setup()

bench.setup({ name = 'resize.lua' }).run(function(i)
    zellij.resize(i % 2 == 0 and 'left' or 'right')
end)
