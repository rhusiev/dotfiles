local cmp = require("cmp")
local compare = cmp.config.compare

-- Enable tailwind colors
local tailwindcss_colorizer_cmp
if vim.g.is_code then
	tailwindcss_colorizer_cmp = require("tailwindcss-colorizer-cmp")
	tailwindcss_colorizer_cmp.setup({
		color_square_width = 1,
	})
end

local cmp_kinds = {
	Text = " ",
	Method = "󰊕 ",
	Function = "󰊕 ",
	Constructor = " ",
	Field = "󰭸 ",
	Variable = " ",
	Class = "󱡠 ",
	Interface = " ",
	Module = " ",
	Property = " ",
	Unit = " ",
	Value = "󰇽 ",
	Enum = " ",
	Keyword = " ",
	Snippet = " ",
	Color = " ",
	File = " ",
	Reference = " ",
	Folder = " ",
	EnumMember = " ",
	Constant = " ",
	Struct = " ",
	Event = " ",
	Operator = " ",
	TypeParameter = " ",
}

cmp.setup({
	preselect = cmp.PreselectMode.None, -- Even if lsp says, do not autoselect first item
	-- performance = {
	--     max_view_entries = 18,
	-- },
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
		end,
	},
	window = {
		completion = POPUP,
		documentation = POPUP,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
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
			elseif require("luasnip").jumpable(-1) then
				require("luasnip").jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
		["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
	sources = cmp.config.sources(SOURCES),
	formatting = {
        expandable_indicator = true,
		fields = { "kind", "abbr", "menu" },
		format = function(_, vim_item)
			vim_item.kind = (cmp_kinds[vim_item.kind] or vim_item.kind)

			if vim_item.menu then
				vim_item.menu = "  " .. vim_item.menu
			end
			if vim.g.is_code then
				return tailwindcss_colorizer_cmp.formatter(_, vim_item)
			end
			return vim_item
		end,
	},
	sorting = {
		priority_weight = 1.0,
		comparators = {
			compare.score,
			compare.recently_used,
			compare.locality,
		},
	},
})

-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, {
		{ name = "buffer" },
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
		{ name = "cmdline" },
	}, {
		{ name = "path" },
	}),
})

-- Completion highlights
require("theme.completion_highlights")

vim.api.nvim_create_user_command("CmpDisable", function()
	cmp.setup.buffer({ enabled = false })
	print("Disabled cmp")
end, {})
vim.api.nvim_create_user_command("CmpEnable", function()
	cmp.setup.buffer({ enabled = true })
	print("Enabled cmp")
end, {})
