local cache = require "taiga.utils.cache"
local M = {}

---@class (exact) Taiga.Users.Get.Query
---@field id number

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Users.Get.Query
M.get = cache.wrap(function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local cmd = {
            "curl",
            "-X",
            "GET",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. login.auth_token,
            "-s",
            "https://api.taiga.io/api/v1/users/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end, "users_get")

return M
