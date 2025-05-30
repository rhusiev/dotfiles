vim.g.codeium_disable_bindings = 1
vim.g.is_latex = true

require("main")

local plugins = require("plugins")
for _, plugin in ipairs(require("plugins_latex")) do
	table.insert(plugins, plugin)
end
require("lazy").setup(plugins, {
	ui = {
		border = "rounded",
	},
})

SOURCES = {
	{ name = 'luasnip' }, -- For luasnip users.
	{ name = "obsidian" },
}

-- Autosave
vim.o.updatetime = 1000 -- Update every 1000 ms
vim.cmd("autocmd TextChanged,InsertLeave,CursorHoldI <buffer> silent write")
-- Enable md tables
vim.cmd("autocmd FileType markdown silent! TableModeEnable")
vim.cmd("autocmd Filetype pandoc set spell spelllang=")

-- MD
vim.g.table_mode_corner = "|"

-- Latex preview
local sioyek_location = os.getenv("HOME") .. "/dotfiles/scripts/sioyek.AppImage"
local gknapsettings = {
	-- textopdf = 'podman run -i --rm -v .:/app tex pdflatex -jobname "$(basename -s .pdf %outputfile%)" -halt-on-error',
    textopdf = "pdflatex -synctex=1 -halt-on-error -interaction=batchmode %docroot%",
	textopdfbufferasstdin = true,
	mdtopdfviewerlaunch = sioyek_location .. " %outputfile%",
	markdowntopdfviewerlaunch = sioyek_location .. " %outputfile%",
	textopdfviewerlaunch = sioyek_location .. " --new-window %outputfile%",
	textopdfviewerrefresh = "none",
	textopdfforwardjump = sioyek_location
		.. " --reuse-window --forward-search-file %srcfile% --forward-search-line %line% %outputfile%",
    -- textopdfshorterror = "A=%outputfile% ; LOGFILE=\"${A%.pdf}.log\" ; podman run -i --rm -e A=\"$A\" -e LOGFILE=\"$LOGFILE\" -v .:/app tex rubber-info \"$LOGFILE\" 2>&1 | head -n 1",
    textopdfshorterror = "A=%outputfile% ; LOGFILE=\"${A%.pdf}.log\" ; rubber-info \"$LOGFILE\" 2>&1 | head -n 1",
	delay = 100,
}
vim.g.knap_settings = gknapsettings

-- Obsidian
require("obsidian").setup({
	dir = "~/Drive/conspectus/Conspectus",
	new_notes_location = "current_dir",

	-- Optional, completion.
	completion = {
		-- If using nvim-cmp, otherwise set to false
		nvim_cmp = true,
		-- Trigger completion at 2 chars
		min_chars = 2,
		-- Where to put new notes created from completion. Valid options are
		--  * "current_dir" - put new notes in same directory as the current buffer.
		--  * "notes_subdir" - put new notes in the default notes subdirectory.
	},
	ui = {
		enable = false,
	},

	mappings = {},
})

-- Cmp
local cmp = require("cmp")
-- Dark white/gray
vim.cmd("highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#d8dee9")
-- Blue
vim.cmd("highlight! CmpItemAbbrMatch guibg=NONE guifg=#81a1c1")
-- Light blue
vim.cmd("highlight! CmpItemKindVariable guibg=NONE guifg=#88c0d0")
-- Red
vim.cmd("highlight! CmpItemKindFunction guibg=NONE guifg=#bf616a")
-- Purple
vim.cmd("highlight! CmpItemMenu guibg=NONE guifg=#b48ead")

local luasnip = require("luasnip")
cmp.setup({
	window = {
		completion = POPUP,
		documentation = POPUP,
	},
	sources = SOURCES,
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
		["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})

vim.defer_fn(function()
	require("keybindings.latex")
end, 0)
