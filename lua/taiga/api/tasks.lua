local cache = require "taiga.utils.cache"
local M = {}

---@class Taiga.Tasks.Create.Query.Data
---@field project string
---@field subject string
---@field user_story string

---@class Taiga.Tasks.Create.Query
---@field data Taiga.Stories.Create.Query.Data
---@field refresh fun(arr: table[])?
---@field storyId string

---@class Taiga.Tasks.List.Query
---@field project string?
---@field user_story string?
---@field assigned_to number?

---@class Taiga.Tasks.Delete.Query
---@field storyId string
---@field id string
---@field epicId string
---@field projectId string


---@class Taiga.Tasks.Edit.Query.Data
---@field subject string?
---@field description string?
---@field assigned_to number?

---@class Taiga.Tasks.Edit.Query
---@field id string
---@field data Taiga.Stories.Edit.Query.Data

---@class Taiga.Tasks.Get.Query
---@field id number|string

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Tasks.List.Query
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
            "https://api.taiga.io/api/v1/tasks" .. queryStr,
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
---@param query Taiga.Tasks.Delete.Query
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
            "https://api.taiga.io/api/v1/tasks/" .. query.id
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            M.get(function() end, { cache = false }, { id = query.id })
            M.list(function() end, { cache = false }, { user_story = query.storyId, projectId = query.projectId })
            onDone(v.stdout)
            -- onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end



---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Tasks.Edit.Query
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
            "https://api.taiga.io/api/v1/tasks/" .. query.id
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
---@param query Taiga.Tasks.Get.Query
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
            "https://api.taiga.io/api/v1/tasks/" .. query.id
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
---@param query Taiga.Tasks.Create.Query
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
            "https://api.taiga.io/api/v1/tasks"
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            local out = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            onDone(out)
            M.list(query.refresh or function() end, { cache = false },
                { project = out.project, user_story = query.storyId })
        end)
    end, opts, nil)
end

return M
