local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	{
        -- "rhusiev/pet.nvim",
		dir = vim.fn.expand("$HOME/Projects/Personal/pet.nvim"),
		config = function()
			require("pet").start_pet_party({
				max_pets = 4,
				spawn_period = 2000,
				step_period = 150,
				wait_period = 1000,
				pet_string = "🐧",
                pet_length = 2,
				repeats = 100,
				min_skip_left = 0,
				min_skip_right = 0,
				min_skip_above = 0,
				min_skip_below = 0,
                stop_moving_probability = 3,
                start_moving_probability = 10,
                debug_marks = false,
			})
		end,
	},
	-- Autocompletion box
	{
		"hrsh7th/nvim-cmp",
		-- lazy = true, -- if set, keybindings don't work for the first completion
		config = function()
			vim.defer_fn(function()
				require("cmp_config")
			end, 0)
		end,
	},
	{
		"hrsh7th/cmp-buffer",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
	},
	{
		"hrsh7th/cmp-path",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
	},
	{
		"hrsh7th/cmp-cmdline",
		event = "CmdlineEnter",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
	},
	-- Snippets
	{
		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		version = "v2.*",
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
		config = function()
			vim.defer_fn(function()
				require("lua_snip_config")
				require("keybindings.luasnip")
			end, 0)
			vim.defer_fn(function()
				require("cmp_luasnip")
			end, 0)
		end,
	},
	{
		"saadparwaiz1/cmp_luasnip",
		lazy = true,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},

	-- Themes
	--[[ {
		"gbprod/nord.nvim",
		-- event = "VeryLazy",
		lazy = false,
        priority = 1000,
		config = function()
			if not vim.g.theme then
				require("theme.colorscheme")
			end
		end,
	}, ]]
	--[[ {
		"catppuccin/nvim",
		name = "catppuccin",
        lazy = true,
		config = function()
			if not vim.g.theme then
				require("theme.colorscheme")
			end
		end,
	}, ]]
	{
		-- "neanias/everforest-nvim",
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		config = function()
			if not vim.g.theme then
				require("theme.colorscheme")
			end
		end,
	},
	-- Make color codes colorized (eg #555 -> grey)
	{
		"brenoprata10/nvim-highlight-colors",
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				require("nvim-highlight-colors").setup({
					enable_named_colors = false,
					enable_tailwind = true,
				})
			end, 0)
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VimEnter",
		config = function()
			require("theme.lualine_config")
		end,
	},
	{
		"nanozuki/tabby.nvim",
		event = "VimEnter",
		config = function()
			require("theme.tabby_config")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim", -- Indentation lines
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				vim.g.indent_blankline_char = "▏"
				vim.g.indent_blankline_char_blankline = " "
				vim.g.indent_blankline_use_treesitter = true
				require("ibl").setup({ scope = { enabled = false } })
			end, 0)
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"rcarriga/nvim-notify",
		event = "VeryLazy",
	},
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		version = false,
		-- event = "VeryLazy", -- don't use, breaks lua parser somehow
		dependencies = {
			-- vif, vic - select in function, class etc
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			if not vim.g.is_latex then
				require("theme.treesitter")
			end
		end,
	},
	-- Show context(a function, class etc) that isn't visible, but you're in
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		enabled = true,
		opts = { mode = "cursor", max_lines = 3 },
	},

	-- Mason for managing external lsps, formatters, linters, debuggers
	{
		"williamboman/mason.nvim",
		lazy = true,
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "",
						package_pending = "➜",
						package_uninstalled = "",
					},
					border = BORDER,
				},
			})
		end,
	},

	-- Trees
	-- {
	-- 	"kyazdani42/nvim-tree.lua",
	--  event = "VeryLazy",
	-- 	config = function()
	-- 		require("nvimtree_config")
	-- 	end,
	-- },
	{
		"stevearc/oil.nvim",
		-- Optional dependencies
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = true,
		config = function()
			require("oil_config")
			require("keybindings.oil_keybindings")
		end,
		cmd = "Oil",
		keys = "\\",
	},
	{
		"mbbill/undotree",
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				require("undotree_config")
			end, 0)
		end,
	},

	-- AI
	{
		"Exafunction/codeium.vim",
		event = "BufEnter",
		config = function()
			require("keybindings.codeium_bindings")
		end,
	},
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	-- event = "VeryLazy",
	-- 	lazy = true,
	-- 	config = function()
	-- 		require("copilot_config")
	-- 		require("keybindings.copilot_bindings")
	-- 	end,
	-- },
	-- {
	-- 	"CopilotC-Nvim/CopilotChat.nvim",
	-- 	branch = "canary",
	-- 	lazy = true,
	-- 	dependencies = {
	-- 		{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
	-- 		{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
	-- 	},
	-- 	opts = {
	-- 		debug = false, -- Enable debugging
	-- 		-- See Configuration section for rest
	-- 	},
	-- 	-- See Commands section for default commands if you want to lazy load on them
	-- },

	-- Comments
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		-- lazy = false,
		config = function()
			vim.defer_fn(function()
				require("Comment").setup()
			end, 0)
		end,
	},

	-- Movement
	-- Fuzzy finder
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"nvim-telescope/telescope.nvim",
		event = "VeryLazy",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		config = function()
			require("telescope").setup({
				extensions = {
					fzf = {},
				},
				pickers = {
					find_files = {
						theme = "ivy",
					},
					lsp_definitions = {
						theme = "ivy",
					},
					lsp_references = {
						theme = "ivy",
					},
					lsp_implementations = {
						theme = "ivy",
					},
					registers = {
						theme = "ivy",
					},
					current_buffer_fuzzy_find = {
						theme = "ivy",
					},
					git_files = {
						theme = "ivy",
					},
					live_grep = {
						theme = "ivy",
					},
					keymaps = {
						theme = "ivy",
					},
					buffers = {
						theme = "ivy",
					},
					help_tags = {
						theme = "ivy",
					},
				},
			})
			require("telescope").load_extension("fzf")
		end,
	},
	{
		"smoka7/hop.nvim",
		event = "VeryLazy",
		version = "v2",
		config = function()
			vim.defer_fn(function()
				require("hop").setup({
					jump_on_sole_occurrence = false, -- Don't autojump when only 1 occurence
					keys = "1234567890",
				})
				-- Hop highlighs
				require("theme.hop_highlights")
				require("keybindings.hop_bindings")
			end, 0)
		end,
	},

	-- Save screenshots of code
	{
		"mistricky/codesnap.nvim",
		build = "make",
		cmd = { "CodeSnap", "CodeSnapSave", "CodeSnapSaveHighlight", "CodeSnapHighlight" },
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("codesnap").setup({
				save_path = (os.getenv("XDG_PICTURES_DIR") or (os.getenv("HOME") .. "/Pictures")) .. "/CodeSnap",
				mac_window_bar = false,
				has_line_number = true,
				bg_theme = "dusk",
				bg_color = vim.g.color_dark2,
				watermark = "",
				code_font_family = "FantasqueSansM Nerd Font Mono",
				bg_x_padding = 16,
				bg_y_padding = 16,
				bg_padding = 0,
			})
		end,
	},
}

return plugins
