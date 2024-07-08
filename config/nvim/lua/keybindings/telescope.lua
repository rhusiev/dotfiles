KEYMAP(
	"n",
	"<Leader>/",
	":Telescope current_buffer_fuzzy_find<CR>",
	GET_OPTIONS("Telescope: [/] fuzzily in current file")
)
KEYMAP(
	"n",
	"<Leader>w",
	":Telescope find_files<CR>",
	GET_OPTIONS("Telescope: files in [w]orking directory")
)
KEYMAP(
	"n",
	"<Leader>G",
	":Telescope git_files<CR>",
	GET_OPTIONS("Telescope: files in [G]it directory")
)
KEYMAP(
	"n",
	"<Leader>g",
	":Telescope live_grep<CR>",
	GET_OPTIONS("Telescope: [g]rep in current directory")
)
KEYMAP(
	"n",
	"<Leader>m",
	":Telescope keymaps<CR>",
	GET_OPTIONS("Telescope: key[m]aps")
)
KEYMAP(
    "n",
    "<Leader>f",
    ":Telescope buffers<CR>",
    GET_OPTIONS("Telescope: open [f]iles (buffers)")
)
