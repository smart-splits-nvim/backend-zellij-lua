local zellij = require('smart-splits-backend-zellij-lua.zellij')

local M = {}

function M.report()
    if zellij.exists() then
        vim.health.ok('Found ' .. zellij.version())
    else
        vim.health.error('zellij not found on PATH')
    end

    if zellij.is_running() then
        vim.health.ok("Found session '" .. vim.env.ZELLIJ_SESSION_NAME .. "'")
    else
        vim.health.error('Not in a zellij session.')
    end
end

function M.check()
    vim.health.start('backend-zellij')
    M.report()
end

return M
