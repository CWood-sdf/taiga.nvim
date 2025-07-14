local utils = require("taiga.banana.utils")
---@module "banana.instance"


---@param el Banana.Ast
---@param users number[]
local function setAssignedUsers(el, users)
    local str = ""
    local countDone = 0
    el:removeChildren()
    if #users == 0 then
        el:setTextContent("no one")
        return
    end
    for _, v in ipairs(users) do
        require("taiga.api.users").get(function(user)
            str = str .. user.full_name
            countDone = countDone + 1
            el:setTextContent(str)
            if countDone ~= #users then
                str = str .. ", "
            end
        end, {}, { id = v })
    end
end

---@param document Banana.Instance
return function(document)
    document:setTitle("task")
    local body = document:getScriptParams().selfNode:parent()
    local params = document:getScriptParams().params
    local taskId = tonumber(params.id) or error("taskId not passed")
    local storyId = tonumber(params.storyId) or error("storyId not passed")
    local blockedCont = document:getElementById("blockedCont")
    local epicId = tonumber(params.epicId) or error("epicId not passed")
    local projectId = tonumber(params.projectId) or error("projectId not passed")
    local container = document:getElementById("container")
    local colorBlock = document:getElementById("color")
    local versionTable = {
        version = nil,
    }

    local statusCont = document:getElementById('status')
    local status = document:createElement("Status")
    status:setData('projectId', projectId)
    status:setData('type', "task")
    status:setData("id", taskId)
    status:setData('editCallback', function(v)
        require("taiga.api.tasks").edit(function(e)
            versionTable.version = e.version
        end, {}, {
            projectId = projectId,
            id = taskId,
            data = {
                version = versionTable.version,
                status = v.id
            }
        })
    end)
    statusCont:appendChild(status)

    document
        :getElementById("epic")
        :attachRemap("n", "H", {}, function()
            document:loadNmlTo(
                "taiga/story?id=" .. storyId .. "&epicId=" .. epicId .. "&projectId=" .. projectId, body, true, false)
        end, {})

    require("taiga.api.epics").get(function(epic)
        utils.epicTitle(document, document:getElementById("epicName"), colorBlock, body,
            epic, epicId, projectId, versionTable)
    end, {}, { id = epicId })


    require("taiga.api.projects").get(function(proj)
        container:setAttribute("projectName", proj.name)
        container:setAttribute("projectDescription", proj.description)
        document
            :getElementById("project")
            :attachRemap("n", "<CR>", { "line-hover" }, function()
                document:loadNmlTo(
                    "taiga/project?id=" .. projectId, body, true, false)
            end, {})
    end, {}, { id = projectId })

    require("taiga.api.stories").get(function(story)
        local storyNameCont = document:getElementById("storyName")
        utils.storyTitle(document, body, storyNameCont, story, versionTable, storyId, epicId, projectId)

        -- storyNameCont:appendChild(title)
        -- container:setAttribute("storyName", story.subject)
    end, {}, { id = storyId })
    require("taiga.api.tasks").get(function(task)
        versionTable.version = task.version
        document:getElementById("taskName"):setTextContent("Task: (#" .. task.ref .. ") " .. task.subject)

        if task.blocked_note ~= nil and task.blocked_note ~= "" then
            blockedCont:setTextContent("Blocked: " .. task.blocked_note)
        end
        -- assigned {
        local assignee = document:getElementById("assignee")
        local assignedUser = task.assigned_to
        setAssignedUsers(assignee, { assignedUser })
        local el = nil
        assignee:attachRemap("n", "<CR>", { "line-hover" }, function()
            if el ~= nil then
                el:remove()
                el = nil
                return
            end
            el = document:createElement("SelectPerson")
            el:setData("callback", function(person)
                if person ~= nil then
                    if assignedUser == person.id then
                        assignedUser = vim.NIL
                    else
                        assignedUser = tonumber(person.id)
                    end
                    local obj = {
                        version = versionTable.version,
                        assigned_to = assignedUser,
                    }
                    if assignedUser == vim.NIL then
                        obj.assigned_to_extra_info = vim.NIL
                    end

                    require("taiga.api.tasks").edit(function(v)
                        if v.version == nil then
                            vim.print("Action failed!")
                            vim.print(v)
                            return
                        end
                        setAssignedUsers(assignee, { v.assigned_to })
                        assignedUser = v.assigned_to
                        versionTable.version = v.version
                        task = v
                    end, {}, {
                        projectId = projectId,
                        id = taskId,
                        data = obj,
                    })
                end
                el:remove()
            end)
            el:setData("projectId", projectId)
            local selector = document:getElementById("userSelector")
            selector:appendChild(el)
        end, {})
        -- -- }

        local textblock = document:createElement("TextBlock")
        textblock:setAttribute("content", task.description)
        textblock:setData("callback", function(str)
            require("taiga.api.stories").edit(function(v)
                if v.version == nil then
                    vim.print("Action Failed!")
                    vim.print(v)
                    return
                end
                versionTable.version = v.version
            end, {}, {
                project = projectId,
                epicId = epicId,
                id = storyId,
                data = {
                    description = str,
                    version = versionTable.version,
                },
            })
        end)
        local taskDesc = document:getElementById('taskDesc')
        taskDesc:removeChildren()
        taskDesc:appendChild(textblock)
    end, {}, {
        id = taskId,
    })
end
