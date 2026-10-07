vim.opt.rtp:append('.') -- Add ./lua to the runtimepath so require() works

local M = {}

---Prints a single-line summary of a benchmark result.
---@param test_name string Name of the test
---@param result Bench.Result The benchmark result to print
function M.print_result(test_name, result)
    local function format_ms(ms)
        return string.format('%.3f ms', ms)
    end
    print(
        string.format(
            '%-13s avg:  %-13s median:  %-13s min:  %-13s max:  %-13s p95:  %-13s',
            '[' .. test_name .. ']',
            format_ms(result.avg),
            format_ms(result.median),
            format_ms(result.min),
            format_ms(result.max),
            format_ms(result.p95)
        )
    )
end

---@param a Bench.Result
---@param b Bench.Result
function M.print_diff(a, b)
    ---@type Bench.Result
    local diff = {
        avg = b.avg - a.avg,
        min = b.min - a.min,
        max = b.max - a.max,
        median = b.median - a.median,
        p95 = b.p95 - a.p95,
    }
    M.print_result('diff', diff)
end

---@class Bench.RunOpts Optional benchmarking configuration
---@field warmup? integer Number of un-timed warmup iterations (default: 20)
---@field iterations? integer Number of measured iterations (default: 1000)

---@class Bench.SetupOpts : Bench.RunOpts
---@field name string Name of the test

---@class Bench.Result Timing statistics, all in milliseconds
---@field min number Minimum timing
---@field max number Maximum timing
---@field avg number Average timing
---@field median number Median timing
---@field p95 number 95th percentile timing

---@param fn fun(i: integer)
---@param opts? Bench.RunOpts
---@return Bench.Result
local function run(fn, opts)
    opts = opts or {}
    local warmup = opts.warmup or 20
    local iterations = opts.iterations or 1000
    assert(iterations > 0, 'iterations must be a positive integer')

    for i = 1, warmup do
        fn(i)
    end

    ---@type number[]
    local timings = {}
    local sum = 0
    for i = 1, iterations do
        local start = vim.uv.hrtime()
        fn(i)
        timings[i] = (vim.uv.hrtime() - start) / 1e6 -- ns -> ms
        sum = sum + timings[i]
    end

    table.sort(timings)

    return {
        min = timings[1],
        max = timings[iterations],
        avg = sum / iterations,
        median = timings[math.ceil(#timings / 2)],
        p95 = timings[math.ceil(#timings * 0.95)],
    }
end

--- Prepares the bench to run
---@param opts Bench.SetupOpts
function M.setup(opts)
    opts = opts or {}
    return {
        ---Runs a benchmark on a function and prints the result
        ---@param fn fun(i: integer) Function to benchmark; receives the current iteration index
        ---@return Bench.Result stats Statistics summary of the execution times
        run = function(fn)
            local result = run(fn, opts)
            M.print_result(opts.name, result)
            return result
        end,
    }
end

return M
