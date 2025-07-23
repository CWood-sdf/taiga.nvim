---@module "banana.instance"

---no
---@param document Banana.Instance
---@param epicCont Banana.Ast
---@param body Banana.Ast
---@param epics table[]
---@param projectId number
local function listEpics(document, epicCont, body, epics, projectId)
    epicCont:removeChildren()
    for _, epic in ipairs(epics) do
        -- if epic.project ~= proj.id then
        --     goto continue
        -- end
        local el = document:createElement("EpicName")
        el:setAttribute("epicName", epic.subject)
        el:setAttribute("color", epic.color)
        el:attachRemap("n", "<CR>", { "line-hover" }, function()
            document:loadNmlTo("taiga/epic?id=" .. epic.id .. "&projectId=" .. projectId, body, true, false)
        end, {})
        epicCont:appendChild(el)
        local div = document:createElement("div")
        div:appendTextNode("[")
        local progress = document:createElement("progress")
        progress:setAttribute("filled-char", "■")
        progress:setAttribute("empty-char", "■")
        if epic.user_stories_counts.total ~= 0 then
            progress:setAttribute("value", epic.user_stories_counts.progress .. "")
            progress:setAttribute("max", epic.user_stories_counts.total .. "")
        end

        div:appendChild(progress)
        div:appendTextNode("]")
        epicCont:appendChild(div)
        -- ::continue::
    end
end

---@param document Banana.Instance
return function(document)
    document:setTitle("project")
    local body = document:getScriptParams().selfNode:parent()
    local params = document:getScriptParams().params
    local projectId = tonumber(params.id) or error("projectId not a valid number")
    local container = document:getElementById("container")
    local epicCont = document:getElementById("epics")

    epicCont:attachRemap("n", "+", {}, function()
        local file = vim.fn.tempname()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, file)
        vim.api.nvim_set_option_value("filetype", "json", { buf = buf })
        vim.bo[buf].buftype = ""
        local obj = {
            description = "",
            is_blocked = false,
            is_closed = false,
            color = "",
            project = projectId,
            subject = "",
            tags = {},
            watchers = {},
        }
        local content = vim.json.encode(obj)
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

        vim.api.nvim_create_autocmd("BufLeave", {
            callback = function()
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                local str = vim.iter(lines):join("\n")
                obj = vim.json.decode(str)
                require("taiga.api.epics").create(function()
                end, {}, {
                    refresh = function(epics)
                        listEpics(document, epicCont, body, epics, projectId)
                    end,
                    projectId = projectId,
                    data = obj,
                })
            end,
            buffer = buf,
        })
    end, {})

    require("taiga.api.projects").get(function(proj)
        container:setAttribute("projectName", proj.name)
        if proj.description ~= '' then
            container:setAttribute("description", proj.description)
        end
    end, {}, { id = projectId })

    require("taiga.api.epics").list(function(epics)
        listEpics(document, epicCont, body, epics, projectId)
    end, {}, { project = projectId })
end
