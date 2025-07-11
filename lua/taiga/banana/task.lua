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
    local body = document:getScriptParams().selfNode:parent()
    local params = document:getScriptParams().params
    local taskId = params.id or error("taskId not passed")
    local storyId = params.storyId or error("storyId not passed")
    local epicId = params.epicId or error("epicId not passed")
    local projectId = params.projectId or error("projectId not passed")
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

    require("taiga.api.epics").get(vim.schedule_wrap(function(epic)
        utils.epicTitle(document, document:getElementById("epicName"), colorBlock, body,
            epic, epicId, projectId, versionTable)
    end), {}, { id = epicId })


    require("taiga.api.projects").get(vim.schedule_wrap(function(proj)
        container:setAttribute("projectName", proj.name)
        container:setAttribute("projectDescription", proj.description)
        document
            :getElementById("project")
            :attachRemap("n", "<CR>", { "line-hover" }, function()
                document:loadNmlTo(
                    "taiga/project?id=" .. projectId, body, true, false)
            end, {})
    end), {}, { id = projectId })

    require("taiga.api.stories").get(vim.schedule_wrap(function(story)
        local storyNameCont = document:getElementById("storyName")
        utils.storyTitle(document, body, storyNameCont, story, versionTable, storyId, epicId, projectId)

        -- storyNameCont:appendChild(title)
        -- container:setAttribute("storyName", story.subject)
    end), {}, { id = storyId, epicId = epicId })
    require("taiga.api.tasks").get(vim.schedule_wrap(function(task)
        versionTable.version = task.version
        document:getElementById("taskName"):setTextContent("(#" .. task.ref .. ") " .. task.subject)
        -- assigned {
        local assignee = document:getElementById("assignee")
        local assignedUser = task.assigned_to
        setAssignedUsers(assignee, { assignedUser })
        assignee:attachRemap("n", "<CR>", { "line-hover" }, function()
            local el = document:createElement("SelectPerson")
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

        local el = document:createElement("TextBlock")
        el:setAttribute("content", task.description)
        el:setData("callback", function(str)
            require("taiga.api.stories").edit(function(v)
                if v.version == nil then
                    vim.print("Action Failed!")
                    vim.print(v)
                    return
                end
                versionTable.version = v.version
            end, {}, {
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
        taskDesc:appendChild(el)
    end), {}, {
        id = taskId,
    })
end
