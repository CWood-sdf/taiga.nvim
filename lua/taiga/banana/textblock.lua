---@module "banana.instance"

---@param document Banana.Instance
---@param root Banana.Ast
---@param content string
---@param prefix string
---@param postfix string
local function setContent(document, root, content, prefix, postfix)
    local nml = prefix .. content .. postfix
    local arr = vim.split(nml, "\n")
    root:removeChildren()
    for _, v in ipairs(arr) do
        local el = document:createElement("div")
        if v == "" then
            el:setTextContent(" ")
        else
            el:setTextContent(v)
        end
        root:appendChild(el)
    end
end

---@param document Banana.Instance
return function(document)
    local root = document:getElementById("cont")
    local content = root:getAttributeSubstitution("content") or
        error("'content' attribute must be provided to <TextBlock>")
    local callback = root:getData("callback") or error("'callback' data must be provided to <TextBlock>")

    local prefix = root:getAttributeSubstitution("prefix") or ""
    local postfix = root:getAttributeSubstitution("postfix") or ""

    setContent(document, root, content, prefix, postfix)

    root:attachRemap("n", "i", { "line-hover" }, function()
        local file = vim.fn.tempname()
        local buf = vim.api.nvim_create_buf(false, true)
        require("taiga.blink").whitelist(buf)
        vim.api.nvim_buf_set_name(buf, file)
        vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
        vim.bo[buf].buftype = ""
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
        local win = vim.api.nvim_open_win(buf, true, {
            relative = "win",
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.7),
            border = "rounded",
            row = 2,
            col = 2,
        })
        vim.wo[win].winhighlight = "Normal:Normal"
        vim.cmd.w()

        vim.api.nvim_create_autocmd("BufWrite", {
            callback = function()
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                local str = vim.iter(lines):join("\n")
                callback(str)
                setContent(document, root, str, prefix, postfix)
                content = str
            end,
            buffer = buf,
        })
    end, {})
end
