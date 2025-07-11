local cache = require "taiga.utils.cache"
local M = {}

---@class Taiga.Stories.Create.Query.Data
---@field project string
---@field subject string

---@class Taiga.Stories.Create.Query
---@field data Taiga.Stories.Create.Query.Data
---@field refresh fun(arr: table[])?
---@field epicId string

---@class Taiga.Stories.List.Query
---@field project string?
---@field epic string?

---@class Taiga.Stories.Get.Query
---@field id string

---@class Taiga.Stories.Delete.Query
---@field id string
---@field epicId string

---@class Taiga.Stories.Edit.Query.Data
---@field subject string?
---@field description string?

---@class Taiga.Stories.Edit.Query
---@field id string
---@field data Taiga.Stories.Edit.Query.Data

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.List.Query
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
            "https://api.taiga.io/api/v1/userstories" .. queryStr,
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
---@param query Taiga.Stories.Create.Query
M.create = function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local cmd = {
            "curl",
            "-X",
            "POST",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. login.auth_token,
            "-d", vim.json.encode(query.data),
            "-s",
            "https://api.taiga.io/api/v1/userstories"
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            local out = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            onDone(out)
            M.list(query.refresh or function() end, { cache = false }, { project = out.project, epic = query.epicId })
        end)
    end, opts, nil)
end

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.Delete.Query
M.delete = function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local cmd = {
            "curl",
            "-X",
            "DELETE",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. login.auth_token,
            "-s",
            "https://api.taiga.io/api/v1/userstories/" .. query.id
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            M.get(function() end, { cache = false }, { id = query.id })
            M.list(function() end, { cache = false }, { epic = query.epicId })
            onDone(v.stdout)
            -- onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end


---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.Edit.Query
M.edit = function(onDone, opts, query)
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
            "https://api.taiga.io/api/v1/userstories/" .. query.id
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            M.get(function() end, { cache = false }, { id = query.id })
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.Get.Query
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
            "https://api.taiga.io/api/v1/userstories/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

return M
