local M = {}

---@param document Banana.Instance
---@param container Banana.Ast
---@param colorBlock Banana.Ast
---@param body Banana.Ast
---@param versionTable { version: number }
---@param epicId number
---@param projectId number
function M.epicTitle(document, container, colorBlock, body, epic, epicId, projectId, versionTable)
    local title = document:createElement("EditTitle")
    title:setAttribute("content", epic.subject)
    title:setData("displayTitle", function(str)
        return "Epic: (#" .. epic.ref .. ") " .. str
    end)
    title:setData("filetype", "text")
    title:setData("callback", function(str)
        require("taiga.api.epics").edit(function(v)
            if v.version == nil then
                vim.print("Action Failed!")
                vim.print(v)
                return
            end
            versionTable.version = v.version
        end, {}, {
            project = projectId,
            id = epicId,
            data = {
                subject = str,
                version = versionTable.version,
            },
        })
    end)
    container:appendChild(title)
    colorBlock:setStyleValue("hl-fg", epic.color)
    container:attachRemap("n", "<CR>", { "line-hover" }, function()
        document:loadNmlTo(
            "taiga/epic?id=" .. epicId .. "&projectId=" .. projectId, body, true, false)
    end, {})
end

---@param document Banana.Instance
---@return Banana.Ast
function M.getBody(document)
    return document:getElementById("body")
end

function M.storyTitle(document, body, container, story, versionTable, storyId, epicId, projectId)
    local title = document:createElement("EditTitle")
    title:setAttribute("content", story.subject)
    title:setData("displayTitle", function(str)
        return "Story: (#" .. story.ref .. ") " .. str
    end)
    title:setData("callback", function(str)
        require("taiga.api.stories").edit(function(v)
            if v.version == nil then
                vim.print("Action Failed!")
                vim.print(v)
                return
            end
            versionTable.version = v.version
        end, {}, {
            project = projectId,
            id = storyId,
            data = {
                subject = str,
                version = versionTable.version,
            },
        })
    end)
    container:appendChild(title)
    container:attachRemap("n", "<CR>", { "line-hover" }, function()
        document:loadNmlTo(
            "taiga/story?id=" .. storyId .. "&epicId=" .. epicId .. "&projectId=" .. projectId, body, true, false)
    end, {})
end

function M.taskTitle(el)

end

function M.projectHeader(el)

end

return M
