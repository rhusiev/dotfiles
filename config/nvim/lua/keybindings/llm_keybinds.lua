require("keybindings.functions")

local completion = require("llm.completion")

local function llm_accept_suggestion()
	if not completion.suggestion then
		return
	end
	vim.schedule(completion.complete)
end

local function llm_dismiss_suggestion()
	if not completion.suggestion then
		return
	end
	vim.schedule(function()
		completion.cancel()
		completion.suggestion = nil
	end)
end

KEYMAP("i", "<M-j>", llm_accept_suggestion, GET_OPTIONS("LLM: Accept suggestion"))
KEYMAP("i", "<M-k>", llm_dismiss_suggestion, GET_OPTIONS("LLM: Dismiss suggestion"))
