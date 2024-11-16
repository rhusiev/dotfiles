vim.g.codeium_disable_bindings = 1
vim.g.is_code = true
vim.g.jupyter_venv = os.getenv("HOME") .. "/.local/share/venvs/jupyter_venv"

-- In venvs still see system packages
vim.g.python_host_prog = "/usr/bin/python3"
vim.g.python3_host_prog = "/usr/bin/python3"

local plugins = require("plugins")
for _, plugin in ipairs(require("plugins_code")) do
	table.insert(plugins, plugin)
end
for _, plugin in ipairs(require("plugins_jupyter")) do
	table.insert(plugins, plugin)
end
require("lazy").setup(plugins, {
	ui = {
		border = "rounded",
	},
})

SOURCES = {
	-- { name = 'vsnip' }, -- For vsnip users.
	{ name = "luasnip", priority = 500 }, -- For luasnip users.
    { name = "jupynium", priority = 400 },
	-- { name = "ultisnips" }, -- For ultisnips users.
	-- { name = 'snippy' }, -- For snippy users.
	{ name = "nvim_lsp", priority = 300 },
	{ name = "buffer", priority = 200 },
	{ name = "path", priority = 100 },
}

require("main")
-- treesitter (here, because highlights don't load for some reason)
-- require("theme.treesitter")
-- require("cmp_config")

-- lspconfig (here, because not all functionality works for some reason)
-- require("lspconfig_config")

-- Disable latex plugins
vim.g.loaded_table_mode = 1
vim.g["pandoc#filetypes#pandoc_markdown"] = 0

require("keybindings.jupyter")

local ls = require("luasnip")
local snippet = ls.snippet
-- local text = ls.text_node
local insert = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("all", {
	snippet(
		{
			trig = "md",
			name = "md_section",
            wordTrig = false,
		},
		fmt(
			[[
# %% [md]
"""
<>
"""
]],
			{ insert(1) },
			{ delimiters = "<>" }
		)
	),
	snippet(
		{
			trig = "py",
			name = "py_section",
			wordTrig = false,
		},
		fmt(
			[[
# %%
<>
]],
			{ insert(1) },
			{ delimiters = "<>" }
		)
	),
})
