local modelname = "codegemma"
-- local modelname = "refact"
-- local modelname = "starcoder"
-- local modelname = "codellama"
-- local modelname = "deepseek"

local model
local prefix
local middle
local suffix
local tokens_to_clear
local repository
if modelname == "codegemma" then
	model = "codegemma:2b-code"
	prefix = "<|fim_prefix|>"
	middle = "<|fim_middle|>"
	suffix = "<|fim_suffix|>"
	tokens_to_clear = {
		"<|file_separator|>",
	}
	repository = "google/codegemma-2b"
elseif modelname == "refact" then
	model = "knoopx/refact:1.6b-q8_0"
	prefix = "<fim_prefix>"
	middle = "<fim_middle>"
	suffix = "<fim_suffix>"
	tokens_to_clear = {
		"<|endoftext|>",
	}
	repository = "oblivious/Refact-1.6B-fim-GGUF"
elseif modelname == "starcoder" then
	model = "starcoder2:3b-q4_K_M"
	prefix = "<fim_prefix>"
	middle = "<fim_middle>"
	suffix = "<fim_suffix>"
	tokens_to_clear = {
		"<|endoftext|>",
	}
	repository = "bigcode/starcoder2-3b"
elseif modelname == "codellama" then
	model = "codellama:7b-code-q4_K_M"
	prefix = "<PRE> "
	middle = " <MID>"
	suffix = " <SUF>"
	tokens_to_clear = {
		"<EOT>",
	}
	repository = "codellama/CodeLlama-7b-hf"
elseif modelname == "deepseek" then
	model = "deepseek-coder:1.3b-base"
	prefix = "<｜fim▁begin｜>"
	middle = "<｜fim▁hole｜>"
	suffix = "<｜fim▁end｜>"
	tokens_to_clear = {
		"<｜end▁of▁sentence｜>",
	}
	repository = "deepseek-ai/deepseek-vl-1.3b-base"
end

local job = require("plenary.job")
job:new({
	command = "curl",
	args = {
		"-X",
		"POST",
		"http://localhost:11434/api/chat",
		"-H",
		"Content-Type: application/json",
		"-d",
		'{"model":"' .. model .. '","prompt":"a"}',
	},
	on_exit = function(j, exit_code)
		local result = j:result()
		if exit_code == 0 then
			require("llm.completion").suggestions_enabled = true
			vim.print("LLM loaded")
		else
			vim.print("LLM failed to load; result:", vim.inspect(result))
		end
	end,
}):start()

require("llm").setup({
	model = model,
	enable_suggestions_on_startup = true,
	accept_keymap = "<C-M-j>",
	dismiss_keymap = "<C-M-k>",
	tokens_to_clear = tokens_to_clear,
	fim = {
		enabled = true,
		prefix = prefix,
		middle = middle,
		suffix = suffix,
	},
	backend = "ollama",
	debounce_ms = 500,
	url = "http://localhost:11434/api/generate",
	context_window = 8192,
	-- cf https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
	request_body = {
		-- Modelfile options for the model you use
		options = {
			num_predict = 4,
			temperature = 0,
			top_p = 0.9,
		},
	},
	lsp = {
		bin_path = vim.api.nvim_call_function("stdpath", { "data" }) .. "/mason/bin/llm-ls",
	},
	tokenizer = {
		repository = repository,
	},
})
require("keybindings.llm_keybinds")
