local lint = require("lint")
local lspconfig_util = require("lspconfig.util")

local flake8 = lint.linters.flake8
flake8.args = vim.list_extend(flake8.args, {
	"--max-line-length=89",
	-- DAR103 - func typehint and the one in the docstring must match. False positive on (..., optional)
	-- W503 - linebreak before operator(...<newline> = ...)
	-- E203 - whitespace before ':' in slices
	-- E704 - multiple statements in one line (such as ... after abstract def)
	-- ANN101 - disallow self without typehint
	-- ANN401 - disallow typing.Any typehint
	-- D107 - missing docstring in __init__
	-- ANN001.. - some that intersect with ruff
	"--ignore=DAR103,W503,E203,E704,ANN101,ANN401,D107,ANN001,ANN201,ANN204,N802,D100,D101,D102,D103,D105,D200,D203,D205,D211,D212,D300,D301,D415,E501,E704,E711,W291,R503,F841,SCS108",
	"--docstring-convention",
	"google",
	-- "--format",
	-- "%(path)s:%(row)d:%(col)d: %(code)s %(text)s",
})
local mypy = lint.linters.mypy
local mypy_path = vim.fn.expand("$HOME/.local/share/venvs/linters_venv/")
-- mypy.cmd = mypy_path .. "bin/mypy"
mypy.args = {
	-- "--python-executable",
	-- mypy_path .. "bin/python",
	"--show-column-numbers",
	"--show-error-end",
	"--hide-error-codes",
	"--hide-error-context",
	"--no-color-output",
	"--no-error-summary",
	"--no-pretty",
    "--cache-dir",
	function()
	    local filename = vim.api.nvim_buf_get_name(0)
	    local root_dir
	    root_dir = lspconfig_util.find_git_ancestor(filename)
	    root_dir = root_dir
	        or lspconfig_util.root_pattern("setup.py", "pyproject.toml", "setup.cfg", "requirements.txt")(filename)
	    root_dir = root_dir or lspconfig_util.root_pattern("*.py")(filename)
	    local cache_dir = vim.fn.expand("$HOME/.cache/mypy/") .. root_dir
	    return cache_dir
	end
}
local pattern = [[%s*(%d+):(%d+)%s+(%w+)%s+(.+%S)%s+(%S+)]]
local groups = { "lnum", "col", "severity", "message", "code" }
local severity_map = {
	["error"] = vim.diagnostic.severity.ERROR,
	["warn"] = vim.diagnostic.severity.WARN,
	["warning"] = vim.diagnostic.severity.WARN,
}
lint.linters.eslint_d = function()
	local args = {
		"--stdin",
		"--stdin-filename",
		function()
			return vim.api.nvim_buf_get_name(0)
		end,
		"-c",
		vim.fn.expand("$HOME/dotfiles/config/eslint/config.json"),
		"--resolve-plugins-relative-to",
	}
	-- if there is a package.json in the root of the project, use that
	local filename = vim.api.nvim_buf_get_name(0)
	local root_dir = lspconfig_util.root_pattern("package.json")(filename)
	if root_dir then
		table.insert(args, root_dir)
	else
		table.insert(args, "")
		-- vim.fn.expand("$HOME/dotfiles/local/share/bun/install/global/package.json"))
	end
	return {
		cmd = function()
			local local_eslintd = vim.fn.fnamemodify("./node_modules/.bin/eslint_d", ":p")
			local stat = vim.loop.fs_stat(local_eslintd)
			if stat then
				return local_eslintd
			end
			return "eslint_d"
		end,
		stdin = true,
		stream = "stdout",
		ignore_exitcode = true,
		parser = require("lint.parser").from_pattern(pattern, groups, severity_map, { ["source"] = "eslint_d" }),
		args = args,
	}
end
local cppcheck = lint.linters.cppcheck
cppcheck.args = vim.list_extend(cppcheck.args, {
	"--enable=all",
	"--suppress=missingIncludeSystem",
})

lint.linters_by_ft = {
	python = { "flake8", "mypy" },

	html = { "tidy" },
	javascript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescript = { "eslint_d" },
	typescriptreact = { "eslint_d" },
	vue = { "eslint_d" },

	cpp = { "cpplint", "cppcheck" },
	c = { "cpplint", "cppcheck" },
}

lint.linters_on_save_by_ft = {}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
	callback = function()
		lint.try_lint()
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
	callback = function()
		local filetype = vim.api.nvim_buf_get_option(0, "filetype")
		local linters = lint.linters_on_save_by_ft[filetype] or {}
		for _, linter in pairs(linters) do
			lint.try_lint(linter)
		end
	end,
})

--- toggle diagnostics
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
