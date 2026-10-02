local conform = require("conform")
local optional_module = require("optional_module")

local opts = {
	formatters = {
		docformatter = {
			command = "docformatter",
			args = { "--wrap-summaries", "88", "--wrap-descriptions", "88", "-" },
			rootPatterns = { ".git", "pyproject.toml" },
		},
		prettier = {
			inherit = true,
			prepend_args = {
				"--tab-width",
				"4",
			},
		},
		clang_format = {
			inherit = true,
			prepend_args = { "--style", "{IndentWidth: 4}" },
		},
	},

	formatters_by_ft = {
		["_"] = { "trim_whitespace" },

		python = function(bufnr)
			if require("ruff_project").has_project_ruff_config(bufnr) then
				return {}
			end
			return { "docformatter" }
		end,

		lua = { "stylua" },

		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		scss = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },

		cpp = { "clang_format" },
		c = { "clang_format" },

		sh = { "shfmt" },
		zsh = { "shfmt" },
		bash = { "shfmt" },
		csh = { "shfmt" },
		ksh = { "shfmt" },
	},
}

local work_opts = optional_module.load("work.formatting")
if work_opts then
	opts = vim.tbl_deep_extend("force", opts, work_opts)
end

conform.setup(opts)
