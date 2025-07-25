local cache = require "taiga.utils.cache"
local M = {}

---@class (exact) Taiga.Epics.Create.Query.Data
---@field project number
---@field subject string
---@field color string

---@class (exact) Taiga.Epics.Delete.Query
---@field id number
---@field project number
---@field refresh fun(arr: table[])?

---@class (exact) Taiga.Epics.Create.Query
---@field data Taiga.Epics.Create.Query.Data
---@field refresh fun(arr: table[])?
---@field projectId number

---@class (exact) Taiga.Epics.List.Query
---@field project number
---@field assigned_to number?

---@class (exact) Taiga.Epics.Get.Query
---@field id number

---@class (exact) Taiga.Epics.Edit.Query.Data
---@field subject string?
---@field description string?

---@class (exact) Taiga.Epics.Edit.Query
---@field id number
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
            local arr = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            for _, epic in ipairs(arr) do
                -- M.get(function() end, { cache = false }, {
                --     id = epic.id
                -- })
                require("taiga.api.refdb").addRef({
                    id = epic.id,
                    name = epic.subject,
                    ref = epic.ref,
                    tp = "epic",
                })
            end
            vim.schedule_wrap(onDone)(arr)
        end)
    end, opts, nil)
end, "epics_list")

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.Create.Query
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
            "https://api.taiga.io/api/v1/epics/",
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            M.list(function(epics)
                query.refresh(epics)
            end, { cache = false }, { project = query.projectId })
            -- TODO: This doesnt work
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.Delete.Query
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
            "https://api.taiga.io/api/v1/epics/" .. query.id
        }

        vim.system(cmd, {
            text = true,
        }, function(v)
            M.list(query.refresh, { cache = false }, { project = query.project })
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.Edit.Query
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
            "https://api.taiga.io/api/v1/epics/" .. query.id
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
            vim.schedule_wrap(onDone)(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
        end)
    end, opts, nil)
end, "epics_get")

return M
