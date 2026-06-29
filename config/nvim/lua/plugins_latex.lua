local plugins = {
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		init = function()
			vim.g.mkdp_auto_start = 1
			vim.g.mkdp_auto_close = 0
			vim.g.mkdp_browser = "chromium-browser"
			vim.g.mkdp_combine_preview = 1
		end,
		config = function()
			vim.g.mkdp_preview_options = {
				mkit = {
					breaks = true,
				},
				uml = {},
				maid = {},
				disable_sync_scroll = 0,
				sync_scroll_type = "middle",
				hide_yaml_meta = 1,
				sequence_diagrams = {},
				flowchart_diagrams = {},
				content_editable = false,
				disable_filename = 1,
				katex = {
					globalGroup = true, -- Compiles macros globally to persist across independent math blocks
					macros = {
						["\\Ud"] = "\\overset{\\circ}{\\mathcal{U}}_{\\delta}",
						["\\U"] = "\\mathcal{U}",
						["\\Uo"] = "\\overset{\\circ}{\\mathcal{U}}",
						["\\R"] = "\\mathbb{R}",
						["\\N"] = "\\mathbb{N}",
						["\\Z"] = "\\mathbb{Z}",
						["\\Q"] = "\\mathbb{Q}",
						["\\cm"] = "\\overset{\\ \\ \\overset{\\rlap{\\text{#1}}}{/}}{#2}",
						["\\cmu"] = "\\underset{\\underset{\\rlap{\\text{#1}}}{/}}{#2}",
						["\\cmm"] = "\\overset{\\ \\ \\ \\ \\overset{\\rlap{#1}}{/}}{#2}",
						["\\cmmu"] = "\\underset{\\underset{\\rlap{#1}}{/}}{#2}",
						["\\eqdef"] = "\\overset{\\text{def}}{=}",
						["\\mlim"] = "\\lim_{\\substack{#1}}",
						["\\grad"] = "\\overrightarrow{\\mathrm{grad}}\\ ",
						["\\pd"] = "\\partial",
						["\\("] = "\\left(",
						["\\)"] = "\\right)",
						["\\["] = "\\left[",
						["\\]"] = "\\right]",
						["\\|"] = "\\bigg|",
						["\\r"] = "\\right",
						["\\l"] = "\\left",
						["\\vect"] = "\\begin{pmatrix}#1\\end{pmatrix}",
						["\\bcase"] = "\\left[\\array{#1}\\right.",
						["\\."] = "\\hspace{0px}",
					},
				},
			}
		end,
	},
	-- {
	-- 	"epwalsh/obsidian.nvim",
	-- 	version = "*",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"hrsh7th/nvim-cmp",
	-- 		"nvim-treesitter",
	-- 	},
	-- },
	-- {
	-- 	"oflisback/obsidian-bridge.nvim",
	-- 	config = function()
	-- 		require("obsidian-bridge").setup({
	-- 			scroll_sync = true,
	-- 		})
	-- 	end,
	-- 	event = {
	-- 		"BufReadPre *.md",
	-- 		"BufNewFile *.md",
	-- 	},
	-- 	lazy = true,
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 	},
	-- },
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
			vim.g["pandoc#modules#disabled"] = { "folding", "keyboard" }
			vim.g["pandoc#hypertext#use_default_mappings"] = 0
			-- cmd on bufreadpost
			-- vim.cmd("autocmd BufReadPost *.md PandocHighlight b")
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
