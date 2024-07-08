vim.g.color_dark4 = "#e0dcc7"
vim.g.color_dark3 = "#efebd4"
vim.g.color_dark2 = "#fdf6e3"

vim.g.color_white2 = "#5c6a72"
vim.g.color_white1 = "#829181"

vim.g.color_blue4 = "#dfa000"
vim.g.color_blue3 = "#3a94c5"
vim.g.color_blue2 = "#35a77c"

vim.g.color_red1 = "#f85552"
vim.g.color_yellow1 = "#dfa000"
vim.g.color_green1 = "#93b259"
vim.g.color_pink1 = "#df69ba"

-- Remove diagnostics bg highlights for virtual text, set colors for text
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextError guibg=NONE guifg=" .. vim.g.color_red1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextWarn guibg=NONE guifg=" .. vim.g.color_yellow1
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextHint guibg=NONE guifg=" .. vim.g.color_white2
)
vim.cmd(
    "autocmd ColorScheme * highlight! DiagnosticVirtualTextInfo guibg=NONE guifg=" .. vim.g.color_blue2
)

-- require("everforest").load()
vim.g.everforest_enable_italic = true
vim.opt.background = "light"
vim.g.everforest_background = "medium"
vim.g.everforest_better_performance = 1
vim.g.everforest_show_eob = 0
vim.g.everforest_float_style = "dim"
vim.g.everforest_colors_override = {
	bg_dim = {vim.g.color_dark2, "0"},
	bg_visual = {vim.g.color_dark4, "0"},
}

vim.cmd.colorscheme("everforest")

vim.g.terminal_color_0 = "#e6e2cc"
vim.g.terminal_color_7 = "#d8cacc"
vim.g.terminal_color_8 = "#939f91"
vim.g.terminal_color_15 = "#d8cacc"
