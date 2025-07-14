local M = {}

---@class Cacheable<T, Query>: { cache: T?, get: fun(self: Cacheable<T>, onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query) }

---@generic T, Query
---@param run fun(onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query)
---@param refreshTime number?
---@return fun(onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query)
function M.wrap(run, refreshTime)
    refreshTime = refreshTime or 3 * 60 * 1000
    local timer = nil
    local cache = {}
    local ret = function(onDone, opts, query)
        local q = vim.json.encode(query)
        if cache[q] ~= nil and opts.cache ~= false then
            onDone(cache[q])
            return
        end
        if timer == nil and refreshTime ~= 0 then
            timer = vim.uv.new_timer()
            -- timer:start(refreshTime, 10000, function()
            --     run(function(v)
            --         cache[q] = v
            --     end, opts, query)
            -- end)
        end
        run(function(v)
            cache[q] = v
            onDone(v)
        end, opts, query)
    end
    return ret
end

return M
