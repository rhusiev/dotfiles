require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/LuaSnip/" })

local ls = require("luasnip")
local snippet = ls.snippet
-- local text = ls.text_node
local insert = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
ls.config.setup({
	enable_autosnippets = true,
	store_selection_keys = "<M-m>",
})
-- Snippet to make a closing curly bracket and newline after the opening curly bracket
-- Only work when the end of line
ls.add_snippets("all", {
	snippet(
		{
			-- "{" in the end of line
			trig = "{",
			name = "curly_bracket",
            wordTrig = false,
		},
		fmt(
			[[
{
    <>
}
]],
			{ insert(1) },
			{ delimiters = "<>" }
		)
	),
	snippet(
		{
			trig = "(",
			name = "parenthesis",
			wordTrig = false,
		},
		fmt(
			[[
(
    <>
)
]],
			{ insert(1) },
			{ delimiters = "<>" }
		)
	),
})
