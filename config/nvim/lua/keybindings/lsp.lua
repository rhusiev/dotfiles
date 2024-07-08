-- Goto definition
KEYMAP("n", "gd", "<cmd>Telescope lsp_definitions<CR>", GET_OPTIONS("Telescope LSP: [g]o to [d]efinition"))
KEYMAP("n", "gp", "<cmd>Telescope lsp_implementations<CR>", GET_OPTIONS("Telescope LSP: [g]o to im[p]lementation"))
KEYMAP("n", "gr", "<cmd>Telescope lsp_references<CR>", GET_OPTIONS("Telescope LSP: [g]o to [r]eferences"))
-- References in quickfix
KEYMAP("n", "gR", vim.lsp.buf.references, GET_OPTIONS("LSP: [g]o to [R]eferences in quickfix"))
-- Smart rename
KEYMAP("n", "<Leader>r", vim.lsp.buf.rename, GET_OPTIONS("LSP: Smart [r]ename"))
-- Code action
KEYMAP("n", "<Leader>a", vim.lsp.buf.code_action, GET_OPTIONS("LSP: code [a]ctions"))
-- Show function documentation
KEYMAP(
	{ "i", "n" },
	"<C-e>",
    vim.lsp.buf.signature_help,
	{ remap = true, silent = true, desc = "LSP: Show signature help" }
)
KEYMAP(
    { "i", "n" },
    "<C-f>",
    vim.lsp.buf.hover,
    { remap = true, silent = true, desc = "LSP: Show hover" }
)
