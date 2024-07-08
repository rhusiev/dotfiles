-- Dark white/gray
vim.cmd(string.format("highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=%s", vim.g.color_white1))
-- Blue
vim.cmd(string.format("highlight! CmpItemAbbrMatch guibg=NONE guifg=%s", vim.g.color_blue3))
-- Light blue
vim.cmd(string.format("highlight! CmpItemKindVariable guibg=NONE guifg=%s", vim.g.color_blue2))
-- Red
vim.cmd(string.format("highlight! CmpItemKindFunction guibg=NONE guifg=%s", vim.g.color_red1))
-- Purple
vim.cmd(string.format("highlight! CmpItemMenu guibg=NONE guifg=%s", vim.g.color_pink1))
