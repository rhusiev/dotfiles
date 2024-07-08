local ls = require("luasnip")
local snippet = ls.snippet
-- local sn = ls.snippet_node
-- local t = ls.text_node
local insert = ls.insert_node
local func = ls.function_node
-- local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local rep = require("luasnip.extras").rep

return {
    snippet(
        {
            trig = "html",
            name = "html",
        },
        fmt(
            [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>\&</title>
</head>
<body>
    \&
</body>
</html>]],
            {
                insert(1),
                insert(2),
            },
            { delimiters = "\\&" }
        )
    ),
    snippet(
        {
            trig = "<(%w*)(%s.*)>",
            regTrig = true,
            name = "html tag with attributes",
        },
        fmt(
            [[
<\!\!>
    \!
</\!>
]],
            {
                func(function(_, snip)
                    return snip.captures[1]
                end),
                func(function(_, snip)
                    return snip.captures[2]
                end),
                insert(1),
                func(function(_, snip)
                    return snip.captures[1]
                end),
            },
            { delimiters = "\\!" }
        )
    ),
    snippet(
        {
            trig = "<(%w*)>",
            regTrig = true,
            name = "html tag",
        },
        fmt(
            [[
<\!>
    \!
</\!>
]],
            {
                func(function(_, snip)
                    return snip.captures[1]
                end),
                insert(1),
                func(function(_, snip)
                    return snip.captures[1]
                end),
            },
            { delimiters = "\\!" }
        )
    ),
}
