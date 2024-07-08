require("lualine").setup({
	options = {
		icons_enabled = true,
        theme = vim.g.theme,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
			"NvimTree",
			"undotree",
			"diff",
			"packer",
			-- nvim dap
			"dapui_scopes",
			"dapui_watches",
			"dapui_breakpoints",
			"dapui_stacks",
			"dap-repl",
			"dapui_console",
		},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(str)
					return str:sub(1, 1)
				end,
			},
		},
		lualine_b = {
			{
				function()
					return " "
				end,
				padding = 0,
				color = { bg = vim.g.color_dark4 },
				separator = { right = "" },
			},
		},
		lualine_c = {
			{
				"branch",
				color = { bg = vim.g.color_dark3 },
				separator = { right = "" },
			},
			{
				"diagnostics",
				color = { bg = vim.g.color_dark3 },
				separator = { right = "" },
			},
		},
		lualine_x = {},
		lualine_y = {
			{
				function(_)
				-- function(str)
					return " "
				end,
				padding = 0,
			},
			{
				"filetype",
				icon_only = true,
				colored = false,
			},
			{
				"filename",
				fmt = function(str)
					return str .. "  "
				end,
				symbols = {
					modified = "", -- Text to show when the file is modified.
					readonly = "", -- Text to show when the file is non-modifiable or readonly.
					unnamed = "[No Name]", -- Text to show for unnamed buffers.
					newfile = "", -- Text to show for newly created file before first write
				},
				padding = 0,
			},
			{
				"progress",
				-- Show 0% and 100% instead of Top and Bot
				fmt = function(progress)
					if progress == "Top" then
						return "  0%%"
					elseif progress == "Bot" then
						return "100%%"
					end
					return " " .. progress
				end,
			},
		},
		lualine_z = {},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = { "location" },
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {
			{
				function(_)
				-- function(str)
					return " "
				end,
				padding = 0,
			},
			{
				"filetype",
				icon_only = true,
				colored = false,
			},
			{
				"filename",
				fmt = function(str)
					return str .. "  "
				end,
				symbols = {
					modified = "", -- Text to show when the file is modified.
					readonly = "", -- Text to show when the file is non-modifiable or readonly.
					unnamed = "[No Name]", -- Text to show for unnamed buffers.
					newfile = "", -- Text to show for newly created file before first write
				},
				padding = 0,
			},
			{
				"progress",
				-- Show 0% and 100% instead of Top and Bot
				fmt = function(progress)
					if progress == "Top" then
						return "  0%%"
					elseif progress == "Bot" then
						return "100%%"
					end
					return " " .. progress
				end,
			},
		},
	},
})
