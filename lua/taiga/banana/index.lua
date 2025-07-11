---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local body = document:getElementsByTagName("body")[1]
    document:loadNmlTo("taiga/main", body, true, true)
end
