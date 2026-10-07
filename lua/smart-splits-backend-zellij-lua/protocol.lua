---@alias SmartSplitsDirection 'left'|'right'|'up'|'down'

---@class SmartSplitsBackendMoveOpts
---@field at_edge 'stop'|'wrap'|'split'|nil what to do when there is no pane in the given direction
---@field maximize_nav_speed? boolean Convenience flag for fastest possible cursor movement. Forcefully overrides any user configuration that negatively impact cursor movement.

---@alias SmartSplitsBackendMove fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendMoveOpts):boolean

---@class SmartSplitsBackendResizeOpts
---@field amount number|nil cells to resize by, already multiplied by `v:count1`

---@alias SmartSplitsBackendResize fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendResizeOpts):boolean

---@class SmartSplitsBackendSplitOpts

---@alias SmartStplitsBackendSplit fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendSplitOpts):boolean

---@class SmartSplitsBackend
---@field name string
---@field protocol_version string
---@field detect fun():boolean
---@field move SmartSplitsBackendMove
---@field resize? SmartSplitsBackendResize
---@field activate? fun()
---@field health? fun()
---@field slow_threshold? number in milliseconds, operations taking longer than this will log a warning; default 100ms
