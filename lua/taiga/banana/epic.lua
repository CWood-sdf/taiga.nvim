local utils = require("taiga.banana.utils")
---@module "banana.instance"

---@param projectId number
---@param epicId number
local function fillStoriesList(document, storyCont, stories, body, epicId, projectId)
    storyCont:removeChildren()
    table.sort(stories, function(l, r)
        return (r.epic_order or r.ref or 0) > (l.epic_order or l.ref or 0)
    end)
    for _, k in ipairs(stories) do
        local el = document:createElement("StoryName")
        el:setAttribute("storyName", k.subject)
        el:setAttribute("ref", k.ref)
        el:attachRemap("n", "<CR>", { "line-hover" }, function()
            document:loadNmlTo("taiga/story?id=" .. k.id .. "&epicId=" .. epicId .. "&projectId=" .. projectId, body,
                true, false)
        end, {})


        el:attachRemap("n", "dd", { "line-hover" }, function()
            print("Deleting " .. k.ref)
            require("taiga.api.stories").delete(function()
                require("taiga.api.stories").list(function(s)
                    fillStoriesList(document, storyCont, s, body, epicId, projectId)
                end, { cache = false }, { epic = epicId, project = projectId })
            end, {}, {
                project = projectId,
                epicId = epicId,
                id = k.id,
            })
        end, {})
        storyCont:appendChild(el)
    end
end
---@param document Banana.Instance
return function(document)
    document:setTitle("epic")
    local body = document:getScriptParams().selfNode:parent()
    local params = document:getScriptParams().params
    local epicId = tonumber(params.id) or error("epicId is invalid number")
    local projectId = tonumber(params.projectId) or error("projectId is invalid number")
    local container = document:getElementById("container")
    local storyCont = document:getElementById("stories")
    local colorBlock = document:getElementById("color")
    local versionTable = { version = nil }

    local statusCont = document:getElementById('status')
    local status = document:createElement("Status")
    status:setData('projectId', projectId)
    status:setData('type', "epic")
    status:setData("id", epicId)
    status:setData('editCallback', function(v)
        require("taiga.api.epics").edit(function(e)
            versionTable.version = e.version
        end, {}, {
            project = projectId,
            id = epicId,
            data = {
                version = versionTable.version,
                status = v.id
            }
        })
    end)
    statusCont:appendChild(status)

    document
        :getElementById("project")
        :attachRemap("n", "H", {}, function()
            document:loadNmlTo(
                "taiga/project?id=" .. projectId, body, true, false)
        end, {})

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


    require("taiga.api.stories").list(function(stories)
        fillStoriesList(document, storyCont, stories, body, epicId, projectId)
    end, {}, { project = projectId, epic = epicId })
    storyCont:attachRemap("n", "+", {}, function()
        local name = vim.fn.input("New name: ")
        require("taiga.api.stories").create(function(story)
            local query = {
                epic = tonumber(epicId) or 0,
                data = {
                    epic = tonumber(epicId) or 0,
                    user_story = story.id,
                },
            }
            require("taiga.api.epic.relatedUserstories").create(function(_)
                require("taiga.api.stories").list(function(stories)
                    fillStoriesList(document, storyCont, stories, body, epicId, projectId)
                end, { cache = false }, { project = projectId, epic = epicId })
            end, {}, query)
        end, {}, {
            projectId = projectId,
            epicId = epicId,
            data = {
                project = projectId,
                subject = name,
            },
        })
    end, {})


    require("taiga.api.epics").get(function(epic)
        utils.epicTitle(document, document:getElementById("epicName"), colorBlock, body,
            epic, epicId, projectId, versionTable)

        versionTable.version = epic.version
        local el = document:createElement("TextBlock")
        el:setAttribute("content", epic.description)
        el:setData("callback", function(str)
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
                    description = str,
                    version = versionTable.version,
                },
            })
        end)
        local epicDesc = document:getElementById('epicDesc')
        epicDesc:removeChildren()
        epicDesc:appendChild(el)
    end, {}, { id = epicId })
end
