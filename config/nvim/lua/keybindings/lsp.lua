-- Goto definition
KEYMAP("n", "gd", function() Snacks.picker.lsp_definitions() end, GET_OPTIONS("Telescope LSP: [g]o to [d]efinition"))
KEYMAP("n", "gri", function() Snacks.picker.lsp_implementations() end, GET_OPTIONS("Telescope LSP: [g]o to [i]mplementation"))
KEYMAP("n", "grr", function() Snacks.picker.lsp_references() end, GET_OPTIONS("Telescope LSP: [g]o to [r]eferences"))
-- References in quickfix
KEYMAP("n", "grR", vim.lsp.buf.references, GET_OPTIONS("LSP: [g]o to [R]eferences in quickfix"))
-- Smart rename - already mapped to grn
KEYMAP("n", "grn", vim.lsp.buf.rename, GET_OPTIONS("LSP: Smart re[n]ame"))
-- Code action - already mapped to gra
KEYMAP("n", "gra", vim.lsp.buf.code_action, GET_OPTIONS("LSP: code [a]ctions"))
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
