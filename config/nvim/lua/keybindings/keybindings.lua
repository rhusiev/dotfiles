-- Leader key
vim.g.mapleader = " "

require("keybindings.functions")

-- Neogit
KEYMAP("n", "<Leader>n", ":Neogit<CR>", GET_OPTIONS("Neogit: open [N]eogit"))

-- Fixes for Konsole
KEYMAP("i", "<F33>", "<C-CR>", GET_OPTIONS_REMAP("Fix (for Konsole): <F33> -> <C-CR>"))
KEYMAP("i", "<F21>", "<S-CR>", GET_OPTIONS_REMAP("Fix (for Konsole): <F21> -> <S-CR>"))

-- <M-m> to be do indentation like tab in insert, emulate tab in normal
-- KEYMAP({ "n", "i" }, "<M-m>", "<Tab>", GET_OPTIONS("<M-m> to emulate tab"))

require("keybindings.workspace")
require("keybindings.copy_paste")
vim.defer_fn(function()
	require("keybindings.format")
end, 0)
vim.defer_fn(function()
	require("keybindings.move")
end, 0)
vim.defer_fn(function()
	require("keybindings.telescope")
end, 0)

--
-- Suggestions
--
-- Make enter always select suggestion, not new line, when popup is active
KEYMAP(
	"i",
	"<CR>",
	'pumvisible() ? "<C-y>" : "<CR>"',
	{ expr = true, desc = "Completion: <Enter> always selects suggestion, not new line" }
)
-- Cycle backwards in completion
KEYMAP(
	"i",
	"<S-Tab>",
	'pumvisible() ? "<C-p>" : "<C-h>"',
	{ expr = true, silent = true, desc = "Completion: cycle backwards" }
)
-- Linter show diagnostics in popup
KEYMAP("n", "<Leader>e", function()
	vim.diagnostic.open_float(0, DIAGNOSTIC_POPUP)
end, GET_OPTIONS("Diagnostics: Linter show linter diagnostics in popup"))
KEYMAP("n", "<leader>E", function()
	TOGGLE_DIAGNOSTICS()
end, GET_OPTIONS("Diagnostics: toggle showing diagnostics"))
KEYMAP("n", "<Leader>D", vim.diagnostic.setqflist, GET_OPTIONS("Diagnostics: show quickfix with [D]iagnostics"))

--
-- Select
--
-- vv to select to the end of line
KEYMAP("v", "v", "$h", GET_OPTIONS("Selection: vv to select to the end of line"))
-- <C-a> to select all
KEYMAP("n", "<C-a>", "ggVG", GET_OPTIONS("Selection: Select all"))

--
-- Search
--
-- Remove highlighting after search
KEYMAP("n", "<Leader>b", ":nohlsearch<CR>", GET_OPTIONS("Search: Remove highlighting after search"))
-- Center the screen after searching for the next occurrence
KEYMAP("n", "n", "nzzzv", GET_OPTIONS("Search: Center the screen after searching for next"))
KEYMAP("n", "N", "Nzzzv", GET_OPTIONS("Search: Center the screen after searching for prev"))

--
-- Delete whole words
--
KEYMAP("i", "<C-Del>", "<C-o>de", GET_OPTIONS("Delete: word ahead"))
KEYMAP("i", "<C-BS>", "<C-W>", GET_OPTIONS("Delete: word behind"))
KEYMAP("i", "<C-H>", "<C-W>", GET_OPTIONS("Delete: word behind"))
