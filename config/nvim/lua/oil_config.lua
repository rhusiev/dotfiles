require("oil").setup({
	-- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
	delete_to_trash = true,
    default_file_explorer = true,
	-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
	-- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
	-- Additionally, if it is a string that matches "actions.<name>",
	-- it will use the mapping at require("oil.actions").<name>
	-- Set to `false` to remove a keymap
	-- See :help oil-actions for a list of all available actions
	keymaps = {
		["g?"] = "actions.show_help",
		["<CR>"] = "actions.select",
		["<C-l>"] = "actions.select_vsplit",
		["<C-j>"] = "actions.select_split",
		["<C-t>"] = "actions.select_tab",
		["<C-p>"] = "actions.preview",
		["\\"] = "actions.close",
		["<C-e>"] = "actions.refresh",
		["-"] = "actions.parent",
		["_"] = "actions.open_cwd",
		["`"] = "actions.cd",
		["~"] = "actions.tcd",
		["gs"] = "actions.change_sort",
		["gx"] = "actions.open_external",
		["g."] = "actions.toggle_hidden",
		["g\\"] = "actions.toggle_trash",
	},
	-- Set to false to disable all of the above keymaps
	use_default_keymaps = true,
	view_options = {
		-- Show files and directories that start with "."
		show_hidden = true,
	},
})
