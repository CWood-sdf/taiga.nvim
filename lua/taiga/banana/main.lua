---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local container = document:getElementById("container")
    local body = document:getScriptParams().selfNode:parent()
    local projectsContainer = document:getElementById("projectscontainer")
    require("taiga.api.auth").getCredentials(function(v)
        container:setAttribute("username", v.full_name)
        require("taiga.api.projects").list(function(projects)
            for i, proj in ipairs(projects) do
                local el = document:createElement("ProjectName")
                el:setAttribute("projectName", proj.name)
                el:setAttribute("index", i .. "")
                el:attachRemap("n", "<CR>", { "line-hover" }, function()
                    print('urmom')
                    document:loadNmlTo(
                        "taiga/project?id=" .. proj.id, body, true, false
                    )
                end, {})
                projectsContainer:appendChild(el)
            end
        end, {}, {})
    end, {}, nil)
end
