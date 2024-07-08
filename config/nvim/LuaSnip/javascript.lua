local ls = require("luasnip")
local snippet = ls.snippet
-- local sn = ls.snippet_node
local text = ls.text_node
local insert = ls.insert_node
-- local f = ls.function_node
-- local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
	snippet({
		trig = "type",
		name = "type",
	}, {
		text("@type {"),
		insert(1),
		text("}"),
		insert(2),
	}),
	snippet({
		trig = "const",
		name = "const",
	}, {
		text("@const {"),
		insert(1),
		text("}"),
		insert(2),
	}),
	snippet({
		trig = "par",
		name = "param",
	}, {
		text("@param {"),
		insert(1),
		text("} "),
		insert(2),
	}),
    snippet({
        trig = "ret",
        name = "return",
    }, {
        text("@return {"),
        insert(1),
        text("} "),
        insert(2),
    }),
    snippet({
        trig = "tdef",
        name = "typedef",
    }, {
        text("@typedef {"),
        insert(1),
        text("} "),
        insert(2),
    }),
    snippet({
        trig = "prop",
        name = "property",
    }, {
        text("@property {"),
        insert(1),
        text("} "),
        insert(2),
    }),
	snippet(
		{
			trig = "doc",
			name = "jsdoc",
		},
		fmt(
			[[
/**
    * \!
 */\!
]],
			{
				insert(1),
				insert(2),
			},
			{ delimiters = "\\!" }
		)
	),
}
