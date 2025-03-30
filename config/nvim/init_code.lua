vim.g.codeium_disable_bindings = 1
vim.g.is_code = true

-- In venvs still see system packages
vim.g.python_host_prog = "/usr/bin/python3"
vim.g.python3_host_prog = "/usr/bin/python3"

local plugins = require("plugins")
for _, plugin in ipairs(require("plugins_code")) do
	table.insert(plugins, plugin)
end
require("lazy").setup(plugins, {
	ui = {
		border = "rounded",
	},
})

SOURCES = {
	{ name = "jupynium", priority = 1000 },
	{ name = "luasnip", priority = 400 }, -- For luasnip users.
	{ name = "nvim_lsp", priority = 300 },
	{ name = "buffer", priority = 200 },
	{ name = "path", priority = 100 },
	{
		name = "lazydev",
		group_index = 0, -- set group index to 0 to skip loading LuaLS completions
	},
}

require("main")

-- Disable latex plugins
vim.g.loaded_table_mode = 1
vim.g["pandoc#filetypes#pandoc_markdown"] = 0
