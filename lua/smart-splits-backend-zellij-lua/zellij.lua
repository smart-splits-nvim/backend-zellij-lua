local zellij = {}

--- Cached path to the Zellij binary.
---@type string|nil
local _zellij_bin = nil

--- Find the name of the Zellij binary.
---@return string|nil bin_name The name of the Zellij executable, or nil if not found.
function zellij.bin_name()
    if _zellij_bin ~= nil then
        return _zellij_bin
    end

    if vim.fn.executable('zellij') == 1 then
        _zellij_bin = 'zellij'
        return _zellij_bin
    end

    if vim.fn.executable('zellij.exe') == 1 then
        _zellij_bin = 'zellij.exe'
        return _zellij_bin
    end

    return nil
end

--- Checks if zellij exists in path
--- @return boolean
function zellij.exists()
    return zellij.bin_name() ~= nil
end

--- Check if zellij is currently running
--- @return boolean
function zellij.is_running()
    return vim.env.ZELLIJ ~= nil and #vim.env.ZELLIJ > 0
end

--- Execute a command with zellij
---@param args (string|integer)[] command arguments
---@param opts? vim.SystemOpts
---@return string stdout
---@return integer code exit code
---@return string stderr
function zellij.exec(args, opts)
    if #args == 0 then
        error('No command provided')
    end
    opts = opts or { text = false }

    local cmd = vim.list_extend({ zellij.bin_name() }, args)
    local result = vim.system(cmd, opts):wait()
    return result.stdout or '', result.code, result.stderr or ''
end

--- Get the output of zellij --version
---@return string sdtout
function zellij.version()
    local result = zellij.exec({ '--version' }, { text = true })
    return vim.trim(result)
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus(direction)
    local _, code = zellij.exec({ 'action', 'move-focus', direction })
    return code == 0
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus_or_tab(direction)
    if direction == 'left' or direction == 'right' then
        local _, code = zellij.exec({ 'action', 'move-focus-or-tab', direction })
        return code == 0
    else
        return zellij.move_focus(direction)
    end
end

---@param pane_id integer|string
---@return boolean exit_status True if exit code is 0
function zellij.focus_pane_id(pane_id)
    local _, code = zellij.exec({ 'action', 'focus-pane-id', pane_id })
    return code == 0
end

--- Creates a new pane in the given direction
---@param direction 'right'|'down' Zellij only creates panes right or down
---@return integer|nil pane_id The pane_id of the new pane, or nil if the command failed.
function zellij.new_pane(direction)
    local result, code = zellij.exec({ 'action', 'new-pane', '--direction', direction }, { text = true })
    if code == 0 then
        return tonumber(result:match('(%d+)'))
    else
        return nil
    end
end

--- Moves a pane in the given direction
---@param direction SmartSplitsDirection
---@param pane_id? integer The pane to move. Defaults to current pane if omitted.
---@return boolean exit_status True if exit code is 0
function zellij.move_pane(direction, pane_id)
    local args = { 'action', 'move-pane', direction }
    if pane_id ~= nil then
        vim.list_extend(args, { '--pane-id', pane_id })
    end
    local _, code = zellij.exec(args)
    return code == 0
end

--- Toggle fullscreen
---@param pane_id? integer Target a specific pane_id. Defaults to current pane if omitted.
---@return boolean exit_status True if exit code is 0
function zellij.toggle_fullscreen(pane_id)
    local args = { 'action', 'toggle-fullscreen' }
    if pane_id ~= nil then
        vim.list_extend(args, { '--pane-id', pane_id })
    end
    local _, code = zellij.exec(args)
    return code == 0
end

--- Toggle fullscreen (including UI bars)
---@param pane_id? integer Target a specific pane_id. Defaults to current pane if omitted.
---@return boolean exit_status True if exit code is 0
function zellij.toggle_no_ui_fullscreen(pane_id)
    local args = { 'action', 'toggle-no-ui-fullscreen' }
    if pane_id ~= nil then
        vim.list_extend(args, { '--pane-id', pane_id })
    end
    local _, code = zellij.exec(args)
    return code == 0
end
---@class ZellijPane
---@field id integer Pane id (unique per pane/plugin type)
---@field is_plugin boolean
---@field is_focused boolean
---@field is_fullscreen boolean
---@field is_floating boolean
---@field is_suppressed boolean
---@field title string
---@field exited boolean
---@field exit_status integer|nil
---@field is_held boolean
---@field pane_x integer
---@field pane_content_x integer
---@field pane_y integer
---@field pane_content_y integer
---@field pane_rows integer
---@field pane_content_rows integer
---@field pane_columns integer
---@field pane_content_columns integer
---@field cursor_coordinates_in_pane [integer, integer]|nil     Cursor position in the pane, nil if not applicable
---@field terminal_command string|nil                           Command running in a terminal pane
---@field plugin_url string|nil                                 WASM plugin URL (e.g. "zellij:strider" or "file:/path/to/plugin.wasm")
---@field is_selectable boolean                                 False for non-interactive UI elements like the status/tab bar
---@field index_in_pane_group table<string, integer>            Client-id (stringified) -> index, for panes staged in a group; empty table when not grouped
---@field default_fg string|nil                                 Hex ("#00e000") or rgb ("rgb:00/e0/00") foreground override
---@field default_bg string|nil                                 Hex or rgb background override
---@field tab_id integer
---@field tab_position integer
---@field tab_name string
---@field pane_command string|nil
---@field pane_cwd string|nil

---@class ZellijTerminalPane : ZellijPane
---@field is_plugin false
---@field pane_command string
---@field pane_cwd string

---@class ZellijPluginPane : ZellijPane
---@field is_plugin true
---@field plugin_url string

---@alias ZellijPaneEntry ZellijTerminalPane|ZellijPluginPane

---@return ZellijPaneEntry[]
function zellij.list_panes()
    local json, code, stderr = zellij.exec({ 'action', 'list-panes', '--json' }, { text = true })
    if code ~= 0 then
        error("'zellij action list-panes --json' exited with code=" .. code .. '\n' .. stderr)
    end

    return vim.json.decode(json, { luanil = { object = true } })
end

---@class ZellijTabInfo
---@field position integer                          The tab's 0-indexed position
---@field name string                               The name of the tab as it appears in the UI (if there's enough room for it)
---@field active boolean                            Whether this tab is focused
---@field panes_to_hide integer                     The number of suppressed panes this tab has
---@field is_fullscreen_active boolean              Whether there's one pane taking up the whole display area on this tab
---@field is_sync_panes_active boolean              Whether input sent to this tab will be synced to all panes in it
---@field are_floating_panes_visible boolean
---@field other_focused_clients integer[]           Client IDs of other clients focused on this tab
---@field active_swap_layout_name string?           The name of the active swap layout, if any
---@field is_swap_layout_dirty boolean              Whether the user manually changed the layout, moving out of the swap layout scheme
---@field viewport_rows integer                     Row count in the viewport (excludes UI bars like the status bar)
---@field viewport_columns integer                  Column count in the viewport (excludes UI bars)
---@field display_area_rows integer                 Row count in the display area (includes all panes; typically larger than the viewport)
---@field display_area_columns integer              Column count in the display area (includes all panes; typically larger than the viewport)
---@field selectable_tiled_panes_count integer      Number of selectable (non-UI) tiled panes in this tab
---@field selectable_floating_panes_count integer   Number of selectable (non-UI) floating panes in this tab
---@field tab_id integer                            The stable identifier for this tab
---@field has_bell_notification boolean             Whether this tab has an active (persistent) bell notification
---@field is_flashing_bell boolean                  Whether this tab is currently flashing its bell (transient 400ms state)

---@return ZellijTabInfo
function zellij.current_tab_info()
    local json, code, stderr = zellij.exec({ 'action', 'current-tab-info', '--json' }, { text = true })
    if code ~= 0 then
        error("'zellij action current-tab-info --json' exited with code=" .. code .. '\n' .. stderr)
    end

    return vim.json.decode(json, { luanil = { object = true } })
end

return zellij
