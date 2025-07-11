local cache = require "taiga.utils.cache"
local M = {}
---@class Taiga.Projects.List.Query
---@field member string?

---@class Taiga.Projects.Get.Query
---@field id string

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Projects.List.Query
M.list = cache.wrap(function(onDone, opts, query)
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
            "https://api.taiga.io/api/v1/projects?member=" .. login.id,
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Projects.Get.Query
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
            "https://api.taiga.io/api/v1/projects/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

return M
