---@module "banana.instance"

local hasCb = false

local requestCount = 0

---@param document Banana.Instance
return function(document)
    local body = document:getElementById("body")
    document:loadNmlTo("taiga/main", body, true, false)
    document:body():attachRemap("n", "<C-r>", {}, function()
        document:loadNmlTo("taiga/main", body, true, false)
    end, {})
    if not hasCb then
        require("taiga.utils.cache").attachRequestCallback(function()
            requestCount = requestCount + 1
            local el = document:getElementById("requests")
            if not el:isNil() then
                el:setTextContent("Requests: " .. requestCount .. "")
            end
        end)
    end
    document:getElementById("requests"):setTextContent("Requests: " .. requestCount .. "")
    document:body():attachRemap("n", "R", {}, function()
        local ref = vim.v.count
        if ref == 0 then
            return
        end
        document:loadNmlTo(
            "taiga/ref?ref=" .. ref, body, true, false
        )
    end)
end
