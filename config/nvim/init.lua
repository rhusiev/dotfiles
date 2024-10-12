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

-- If it's nvim-qt
-- if vim.fn.exists("g:nvim_gui_running") then
-- 	-- Add autocommand to change font
-- 	vim.cmd("autocmd GUIEnter * set guifont=CodeNewRoman\\ Nerd\\ Font Mono:h14")
-- end
