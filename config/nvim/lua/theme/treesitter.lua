require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	incremental_selection = {
		enable = true,
		keymaps = {
			-- use leader-m to init selection
			node_incremental = "<Leader>m",
			node_decremental = "<Leader>l",
			init_selection = "gnn", -- set to `false` to disable one of the mappings
			scope_incremental = "grc",
		},
	},
	textobjects = {
		select = {
			enable = true,

			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,

			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
				["il"] = "@loop.inner",
				["al"] = "@loop.outer",
				["ii"] = "@conditional.inner",
				["ai"] = "@conditional.outer",
                ["it"] = "@comment.outer",
                ["at"] = "@comment.outer",
                ["ia"] = "@parameter.inner",
                ["aa"] = "@parameter.outer",
			},
			selection_modes = {
				["@parameter.outer"] = "v", -- charwise
				["@function.outer"] = "V", -- linewise
				["@class.outer"] = "<c-v>", -- blockwise
			},
			include_surrounding_whitespace = false,
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]["] = { query = "@class.outer", desc = "Next class start" },
				["]l"] = "@loop.*",
                ["]t"] = "@comment.outer",
                ["]a"] = "@parameter.inner",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]]"] = "@class.outer",
				["]L"] = "@loop.*",
                ["]T"] = "@comment.outer",
                ["]A"] = "@parameter.inner",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
				["[l"] = "@loop.*",
                ["[t"] = "@comment.outer",
                ["[a"] = "@parameter.inner",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
				["[L"] = "@loop.*",
                ["[T"] = "@comment.outer",
                ["[A"] = "@parameter.inner",
			},
		},
	},
	refactor = {
		highlight_definitions = { enable = false },
		highlight_current_scope = { enable = false },
	},
})

-- Treesitter highlights
-- For treesitter-context to ColorColumn highlight
vim.cmd("hi link TreesitterContext ColorColumn")

vim.g.indentLine_concealcursor = "c"
