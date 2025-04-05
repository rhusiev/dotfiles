local plugins = {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-treesitter",
		},
	},
	{
		"oflisback/obsidian-bridge.nvim",
		config = function()
			require("obsidian-bridge").setup({
                scroll_sync = true,
            })
		end,
		event = {
			"BufReadPre *.md",
			"BufNewFile *.md",
		},
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"vim-pandoc/vim-pandoc",
		lazy = true,
	},
	{
		"vim-pandoc/vim-pandoc-syntax",
		dependencies = { "vim-pandoc/vim-pandoc" },
		config = function()
			-- Disable conceal and folding
			vim.g["pandoc#syntax#conceal#use"] = 0
			vim.g["pandoc#modules#disabled"] = { "folding" }
			-- cmd on bufreadpost
			vim.cmd("autocmd BufReadPost *.md PandocHighlight b")
		end,
	},
	{
		"frabjous/knap",
		lazy = true,
	},

	-- Tables
	{
		"dhruvasagar/vim-table-mode",
	},
}

return plugins
