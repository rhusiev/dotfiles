local plugins = {
	-- Git
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim", -- required
			"sindrets/diffview.nvim", -- optional - Diff integration
		},
		cmd = "Neogit",
		config = true,
	},

	-- Debug
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		config = function()
			require("debugger_config")
		end,
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				lazy = true,
				dependencies = {
					{
						"nvim-neotest/nvim-nio",
						lazy = true,
					},
				},
			},
			-- Show some info like errors or in-between results in virtual text
			{
				"theHamsta/nvim-dap-virtual-text",
				lazy = true,
			},
			-- Autoconfigure installed by mason debuggers
			{
				"jay-babu/mason-nvim-dap.nvim",
				lazy = true,
				dependencies = "mason.nvim",
			},
			-- Suggestions in debugger
			{
				"rcarriga/cmp-dap",
				lazy = true,
			},
		},
	},

	-- Hide secrets (like api keys)
	{
		"laytan/cloak.nvim",
		config = function()
			require("cloak").setup()
		end,
	},

	-- Cmp, code specific
	-- LSP suggestions
	{
		"hrsh7th/cmp-nvim-lsp",
		lazy = true,
		dependencies = {
			-- for vim.* completions in lua etc
			{
				"folke/lazydev.nvim",
				ft = "lua", -- only load on lua files
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
		},
	},
	-- Show tailwind colors in cmp
	{
		"roobert/tailwindcss-colorizer-cmp.nvim",
		lazy = true,
		ft = {
			"html",
			"css",
			"scss",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"svelte",
			"vue",
		},
	},

	-- Configurations for Nvim LSP
	{
		"neovim/nvim-lspconfig", -- LSP itself
		event = { "BufReadPre", "BufNewFile" },
		-- lazy = true,
		dependencies = {
			"mason.nvim",
		},
		config = function()
			require("lspconfig_config")
			require("keybindings.lsp")
		end,
	},

	-- conform for formatting, nvim-lint for linting
	{
		"stevearc/conform.nvim",
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				require("formatting")
			end, 0)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				require("linting")
			end, 0)
		end,
	},
}

return plugins
