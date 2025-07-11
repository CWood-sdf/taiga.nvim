local taigaUi = nil
vim.api.nvim_create_user_command("TaigaUi", function()
    taigaUi = taigaUi or require("banana.instance").newInstance("taiga", "taiga")
    taigaUi.DEBUG_catch = false
    taigaUi:open()
end, {})

vim.api.nvim_set_hl(0, "@lang.yuhh", {
    link = "Comment",
})

vim.api.nvim_set_hl(0, "@header.yuhh", {
    link = "Comment",
})
