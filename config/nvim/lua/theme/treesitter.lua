local ensure_ts = {
	"python",
	"rust",
	"lua",
	"markdown",
	"markdown_inline",
	"regex",
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
	"cuda",
	"vimdoc",
	"fish",
	"java",
}

require("nvim-treesitter").install(ensure_ts)

local latex_regex_langs = { markdown = true, pandoc = true }

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("ts_highlight", { clear = true }),
	callback = function(args)
		local buf = args.buf
		local ft = vim.bo[buf].filetype
		local lang = vim.treesitter.language.get_lang(ft)
		if not lang or not vim.treesitter.language.add(lang) then
			return
		end
		vim.treesitter.start(buf, lang)

		if vim.g.is_latex and latex_regex_langs[ft] then
			vim.bo[buf].syntax = "on"
		end
	end,
})

vim.cmd("hi link TreesitterContext ColorColumn")
vim.g.indentLine_concealcursor = "c"
