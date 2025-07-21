---@module "banana.instance"

local function startsWithDigit(str)
    local split = vim.split(str, "%d", { plain = false })
    if #split > 1 and #split[1] == 0 then
        return true
    end
    return false
end


---@param document Banana.Instance
---@param root Banana.Ast
---@param content string
local function setContent(document, root, content)
    root:removeChildren()
    local el = document:createElement("span")
    local split = vim.split(content, "#", {
        plain = true
    })
    local currentString = ""
    currentString = split[1]
    for i, v in ipairs(split) do
        if startsWithDigit(v) then
            if currentString ~= "" then
                el:appendTextNode(currentString)
                currentString = ""
            end
            local str = ""
            local rest = v
            repeat
                str = str .. rest:sub(1, 1)
                rest = rest:sub(2, #rest)
            until not startsWithDigit(rest)
            local e = document:createElement("Ref")
            e:setAttribute("ref", str)
            el:appendChild(e)

            currentString = rest
        elseif i ~= 1 then
            currentString = "#" .. v
        end
    end
    if currentString ~= "" then
        el:appendTextNode(currentString)
        currentString = ""
    end
    root:appendChild(el)
end

---@param document Banana.Instance
return function(document)
    local root = document:getElementById("cont")
    local content = root:getAttributeSubstitution("content") or
        error("'content' attribute must be provided to <TextBlock>")
    local callback = root:getData("callback") or error("'callback' data must be provided to <TextBlock>")
    local filetype = root:getData("filetype") or "markdown"
    local displayTitle = root:getData("displayTitle") or function(s) return s end

    setContent(document, root, displayTitle(content))

    root:attachRemap("n", "i", { "line-hover" }, function()
        local file = vim.fn.tempname()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, file)
        vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
        vim.bo[buf].buftype = ""
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "New title:", content })
        local win = vim.api.nvim_open_win(buf, true, {
            relative = "win",
            width = math.floor(vim.o.columns * 0.3),
            height = 2,
            border = "rounded",
            row = 2,
            col = 2,
        })
        vim.wo[win].winhighlight = "Normal:Normal"

        vim.api.nvim_win_set_cursor(win, { 2, 0 })
        vim.cmd.w()

        vim.api.nvim_create_autocmd("BufWrite", {
            callback = function()
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                local str = lines[#lines]
                callback(str)
                setContent(document, root, displayTitle(str))
                content = str
            end,
            buffer = buf,
        })
    end, {})
end
