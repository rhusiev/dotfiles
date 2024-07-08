-- Latex specific keybindings
-- go to follow obsidian link, gl to create a link(selection into brackets)
KEYMAP("n", "go", "<cmd>ObsidianFollowLink<CR>", { remap = false, desc = "Obsidian: [g]o [o]bsidian link" })
KEYMAP("v", "gl", "c[[]]<Esc>hP", { remap = false, desc = "Obsidian: create [l]ink" })
-- <C-p> to quick switch
KEYMAP("n", "<C-p>", "<cmd>ObsidianQuickSwitch<CR>", { remap = false, desc = "Obsidian: Quick switch" })
-- Keybindings for tables
KEYMAP("i", "<M-H>", "<C-o>:TableModeRealign<CR><C-o>[|", GET_OPTIONS("Table: go to prev column"))
KEYMAP("i", "<M-Р>", "<C-o>:TableModeRealign<CR><C-o>[|", GET_OPTIONS("Table: go to prev column"))
KEYMAP("i", "<M-L>", "<C-o>:TableModeRealign<CR><C-o>]|", GET_OPTIONS("Table: go to next column"))
KEYMAP("i", "<M-Д>", "<C-o>:TableModeRealign<CR><C-o>]|", GET_OPTIONS("Table: go to next column"))
KEYMAP("i", "<M-K>", "<C-o>:TableModeRealign<CR><C-o>{|", GET_OPTIONS("Table: go to prev row"))
KEYMAP("i", "<M-Л>", "<C-o>:TableModeRealign<CR><C-o>{|", GET_OPTIONS("Table: go to prev row"))
KEYMAP("i", "<M-J>", "<C-o>:TableModeRealign<CR><C-o>}|", GET_OPTIONS("Table: go to next row"))
KEYMAP("i", "<M-О>", "<C-o>:TableModeRealign<CR><C-o>}|", GET_OPTIONS("Table: go to next row"))
-- Removing, adding
KEYMAP("i", "<M-r>", "<Esc><Leader>tdda", GET_OPTIONS("Table: remove row"))
KEYMAP("i", "<M-к>", "<Esc><Leader>tdda", GET_OPTIONS("Table: remove row"))
KEYMAP("i", "<M-c>", "<Esc><Leader>tdca", GET_OPTIONS("Table: remove column"))
KEYMAP("i", "<M-с>", "<Esc><Leader>tdca", GET_OPTIONS("Table: remove column"))
KEYMAP("i", "<M-n>", "<Esc><Leader>tic", GET_OPTIONS("Table: insert column"))
KEYMAP("i", "<M-т>", "<Esc><Leader>tic", GET_OPTIONS("Table: insert column"))
-- Links for markdown
KEYMAP("i", "<M-u>", "[[", GET_OPTIONS("Obsidian: open link"))
KEYMAP("i", "<M-г>", "[[", GET_OPTIONS("Obsidian: open link"))
KEYMAP("i", "<M-i>", "]]", GET_OPTIONS("Obsidian: close link"))
KEYMAP("i", "<M-ш>", "]]", GET_OPTIONS("Obsidian: close link"))
