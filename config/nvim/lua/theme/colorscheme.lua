vim.g.theme = "everforest"
local everforest_background = "dark"

-- Highlight what has just been yoinked
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight what has just been yoinked",
    group = vim.api.nvim_create_augroup("highlight_yoink", {clear = true}),
    callback = function()
        vim.highlight.on_yank({higroup = "Search", timeout = 200})
    end,
})

if vim.g.theme == "everforest" then
    if everforest_background == "dark" then
        require("theme.everforest")
    else
        require("theme.everforest_light")
    end
elseif vim.g.theme == "nord" then
	require("theme.nord")
elseif vim.g.theme == "catppuccin" then
	require("theme.catppuccin")
end

vim.defer_fn(function()
    require("theme.diagnostics_theme")
end, 0)
