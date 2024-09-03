local conform = require("conform")
local global_bun = os.getenv("HOME") .. "/dotfiles/local/share/bun/install/global/node_modules/"

conform.setup({
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
				"--plugin",
				global_bun .. "prettier-plugin-tailwindcss/dist/index.mjs",
			},
		},
		clang_format = {
			inherit = true,
			prepend_args = { "--style", "{IndentWidth: 4}" },
		},
	},

	formatters_by_ft = {
		["_"] = { "trim_whitespace" },

		python = { "docformatter" },

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

        sh = { "shfmt" },
        zsh = { "shfmt" },
        bash = { "shfmt" },
        csh = { "shfmt" },
        ksh = { "shfmt" },
	},
})
