vim.cmd([[
syntax off
filetype off
set noundofile
set noswapfile
]])

vim.g.is_code = false

local plugins = require("plugins") -- A list of tables - each representing a plugin
-- Remove all tables that have a field "brenoprata10/nvim-highlight-colors" or "hrsh7th/nvim-cmp" in them
for i = #plugins, 1, -1 do
    if plugins[i][1] == "brenoprata10/nvim-highlight-colors" or plugins[i][1] == "nvim-treesitter/nvim-treesitter" or plugins[i][1] == "mbbill/undotree" or plugins[i][1] == "mistricky/codesnap.nvim" or plugins[i][1] == "hrsh7th/cmp-buffer" then
        table.remove(plugins, i)
    end
end

require("lazy").setup(plugins, {
    ui = {
        border = "rounded",
    },
})

require("main")

SOURCES = {
    { name = "path" },
}
