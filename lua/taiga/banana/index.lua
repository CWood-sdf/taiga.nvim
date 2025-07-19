---@module "banana.instance"

local hasCb = false


---@param document Banana.Instance
return function(document)
    local body = document:getElementById("body")
    document:loadNmlTo("taiga/main", body, true, false)
    document:body():attachRemap("n", "<C-r>", {}, function()
        document:loadNmlTo("taiga/main", body, true, false)
    end, {})
    if not hasCb then
        local requestCount = 0
        require("taiga.utils.cache").attachRequestCallback(function()
            requestCount = requestCount + 1
            document:getElementById("requests"):setTextContent("Requests: " .. requestCount .. "")
        end)
    end
end
