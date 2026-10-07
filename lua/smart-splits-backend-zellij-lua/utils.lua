local M = {}

local opposite_directions = {
    left = 'right',
    right = 'left',
    up = 'down',
    down = 'up',
}

function M.reverse(direction)
    return opposite_directions[direction]
end

local bugreport_url = 'https://github.com/smart-splits-nvim/backend-zellij-lua/issues'
function M.assert(condition, message)
    assert(
        condition,
        string.format('%s\nThis should never happen. Please create a bugreport at:\n%s', message, bugreport_url)
    )
end

function M.error(message)
    M.assert(false, message)
end

return M
