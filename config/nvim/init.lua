vim.g.codeium_disable_bindings = 1
vim.g.is_code = false

local plugins = {}
for _, plugin in ipairs(require("plugins")) do
    if not (vim.g.vscode and vim.tbl_contains(plugin, "Exafunction/codeium.vim")) then
        table.insert(plugins, plugin)
    end
end
require("lazy").setup(plugins, {
    ui = {
        border = "rounded",
    },
})

require("main")
SOURCES = {
	-- { name = 'vsnip' }, -- For vsnip users.
	{ name = 'luasnip' }, -- For luasnip users.
	-- { name = "ultisnips" }, -- For ultisnips users.
	-- { name = 'snippy' }, -- For snippy users.
	{ name = "buffer" },
    { name = "path" },
}
