local ensure_mason = {
	"basedpyright",
	"debugpy",
	"docformatter",
	"ruff",

    "lua-language-server",
	"stylua",

    "bash-language-server",
    "shfmt",

	"css-lsp",
    "html-lsp",
    "tailwindcss-language-server",
	"typescript-language-server",
    "deno",
    "eslint_d",

    "clangd",
    "clang-format",
    "cpptools",
    "cpplint",
    "cmakelint",
    "neocmakelsp",

    "json-lsp",

    -- "glsl_analyzer",
}
-- Install using mason everything that is not yet installed
for _, v in ipairs(ensure_mason) do
	if vim.fn.executable(v) == 0 then
		vim.cmd("MasonInstall " .. v)
	end
end

local ensure_ts = {
    "python",

    "rust",

    "lua",

    "markdown",
    "markdown_inline",

    "toml",
    "yaml",
    "json",
    "json5",
    "proto",

    "javascript",
    "typescript",
    "tsx",
    "scss",
    "css",
    "html",

    "cpp",
    "cmake",
    "glsl",

    "vimdoc",

    "fish",

    "java",
}
-- Install using TS everything that is not yet installed
for _, v in ipairs(ensure_ts) do
    vim.cmd("TSUpdate " .. v)
end

vim.cmd("MasonUpdate")
vim.cmd("Lazy sync")
vim.cmd("TSUpdate")
