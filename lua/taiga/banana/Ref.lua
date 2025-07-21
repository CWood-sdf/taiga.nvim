---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local root = document:getElementById("cont")
    local ref = root:getAttributeSubstitution("ref")
    root:attachRemap("n", "gd", { "hover" }, function()
        vim.cmd("TaigaUi " .. ref)
    end, {})
end
