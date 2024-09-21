vim.g.codeium_disable_bindings = 1
vim.g.codeium_idle_delay = 100

KEYMAP("i", "<C-l>", function()
	return vim.fn["codeium#Accept"]()
end, { remap = true, expr = true, silent = true, desc = "Codeium: accept all" })
KEYMAP("i", "<C-д>", function()
	return vim.fn["codeium#Accept"]()
end, { remap = true, expr = true, silent = true, desc = "Codeium: accept all" })

KEYMAP("i", "<C-x>", function()
	return vim.fn["codeium#Clear"]()
end, { remap = true, expr = true, silent = true, desc = "Codeium: clear" })
--
KEYMAP("i", "<M-]>", function()
	return vim.fn["codeium#CycleCompletions"](1)
end, { remap = true, expr = true, silent = true, desc = "Codeium: next completion" })
KEYMAP("i", "<M-[>", function()
	return vim.fn["codeium#CycleCompletions"](-1)
end, { remap = true, expr = true, silent = true, desc = "Codeium: prev completion" })

--
-- Custom bindings for find and till characters
-- And to accept word and line
--
-- Functions
local last_called = { func = nil, char = nil }

local function getCodeiumCompletions()
	local status, completion = pcall(function()
		return vim.api.nvim_eval("b:_codeium_completions.items[b:_codeium_completions.index].completionParts[0].text")
	end)
	if status then
		return completion
	else
		return ""
	end
end

local function till(char)
	if not char then
		char = vim.fn.getcharstr()
	end
	local text = getCodeiumCompletions()

	local _, char_idx = string.find(text, char, 1, true)
	if char_idx then
		text = string.sub(text, 1, char_idx - 1)
	else
		text = ""
	end
	last_called = { func = till, char = char }
	return text
end

local function find(char)
	if not char then
		char = vim.fn.getcharstr()
	end
	local text = getCodeiumCompletions()

	local _, char_idx = string.find(text, char, 1, true)
	if char_idx then
		text = string.sub(text, 1, char_idx)
	else
		text = ""
	end
	last_called = { func = find, char = char }
	return text
end

local function call_last()
	if last_called.func then
		last_called.func(last_called.char)
	end
end

local function accept_one_line()
	local text = getCodeiumCompletions()
	return vim.fn.split(text, [[[\n]\zs]])[1] .. "\n"
end
local function accept_one_word()
	local text = getCodeiumCompletions()
    return vim.fn.split(text, [[\s\zs]])[1]
end
local function accept_all()
    return getCodeiumCompletions()
end

-- Bindings themselves
KEYMAP("i", "<C-`>t", till, {
	desc = "Codeium: accept [t]ill",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-'>е", till, {
	desc = "Codeium: accept [t]ill",
	silent = true,
	expr = true,
	replace_keycodes = false,
})

KEYMAP("i", "<C-`>f", find, {
	desc = "Codeium: accept [f]ind",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-'>а", find, {
	desc = "Codeium: accept [f]ind",
	silent = true,
	expr = true,
	replace_keycodes = false,
})

KEYMAP("i", "<C-`>;", call_last, {
	desc = "Codeium: accept last",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-'>ж", call_last, {
	desc = "Codeium: accept last",
	silent = true,
	expr = true,
	replace_keycodes = false,
})

KEYMAP("i", "<C-j>", accept_one_word, {
	desc = "Codeium: accept word",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-л>", accept_one_line, {
	desc = "Codeium: accept word",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-о>", accept_one_word, {
	desc = "Codeium: accept word",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
KEYMAP("i", "<C-k>", accept_one_line, {
	desc = "Codeium: accept word",
	silent = true,
	expr = true,
	replace_keycodes = false,
})
