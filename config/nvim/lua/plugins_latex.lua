local plugins = {
    {
        "epwalsh/obsidian.nvim",
        version = "*",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter",
        },
    },
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
            vim.g["pandoc#modules#disabled"] = { "folding" }
            -- cmd on bufreadpost
            vim.cmd("autocmd BufReadPost *.md PandocHighlight b")
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