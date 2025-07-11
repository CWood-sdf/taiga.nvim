local cache = require "taiga.utils.cache"
local M = {}

---@class Taiga.Epics.List.Query
---@field project number|string?
---@field assigned_to number?

---@class Taiga.Epics.Get.Query
---@field id number|string

---@class Taiga.Epics.Edit.Query.Data
---@field subject string?
---@field description string?

---@class Taiga.Epics.Edit.Query
---@field id string
---@field data Taiga.Epics.Edit.Query.Data

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.List.Query
M.list = cache.wrap(function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local queryStr = ""

        for k, v in pairs(query) do
            if queryStr == "" then
                queryStr = "?"
            else
                queryStr = queryStr .. "&"
            end
            queryStr = queryStr .. k .. "=" .. v
        end
        local cmd = {
            "curl",
            "-X",
            "GET",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. login.auth_token,
            "-s",
            "https://api.taiga.io/api/v1/epics" .. queryStr,
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
---@param query Taiga.Epics.Edit.Query
M.edit = cache.wrap(function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local cmd = {
            "curl",
            "-X",
            "PATCH",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. login.auth_token,
            "-d", vim.json.encode(query.data),
            "-s",
            "https://api.taiga.io/api/v1/epics/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            M.get(function() end, { cache = false }, { id = query.id })
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.Get.Query
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
            "https://api.taiga.io/api/v1/epics/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

return M
