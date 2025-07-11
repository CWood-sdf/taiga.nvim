---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local body = document:getScriptParams().selfNode:parent()
    local params = document:getScriptParams().params
    local projectId = params.id .. ""
    local container = document:getElementById("container")
    local epicCont = document:getElementById("epics")

    require("taiga.api.projects").get(vim.schedule_wrap(function(proj)
        container:setAttribute("projectName", proj.name)
        if proj.description ~= '' then
            container:setAttribute("description", proj.description)
        end
    end), {}, { id = projectId })

    require("taiga.api.epics").list(vim.schedule_wrap(function(epics)
        for _, epic in ipairs(epics) do
            -- if epic.project ~= proj.id then
            --     goto continue
            -- end
            local el = document:createElement("EpicName")
            el:setAttribute("epicName", epic.subject)
            el:setAttribute("color", epic.color)
            el:attachRemap("n", "<CR>", { "line-hover" }, function()
                document:loadNmlTo("taiga/epic?id=" .. epic.id .. "&projectId=" .. projectId, body, true, false)
            end, {})
            epicCont:appendChild(el)
            local div = document:createElement("div")
            div:appendTextNode("[")
            local progress = document:createElement("progress")
            progress:setAttribute("filled-char", "■")
            progress:setAttribute("empty-char", "■")
            if epic.user_stories_counts.total ~= 0 then
                progress:setAttribute("value", epic.user_stories_counts.progress .. "")
                progress:setAttribute("max", epic.user_stories_counts.total .. "")
            end
            div:appendChild(progress)
            div:appendTextNode("]")
            epicCont:appendChild(div)
            -- ::continue::
        end
    end), {}, { project = projectId })
end
