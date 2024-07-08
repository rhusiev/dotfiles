vim.g.color_dark4 = "#45475a"
vim.g.color_dark2 = "#313244"
vim.g.color_dark1 = "#1e1e2e"

vim.g.color_white2 = "#cdd6f4"
vim.g.color_white1 = "#bac2de"

vim.g.color_blue4 = "#6c7086"
vim.g.color_blue3 = "#74c7ec"
vim.g.color_blue2 = "#89b4fa"

vim.g.color_red1 = "#f38ba8"
vim.g.color_yellow1 = "#fab387"
vim.g.color_green1 = "#a6e3a1"
vim.g.color_pink1 = "#eba0ac"

-- Remove diagnostics bg highlights for virtual text, set colors for text
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextError guibg=NONE guifg=" .. vim.g.color_red1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextWarn guibg=NONE guifg=" .. vim.g.color_yellow1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextHint guibg=NONE guifg=" .. vim.g.color_blue3
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextInfo guibg=NONE guifg=" .. vim.g.color_white2
)

require("catppuccin").setup({
	flavour = "mocha", -- latte, frappe, macchiato, mocha
	background = { -- :h background
		light = "latte",
		dark = "mocha",
	},
	transparent_background = false, -- disables setting the background color.
	show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
	term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
	dim_inactive = {
		enabled = false, -- dims the background color of inactive window
		shade = "dark",
		percentage = 0.15, -- percentage of the shade to apply to the inactive window
	},
	no_italic = false, -- Force no italic
	no_bold = false, -- Force no bold
	no_underline = false, -- Force no underline
	styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
		comments = { "italic" }, -- Change the style of comments
		conditionals = { "italic" },
		loops = {},
		functions = {},
		keywords = {},
		strings = {},
		variables = {},
		numbers = {},
		booleans = {},
		properties = {},
		types = {},
		operators = {},
	},
	color_overrides = {},
	custom_highlights = {},
	integrations = {
		cmp = true,
		gitsigns = true,
		nvimtree = true,
		treesitter = true,
		notify = false,
		mini = {
			enabled = true,
			indentscope_color = "",
		},
		-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
	},
})

vim.g.color_dark4 = "#45475a"

-- setup must be called before loading
vim.cmd.colorscheme("catppuccin")
