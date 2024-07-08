local ls = require("luasnip")
local snippet = ls.snippet
local sn = ls.snippet_node
local text = ls.text_node
local insert = ls.insert_node
local f = ls.function_node
local dynamic = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local rep = require("luasnip.extras").rep
local TWO_LETTER = {
	ln = "\\ln",
	le = "\\le",
	ge = "\\ge",
	pd = "\\pd",
}
local THREE_LETTER_FUNCTIONS = {
	int = "\\int",
	sup = "\\sup",
	inf = "\\inf",
	min = "\\min",
	max = "\\max",
	sin = "\\sin",
	cos = "\\cos",
	tan = "\\tan",
	cot = "\\cot",
	csc = "\\csc",
	log = "\\log",
	exp = "\\exp",
	gcd = "\\gcd",
	mid = "\\mid",
	neq = "\\neq",
	hat = "\\hat",
	vec = "\\vec",
	def = "\\def",
	cup = "\\cup",
	cap = "\\cap",
	lor = "\\lor",
	sim = "\\sim",
}
local SIX_LETTER_FUNCTIONS = {
	arcsin = "\\arcsin",
	arccos = "\\arccos",
	arctan = "\\arctan",
	arccot = "\\arccot",
	arccsc = "\\arccsc",
	arcsec = "\\arcsec",
}
local GREEK = {
	all = "\\alpha",
	bee = "\\beta",
	gaa = "\\gamma",
	dee = "\\delta",
	epp = "\\varepsilon",
	zee = "\\zeta",
	ett = "\\eta",
	thh = "\\theta",
	ioo = "\\iota",
	kaa = "\\kappa",
	laa = "\\lambda",
	muu = "\\mu",
	nuu = "\\nu",
	xii = "\\xi",
	-- omm = "\\omicron",
	pii = "\\pi",
	rhh = "\\rho",
	sii = "\\sigma",
	taa = "\\tau",
	upp = "\\upsilon",
	phh = "\\varphi",
	chh = "\\chi",
	pss = "\\psi",
	omm = "\\omega",
	Gaa = "\\Gamma",
	Dee = "\\Delta",
	Thh = "\\Theta",
	Laa = "\\Lambda",
	Xii = "\\Xi",
	Pii = "\\Pi",
	Sii = "\\Sigma",
	Upp = "\\Upsilon",
	Phh = "\\Phi",
	Pss = "\\Psi",
	Omm = "\\Omega",
}

local function in_mathzone()
	local synstackids = vim.api.nvim_call_function("synstack", { vim.fn.line("."), vim.fn.col(".") - 1 })
	local texMathZoneIds = {}
	local texIgnoreMathZoneIds = {}

	for _, zone in ipairs({
		"texMathZoneA",
		"texMathZoneAS",
		"texMathZoneB",
		"texMathZoneBS",
		"texMathZoneC",
		"texMathZoneCS",
		"texMathZoneD",
		"texMathZoneDS",
		"texMathZoneV",
		"texMathZoneW",
		"texMathZoneX",
		"texMathZoneY",
		"texMathZoneZ",
	}) do
		local id = vim.api.nvim_eval("hlID('" .. zone .. "')")
		table.insert(texMathZoneIds, id)
	end

	for _, zone in ipairs({ "texMathText" }) do
		local id = vim.api.nvim_eval("hlID('" .. zone .. "')")
		table.insert(texIgnoreMathZoneIds, id)
	end

	local texMathZoneIdsSet = {}
	for _, id in ipairs(texMathZoneIds) do
		texMathZoneIdsSet[id] = true
	end

	local texIgnoreMathZoneIdsSet = {}
	for _, id in ipairs(texIgnoreMathZoneIds) do
		texIgnoreMathZoneIdsSet[id] = true
	end

	local math_not_ignored = false

	for _, id in ipairs(synstackids) do
		if texIgnoreMathZoneIdsSet[id] then
			return false
		end
		if texMathZoneIdsSet[id] then
			math_not_ignored = true
		end
	end

	return math_not_ignored
end

-- local get_visual = function(args, parent)
local get_visual = function(_, parent)
    vim.print(#parent.snippet.env.LS_SELECT_RAW)
	if #parent.snippet.env.LS_SELECT_RAW > 0 then
		return sn(nil, insert(1, parent.snippet.env.LS_SELECT_RAW))
	else -- If LS_SELECT_RAW is empty, return a blank insert node
		return sn(nil, insert(1))
	end
end

return {
	--
	-- Outline
	--
	snippet(
		{
			trig = "fla",
			name = "flalign",
			condition = in_mathzone,
			snippetType = "autosnippet",
		},
		fmt(
			[[
              \begin{flalign}
                  <>
              \end{flalign}
            ]],
			{
				insert(1),
			},
			{ delimiters = "<>" }
		)
	),
	snippet(
		{
			trig = "$$",
			name = "$$ to block math",
			priority = 200,
		},
		fmt(
			[[
            $$
            <>
            $$
            ]],
			{
                insert(1),
			},
			{ delimiters = "<>" }
		)
	),
	snippet({
		trig = "$",
		name = "$ to inline math",
		priority = 200,
	}, {
		text("$\\displaystyle "),
		insert(1),
		text("$"),
	}),
	snippet(
		{
			trig = "$$$",
			name = "$$$ to $$ and flalign",
			priority = 300,
		},
		fmt(
			[[
            $$
            \begin{flalign}
                & <>
            \end{flalign}
            $$
            ]],
			{
				insert(1),
			},
			{ delimiters = "<>" }
		)
	),
	snippet({
		trig = "  ",
		name = "auto space to \\\\",
		priority = 200,
		condition = in_mathzone,
		wordTrig = false,
	}, {
		text(" \\\\ "),
	}),
	snippet({
		trig = " ",
		name = "auto space to &",
		priority = 100,
		condition = in_mathzone,
		wordTrig = false,
	}, {
		text(" & "),
	}),
	snippet(
		{
			trig = "case",
			name = "auto cases",
			condition = in_mathzone,
			snippetType = "autosnippet",
		},
		fmt(
			[[
              \begin{cases}
                  <>
              \end{cases}
            ]],
			{
				insert(1),
			},
			{ delimiters = "<>" }
		)
	),
	snippet({
		trig = "bcase",
		name = "auto bcase",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\bcase{"),
		insert(1),
		text("}"),
	}),
	snippet(
		{
			trig = "==",
			name = "double equal",
			condition = in_mathzone,
		},
		fmt(
			[[
             = \\
            &
            ]],
			{}
		)
	),
	snippet(
		{
			trig = "\\\\",
			name = "double backslash at the end of line",
			condition = in_mathzone,
		},
		fmt(
			[[
            \\
            &
            ]],
			{}
		)
	),
	snippet({
		trig = "\\",
		name = "backslash",
		condition = in_mathzone,
	}, { text("\\backslash") }),
	snippet(
		{
			trig = "&&",
			condition = in_mathzone,
		},
		fmt(
			[[
            &&\\
            &
            ]],
			{}
		)
	),
	snippet({
		trig = "ds",
		name = "displaystyle",
		condition = in_mathzone,
	}, { text("\\displaystyle") }),
	snippet({
		trig = "lll",
		name = "limits",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, { text("\\limits") }),
	--
	-- Draw on top of something
	--
	snippet({
		trig = "c",
		name = "cancel",
		condition = in_mathzone,
	}, {
		text("\\cancel{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "not",
		name = "not",
		condition = in_mathzone,
	}, { text("\\not") }),
	--
	-- Fractions
	--
	snippet({
		trig = "//",
		name = "fraction of double slash",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\frac{"),
		insert(1),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "/",
		name = "fraction of visual selection",
		condition = in_mathzone,
	}, {
		text("\\frac{"),
        dynamic(1, get_visual),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "(%b())/",
		regTrig = true,
		name = "frac after parenthesis",
		condition = in_mathzone,
	}, {
		text("\\frac{"),
		f(function(_, snip)
			return snip.captures[1]:sub(2, -2)
		end),
		insert(1),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "(%S+)/",
		regTrig = true,
		name = "frac after continious word",
		condition = in_mathzone,
	}, {
		text("\\frac{"),
		f(function(_, snip)
			return snip.captures[1]
		end),
		insert(1),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "pmo",
		name = "pmod",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\pmod{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	--
	-- Sub, sup
	--
	snippet({
		trig = "--",
		name = "superscript",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("^"),
	}),
	snippet({
		trig = "__",
		name = "long subscript",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "^-",
		name = "long superscript",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("^{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "^(",
		name = "superscript with parenthesis",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("^{("),
		insert(1),
		text(")}"),
	}),
	snippet({
		trig = "(%a)(%d)",
		regTrig = true,
		name = "auto subscript",
		condition = in_mathzone,
	}, {
		f(function(_, snip)
			return snip.captures[1]
		end),
		text("_"),
		f(function(_, snip)
			return snip.captures[2]
		end),
	}),
	snippet({
		trig = "(%a)_(%d%d)",
		regTrig = true,
		name = "auto subscript 2",
		condition = in_mathzone,
	}, {
		f(function(_, snip)
			return snip.captures[1]
		end),
		text("_{"),
		f(function(_, snip)
			return snip.captures[2]
		end),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "nnn",
		name = "_n",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_n"),
	}),
	snippet({
		trig = "mmm",
		name = "_m",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_m"),
	}),
	snippet({
		trig = "kkk",
		name = "_k",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_k"),
	}),
	snippet({
		trig = "iii",
		name = "_i",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_i"),
	}),
	snippet({
		trig = "\\xii",
		name = "x_i",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("x_i"),
	}),
	snippet({
		trig = "jjj",
		name = "_j",
		condition = in_mathzone,
		wordTrig = false,
		snippetType = "autosnippet",
	}, {
		text("_j"),
	}),
	--
	-- Braces
	--
	snippet({
		trig = "ll",
		name = "\\l",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l"),
	}),
	snippet({
		trig = "rr",
		name = "\\r",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\r"),
	}),
	snippet({
		trig = "cl",
		name = "ceil",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l\\lceil"),
        dynamic(1, get_visual),
		text("\\r\\rceil"),
	}),
	snippet({
		trig = "fl",
		name = "floor",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l\\lfloor"),
        dynamic(1, get_visual),
		text("\\r\\rfloor"),
	}),
	snippet({
		trig = "lcl",
		name = "left ceiling",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l\\lceil"),
	}),
	snippet({
		trig = "rcl",
		name = "right ceiling",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\r\\rceil"),
	}),
	snippet({
		trig = "lfl",
		name = "left floor",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l\\lfloor "),
	}),
	snippet({
		trig = "rfl",
		name = "right floor",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\r\\rfloor"),
	}),
	snippet({
		trig = "()",
		name = "left( right)",
		condition = in_mathzone,
	}, {
		text("\\l("),
        dynamic(1, get_visual),
		text("\\r)"),
	}),
	snippet({
		trig = "[]",
		name = "left[ right]",
		condition = in_mathzone,
	}, {
		text("\\l["),
        dynamic(1, get_visual),
		text("\\r]"),
	}),
	snippet({
		trig = "{}",
		name = "left{ right}",
		condition = in_mathzone,
	}, {
		text("\\l\\{"),
        dynamic(1, get_visual),
		text("\\r\\}"),
	}),
	snippet({
		trig = "||",
		name = "left| right|",
		condition = in_mathzone,
	}, {
		text("\\l|"),
        dynamic(1, get_visual),
		text("\\r|"),
	}),
	snippet({
		trig = "<>",
		name = "left< right>",
		condition = in_mathzone,
	}, {
		text("\\l<"),
        dynamic(1, get_visual),
		text("\\r>"),
	}),
	snippet({
		trig = "((",
		name = "left(",
		condition = in_mathzone,
	}, {
		text("\\l("),
	}),
	snippet({
		trig = "))",
		name = "right)",
		condition = in_mathzone,
	}, {
		text("\\r)"),
	}),
	snippet({
		trig = "[[",
		name = "left[",
		condition = in_mathzone,
	}, {
		text("\\l["),
	}),
	snippet({
		trig = "]]",
		name = "right]",
		condition = in_mathzone,
	}, {
		text("\\r]"),
	}),
	snippet({
		trig = "{{",
		name = "left{",
		condition = in_mathzone,
	}, {
		text("\\l\\{"),
	}),
	snippet({
		trig = "}}",
		name = "right}",
		condition = in_mathzone,
	}, {
		text("\\r\\}"),
	}),
	snippet({
		trig = "l|",
		name = "left|",
		condition = in_mathzone,
	}, {
		text("\\l|"),
	}),
	snippet({
		trig = "r|",
		name = "right|",
		condition = in_mathzone,
	}, {
		text("\\r|"),
	}),
	snippet({
		trig = "<<",
		name = "left<",
		condition = in_mathzone,
	}, {
		text("\\l<"),
	}),
	snippet({
		trig = ">>",
		name = "right>",
		condition = in_mathzone,
	}, {
		text("\\r>"),
	}),
	snippet({
		trig = "lag",
		name = "left angle",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\l\\langle"),
	}),
	snippet({
		trig = "rag",
		name = "right angle",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text(" \\r\\rangle"),
	}),
	snippet({
		trig = "\\|",
		name = "vert",
		condition = in_mathzone,
	}, {
		text("\\Vert"),
	}),
	--
	-- Matrices
	--
	snippet({
		trig = "pmat",
		name = "pmatrix",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\begin{pmatrix}"),
		insert(1),
		text("\\end{pmatrix}"),
	}),
	snippet({
		trig = "bmat",
		name = "bmatrix",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\begin{bmatrix}"),
		insert(1),
		text("\\end{bmatrix}"),
	}),
	snippet({
		trig = "vmat",
		name = "vmatrix",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\begin{vmatrix}"),
		insert(1),
		text("\\end{vmatrix}"),
	}),
	snippet({
		trig = "\\vect",
		name = "vector",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\vect{"),
		insert(1),
		text("}"),
	}),
	--
	-- Operators
	--
	snippet({
		trig = "sum",
		name = "sum",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\sum_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "prod",
		name = "prod",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\prod_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "bcu",
		name = "bigcup",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\bigcup_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "bcap",
		name = "bigcap",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\bigcap_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "\\intt",
		name = "int with limits",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\int_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "iint",
		name = "iint",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\iint"),
	}),
	snippet({
		trig = "\\iintt",
		name = "iint with limits",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\iint_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "_int",
		name = "iiint",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\iiint"),
	}),
	snippet({
		trig = "\\iiintt",
		name = "iiint with limits",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\iiint_{"),
		insert(1),
		text("}^{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "sq",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\sqrt{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "rt",
		name = "sqrt[n]",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\sqrt["),
		insert(1),
		text("]{"),
        dynamic(2, get_visual),
		text("}"),
	}),
	snippet({
		trig = "lim",
		name = "lim",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\lim_{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "vli",
		name = "varliminf",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\varliminf_{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "vls",
		name = "varlimsup",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\varlimsup_{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "mlim",
		name = "multivariable lim",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\mlim{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "grad",
		name = "grad",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\grad"),
	}),
	--
	-- Operations
	--
	snippet({
		trig = "cd",
		name = "cdot",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\cdot"),
	}),
	snippet({
		trig = "ti",
		name = "times",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\times"),
	}),
	snippet({
		trig = "prec",
		name = "prec",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\prec"),
	}),
	snippet({
		trig = "succ",
		name = "succ",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\succ"),
	}),
	snippet({
		trig = "\\prece",
		name = "preceq",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\preceq"),
	}),
	snippet({
		trig = "\\succe",
		name = "succeq",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\succeq"),
	}),
	snippet({
		trig = "eq",
		name = "equiv",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\equiv"),
	}),
	snippet({
		trig = "neq",
		name = "nequiv",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\nequiv"),
	}),
    snippet({
        trig = "prop",
        name = "propto",
        condition = in_mathzone,
        snippetType = "autosnippet",
    }, {
        text("\\propto"),
    }),
	--
	-- Under, over
	--
	snippet({
		trig = "ul",
		name = "underline",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\underline{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "ol",
		name = "overline",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overline{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "ub",
		name = "underbrace",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\underbrace{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "ob",
		name = "overbrace",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overbrace{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "oa",
		name = "overrightarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overrightarrow{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "ua",
		name = "underrightarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\underrightarrow{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "wtil",
		name = "widetilde",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\widetilde{"),
        dynamic(1, get_visual),
		text("}"),
	}),
    snippet({
        trig = "what",
        name = "widehat",
        condition = in_mathzone,
        snippetType = "autosnippet",
    }, {
        text("\\widehat{"),
        dynamic(1, get_visual),
        text("}"),
    }),
	snippet({
		trig = "os",
		name = "overset",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overset{"),
		insert(1),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "us",
		name = "underset",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\underset{"),
		insert(1),
		text("}{"),
		insert(2),
		text("}"),
	}),
	snippet({
		trig = "ous",
		name = "overunderset",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overset{"),
		insert(1),
		text("}{"),
		text("\\underset{"),
		insert(2),
		text("}{"),
		insert(3),
		text("}}"),
	}),
	snippet({
		trig = "ot",
		name = "overbracket",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\overbracket{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "ut",
		name = "underbracket",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\underbracket{"),
		insert(1),
		text("}"),
	}),
	snippet({
		trig = "CM",
		name = "comment",
		condition = in_mathzone,
        snippetType = "autosnippet",
	}, {
		text("\\cm{"),
		insert(1),
		text("}"),
		text("{"),
        dynamic(2, get_visual),
		text("}"),
		insert(3),
	}),
	snippet({
		trig = "CMU",
		name = "comment under",
		condition = in_mathzone,
	}, {
		text("\\cmu{"),
		insert(1),
		text("}"),
		text("{"),
        dynamic(2, get_visual),
		text("}"),
		insert(3),
	}),
	snippet({
		trig = "CMM",
		name = "comment math",
		condition = in_mathzone,
	}, {
		text("\\cmm{"),
		insert(1),
		text("}"),
		text("{"),
        dynamic(2, get_visual),
		text("}"),
		insert(3),
	}),
	snippet({
		trig = "CMMU",
		name = "comment math under",
		condition = in_mathzone,
	}, {
		text("\\cmmu{"),
		insert(1),
		text("}"),
		text("{"),
        dynamic(2, get_visual),
		text("}"),
		insert(3),
	}),
	snippet({
		trig = "stack",
		name = "substack",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\substack{"),
		insert(1),
		text("}"),
	}),
	--
	-- Logical, sets
	--
	snippet({
		trig = "set",
		name = "set",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\{"),
		insert(1),
		text("\\}"),
	}),
	snippet({
		trig = "ss",
		name = "subset",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\subset"),
	}),
	snippet({
		trig = "\\subsete",
		name = "subseteq",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\subseteq"),
	}),
	snippet({
		trig = "nss",
		name = "not subset",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\not\\subset"),
	}),
	snippet({
		trig = "\\not\\subsete",
		name = "not subseteq",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\not\\subseteq"),
	}),
	snippet({
		trig = "nin",
		name = "not in",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\not\\in"),
	}),
	snippet({
		trig = "inn",
		name = "in",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\in"),
	}),
	snippet({
		trig = "lan",
		name = "land",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\land"),
	}),
	snippet({
		trig = "lno",
		name = "lnot",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\lnot"),
	}),
	snippet({
		trig = "xor",
		name = "xor",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\oplus"),
	}),
	snippet({
		trig = "ex",
		name = "exists",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\exists"),
	}),
	snippet({
		trig = "fa",
		name = "forall",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\forall"),
	}),
	--
	-- Special numbers, symbols
	--
	snippet({
		trig = "oo",
		name = "infinity",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\infty"),
	}),
	snippet({
		trig = "vn",
		name = "varnothing",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\varnothing"),
	}),
	snippet({
		trig = "naa",
		name = "nabla",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\nabla"),
	}),
	snippet({
		trig = "RR",
		name = "real",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\RR"),
	}),
	snippet({
		trig = "QQ",
		name = "rational",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\QQ"),
	}),
	snippet({
		trig = "ZZ",
		name = "integer",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\ZZ"),
	}),
	snippet({
		trig = "NN",
		name = "natural",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\NN"),
	}),
	snippet({
		trig = "heart",
		name = "heartsuit",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\heartsuit"),
	}),
	snippet({
		trig = "leaf",
		name = "spadesuit",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\spadesuit"),
	}),
	--
	-- Text style
	--
	snippet({
		trig = "te",
		name = "text",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\text{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "bf",
		name = "textbf",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\textbf{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "it",
		name = "textit",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\textit{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "mca",
		name = "mathcal",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\mathcal{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "mbb",
		name = "mathbb",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\mathbb{"),
        dynamic(1, get_visual),
		text("}"),
	}),
	snippet({
		trig = "mbf",
		name = "mathbf",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\mathbf{"),
        dynamic(1, get_visual),
		text("}"),
	}),
    snippet({
        trig = "mrm",
        name = "mathrm",
        condition = in_mathzone,
        snippetType = "autosnippet",
    }, {
        text("\\mathrm{"),
        dynamic(1, get_visual),
        text("}"),
    }),
	--
	-- Arrows
	--
	snippet({
		trig = "rar",
		name = "rightarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\rightarrow"),
	}),
	snippet({
		trig = "lar",
		name = "leftarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\leftarrow"),
	}),
	snippet({
		trig = "uar",
		name = "uparrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\uparrow"),
	}),
	snippet({
		trig = "dar",
		name = "downarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\downarrow"),
	}),
	snippet({
		trig = "Rar",
		name = "Rightarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\Rightarrow"),
	}),
	snippet({
		trig = "Lar",
		name = "Leftarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\Leftarrow"),
	}),
	snippet({
		trig = "Uar",
		name = "Uparrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\Uparrow"),
	}),
	snippet({
		trig = "Dar",
		name = "Downarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\Downarrow"),
	}),
	snippet({
		trig = "rrar",
		name = "rightrightarrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\rightrightarrows"),
	}),
	snippet({
		trig = "llar",
		name = "leftleftarrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\leftleftarrows"),
	}),
	snippet({
		trig = "uuar",
		name = "upuparrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\upuparrows"),
	}),
	snippet({
		trig = "ddar",
		name = "downdownarrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\downdownarrows"),
	}),
	snippet({
		trig = "lrar",
		name = "leftrightarrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\leftrightarrows"),
	}),
	snippet({
		trig = "udar",
		name = "updownarrows",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\updownarrows"),
	}),
	snippet({
		trig = "Lrar",
		name = "Leftrightarrow",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\Leftrightarrow"),
	}),
	snippet({
		trig = "to",
		name = "to",
		condition = in_mathzone,
		snippetType = "autosnippet",
	}, {
		text("\\to"),
	}),
	--
	-- From dict
	--
	snippet({
		trig = "(%a%a)",
		name = "2-letter",
		condition = in_mathzone,
		snippetType = "autosnippet",
		regTrig = true,
	}, {
		f(function(_, snip)
			text = snip.captures[1]
			local two_letter = TWO_LETTER[text]
			if two_letter ~= nil then
				return two_letter
			end
			return text
		end),
	}),
	snippet({
		trig = "(%a%a%a)",
		name = "3-letter functions",
		condition = in_mathzone,
		snippetType = "autosnippet",
		regTrig = true,
	}, {
		f(function(_, snip)
			text = snip.captures[1]
			-- Check whether there is a key in GREEK that matches the text
			local greek = GREEK[text]
			if greek ~= nil then
				return greek
			end
			-- Then if there is a function
			local three_letter = THREE_LETTER_FUNCTIONS[text]
			if three_letter ~= nil then
				return three_letter
			end
			return text
		end),
	}),
	snippet({
		trig = "(%a%a%a%a%a%a)",
		name = "6-letter functions",
		condition = in_mathzone,
		snippetType = "autosnippet",
		regTrig = true,
	}, {
		f(function(_, snip)
			text = snip.captures[1]
			local six_letter = SIX_LETTER_FUNCTIONS[text]
			if six_letter ~= nil then
				return six_letter
			end
			return text
		end),
	}),
}
