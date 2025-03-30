require("secrets")
-- Line numbers
vim.o.number = true -- Show line numbers
vim.o.relativenumber = true -- Show relative line numbers
vim.o.signcolumn = "yes" -- Always show sign column(where are diagnostics, breakpoints, etc)
vim.o.foldcolumn = "auto" -- Show a column for folds near the line numbers when there are folds present

-- Indentation
vim.o.autoindent = true -- Remember indent from previous line
-- Also do tab indent according to the language
vim.o.smartindent = true
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.tabstop = 4 -- How mant spaces quals tab char(\t) equals
vim.o.shiftwidth = 4 -- How many spaces a level of indentation equals
vim.o.softtabstop = 4 -- How mant spaces a tab keypress equals
-- If .js, .ts, .jsx, .tsx file, use 2 spaces
-- vim.cmd("autocmd FileType javascript,typescript,javascriptreact,typescriptreact setlocal shiftwidth=2 tabstop=2 softtabstop=2")

vim.o.mouse = "a" -- Enable mouse support

-- Cursor
vim.o.cursorline = true -- Highlight selected line
vim.o.scrolloff = 5
vim.o.smoothscroll = true

-- Undo directory and files
vim.o.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
vim.o.undofile = true

-- Open new windows to bottom and right instead of left and up
vim.o.splitbelow = true
vim.o.splitright = true

-- Startup things
-- vim.o.autochdir = true -- Change directory to the current file
vim.o.shell = "/bin/zsh"

-- Other
vim.o.termguicolors = true -- Set better colors mb somewhere
vim.o.langmap =
	"!\\\"№%*'йцукенгшщзхїфівапролджєячсмитьбюʼЙЦУКЕHГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ;!\\\"#%*'qwertyuiop[]asdfghjkl\\$'zxcvbnm\\,.~QWERTYUIOP{}ASDFGHJKL:\\\"ZXCVBNM<>"
vim.o.showmode = false -- Disable '-- INSERT --' message
vim.o.linebreak = true -- Break lines at word boundaries, not in the middle of a word
vim.g.skipWordSeparatorInWordMotion = false

-- Variables
WINHIGHLIGHT = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None"
BORDER = "rounded"

-- Popup
vim.o.pumheight = 15 -- Max height of popup menu
vim.o.wildmode = "longest,full" -- Autocompletion in command mode
vim.o.completeopt = "menu,menuone,noselect"
POPUP = {
	border = BORDER,
	winhighlight = WINHIGHLIGHT,
	col_offset = 1,
	side_padding = 1,
}
DIAGNOSTIC_POPUP = {
	border = BORDER,
	winhighlight = WINHIGHLIGHT,
	col_offset = 1,
	side_padding = 1,
	scope = "line",
	header = false,
}

function sync_input(prompt, text, completion)
	local co = coroutine.running()
	if not co then
		error("sync_input must be called from within a coroutine")
	end

	local callback = vim.schedule_wrap(function(value)
		coroutine.resume(co, value)
	end)

	vim.ui.input({
		prompt = prompt,
		default = text,
		completion = completion,
	}, callback)

	return coroutine.yield()
end
