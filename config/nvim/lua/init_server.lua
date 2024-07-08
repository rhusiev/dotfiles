local plugins = {
	{
		"L3MON4D3/LuaSnip",
		lazy = true,
		version = "v2.*",
		build = "make install_jsregexp",
		config = function()
			require("lua_snip_config")
		end,
		dependencies = {
			{
				"nvim-cmp",
				lazy = true,
				dependencies = {
					"saadparwaiz1/cmp_luasnip",
				},
			},
		},
	},
	{
		"numToStr/Comment.nvim",
		lazy = false,
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"smoka7/hop.nvim",
		lazy = true,
		version = "v2",
		config = function()
			require("hop").setup({
				jump_on_sole_occurrence = false, -- Don't autojump when only 1 occurence
				keys = "1234567890",
			})
			require("theme.hop_highlights")
		end,
	},
}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(plugins)

require("sets")
require("keybindings.keybindings")

-- Add ~/.local/bin to PATH
vim.cmd('let $PATH .= ":" . $HOME . "/.local/bin"')
-- Disable concealing quotes in json
vim.g.vim_json_conceal = 0

-- Disable latex plugins
vim.g.loaded_table_mode = 1
vim.g["pandoc#filetypes#pandoc_markdown"] = 0
