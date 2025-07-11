local M       = {}

local cache   = require("taiga.utils.cache")

---@class Taiga.Auth.UsernamePassword
---@field username string
---@field password string

---@class Taiga.Auth.Credentials
---@field id number
---@field username string
---@field full_name string
---@field auth_token string
---@field refresh string

---@param onDone fun(up: Taiga.Auth.UsernamePassword)
---@param opts Taiga.Api.BaseOpts
M.getUsername = cache.wrap(function(onDone, opts, query)
    vim.system({ "/home/christopher-wood/projects/taiga.nvim/scripts/login.sh", }, {
        text = true,
        cwd = "/home/christopher-wood/projects/taiga.nvim/",
    }, function(v)
        onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
    end)
end, 0)


---@type Taiga.Auth.Credentials?
local me = nil

-- M.refresh = function()
--     if me == nil then
--         return
--     end
--     local obj = {
--         refresh = me.refresh
--     }
--
--     vim.system({
--         "curl",
--         "-X", "POST",
--         "-H", "Content-Type: application/json",
--         "-d", vim.json.encode(obj),
--         "https://api.taiga.io/api/v1/auth/refresh",
--     }, {
--         text = true,
--     }, function(o)
--         -- me = vim.json.decode(o.stdout, { luanil = { object = true, array = true } })
--         local out = vim.json.decode(o.stdout)
--         me.auth_token = out.auth_token
--     end)
--     vim.defer_fn(vim.schedule_wrap(M.refresh), 3 * 60 * 1000)
-- end

---@param onDone fun(v: Taiga.Auth.Credentials)
---@param opts Taiga.Api.BaseOpts
M.getCredentials = cache.wrap(function(onDone, opts)
    M.getUsername(function(up)
        local obj = {
            type = "normal",
            username = up.username,
            password = up.password,
        }

        vim.system({
            "curl",
            "-X", "POST",
            "-H", "Content-Type: application/json",
            "-d", vim.json.encode(obj),
            "https://api.taiga.io/api/v1/auth",
        }, {
            text = true,
        }, function(o)
            me = vim.json.decode(o.stdout, { luanil = { object = true, array = true } })
            onDone(me)
            -- M.refresh()
        end)
    end, opts, nil)
end)

function M.getAuthToken()
    if me == nil then return "" end
    return me.auth_token
end

return M
