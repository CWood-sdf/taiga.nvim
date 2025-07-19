local cache = require "taiga.utils.cache"
local M = {}
---@class (exact) Taiga.Projects.List.Query
---@field member string?

---@class (exact) Taiga.Projects.Get.Query
---@field id number

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
            local arr = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            for _, proj in ipairs(arr) do
                M.get(function() end, { cache = false }, { id = proj.id })
            end
            vim.schedule_wrap(onDone)(arr)
        end)
    end, opts, nil)
end, "projects_list")

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
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end, "projects_get")

return M
