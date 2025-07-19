local M = {}

---@type fun()[]
local onRequests = {}

local saveDir = vim.fn.stdpath("data") .. "/taiga/"

vim.fn.mkdir(saveDir, "p")

local function stringToHex(inputString)
    local hexString = ""
    for i = 1, #inputString do
        local byte = string.byte(inputString, i)
        hexString = hexString .. string.format("%02x", byte)
    end
    return hexString
end

---@class Cacheable<T, Query>: { cache: T?, get: fun(self: Cacheable<T>, onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query) }

---@generic T, Query
---@param run fun(onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query)
---@param refreshTime number?
---@param name string
---@return fun(onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query)
function M.wrap(run, name, refreshTime)
    refreshTime = refreshTime or 3 * 60 * 1000
    local timer = nil
    local cache = {}
    local inflights = {}
    local ret = function(onDone, opts, query)
        local q = vim.json.encode(query)
        local hash = name .. "__" .. stringToHex(q)
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
        local saveFile = saveDir .. hash .. ".json"
        if vim.fn.filereadable(saveFile) and opts.cache ~= false then
            local file = io.open(saveFile, "r")
            if file ~= nil then
                local contents = file:read("*a")
                file:close()
                cache[q] = vim.json.decode(contents)
                onDone(cache[q])
                return
            end
        end
        if inflights[q] ~= nil then
            table.insert(inflights[q], onDone)
            return
        end


        inflights[q] = {}
        run(function(v)
            cache[q] = v
            local file = io.open(saveFile, "w")
            if file ~= nil then
                file:write(vim.json.encode(v))
                file:close()
            end
            onDone(v)
            for _, fn in ipairs(inflights[q]) do
                fn(v)
            end
            for _, onreq in ipairs(onRequests) do
                onreq()
            end
            inflights[q] = nil
        end, opts, query)
    end
    return ret
end

function M.attachRequestCallback(fn)
    table.insert(onRequests, fn)
end

return M
