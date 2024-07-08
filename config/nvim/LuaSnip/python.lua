local ls = require("luasnip")
local snippet = ls.snippet
-- local sn = ls.snippet_node
local t = ls.text_node
local insert = ls.insert_node
-- local f = ls.function_node
-- local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
	snippet(
		{
            trig = "def",
			name = "def",
		},
		fmt(
			[[
def \!(\!) -> \!:
    \!]],
			{
				insert(1),
				insert(2),
				insert(3),
				insert(4),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet({
		trig = ")to",
		name = "-> after function",
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		t(") -> "),
	}),
	snippet(
		{
			trig = "doc",
			name = "docstring",
			wordTrig = false,
		},
		fmt(
			[[
"""\!"""
]],
			{
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet(
		{
			trig = "args",
			name = "args in docstring",
			wordTrig = false,
		},
		fmt(
			[[
Args:
    \!]],
			{
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet(
		{
			trig = "ret",
			name = "return in docstring",
			wordTrig = false,
		},
		fmt(
			[[
Returns:
    \!]],
			{
				insert(1),
			},
			{ delimiters = "\\!" }
		)
	),
	snippet(
		{
			trig = "class",
			name = "class",
		},
		fmt(
			[[
class \!:
    \!]],
			{
				insert(1),
				insert(2),
			},
			{ delimiters = "\\!" }
		)
	),
    snippet(
        {
            trig = "init",
            name = "init",
        },
        fmt(
            [[
def __init__(self, \!):
    \!]],
            {
                insert(1),
                insert(2),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "property",
            name = "property",
        },
        fmt(
            [[
@property
def \!(self) -> \!:
    \!

@\!.setter
def \!(self, value: \!) -> None:
    \!]],
            {
                insert(1),
                insert(2),
                insert(3),
                rep(1),
                rep(1),
                rep(2),
                insert(4),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "^ifmain",
            name = "if __name__ == '__main__'",
            regTrig = true,
            snippetType = "autosnippet",
        },
        fmt(
            [[
if __name__ == '__main__':
    \!]],
            {
                insert(1),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "str",
            name = "__str__",
        },
        fmt(
            [[
def __str__(self) -> str:
    """Return a string representation of the \!.

    Returns:
        str: The string representation of the \!.
    """
    return \!]],
            {
                insert(1),
                rep(1),
                insert(2),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "repr",
            name = "__repr__",
        },
        fmt(
            [[
def __repr__(self) -> str:
    """Return a string representation of the \!.

    Format:
        \!

    Returns:
        str: The string representation of the \!.
    """
    return \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "add",
            name = "__add__",
        },
        fmt(
            [[
def __add__(self, other: \!) -> \!:
    """Add two \!s together.

    Args:
        other (\!): The other \! to add to this one.

    Returns:
        \!: The sum of the two \!s.
    """
    \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "sub",
            name = "__sub__",
        },
        fmt(
            [[
def __sub__(self, other: \!) -> \!:
    """Subtract one \! from another.

    Args:
        other (\!): The other \! to subtract from this one.

    Returns:
        \!: The difference of the two \!s.
    """
    \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "mul",
            name = "__mul__",
        },
        fmt(
            [[
def __mul__(self, other: \!) -> \!:
    """Multiply two \!s together.

    Args:
        other (\!): The other \! to multiply this one by.

    Returns:
        \!: The product of the two \!s.
    """
    \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "div",
            name = "__div__",
        },
        fmt(
            [[
def __div__(self, other: \!) -> \!:
    """Divide one \! by another.

    Args:
        other (\!): The other \! to divide this one by.

    Returns:
        \!: The quotient of the two \!s.
    """
    return \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "truediv",
            name = "__truediv__",
        },
        fmt(
            [[
def __truediv__(self, other: \!) -> \!:
    """Divide one \! by another using true division.

    Args:
        other (\!): The other \! to divide this one by.

    Returns:
        \!: The quotient of the two \!s.
    """
    \!]],
            {
                insert(1),
                insert(2),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                rep(1),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "eq",
            name = "__eq__",
        },
        fmt(
            [[
def __eq__(self, other: object) -> bool:
    """Check if two \!s are equal.

    Args:
        other (\!): The other \! to compare this one to.

    Returns:
        bool: True if the two \!s are equal, False otherwise.
    """
    \!]],
            {
                insert(1),
                rep(1),
                rep(1),
                rep(1),
                insert(2),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "ne",
            name = "__ne__",
        },
        fmt(
            [[
def __ne__(self, other: object) -> bool:
    """Check if two \!s are not equal.

    Args:
        other (\!): The other \! to compare this one to.

    Returns:
        bool: True if the two \!s are not equal, False otherwise.
    """
    \!]],
            {
                insert(1),
                rep(1),
                rep(1),
                rep(1),
                insert(2),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "setitem",
            name = "__setitem__",
        },
        fmt(
            [[
def __setitem__(self, key: \!, value: \!) -> None:
    \!]],
            {
                insert(1),
                insert(2),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "getitem",
            name = "__getitem__",
        },
        fmt(
            [[
def __getitem__(self, key: \!) -> \!:
    \!]],
            {
                insert(1),
                insert(2),
                insert(3),
            },
            { delimiters = "\\!" }
        )
    ),
}
