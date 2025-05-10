local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
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
		dir = vim.fn.expand("$HOME/Drive/Projects/Personal/pet.nvim"),
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
			require("nvim-surround").setup({})
		end,
	},

	-- Themes
	{
		"gbprod/nord.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			if not vim.g.theme then
				require("theme.colorscheme")
			end
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
		config = function()
			if not vim.g.theme then
				require("theme.colorscheme")
			end
		end,
	},
	{
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
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			dashboard = { enabled = false },
			explorer = { enabled = false },
			indent = { enabled = true, animate = { enabled = false } },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true, timeout = 5000 },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = false }, -- breaks fast ctrl-a etc
			statuscolumn = { enabled = false },
			styles = {
				notification = {
					border = "rounded",
					zindex = 100,
					ft = "markdown",
					wo = {
						winblend = 5,
						wrap = true,
						conceallevel = 2,
						colorcolumn = "",
					},
					bo = { filetype = "snacks_notif" },
				},
				terminal = {
					border = "rounded",
					bo = {
						filetype = "snacks_terminal",
					},
					wo = {},
					keys = {
						q = "hide",
						gf = function(self)
							local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
							if f == "" then
								Snacks.notify.warn("No file under cursor")
							else
								self:hide()
								vim.schedule(function()
									vim.cmd("e " .. f)
								end)
							end
						end,
						quit = {
							"<C-q>",
							function(self)
								self:hide()
							end,
							mode = "t",
							expr = true,
							desc = "Hide from insert",
						},
						term_normal = {
							"<esc>",
							function()
								vim.cmd("stopinsert")
								return ""
							end,
							mode = "t",
							expr = true,
							desc = "Double escape to normal mode",
						},
					},
				},
			},
			terminal = { enabled = true },
			words = { enabled = true },
		},
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		version = false,
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

	-- Movement
	-- Fuzzy finder
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
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
