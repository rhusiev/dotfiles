require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
		selection_modes = {
			["@parameter.outer"] = "v",
			["@function.outer"] = "V",
			["@class.outer"] = "V",
		},
		include_surrounding_whitespace = false,
	},
})

local select = require("nvim-treesitter-textobjects.select").select_textobject
local move = require("nvim-treesitter-textobjects.move")

local select_maps = {
	["af"] = "@function.outer",
	["if"] = "@function.inner",
	["ac"] = "@class.outer",
	["ic"] = "@class.inner",
	["il"] = "@loop.inner",
	["al"] = "@loop.outer",
	["ii"] = "@conditional.inner",
	["ai"] = "@conditional.outer",
	["it"] = "@comment.outer",
	["at"] = "@comment.outer",
	["ia"] = "@parameter.inner",
	["aa"] = "@parameter.outer",
}
for key, query in pairs(select_maps) do
	vim.keymap.set({ "x", "o" }, key, function()
		select(query, "textobjects")
	end, { silent = true })
end

local move_maps = {
	goto_next_start = {
		["]m"] = "@function.outer",
		["]["] = "@class.outer",
		["]l"] = "@loop.outer",
		["]t"] = "@comment.outer",
		["]a"] = "@parameter.inner",
	},
	goto_next_end = {
		["]M"] = "@function.outer",
		["]]"] = "@class.outer",
		["]L"] = "@loop.outer",
		["]T"] = "@comment.outer",
		["]A"] = "@parameter.inner",
	},
	goto_previous_start = {
		["[m"] = "@function.outer",
		["[["] = "@class.outer",
		["[l"] = "@loop.outer",
		["[t"] = "@comment.outer",
		["[a"] = "@parameter.inner",
	},
	goto_previous_end = {
		["[M"] = "@function.outer",
		["[]"] = "@class.outer",
		["[L"] = "@loop.outer",
		["[T"] = "@comment.outer",
		["[A"] = "@parameter.inner",
	},
}
for fn_name, maps in pairs(move_maps) do
	for key, query in pairs(maps) do
		vim.keymap.set({ "n", "x", "o" }, key, function()
			move[fn_name](query, "textobjects")
		end, { silent = true })
	end
end
