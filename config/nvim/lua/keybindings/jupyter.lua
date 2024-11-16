KEYMAP("n", "zG", function()
	vim.cmd("!" .. vim.g.jupyter_venv .. "/bin/ipynb2jupytext %")
	local current_file_name = vim.fn.expand("%")
	local jupy_file_name = string.gsub(current_file_name, ".ipynb", ".ju.py")
	vim.cmd("edit " .. jupy_file_name)
end, GET_OPTIONS("Jupyter: [G]enerate .ju.py"))
KEYMAP("n", "zA", function()
    local current_file_name = vim.fn.expand("%:p:r:r") .. "_DEV.ipynb"
    os.remove(current_file_name)
    vim.cmd("JupyniumStartAndAttachToServer")
end, GET_OPTIONS("Jupyter: start and [A]ttach to server"))
KEYMAP("n", "zS", function()
    local current_file_name = vim.fn.expand("%:t:r:r") .. "_DEV.ipynb"
    vim.cmd("JupyniumStartSync " .. current_file_name)
end, GET_OPTIONS("Jupyter: [S]ync"))
KEYMAP(
	"n",
	"zL",
	"<cmd>read " .. vim.fn.expand("$HOME/Templates/leavenoonebehind.ju.py<CR>"),
	GET_OPTIONS("Jupyter: use template for [L]eaveNoOneBehind")
)

local add_cell_after = function()
	local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd.normal(vim.api.nvim_replace_termcodes("<Esc>]j", true, true, true))
	local new_cursor_pos = vim.api.nvim_win_get_cursor(0)
	if current_cursor_pos[1] == new_cursor_pos[1] then
		vim.cmd.normal(vim.api.nvim_replace_termcodes("Go<CR>", true, true, true))
	else
		vim.cmd.normal(vim.api.nvim_replace_termcodes("kO<CR>", true, true, true))
	end
	vim.cmd("startinsert")
end

KEYMAP({ "i", "n" }, "<M-a>", add_cell_after, GET_OPTIONS_REMAP("Jupyter: add cell [a]fter the current one"))
KEYMAP({ "i", "n" }, "<M-b>", "<Esc><Space>jjO<Esc>O", GET_OPTIONS_REMAP("Jupyter: add cell [b]efore the current one"))
KEYMAP({ "i", "n" }, "<M-ф>", add_cell_after, GET_OPTIONS_REMAP("Jupyter: add cell [a]fter the current one"))
KEYMAP({ "i", "n" }, "<M-и>", "<Esc><Space>jjO<Esc>O", GET_OPTIONS_REMAP("Jupyter: add cell [b]efore the current one"))

KEYMAP({ "i", "n" }, "<M-p>", "py<C-Tab>", GET_OPTIONS_REMAP("Jupyter: add [p]ython cell"))
KEYMAP({ "i", "n" }, "<M-d>", "md<C-Tab>", GET_OPTIONS_REMAP("Jupyter: add m[d] cell"))
KEYMAP({ "i", "n" }, "<M-з>", "py<C-Tab>", GET_OPTIONS_REMAP("Jupyter: add [p]ython cell"))
KEYMAP({ "i", "n" }, "<M-в>", "md<C-Tab>", GET_OPTIONS_REMAP("Jupyter: add m[d] cell"))
