local utils = require("taiga.banana.utils")
---@module "banana.instance"

local function drawTasks(document, tasks, taskCont, projectId, epicId, storyId, body)
    taskCont:removeChildren()
    for _, task in ipairs(tasks) do
        local el = document:createElement("TaskName")
        el:setAttribute("taskName", task.subject)
        el:setAttribute("ref", task.ref)
        el:attachRemap("n", "<CR>", { "line-hover" }, function()
            document:loadNmlTo(
                "taiga/task?id=" ..
                task.id .. "&storyId=" .. storyId .. "&epicId=" .. epicId .. "&projectId=" .. projectId,
                body,
                true, false)
        end, {})
        el:setAttribute("blockReason", task.blocked_note)
        el:attachRemap("n", "dd", { "line-hover" }, function()
            print("Deleting " .. task.ref)
            require("taiga.api.tasks").delete(function()
                require("taiga.api.tasks").list(vim.schedule_wrap(function(s)
                    drawTasks(document, s, taskCont, projectId, epicId, storyId, body)
                end), { cache = false }, { epic = epicId, project = projectId, user_story = storyId })
            end, {}, {
                epicId = epicId,
                id = task.id,
                projectId = projectId,
                storyId = storyId,
            })
        end, {})
        taskCont:appendChild(el)
    end
end

---@param el Banana.Ast
---@param users number[]
local function setAssignedUsers(el, users)
    users = users or {}
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
    local storyId = params.id or error("storyId not passed")
    local epicId = params.epicId or error("epicId not passed")
    local projectId = params.projectId or error("projectId not passed")
    local container = document:getElementById("container")
    local taskCont = document:getElementById("tasks")
    local colorBlock = document:getElementById("color")
    local versionTable = {
        version = nil,
    }

    local statusCont = document:getElementById('status')
    local status = document:createElement("Status")
    status:setData('projectId', projectId)
    status:setData('type', "story")
    status:setData("id", storyId)
    status:setData('editCallback', function(v)
        require("taiga.api.stories").edit(function(e)
            versionTable.version = e.version
        end, {}, {
            id = storyId,
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
                "taiga/epic?id=" .. epicId .. "&projectId=" .. projectId, body, true, false)
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
        versionTable.version = story.version
        local storyNameCont = document:getElementById("storyName")
        utils.storyTitle(document, body, storyNameCont, story, versionTable, storyId, epicId, projectId)
        -- assigned {
        local assignee = document:getElementById("assignee")
        local assignedUsers = story.assigned_users
        setAssignedUsers(assignee, assignedUsers)
        assignee:attachRemap("n", "<CR>", { "line-hover" }, function()
            local el = document:createElement("SelectPerson")
            el:setData("callback", function(person)
                if person ~= nil then
                    local found = false
                    for i, v in ipairs(assignedUsers) do
                        if person.id == v then
                            found = true
                            table.remove(assignedUsers, i)
                            break
                        end
                    end
                    if not found then
                        table.insert(assignedUsers, person.id)
                    end
                    local assigned_to = story.assigned_to
                    if assigned_to == person.id then
                        assigned_to = assignedUsers[1] or vim.NIL
                    end
                    vim.print(assignedUsers)
                    vim.print(assigned_to)
                    local obj = {
                        version = versionTable.version,
                        assigned_users = assignedUsers,
                        assigned_to = assigned_to,
                    }
                    if assigned_to == nil then
                        obj.assigned_to_extra_info = vim.NIL
                    end
                    require("taiga.api.stories").edit(function(v)
                        if v.version == nil then
                            vim.print("Action failed!")
                            vim.print(v)
                            return
                        end
                        -- vim.print(v)
                        assignedUsers = v.assigned_users
                        setAssignedUsers(assignee, v.assigned_users)
                        versionTable.version = v.version
                        story = v
                    end, {}, {
                        id = storyId,
                        data = obj,
                    })
                end
                el:remove()
            end)
            el:setData("projectId", projectId)
            local selector = document:getElementById("userSelector")
            selector:appendChild(el)
        end, {})
        -- }

        -- storyNameCont:appendChild(title)
        local el = document:createElement("TextBlock")
        el:setAttribute("content", story.description)
        el:setData("callback", function(str)
            require("taiga.api.stories").edit(function(v)
                if v.version == nil then
                    vim.print("Action Failed!")
                    vim.print(v)
                    return
                end
                versionTable.version = v.version
            end, {}, {
                id = storyId,
                data = {
                    description = str,
                    version = versionTable.version,
                },
            })
        end)
        local storyDesc = document:getElementById('storyDesc')
        storyDesc:removeChildren()
        storyDesc:appendChild(el)
        -- container:setAttribute("storyName", story.subject)
    end), {}, { id = storyId })
    require("taiga.api.tasks").list(vim.schedule_wrap(function(tasks)
        drawTasks(document, tasks, taskCont, projectId, epicId, storyId, body)
    end), {}, { project = projectId, user_story = storyId })
    taskCont:attachRemap("n", "+", {}, function()
        local name = vim.fn.input("New name: ")
        require("taiga.api.tasks").create(vim.schedule_wrap(function(story)
        end), {}, {
            refresh = vim.schedule_wrap(function(tasks)
                drawTasks(document, tasks, taskCont, projectId, epicId, storyId, body)
            end),
            storyId = storyId,
            data = {
                project = projectId,
                subject = name,
                user_story = storyId,
            },
        })
    end, {})
end
