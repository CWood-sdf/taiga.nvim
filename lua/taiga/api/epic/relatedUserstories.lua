local cache = require "taiga.utils.cache"
local M = {}

---@class Taiga.Epics.RelUs.Create.Query.Data
---@field epic number
---@field user_story number

---@class Taiga.Epics.RelUs.Create.Query
---@field epic number
---@field data Taiga.Epics.RelUs.Create.Query.Data

---@class Taiga.Epics.RelUs.List.Query
---@field project string?
---@field epic string?

---@class Taiga.Epics.RelUs.Get.Query
---@field id string

---@class Taiga.Epics.RelUs.Edit.Query.Data
---@field subject string?
---@field description string?

---@class Taiga.Epics.RelUs.Edit.Query
---@field id string
---@field data Taiga.Epics.RelUs.Edit.Query.Data

-- ---@param onDone fun(projects)
-- ---@param opts Taiga.Api.BaseOpts
-- ---@param query Taiga.Epics.RelUs.List.Query
-- M.list = cache.wrap(function(onDone, opts, query)
--     require("taiga.api.auth").getCredentials(function(login)
--         local queryStr = ""
--
--         for k, v in pairs(query) do
--             if queryStr == "" then
--                 queryStr = "?"
--             else
--                 queryStr = queryStr .. "&"
--             end
--             queryStr = queryStr .. k .. "=" .. v
--         end
--         local cmd = {
--             "curl",
--             "-X",
--             "GET",
--             "-H",
--             "Content-Type: application/json",
--             "-H",
--             "Authorization: Bearer " .. login.auth_token,
--             "-s",
--             "https://api.taiga.io/api/v1/userstories" .. queryStr,
--         }
--
--         vim.system(cmd, {
--             text = true,
--         }, function(v)
--             onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
--         end)
--     end, opts, nil)
-- end)

---@param onDone fun(projects)
---@param opts Taiga.Api.BaseOpts
---@param query Taiga.Epics.RelUs.Create.Query
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
            "https://api.taiga.io/api/v1/epics/" .. query.epic .. "/related_userstories"
        }
        vim.system(cmd, {
            text = true,
        }, function(v)
            local out = vim.json.decode(v.stdout, { luanil = { object = true, array = true } })
            onDone(out)
            -- M.list(function() end, { cache = false }, { project = out.project })
        end)
    end, opts, nil)
end


-- ---@param onDone fun(projects)
-- ---@param opts Taiga.Api.BaseOpts
-- ---@param query Taiga.Epics.RelUs.Edit.Query
-- M.edit = function(onDone, opts, query)
--     require("taiga.api.auth").getCredentials(function(login)
--         local cmd = {
--             "curl",
--             "-X",
--             "PATCH",
--             "-H",
--             "Content-Type: application/json",
--             "-H",
--             "Authorization: Bearer " .. login.auth_token,
--             "-d", vim.json.encode(query.data),
--             "-s",
--             "https://api.taiga.io/api/v1/userstories/" .. query.id
--         }
--         vim.system(cmd, {
--             text = true,
--         }, function(v)
--             M.get(function() end, { cache = false }, { id = query.id })
--             onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
--         end)
--     end, opts, nil)
-- end
--
-- ---@param onDone fun(projects)
-- ---@param opts Taiga.Api.BaseOpts
-- ---@param query Taiga.Epics.RelUs.Get.Query
-- M.get = cache.wrap(function(onDone, opts, query)
--     require("taiga.api.auth").getCredentials(function(login)
--         local cmd = {
--             "curl",
--             "-X",
--             "GET",
--             "-H",
--             "Content-Type: application/json",
--             "-H",
--             "Authorization: Bearer " .. login.auth_token,
--             "-s",
--             "https://api.taiga.io/api/v1/userstories/" .. query.id
--         }
--
--         vim.system(cmd, {
--             text = true,
--         }, function(v)
--             onDone(vim.json.decode(v.stdout, { luanil = { object = true, array = true } }))
--         end)
--     end, opts, nil)
-- end)

return M
