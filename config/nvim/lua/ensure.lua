local ensure_mason = {
	-- "basedpyright",
    "ty",
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
    "eslint_d",

    "clangd",
    "clang-format",
    "cpptools",
    "cpplint",
    "cmakelint",
    "neocmakelsp",

    "json-lsp",
    "docker-compose-language-service",
    "dockerfile-language-server",

    "texlab",
    "ltex-ls-plus",

    -- "glsl_analyzer",
}
for _, v in ipairs(ensure_mason) do
	if vim.fn.executable(v) == 0 then
		vim.cmd("MasonInstall " .. v)
	end
end

vim.cmd("MasonUpdate")
vim.cmd("Lazy sync")
