vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "", linehl = "", numhl = "" })

require("mason-nvim-dap").setup({
	handlers = {},
})
local dap, dapui = require("dap"), require("dapui")
require("nvim-dap-virtual-text").setup()

dap.configurations.cpp = {
	{
		name = "Launch LLDB",
		type = "codelldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = function()
			local args_string = vim.fn.input("Args: ")
			if args_string == "" then
				return {}
			end
			return vim.fn.split(args_string, " ")
		end,
	},
}

dapui.setup({
	layouts = {
		{
			elements = {
				{
					id = "scopes",
					size = 0.45,
				},
				{
					id = "watches",
					size = 0.2,
				},
				{
					id = "breakpoints",
					size = 0.2,
				},
				{
					id = "stacks",
					size = 0.15,
				},
			},
			position = "left",
			size = 40,
		},
		{
			elements = {
				{
					id = "console",
					size = 0.7,
				},
				{
					id = "repl",
					size = 0.3,
				},
			},
			position = "bottom",
			size = 13,
		},
	},
	icons = {
		expanded = "▾",
		collapsed = "▸",
		current_frame = "",
	},
})

-- Open, close ui with debugger
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

vim.defer_fn(function()
	require("cmp").setup({
		enabled = function()
			return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or require("cmp_dap").is_dap_buffer()
		end,
	})

	require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
		sources = {
			{ name = "dap" },
		},
	})
end, 0)

-- Debugger highlights
require("theme.debugger_highlights")
