---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local container = document:getElementById("container")
    local body = container:parent()
    local refid = document:getScriptParams().params.ref
    container:setAttribute("refid", refid)
    local ref = require("taiga.api.refdb").findRefByRefNo(tonumber(refid) or 0)
    container:attachRemap("n", "H", {}, function()
        document:loadNmlTo("taiga/main", body, true, false)
    end, {})
    if ref == nil then
        container:setTextContent("NO REF FOUND FOR " .. refid)
        return
    end
    local invalid = false
    document:on("NmlLoaded", {
        callback = function()
            invalid = true
        end
    })
    require("taiga.api.projects").list(function(projects)
        local projid = projects[1].id
        if invalid then return end

        if ref.tp == "epic" then
            document:loadNmlTo("taiga/epic?id=" .. ref.id .. "&projectId=" .. projid, body, true, false)
        elseif ref.tp == "story" then
            require("taiga.api.stories").get(function(v)
                if invalid then return end
                document:loadNmlTo("taiga/story?id=" .. ref.id .. "&epicId=" .. v.epics[1].id .. "&projectId=" .. projid,
                    body, true, false)
            end, {}, {
                id = ref.id
            })
        elseif ref.tp == "task" then
            require("taiga.api.tasks").get(function(v)
                if invalid then return end
                document:loadNmlTo(
                    "taiga/task?id=" ..
                    ref.id ..
                    "&storyId=" ..
                    v.user_story .. "&epicId=" .. v.user_story_extra_info.epics[1].id .. "&projectId=" .. projid,
                    body, true, false)
            end, {}, {
                id = ref.id
            })
        else
            error("Unknown reftype " .. ref.tp)
        end
    end, {}, {})
end
