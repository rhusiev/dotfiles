--
-- General bindings
--
KEYMAP({ "i", "n" }, "<M-c>", "<cmd>Copilot disable<CR>", GET_OPTIONS("Copilot: Disable [c]opilot"))
KEYMAP("i", "<C-о>", "<C-j>", { remap = true, silent = true, desc = "Copilot: select word" })
KEYMAP("i", "<C-л>", "<C-k>", { remap = true, silent = true, desc = "Copilot: select line" })
KEYMAP("i", "<C-д>", "<C-l>", { remap = true, silent = true, desc = "Copilot: select all" })

--
-- Custom bindings for find and till characters
--
-- Functions
local last_called = { func = nil, char = nil }

local function till(char)
	if not char then
		char = vim.fn.getcharstr()
	end
	require("copilot.suggestion").accept(function(suggestion)
		local range, text = suggestion.range, suggestion.text

		local cursor = vim.api.nvim_win_get_cursor(0)
		local _, character = cursor[1], cursor[2]

		local _, char_idx = string.find(text, char, character + 1, true)
		if char_idx then
			suggestion.text = string.sub(text, 1, char_idx - 1)

			range["end"].line = range["start"].line
			range["end"].character = char_idx - 1
		else
			-- Leave what is already typed
			suggestion.text = string.sub(text, 1, character)

			range["end"].line = range["start"].line
			range["end"].character = character
		end
		last_called = { func = till, char = char }
		return suggestion
	end)
end

local function find(char)
	if not char then
		char = vim.fn.getcharstr()
	end
	require("copilot.suggestion").accept(function(suggestion)
		local range, text = suggestion.range, suggestion.text

		local cursor = vim.api.nvim_win_get_cursor(0)
		local _, character = cursor[1], cursor[2]

		local _, char_idx = string.find(text, char, character + 1, true)
		if char_idx then
			suggestion.text = string.sub(text, 1, char_idx)

			range["end"].line = range["start"].line
			range["end"].character = char_idx
		else
			-- Leave what is already typed
			suggestion.text = string.sub(text, 1, character)

			range["end"].line = range["start"].line
			range["end"].character = character
		end
		last_called = { func = find, char = char }
		return suggestion
	end)
end

local function call_last()
	if last_called.func then
		last_called.func(last_called.char)
	end
end

-- Bindings themselves
KEYMAP("i", "<C-`>t", till, {
	desc = "Copilot: accept [t]ill",
	silent = true,
})
KEYMAP("i", "<C-'>е", till, {
	desc = "Copilot: accept [t]ill",
	silent = true,
})

KEYMAP("i", "<C-`>f", find, {
	desc = "Copilot: accept [f]ind",
	silent = true,
})
KEYMAP("i", "<C-'>а", find, {
	desc = "Copilot: accept [f]ind",
	silent = true,
})

KEYMAP("i", "<C-`>;", call_last, {
	desc = "Copilot: accept last",
	silent = true,
})
KEYMAP("i", "<C-'>ж", call_last, {
	desc = "Copilot: accept last",
	silent = true,
})
