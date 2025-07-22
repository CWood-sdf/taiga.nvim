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
---@param name string
---@param refreshTime number?
---@param storeAsFile boolean?
---@return fun(onDone: fun(value: T), opts: Taiga.Api.BaseOpts, query: Query)
function M.wrap(run, name, refreshTime, storeAsFile)
    -- refreshTime = refreshTime or 3 * 60 * 1000
    local cache = {}
    local inflights = {}
    local ret = function(onDone, opts, query)
        local q = vim.json.encode(query)
        local hash = name .. "__" .. stringToHex(q)
        local clock = vim.uv.clock_gettime("realtime")
        if clock == nil then
            error("BRO")
        end
        if cache[q] ~= nil and opts.cache ~= false then
            if clock.sec - cache[q].__ran_at.sec < 2 * 60 * 60 then
                onDone(cache[q])
                return
            else
                cache[q] = nil
            end
        end
        local saveFile = saveDir .. hash .. ".json"
        if vim.fn.filereadable(saveFile) and opts.cache ~= false and storeAsFile ~= false then
            local file = io.open(saveFile, "r")
            if file ~= nil then
                local contents = file:read("*a")
                file:close()
                local obj = vim.json.decode(contents)
                for k, v in pairs(obj) do
                    local isnum = #vim.split(k .. "", "%d", { plain = false, trimempty = true }) == 0
                    if isnum then
                        obj[tonumber(k)] = v
                    end
                end
                if obj.__ran_at ~= nil and obj.__ran_at.sec ~= nil and clock.sec - obj.__ran_at.sec < 30 * 60 then
                    cache[q] = obj
                    onDone(cache[q])
                    return
                end
            end
        end
        if inflights[q] ~= nil then
            table.insert(inflights[q], onDone)
            return
        end


        inflights[q] = {}
        run(function(v)
            cache[q] = v
            v.__ran_at = vim.uv.clock_gettime("realtime")
            if v.__ran_at == nil then
                error("bro clock gave me nothing")
            end
            if storeAsFile ~= false then
                local file = io.open(saveFile, "w")
                if file ~= nil then
                    file:write(vim.json.encode(v))
                    file:close()
                end
            end
            onDone(v)
            for _, fn in ipairs(inflights[q]) do
                fn(v)
            end
            for _, onreq in ipairs(onRequests) do
                onreq()
            end
            if refreshTime ~= nil and refreshTime ~= 0 then
                local timer = vim.uv.new_timer()
                if timer ~= nil then
                    timer:start(refreshTime, 0, function()
                        cache[q] = nil
                        timer:stop()
                    end)
                end
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
