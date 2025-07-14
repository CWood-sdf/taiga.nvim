---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local root = document:getPrimaryNode()
    local projectId = tonumber(root:getData("projectId")) or error("projectId not passed to <SelectPerson>")
    local callback = root:getData("callback") or error("callback not passed to <SelectPerson>")
    local cont = document:getElementById("cont")

    require("taiga.api.projects").get(function(v)
        cont:removeChildren()
        for i, member in ipairs(v.members) do
            local li = document:createElement("li")
            li:setTextContent(member.full_name)
            li:attachRemap("n", "<CR>", { i, "line-hover" }, function()
                callback(member)
            end, {})
            cont:appendChild(li)
        end
    end, {}, {
        id = projectId
    })
    cont:attachRemap("n", "X", { "line-hover" }, function()
        callback(nil)
    end, {})
end
