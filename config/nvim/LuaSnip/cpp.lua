local ls = require("luasnip")
local snippet = ls.snippet
-- local sn = ls.snippet_node
-- local t = ls.text_node
local insert = ls.insert_node
local func = ls.function_node
-- local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
    snippet(
		{
			trig = "inc",
			name = "include guard",
		},
		fmt(
			[[
#pragma once
#ifndef INCLUDE_\!_HPP_
#define INCLUDE_\!_HPP_

\!

#endif // INCLUDE_\!_HPP_
]],
			{
				-- func(function(args, snip)
				func(function(_, _)
					local filename = vim.fn.expand("%:t:r")
                    filename = string.upper(filename)
					return { filename }
				end),
				func(function(_, _)
					local filename = vim.fn.expand("%:t:r")
                    filename = string.upper(filename)
					return { filename }
				end),
				insert(1),
				func(function(_, _)
					local filename = vim.fn.expand("%:t:r")
                    filename = string.upper(filename)
					return { filename }
				end),
			},
			{ delimiters = "\\!" }
		)
	),
}
