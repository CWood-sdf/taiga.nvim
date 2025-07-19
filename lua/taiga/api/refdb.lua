local M = {}

---@class (exact) Taiga.Ref
---@field id number
---@field tp "epic"|"story"|"task"
---@field ref number
---@field name string

---@type { [string]: Taiga.Ref }
local refdb = {}

---@param ref Taiga.Ref
function M.addRef(ref)
    refdb[ref.id .. ""] = ref
end

---@param refid number
---@return Taiga.Ref?
function M.getRef(refid)
    return refdb[refid .. ""]
end

---@return string[]
function M.getRefNameStrings()
    local ret = {}
    for id, ref in pairs(refdb) do
        table.insert(ret, "(#" .. id .. ") " .. ref.name)
    end
    return ret
end

---@param str string
---@return Taiga.Ref?
function M.getRefByNameString(str)
    for id, ref in pairs(refdb) do
        local name = "(#" .. id .. ") " .. ref.name
        if name == str then
            return ref
        end
    end
    return nil
end

return M
