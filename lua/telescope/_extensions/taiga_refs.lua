local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

---@type Banana.Instance?
local ui = nil

local previewer = previewers.Previewer:new({
    preview_fn = function(_, entry, status)
        if ui == nil then
            print("no ui :(")
            return
        end
        ui:useBuffer(status.preview_bufnr)
        ui:useWindow(status.preview_win)

        ui:open()
        ui:loadNmlTo("taiga/ref?ref=" .. entry.value.ref, ui:getElementById("body"), true, false)
        ui:_requestRender()
    end,
    title = function()
        return "Select Ref"
    end,
    keep_last_buf = true,
    setup = function()
        if ui == nil then
            ui = require("banana.instance").newInstance("taiga", "")
        end
    end,
    teardown = function()
        if ui == nil then return end
        ui:close()
    end,
})


return function(opts)
    -- opts = opts or require("telescope.themes").get_ivy({})
    pickers
        .new(opts, {
            previewer = previewer,
            prompt_title = "Taiga Refs",
            finder = finders.new_table({
                results = require("taiga.api.refdb").getRefArr(),

                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = require("taiga.api.refdb")
                            .getNameStringFor(entry),
                        ordinal = require("taiga.api.refdb")
                            .getNameStringFor(entry),
                    }
                end,
            }),
            sorter = conf.generic_sorter(opts),
            ---@diagnostic disable-next-line: unused-local
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    vim.cmd("TaigaUi " .. selection.value.ref)
                end)
                return true
            end,
        })
        :find()
end
