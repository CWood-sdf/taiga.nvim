local M = {}

---@class (exact) Taiga.Ref
---@field id number
---@field tp "epic"|"story"|"task"
---@field ref number
---@field name string

---@type { [string]: Taiga.Ref }
local refdb = nil

local saveDir = vim.fn.stdpath("data") .. "/taiga/"

vim.defer_fn(vim.schedule_wrap(function()
    vim.fn.mkdir(saveDir, "p")
end), 10)

local saveFile = saveDir .. "refdb.json"

local function createRefdb()
    if refdb ~= nil then
        return
    end

    local f = io.open(saveFile, "r")
    if f == nil then
        refdb = {}
        return
    end

    local contents = f:read("*a")
    refdb = vim.json.decode(contents, { luanil = { object = true, array = true } })

    f:close()
end

local function saveRefDb()
    createRefdb()

    local f = io.open(saveFile, "w")

    if f == nil then
        print("Couldnt create refdb file")
        return
    end

    f:write(vim.json.encode(refdb))

    f:close()
end

---@param ref Taiga.Ref
function M.addRef(ref)
    createRefdb()
    refdb[ref.id .. ""] = ref
    saveRefDb()
end

---@param refid number
function M.deleteRef(refid)
    createRefdb()
    refdb[refid .. ""] = nil
    saveRefDb()
end

---@param ref number
---@return Taiga.Ref?
function M.findRefByRefNo(ref)
    createRefdb()
    for _, v in pairs(refdb) do
        if v.ref == ref then
            return v
        end
    end
    return nil
end

---@param refid number
---@return Taiga.Ref?
function M.getRef(refid)
    createRefdb()
    return refdb[refid .. ""]
end

---@return Taiga.Ref[]
function M.getRefArr()
    createRefdb()
    local ret = {}
    for _, v in pairs(refdb) do
        table.insert(ret, v)
    end
    return ret
end

---@return string[]
function M.getRefNameStrings()
    createRefdb()
    local ret = {}
    for _, ref in pairs(refdb) do
        table.insert(ret, M.getNameStringFor(ref))
    end
    return ret
end

---@param ref Taiga.Ref
---@return string
function M.getNameStringFor(ref)
    return "(#" .. ref.ref .. ") " .. ref.name
end

---@param str string
---@return Taiga.Ref?
function M.getRefByNameString(str)
    createRefdb()
    for _, ref in pairs(refdb) do
        local name = M.getNameStringFor(ref)
        if name == str then
            return ref
        end
    end
    return nil
end

return M
