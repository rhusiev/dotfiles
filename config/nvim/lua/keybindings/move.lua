-- Navigate visual lines, not logical ones
KEYMAP({"n", "v"}, "<C-j>", "gj", GET_OPTIONS("Move: down visual line"))
KEYMAP({"n", "v"}, "<C-k>", "gk", GET_OPTIONS("Move: up visual line"))
KEYMAP({"n", "v"}, "<C-О>", "gj", GET_OPTIONS("Move: down visual line"))
KEYMAP({"n", "v"}, "<C-Л>", "gk", GET_OPTIONS("Move: up visual line"))
KEYMAP({"n", "v"}, "<C-0>", "g0", GET_OPTIONS("Move: start of visual line"))
KEYMAP({"n", "v"}, "<C-4>", "g$", GET_OPTIONS("Move: end of visual line"))
-- Move half page up, down, center the screen
KEYMAP("n", "<C-d>", "<C-d>zz", GET_OPTIONS("Move: half page [d]own"))
KEYMAP("n", "<C-u>", "<C-u>zz", GET_OPTIONS("Move: half page [u]p"))
-- In insert mode move like using %
KEYMAP("i", "<C-s>", "<C-o>%", { desc = "Move: like %" })
-- Move selected lines up and down
KEYMAP("v", "J", ":m '>+1<CR>gv=gv", GET_OPTIONS("Move: selected lines down"))
KEYMAP("v", "K", ":m '<-2<CR>gv=gv", GET_OPTIONS("Move: selected lines up"))

-- Find 1-character long sequence(same backwards) using hop
local hop = require("hop")
local directions = require("hop.hint").HintDirection
KEYMAP("", "gs", function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
end, { remap = true, desc = "Move: [s]earch for a letter" })
KEYMAP("", "gS", function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
end, { remap = true, desc = "Move: [S]earch for a letter backwards" })
KEYMAP("", "пі", function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
end, { remap = true, desc = "Move: [f]ind a letter" })
KEYMAP("", "пІ", function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
end, { remap = true, desc = "Move: [F]ind a letter backwards" })
-- Jump word
KEYMAP("", "gw", ":HopWord<CR>", GET_OPTIONS("Move: Jump [w]ord"))
KEYMAP("", "gW", ":HopWordBC<CR>", GET_OPTIONS("Move: Jump [W]ord backwards"))
KEYMAP("", "пц", ":HopWord<CR>", GET_OPTIONS("Move: Jump [w]ord"))
KEYMAP("", "пЦ", ":HopWordBC<CR>", GET_OPTIONS("Move: Jump [W]ord backwards"))

-- Go to next in jumplist, but inside the current file
local function jump_next_within_file()
	local current_file = vim.fn.expand("%:p")
	local jump_list = vim.fn.getjumplist()
	local jumps = jump_list[1]
	local index = jump_list[2]
	for i = index, 0, -1 do
		local jump = jumps[i]
		-- If jump is nil
		if not jump then
			return
		end
		if jump.bufnr == vim.fn.bufnr(current_file) then
			-- <c-o> the right amount of times
			for _ = 1, index - i + 1 do
				vim.cmd(vim.api.nvim_replace_termcodes("normal <C-o>", true, true, true))
			end
			return
		end
	end
end

local function jump_prev_within_file()
	local current_file = vim.fn.expand("%:p")
	local jump_list = vim.fn.getjumplist()
	local jumps = jump_list[1]
	local index = jump_list[2]
	for i = index, #jumps do
		local jump = jumps[i]
		if not jump then
			return
		end
		if jump.bufnr == vim.fn.bufnr(current_file) then
			-- <c-i> the right amount of times
			for _ = 1, i - index + 1 do
				vim.cmd(vim.api.nvim_replace_termcodes("normal <M-m>", true, true, true))
			end
			return
		end
	end
end

KEYMAP("n", "<M-o>", jump_next_within_file, GET_OPTIONS("Move: next in jumplist within file"))
KEYMAP("n", "<M-i>", jump_prev_within_file, GET_OPTIONS("Move: prev in jumplist within file"))
