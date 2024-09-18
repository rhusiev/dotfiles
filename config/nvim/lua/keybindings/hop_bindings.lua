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

