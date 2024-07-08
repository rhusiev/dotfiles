local ensure_mason = {
	"basedpyright",
	"debugpy",
	"docformatter",
	"ruff",

    "lua-language-server",
	"stylua",

    "bash-language-server",

	"css-lsp",
    "html-lsp",
	"typescript-language-server",
    "tailwindcss-language-server",

    "clangd",
    "clang-format",
    "codelldb",
    "cpptools",
    "cpplint",

    "glsl_analyzer",

    "llm-ls",

    "shfmt",

    -- "jdtls",
    -- "checkstyle",
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

    "javascript",
    "typescript",
    "tsx",
    "scss",
    "css",
    "html",

    "cpp",
    "cmake",

    "glsl",

    -- "java",
}
-- Install using TS everything that is not yet installed
for _, v in ipairs(ensure_ts) do
    vim.cmd("TSUpdate " .. v)
end

vim.cmd("MasonUpdate")
vim.cmd("Lazy sync")
vim.cmd("TSUpdate")
