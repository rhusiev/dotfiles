vim.g.color_dark4 = "#4f585e"
vim.g.color_dark3 = "#3d484d"
vim.g.color_dark2 = "#2d353b"

vim.g.color_white2 = "#d3c6aa"
vim.g.color_white1 = "#9da9a0"

vim.g.color_blue4 = "#d699b6"
vim.g.color_blue3 = "#9da9a0"
vim.g.color_blue2 = "#7fbbb3"

vim.g.color_red1 = "#e67e80"
vim.g.color_yellow1 = "#dbbc7f"
vim.g.color_green1 = "#83c092"
vim.g.color_pink1 = "#d699b6"

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
vim.opt.background = "dark"
vim.g.everforest_background = "medium"
vim.g.everforest_better_performance = 1
vim.g.everforest_show_eob = 0
vim.g.everforest_float_style = "dim"
vim.g.everforest_colors_override = {
	bg_dim = {vim.g.color_dark2, "0"},
	bg_visual = {vim.g.color_dark4, "0"},
}

vim.cmd.colorscheme("everforest")

vim.g.terminal_color_0 = "#475258"
vim.g.terminal_color_7 = "#d8cacc"
vim.g.terminal_color_8 = "#859289"
vim.g.terminal_color_15 = "#d8cacc"
