-- Linters, fixers
local null_ls = require("null-ls")
local h = require("null-ls.helpers")
local lspconfig_util = require("lspconfig.util")
local global_bun = os.getenv("HOME") .. "/dotfiles/local/share/bun/install/global/node_modules/"

local docformatter = h.make_builtin({
	method = null_ls.methods.FORMATTING,
	filetypes = { "python" },
	generator_opts = {
		command = "docformatter",
		args = { "--wrap-summaries=88", "--wrap-descriptions=88", "-" },
		to_stdin = true,
		from_stderr = false,
	},
	factory = h.formatter_factory,
})

local sources = {
	null_ls.builtins.diagnostics.todo_comments,

	null_ls.builtins.formatting.prettier.with({
		extra_args = { "--tab-width", "4", "--plugin", global_bun .. "prettier-plugin-tailwindcss/dist/index.mjs" },
		-- Ignore .md files
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"css",
			"scss",
			"html",
			"json",
			"yaml",
		},
	}),
	null_ls.builtins.diagnostics.tidy,
	require("none-ls.diagnostics.eslint_d").with({
		extra_args = function(params)
			-- if there is a package.json in the root of the project, use that
			local filename = params.bufname
			local root_dir = lspconfig_util.root_pattern("package.json")(filename)
			if root_dir then
				return {
					"-c",
					vim.fn.expand("$HOME/dotfiles/config/eslint/config.json"),
					"--resolve-plugins-relative-to",
					root_dir,
				}
			end
			return {
				"-c",
				vim.fn.expand("$HOME/dotfiles/config/eslint/config.json"),
				"--resolve-plugins-relative-to",
				vim.fn.expand("$HOME/dotfiles/local/share/bun/install/global/package.json"),
			}
		end,
	}),

	null_ls.builtins.formatting.stylua,

	--[[ null_ls.builtins.diagnostics.checkstyle.with({
		extra_args = {
			"-c",
			vim.fn.expand("$HOME/dotfiles/config/checkstyle/checkstyle.xml"),
		},
		-- Ignore diagnostics whose message has "Picked up _JAVA_OPTIONS"
		filter = function(line)
			return not string.find(line.message, "Picked up _JAVA_OPTIONS")
		end,
	}), ]]

	require("none-ls.diagnostics.cpplint"),
	-- require("none-ls..diagnostics.clang_check"),
	null_ls.builtins.diagnostics.cppcheck,
	null_ls.builtins.formatting.clang_format.with({
		extra_args = {
			"--style",
			"{IndentWidth: 4}",
		},
	}),

	docformatter,
	null_ls.builtins.diagnostics.mypy.with({
		extra_args = function(params)
			local filename = params.bufname
			local root_dir
			root_dir = lspconfig_util.find_git_ancestor(filename)
			root_dir = root_dir
				or lspconfig_util.root_pattern("setup.py", "pyproject.toml", "setup.cfg", "requirements.txt")(filename)
			root_dir = root_dir or lspconfig_util.root_pattern("*.py")(filename)
			local cache_dir = vim.fn.expand("$HOME/.cache/mypy/") .. root_dir
			return { "--cache-dir", cache_dir }
		end,
	}),
	require("none-ls.diagnostics.flake8").with({
		-- Extra args, format, so that error code is part of the message, not separated by anything
		extra_args = {
			"--max-line-length=89",
			-- DAR103 - func typehint and the one in the docstring must match. False positive on (..., optional)
			-- W503 - linebreak before operator(...<newline> = ...)
			-- E203 - whitespace before ':' in slices
			-- ANN101 - disallow self without typehint
			-- ANN401 - disallow typing.Any typehint
			-- D107 - missing docstring in __init__
			-- ANN001.. - some that intersect with ruff
			"--ignore=DAR103,W503,E203,ANN101,ANN401,D107,ANN001,ANN201,ANN204,N802,D100,D103,D105,D200,D203,D205,D211,D212,D300,D301,D415,E501,W291,R503,F841",
			"--docstring-convention",
			"google",
			"--format",
			"%(path)s:%(row)d:%(col)d: %(code)s %(text)s  ",
		},
	}),
}

--- toggle diagnostics, used in null_ls
vim.g.diagnostics_visible = true
function TOGGLE_DIAGNOSTICS()
	if vim.g.diagnostics_visible then
		vim.g.diagnostics_visible = false
		vim.diagnostic.disable()
	else
		vim.g.diagnostics_visible = true
		vim.diagnostic.enable()
	end
end

null_ls.setup({
	sources = sources,
})
