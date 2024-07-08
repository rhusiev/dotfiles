local ls = require("luasnip")
local snippet = ls.snippet
-- local sn = ls.snippet_node
local t = ls.text_node
local insert = ls.insert_node
local f = ls.function_node
-- local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local rep = require("luasnip.extras").rep

return {
	snippet(
        {
            trig = "pc",
            name = "public class",
        },
        fmt(
            [[
public class \! {
    \!
}
]],
            {
                insert(1),
                insert(2),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
		{
			trig = "pmc",
			name = "public main class",
		},
		fmt(
			[[
public class \! {
    public static void main(String[] args) {
        \!
    }
}
]],
			{
				-- f(function(args, snip)
				f(function(_, _)
					local filename = vim.fn.expand("%:t:r")
					return { filename }
				end),
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
    snippet(
        {
            trig = "psvm",
            name = "public static void main",
        },
        fmt(
            [[
public static void main(String[] args) {
    \!
}
]],
            {
                insert(1),
            },
            { delimiters = "\\!" }
        )
    ),
	snippet(
		{
			trig = "prln",
			name = "println",
		},
		fmt(
			[[
System.out.println(\!);
]],
			{
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet(
		{
			trig = "pr",
			name = "print",
		},
		fmt(
			[[
System.out.print(\!);
]],
			{
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet({
		trig = "scanner",
		name = "scanner",
	}, {
		t("Scanner scanner = new Scanner(System.in);"),
	}),
}
