KEYMAP(
	"n",
	"<Leader>/",
	function() Snacks.picker.lines() end,
	GET_OPTIONS("Telescope: [/] fuzzily in current file")
)
KEYMAP(
	"n",
	"<Leader>w",
	function() Snacks.picker.files() end,
	GET_OPTIONS("Telescope: files in [w]orking directory")
)
KEYMAP(
	"n",
	"<Leader>G",
	function() Snacks.picker.git_files() end,
	GET_OPTIONS("Telescope: files in [G]it directory")
)
KEYMAP(
	"n",
	"<Leader>g",
	function() Snacks.picker.grep() end,
	GET_OPTIONS("Telescope: [g]rep in current directory")
)
KEYMAP(
	"n",
	"<Leader>m",
	function() Snacks.picker.keymaps() end,
	GET_OPTIONS("Telescope: key[m]aps")
)
KEYMAP(
    "n",
    "<Leader>f",
    function() Snacks.picker.buffers() end,
    GET_OPTIONS("Telescope: open [f]iles (buffers)")
)
KEYMAP(
    "n",
    "<Leader>h",
    function() Snacks.picker.help() end,
    GET_OPTIONS("Telescope: open [h]elp")
)
-- Copy-paste telescope
KEYMAP({ "n", "i" }, "<M-r>", function() Snacks.picker.registers() end, GET_OPTIONS("Copy-paste Telescope: [R]egisters"))
