--- Set up configurations
---@param opts? SmartSplits.Zellij.PartialConfig
local function setup(opts)
    local config = require('smart-splits-backend-zellij-lua.config')
    config.setup(opts)
end

--- Detect if zellij is available in the current environment
local function detect()
    local zellij = require('smart-splits-backend-zellij-lua.zellij')
    return zellij.is_running() and zellij.exists()
end

---@type SmartSplitsBackend
local M = {
    name = 'smart-splits-backend-zellij',
    protocol_version = '3.0.0',
    detect = detect,
    move = require('smart-splits-backend-zellij-lua.move').try_move,
    resize = require('smart-splits-backend-zellij-lua.resize').resize,
    setup = setup,
    health = require('smart-splits-backend-zellij-lua.health').report,
}

return M
