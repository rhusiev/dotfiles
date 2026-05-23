vim.g.codeium_disable_bindings = 1
vim.g.is_code = false

require("main")

local plugins = {}
for _, plugin in ipairs(require("plugins")) do
    table.insert(plugins, plugin)
end
require("lazy").setup(plugins, {
    ui = {
        border = "rounded",
    },
})

SOURCES = {
	-- { name = 'vsnip' }, -- For vsnip users.
	{ name = 'luasnip' }, -- For luasnip users.
	-- { name = "ultisnips" }, -- For ultisnips users.
	-- { name = 'snippy' }, -- For snippy users.
	{ name = "buffer" },
    { name = "path" },
}
