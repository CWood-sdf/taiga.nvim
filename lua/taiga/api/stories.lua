local cache = require "taiga.utils.cache"
local M = {}

---@class (exact) Taiga.Stories.Create.Query.Data
---@field project number
---@field subject string

---@class (exact) Taiga.Stories.Create.Query
---@field data Taiga.Stories.Create.Query.Data
---@field refresh fun(arr: table[])?
---@field epicId number
---@field projectId number

---@class (exact) Taiga.Stories.List.Query
---@field project number
---@field epic number?

---@class (exact) Taiga.Stories.Get.Query
---@field id number

---@class (exact) Taiga.Stories.Delete.Query
---@field id number
---@field epicId number
---@field project number

---@class (exact) Taiga.Stories.Edit.Query.Data
---@field subject string?
---@field description string?

---@class (exact) Taiga.Stories.Edit.Query
---@field id number
---@field project number
---@field data Taiga.Stories.Edit.Query.Data

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.List.Query
local mainList = cache.wrap(function(onDone, opts, query)
    require("taiga.api.auth").getCredentials(function(login)
        local queryStr = "?project=" .. query.project

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
            local arr = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            for _, story in ipairs(arr) do
                M.get(function() end, { cache = false }, {
                    id = story.id
                })
            end
            vim.schedule_wrap(onDone)(arr)
        end)
    end, opts, nil)
end)

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Stories.List.Query
M.list = function(onDone, opts, query)
    mainList(function(arr)
        if query.epic ~= nil then
            local newArr = {}
            for _, story in ipairs(arr) do
                for _, epic in ipairs(story.epics or {}) do
                    if epic.id == query.epic then
                        table.insert(newArr, story)
                        break
                    end
                end
            end
            onDone(newArr)
        else
            onDone(arr)
        end
    end, opts, {
        project = query.project
    })
end

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
            vim.schedule_wrap(onDone)(out)
            mainList(query.refresh or function() end, { cache = false }, { project = out.project, epic = query.epicId })
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
            mainList(function() end, { cache = false }, { project = query.project })
            vim.schedule_wrap(onDone)(v.stdout)
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
            mainList(function() end, { cache = false }, { project = query.project })
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
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
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end)

return M
