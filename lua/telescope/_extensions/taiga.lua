local telescope = require("telescope")

return telescope.register_extension({
    exports = {
        refs = require("telescope._extensions.taiga_refs"),
    },
})
