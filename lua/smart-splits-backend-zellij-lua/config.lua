local M = {}

---@class SmartSplits.ZellijLua.Config
---@field move_cursor SmartSplits.ZellijLua.Config.Move
---@field fullscreen SmartSplits.ZellijLua.Config.Fullscreen
---@field split SmartSplits.ZellijLua.Config.Split

---@class SmartSplits.ZellijLua.Config.Move
---@field pane_or_tab boolean

---@class SmartSplits.ZellijLua.Config.Split
---@field left boolean
---@field right boolean
---@field up boolean
---@field down boolean

---@class SmartSplits.ZellijLua.Config.Fullscreen
---@field block_nav boolean

-- Same as above, but every field is nullable
---@class SmartSplits.ZellijLua.PartialConfig
---@field move_cursor? SmartSplits.ZellijLua.PartialConfig.Move
---@field fullscreen? SmartSplits.ZellijLua.PartialConfig.Fullscreen
---@field split? SmartSplits.ZellijLua.PartialConfig.Split

---@class SmartSplits.ZellijLua.PartialConfig.Move
---@field pane_or_tab? boolean

---@class SmartSplits.ZellijLua.PartialConfig.Split
---@field left? boolean
---@field right? boolean
---@field up? boolean
---@field down? boolean

---@class SmartSplits.ZellijLua.PartialConfig.Fullscreen
---@field block_nav? boolean

---@type SmartSplits.ZellijLua.Config
M.defaults = {
    move_cursor = {
        pane_or_tab = false,
    },

    split = {
        left = true,
        right = true,
        up = true,
        down = true,
    },

    fullscreen = {
        block_nav = false,
    },
}

---@type SmartSplits.ZellijLua.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? SmartSplits.ZellijLua.PartialConfig
function M.setup(opts)
    opts = opts or {}
    M.options = vim.tbl_deep_extend('force', M.defaults, opts)
    return M.options
end

return M
