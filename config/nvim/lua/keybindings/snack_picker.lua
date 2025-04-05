KEYMAP("n", "gd", function() Snacks.picker.lsp_definitions() end, GET_OPTIONS("Picker LSP: [g]o to [d]efinition"))
KEYMAP("n", "gri", function() Snacks.picker.lsp_implementations() end, GET_OPTIONS("Picker LSP: [g]o to [i]mplementation"))
KEYMAP("n", "grr", function() Snacks.picker.lsp_references() end, GET_OPTIONS("Picker LSP: [g]o to [r]eferences"))

KEYMAP(
	"n",
	"<Leader>/",
	function() Snacks.picker.lines() end,
	GET_OPTIONS("Picker: [/] fuzzily in current file")
)
KEYMAP(
	"n",
	"<Leader>w",
	function() Snacks.picker.files() end,
	GET_OPTIONS("Picker: files in [w]orking directory")
)
KEYMAP(
	"n",
	"<Leader>G",
	function() Snacks.picker.git_files() end,
	GET_OPTIONS("Picker: files in [G]it directory")
)
KEYMAP(
	"n",
	"<Leader>g",
	function() Snacks.picker.grep() end,
	GET_OPTIONS("Picker: [g]rep in current directory")
)
KEYMAP(
	"n",
	"<Leader>m",
	function() Snacks.picker.keymaps() end,
	GET_OPTIONS("Picker: key[m]aps")
)
KEYMAP(
    "n",
    "<Leader>f",
    function() Snacks.picker.buffers() end,
    GET_OPTIONS("Picker: open [f]iles (buffers)")
)
KEYMAP(
    "n",
    "<Leader>h",
    function() Snacks.picker.help() end,
    GET_OPTIONS("Picker: open [h]elp")
)
-- Copy-paste telescope
KEYMAP({ "n", "i" }, "<M-r>", function() Snacks.picker.registers() end, GET_OPTIONS("Copy-paste Picker: [R]egisters"))
