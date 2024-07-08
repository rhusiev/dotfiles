--
-- Format
--
-- Null-ls format
KEYMAP("n", "<Leader>c", function()
    vim.print("Formatting...")
    vim.lsp.buf.format()
	require("conform").format({timeout_ms = 2000})
end, GET_OPTIONS("Format: Format code"))
-- Quote, put into brackets selected
KEYMAP("v", "<Leader>q", "c''<Esc>Pl", GET_OPTIONS("Format: [Q]uote selected in '"))
KEYMAP("v", "<Leader>Q", 'c""<Esc>Pl', GET_OPTIONS('Format: [Q]uote selected in "'))
KEYMAP("v", "<Leader>`", "c``<Esc>Pl", GET_OPTIONS("Format: Quote selected in [`]"))
KEYMAP("v", "<Leader>9", "c()<Esc>Pl", GET_OPTIONS("Format: Put selected into ("))
KEYMAP("v", "<Leader>[", "c[]<Esc>Pl", GET_OPTIONS("Format: Put selected into ["))
KEYMAP("v", "<Leader>{", "c{}<Esc>Pl", GET_OPTIONS("Format: Put selected into {"))
KEYMAP("v", "<Leader>0", "c\\(\\)<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\("))
KEYMAP("v", "<Leader>}", "c\\{\\}<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\{"))
KEYMAP("v", "<Leader>]", "c\\[\\]<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\["))
KEYMAP("v", "<Leader>8", "c**<Esc>Pl", GET_OPTIONS("Format: Put selected into *"))
KEYMAP("v", "<Leader>*", "c****<Esc>hPl", GET_OPTIONS("Format: Put selected into **"))
KEYMAP("v", "<Leader>=", "c====<Esc>hPl", GET_OPTIONS("Format: Put selected into =="))
KEYMAP("v", "<Leader>`", "c~~~~<Esc>hPl", GET_OPTIONS("Format: Put selected into ~~"))
KEYMAP("v", "<Leader>u", "ygvlohp", GET_OPTIONS("Format: [u]nquote selected"))
KEYMAP("v", "<Leader>U", "ygv2lo2hp", GET_OPTIONS("Format: [U]quote selected from 2-symbol outline"))
