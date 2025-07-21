---@module 'cmdTree'
local ct = require("cmdTree")

local taigaUi = nil

ct.createCmd({
    TaigaUi = {
        _callback = function(args)
            local exists = taigaUi == nil
            taigaUi = taigaUi or require("banana.instance").newInstance("taiga", "taiga")
            -- taigaUi.DEBUG = true
            -- taigaUi.DEBUG_showPerf = true
            -- taigaUi.DEBUG_catch = false
            taigaUi:open()
            if #args.params >= 1 then
                local fn = function()
                    local body = taigaUi:getElementById("body")
                    taigaUi:loadNmlTo("taiga/ref?ref=" .. args.params[1][1], body, true, false)
                end
                if exists then
                    fn()
                else
                    vim.defer_fn(fn, 30)
                end
            end
        end,
        ct.positionalParam("ref", false),
    },
})

vim.api.nvim_set_hl(0, "@lang.yuhh", {
    link = "Comment",
})

vim.api.nvim_set_hl(0, "@header.yuhh", {
    link = "Comment",
})
