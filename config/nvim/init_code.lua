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
	-- { name = 'vsnip' }, -- For vsnip users.
	{ name = 'luasnip' }, -- For luasnip users.
	-- { name = "ultisnips" }, -- For ultisnips users.
	-- { name = 'snippy' }, -- For snippy users.
    { name = "nvim_lsp" },
	{ name = "buffer" },
    { name = "path" },
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

-- Copilot and llm.nvim switching
vim.api.nvim_create_user_command("SwitchCopilot", function()
    require("copilot")
    require("CopilotChat")
    vim.cmd(":Copilot enable")
    require("llm.completion").suggestions_enabled = false
end, {})
vim.api.nvim_create_user_command("SwitchLLM", function()
    vim.cmd(":Copilot disable")
    require("llm.completion").suggestions_enabled = true
end, {})
