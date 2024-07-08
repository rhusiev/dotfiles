-- Undotree set width on create
vim.cmd([[
  augroup undotree
    autocmd!
    autocmd FileType undotree vertical resize 35
  augroup END
]])
