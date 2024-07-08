-- vim.g.copilot_proxy = 'http://localhost:11435'
-- vim.g.copilot_proxy_strict_ssl = false

require("copilot").setup({
	panel = {
		auto_refresh = false,
		keymap = {
			accept = "<CR>",
			refresh = "gr",
			open = "<M-CR>",
		},
		layout = {
			position = "bottom", -- | top | left | right
			ratio = 0.3,
		},
	},
	suggestion = {
		enabled = true,
		auto_trigger = true,
		debounce = 75,
		keymap = {
			accept = "<C-l>",
			accept_word = "<C-j>",
			accept_line = "<C-k>",
			next = "<M-]>",
			prev = "<M-[>",
			dismiss = "<C-]>",
		},
	},
	filetypes = {
		yaml = true,
		markdown = true,
		help = true,
		gitcommit = true,
		gitrebase = true,
		hgcommit = true,
		svn = true,
		cvs = true,
		["."] = true,
	},
})
