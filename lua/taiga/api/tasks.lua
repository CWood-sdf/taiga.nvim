local cache = require "taiga.utils.cache"
local M = {}

---@class (exact) Taiga.Tasks.Create.Query.Data
---@field project number
---@field subject string
---@field user_story string

---@class (exact) Taiga.Tasks.Create.Query
---@field data Taiga.Stories.Create.Query.Data
---@field refresh fun(arr: table[])?
---@field storyId number

---@class (exact) Taiga.Tasks.List.Query
---@field project number
---@field user_story number
---@field assigned_to number?

---@class (exact) Taiga.Tasks.Delete.Query
---@field storyId number
---@field id number
---@field epicId number
---@field project number


---@class (exact) Taiga.Tasks.Edit.Query.Data
---@field subject string?
---@field description string?
---@field assigned_to number?

---@class (exact) Taiga.Tasks.Edit.Query
---@field id number
---@field projectId number
---@field data Taiga.Stories.Edit.Query.Data

---@class (exact) Taiga.Tasks.Get.Query
---@field id number

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
            local arr = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            for _, task in ipairs(arr) do
                require("taiga.api.refdb").addRef({
                    id = task.id,
                    name = task.subject,
                    ref = task.ref,
                    tp = "epic",
                })
                M.get(function() end, { cache = false }, { id = task.id })
            end
            vim.schedule_wrap(onDone)(arr)
        end)
    end, opts, nil)
end, "tasks_list")

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
            M.list(function() end, { cache = false },
                { project = query.project, user_story = query.storyId, projectId = query.project })
            vim.schedule_wrap(onDone)(v.stdout)
            -- onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end



---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Tasks.Edit.Query
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
            "https://api.taiga.io/api/v1/tasks/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            M.get(function() end, { cache = false }, { id = query.id })
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end

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
end, "tasks_get")

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
            vim.schedule_wrap(onDone)(out)
            M.list(query.refresh or function() end, { cache = false },
                { project = out.project, user_story = query.storyId })
        end)
    end, opts, nil)
end

return M
