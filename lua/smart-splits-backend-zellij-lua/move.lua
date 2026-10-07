local utils = require('smart-splits-backend-zellij-lua.utils')
local zellij = require('smart-splits-backend-zellij-lua.zellij')
local config = require('smart-splits-backend-zellij-lua.config')

local M = {}

---@class ZellijState
---@field nvim_pane? ZellijTerminalPane
---@field panes? ZellijPaneEntry[]
---@field current_tab_panes ZellijTerminalPane[]
---@field current_tab_info ZellijTabInfo

---@type ZellijState
local cache = {} ---@diagnostic disable-line: missing-fields

--- Get the current zellij pane
---@return ZellijPaneEntry[]
local function get_all_panes()
    if cache.panes == nil then
        cache.panes = zellij.list_panes()
    end
    return cache.panes
end

local function get_current_tab_info()
    if cache.current_tab_info == nil then
        cache.current_tab_info = zellij.current_tab_info()
    end
    return cache.current_tab_info
end

--- Get a list of all zellij panes in the current session
---@return ZellijTerminalPane
local function get_nvim_pane()
    if cache.nvim_pane ~= nil then
        return cache.nvim_pane
    end

    local current_pane_id = tonumber(vim.env.ZELLIJ_PANE_ID)
    local panes = get_all_panes()
    for _, pane in ipairs(panes) do
        if pane.id == current_pane_id and pane.is_plugin == false then
            cache.nvim_pane = pane
            break
        end
    end
    utils.assert(cache.nvim_pane ~= nil, 'Failed to find the current pane.')

    return cache.nvim_pane
end

--- Get all panes in the current tab
--- Assumes that this nvim instance is in the current tab (normally a safe assumption).
---@return ZellijTerminalPane[]
local function get_current_tab_panes()
    if cache.current_tab_panes ~= nil then
        return cache.current_tab_panes
    end

    local panes = get_all_panes()
    local nvim = get_nvim_pane()
    cache.current_tab_panes = {} ---@type ZellijTerminalPane[]
    for _, pane in ipairs(panes) do
        if
            pane.tab_id == nvim.tab_id
            and pane.is_plugin == false
            and pane.is_floating == false
            and pane.is_selectable == true
        then
            table.insert(cache.current_tab_panes, pane)
        end
    end

    return cache.current_tab_panes
end

local function invalidate_cache()
    cache = {} ---@diagnostic disable-line: missing-fields
end

---@alias FullscreenState "none"|"fullscreen"|"no_ui_fullscreen"

---@param pane ZellijTerminalPane
---@return FullscreenState
local function get_fullscreen_state(pane)
    if pane.is_fullscreen == false then
        return 'none'
    end

    if pane.pane_x > 0 or pane.pane_y > 0 then
        return 'fullscreen'
    end

    local tab = get_current_tab_info()
    if
        pane.pane_x <= 0
        and pane.pane_y <= 0
        and pane.pane_rows == tab.display_area_rows
        and pane.pane_columns == tab.display_area_columns
    then
        return 'no_ui_fullscreen'
    else
        return 'fullscreen'
    end
end

---@param next_state FullscreenState
---@param target { pane?: ZellijTerminalPane, current_state?: FullscreenState }
local function set_fullscreen_state(next_state, target)
    utils.assert(
        not (target.current_state == nil and target.pane == nil),
        "Not implemented by 'set_fullscreen_state()': target.pane and target.current_state can not both be nil"
    )

    local current_state = target.current_state or get_fullscreen_state(target.pane)
    local pane_id = target.pane and target.pane.id or nil

    if current_state == next_state then
        return -- nothing to do
    elseif current_state == 'none' and next_state == 'fullscreen' then
        zellij.toggle_fullscreen(pane_id)
    elseif current_state == 'none' and next_state == 'no_ui_fullscreen' then
        zellij.toggle_no_ui_fullscreen(pane_id)
    elseif current_state == 'fullscreen' and next_state == 'none' then
        zellij.toggle_fullscreen(pane_id)
    elseif current_state == 'fullscreen' and next_state == 'no_ui_fullscreen' then
        zellij.toggle_no_ui_fullscreen(pane_id)
    elseif current_state == 'no_ui_fullscreen' and next_state == 'none' then
        zellij.toggle_no_ui_fullscreen(pane_id)
    elseif current_state == 'no_ui_fullscreen' and next_state == 'fullscreen' then
        zellij.toggle_fullscreen(pane_id)
    else
        -- We should never arrive here.
        utils.error(
            'Not implemented case in set_fullscreen_state().\nCan not change:"'
                .. current_state
                .. '" --> "'
                .. next_state
                .. '"'
        )
    end
end

--- Check if interval a = [a_start, a_start + a_length) overlaps
--- interval b = [b_start, b_start + b_length).
---@param a_start integer start coordinate of interval a
---@param a_length integer length of interval a
---@param b_start integer start coordinate of interval b
---@param b_length integer length of interval b
---@return boolean
local function intervals_overlap(a_start, a_length, b_start, b_length)
    local a_end = a_start + a_length
    local b_end = b_start + b_length
    return a_start < b_end and b_start < a_end
end

--- Check if two panes overlap on a given axis.
---@param a ZellijTerminalPane
---@param b ZellijTerminalPane
---@param axis "x-axis"|"y-axis"
---@return boolean
local function axis_overlap(a, b, axis)
    if axis == 'x-axis' then
        return intervals_overlap(a.pane_x, a.pane_columns, b.pane_x, b.pane_columns)
    else
        return intervals_overlap(a.pane_y, a.pane_rows, b.pane_y, b.pane_rows)
    end
end

--- Check if there exists any neighboring panes in the given direction
---@param origin ZellijTerminalPane The origin pane
---@param panes ZellijPaneEntry[] The panes to test
---@param direction SmartSplitsDirection The direction to look
---@return boolean
local function has_neighbor(origin, panes, direction)
    for _, target in ipairs(panes) do
        if
            target.id == origin.id
            or target.tab_id ~= origin.tab_id
            or target.is_plugin == true
            or target.is_floating == true
            or target.is_suppressed == true
        then
            goto continue -- Invalid target, skip
        end

        local in_direction = false -- True if the the pane is in the given direction
        local is_aligned = false -- True if the pane has any overlaping coordinates on the perpendicular axis

        if direction == 'left' then
            in_direction = origin.pane_x > target.pane_x
            is_aligned = axis_overlap(origin, target, 'y-axis')
        elseif direction == 'right' then
            in_direction = target.pane_x > origin.pane_x
            is_aligned = axis_overlap(origin, target, 'y-axis')
        elseif direction == 'up' then
            in_direction = origin.pane_y > target.pane_y
            is_aligned = axis_overlap(origin, target, 'x-axis')
        elseif direction == 'down' then
            in_direction = target.pane_y > origin.pane_y
            is_aligned = axis_overlap(origin, target, 'x-axis')
        end

        if in_direction and is_aligned then
            return true
        end

        ::continue::
    end

    return false
end

---@param direction SmartSplitsDirection
---@return boolean did_move
local function move_or_wrap(direction)
    local nvim = get_nvim_pane()
    local panes = get_current_tab_panes()
    if #panes <= 1 then
        return false -- Nothing to do, no other panes in tab
    end

    if has_neighbor(nvim, panes, direction) then
        return zellij.move_focus(direction)
    end

    -- Find all panes that borders the diametrical opposing edge
    local opposing_panes = {} --@type ZellijTerminalPane[]
    local largest_delta = 0
    local wrap_direction = utils.reverse(direction)
    for _, target in ipairs(panes) do
        local delta = 0
        if nvim.id == target.id then
            delta = -999 -- Invliad target, skip
        elseif wrap_direction == 'left' then
            delta = nvim.pane_x - target.pane_x
        elseif wrap_direction == 'right' then
            delta = target.pane_x + target.pane_columns - nvim.pane_x
        elseif wrap_direction == 'up' then
            delta = nvim.pane_y - target.pane_y
        elseif wrap_direction == 'down' then
            delta = target.pane_y + target.pane_rows - nvim.pane_y
        end

        if delta > largest_delta then
            largest_delta = delta
            opposing_panes = { target }
        elseif delta == largest_delta then
            table.insert(opposing_panes, target)
        end
    end
    utils.assert(#opposing_panes > 0, 'Failed to find an opposing pane.')

    if #opposing_panes == 1 then
        return zellij.focus_pane_id(opposing_panes[1].id)
    end

    -- We now have multiple panes to choose from. Each equidistant from the current pane.
    -- Tiebreaker: Pick the pane that aligns with the cursor position on the perpendicular axis.
    -- If we can't find the cursor position, use the middle of the pane instead.
    local cursor = nvim.cursor_coordinates_in_pane or {}
    local cursor_x = nvim.pane_x + (cursor[1] or nvim.pane_columns / 2)
    local cursor_y = nvim.pane_y + (cursor[2] or nvim.pane_rows / 2)
    for _, target in ipairs(opposing_panes) do
        local is_aligned = false

        if direction == 'left' or direction == 'right' then
            is_aligned = target.pane_y <= cursor_y and cursor_y < (target.pane_y + target.pane_rows)
        elseif direction == 'up' or direction == 'down' then
            is_aligned = target.pane_x <= cursor_x and cursor_x < (target.pane_x + target.pane_columns)
        end

        if is_aligned then
            return zellij.focus_pane_id(target.id)
        end
    end

    utils.error('Failed to pick the best pane out of multiple options') -- We should never arrive here.
    return false
end

---@param direction SmartSplitsDirection
---@return boolean
local function split_and_focus(direction)
    local nvim = get_nvim_pane()

    local panes = get_current_tab_panes()
    if has_neighbor(nvim, panes, direction) then
        return zellij.move_focus(direction)
    end

    local did_split = false

    if direction == 'right' then
        did_split = zellij.new_pane('right') ~= nil
    end

    if direction == 'down' then
        did_split = zellij.new_pane('down') ~= nil
    end

    if direction == 'left' then
        -- Zellij does not support creating panes to the left.
        -- We must create one to the right and then swap position.
        local new_pane_id = zellij.new_pane('right')
        if new_pane_id ~= nil then
            did_split = zellij.move_pane('left', new_pane_id)
        else
            did_split = false
        end
    end

    if direction == 'up' then
        -- Same as above. Create new pane down, then swap
        local new_pane_id = zellij.new_pane('down')
        if new_pane_id ~= nil then
            did_split = zellij.move_pane('up', new_pane_id)
        else
            did_split = false
        end
    end

    assert(did_split, 'Failed to split pane.')

    return did_split
end

--- Moves the cursor if more than one tab exists.
--- Respects fullscreen config.
---@param direction SmartSplitsDirection
---@return boolean did_move True if the cursor did move, otherwise false.
local function try_move_or_tab(direction)
    if direction == 'up' or direction == 'down' then
        return false
    end

    local is_multiple_tabs = false
    for _, pane in ipairs(get_all_panes()) do
        if pane.tab_position > 0 then
            is_multiple_tabs = true
            break
        end
    end

    if is_multiple_tabs then
        return zellij.move_focus_or_tab(direction)
    else
        return false
    end
end

local last_move_time = 0

--- Entrypoint for normal moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_normal_move(direction)
    local move_or_tab = config.options.move_cursor.pane_or_tab == true

    if move_or_tab then
        return zellij.move_focus_or_tab(direction)
    else
        return zellij.move_focus(direction)
    end
end

--- Entrypoint for split moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_split(direction)
    if
        (config.options.split.left == false and direction == 'left')
        or (config.options.split.right == false and direction == 'right')
        or (config.options.split.up == false and direction == 'up')
        or (config.options.split.down == false and direction == 'down')
    then
        return handle_normal_move(direction)
    end

    -- Split causes a bunch of side effect to the zellij state.
    -- This gets difficult to mannage if the user spams the navigations keys.
    -- We avoid a plethora of edge casess by just not allowing split to be called if
    -- there is less than 500 ms since the last key press.
    if vim.uv.now() - last_move_time <= 500 then
        return handle_normal_move(direction)
    end

    if config.options.move_cursor.pane_or_tab == true then
        local did_move = try_move_or_tab(direction)
        if did_move then
            return did_move
        end
    end

    -- Split does not work when we are fullscreen - it messes up the layout coodrinates
    -- This is possibly a bug in zellij v0.45.0
    local nvim = get_nvim_pane()
    if nvim.is_fullscreen == true then
        set_fullscreen_state('none', { pane = nvim })
        invalidate_cache()
    end

    local result = split_and_focus(direction)

    return result
end

--- Entrypoint for wrap moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_wrap(direction)
    if config.options.move_cursor.pane_or_tab == true then
        local did_move = try_move_or_tab(direction)
        if did_move then
            return did_move
        end
    end

    -- Wrap does not work when we are fullscreen - it messes up the layout coodrinates
    -- This is possibly a bug in zellij v0.45.0
    local nvim = get_nvim_pane()
    if nvim.is_fullscreen == true then
        set_fullscreen_state('none', { pane = nvim })
        invalidate_cache()
    end

    local result = move_or_wrap(direction)

    return result
end

---@type SmartSplitsBackendMove
local function handle_move(direction, opts)
    if config.options.fullscreen.block_nav == true and get_nvim_pane().is_fullscreen == true then
        return false
    end

    if opts.at_edge == 'wrap' then
        return handle_wrap(direction)
    elseif opts.at_edge == 'split' then
        return handle_split(direction)
    else
        return handle_normal_move(direction)
    end
end

---@type SmartSplitsBackendMove
function M.try_move(direction, opts)
    invalidate_cache()
    local ok, result = pcall(handle_move, direction, opts)
    invalidate_cache()
    if not ok then
        vim.notify(tostring(result), vim.log.levels.ERROR)
        return false
    end
    last_move_time = vim.uv.now()
    return result
end

return M
