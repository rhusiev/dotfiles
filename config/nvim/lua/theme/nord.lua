vim.g.color_dark4 = "#4c566a"
vim.g.color_dark2 = "#3b4252"
vim.g.color_dark1 = "#2e3440"

vim.g.color_white2 = "#e5e9f0"
vim.g.color_white1 = "#d8dee9"

vim.g.color_blue4 = "#5e81ac"
vim.g.color_blue3 = "#81a1c1"
vim.g.color_blue2 = "#88c0d0"

vim.g.color_red1 = "#bf616a"
vim.g.color_yellow1 = "#ebcb8b"
vim.g.color_green1 = "#a3be8c"
vim.g.color_pink1 = "#b48ead"

-- Remove diagnostics bg highlights for virtual text, set colors for text
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextError guibg=NONE guifg=" .. vim.g.color_red1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextWarn guibg=NONE guifg=" .. vim.g.color_yellow1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextHint guibg=NONE guifg=" .. vim.g.color_blue2
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextInfo guibg=NONE guifg=" .. vim.g.color_blue3
)

require("nord").setup({
	errors = { mode = "none" },
	-- on_highlights = function(highlights, colors)
	on_highlights = function(highlights, _)
		local search_bg = "#4c566a"
		highlights.Search = { bg = search_bg }
		highlights.IncSearch = { bg = search_bg }
		highlights.CurSearch = { bg = search_bg }
	end,
})

vim.cmd.colorscheme("nord")
