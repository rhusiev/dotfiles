-- Toggle undotree
KEYMAP("n", "_", ":UndotreeToggle<CR><C-w>h", GET_OPTIONS("UndoTree: toggle [m]enu"))

-- Terminal
-- Esc for terminal mode
KEYMAP("t", "<M-Esc>", "<C-\\><C-n>", GET_OPTIONS("Terminal: Esc for terminal mode"))
-- Create terminal horizontal split, vertical split
KEYMAP(
	"n",
	"<Leader>tt",
	":belowright 15split term://fish<CR>:set winfixheight<CR>A",
	GET_OPTIONS("Terminal: Spawn [t]erminal")
)
-- Run script in terminal
-- Python
KEYMAP(
	"n",
	"<Leader>tp",
	":belowright 15split term://python '%'<CR>:set winfixheight<CR>",
	GET_OPTIONS("Terminal: Run [p]ython script in terminal")
)
-- Python + import
KEYMAP(
	"n",
	"<Leader>ti",
	":belowright 15split term://python -i '%'<CR>:set winfixheight<CR>A",
	GET_OPTIONS("Terminal: [I]mport python script and interactively")
)
-- Bash
KEYMAP(
	"n",
	"<Leader>tb",
	":belowright 15split term://bash '%'<CR>:set winfixheight<CR>",
	GET_OPTIONS("Terminal: Run [b]ash script in terminal")
)
-- Javascript
KEYMAP(
    "n",
    "<Leader>tj",
    ":belowright 15split term://bun '%'<CR>:set winfixheight<CR>",
    GET_OPTIONS("Terminal: Run [j]avascript script in terminal")
)
-- Dolphin
KEYMAP("n", "<Leader>td", ":!nohup dolphin . &>/dev/null & disown<CR><CR>", GET_OPTIONS("Terminal: Open in [D]olphin"))
-- Codium
KEYMAP("n", "<Leader>tc", ":!nohup codium '%' &>/dev/null & disown<CR><CR>", GET_OPTIONS("Terminal: Open in [C]odium"))
-- Kitty
KEYMAP("n", "<Leader>tk", ":!nohup kitty '%' &>/dev/null & disown<CR><CR>", GET_OPTIONS("Terminal: Open in [K]itty"))

-- Help page for word under cursor in new tab
KEYMAP("n", "<C-K>", ":tab help <C-r><C-w><CR>", GET_OPTIONS("Open help page for word under cursor in new tab"))

--
-- Splits, tabs
--
-- Creation
KEYMAP("n", "L", ":vsp<CR>", GET_OPTIONS("Split: Create split on the right"))
KEYMAP("n", "<C-n>", ":tabnew<CR>", GET_OPTIONS("Tab: Create new tab"))
KEYMAP("n", "<C-т>", ":tabnew<CR>", GET_OPTIONS("Tab: Create new tab"))
-- Navigating between split windows
KEYMAP("n", "<M-h>", "<C-w>h", GET_OPTIONS("Split: Go to split left"))
KEYMAP("n", "<M-j>", "<C-w>j", GET_OPTIONS("Split: Go to split below"))
KEYMAP("n", "<M-k>", "<C-w>k", GET_OPTIONS("Split: Go to split above"))
KEYMAP("n", "<M-l>", "<C-w>l", GET_OPTIONS("Split: Go to split right"))
-- Navigating between tabs
KEYMAP("n", "<C-Tab>", ":tabnext<CR>", GET_OPTIONS("Tab: Go to next [tab]"))
KEYMAP("n", "<S-Tab>", ":tabprevious<CR>", GET_OPTIONS("Tab: Go to previous [tab]"))
-- Quiting split windows and tabs
KEYMAP("n", "Q", ":q<CR>", GET_OPTIONS("Split: [Q]uit"))
KEYMAP("n", "Й", ":q<CR>", GET_OPTIONS("Split: [Q]uit"))
KEYMAP("n", "<C-q>", ":tabclose<CR>", GET_OPTIONS("Tab: [Q]uit"))
KEYMAP("n", "<C-й>", ":tabclose<CR>", GET_OPTIONS("Tab: [Q]uit"))
