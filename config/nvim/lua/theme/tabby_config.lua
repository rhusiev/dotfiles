-- Set highlight groups for tabline
vim.cmd(string.format("highlight TabLine guibg=%s", vim.g.color_dark1))
-- Show tabs even when there is only one
vim.o.showtabline = 2
local theme = {
	fill = "TabLine",
	head = "TabLine",
	current_tab = { fg = vim.g.color_white2, bg = vim.g.color_dark4 },
	tab = { fg = vim.g.color_white2, bg = vim.g.color_dark2 },
	win = "TabLine",
	tail = "TabLine",
}
require("tabby.tabline").set(function(line)
	return {
		line.tabs().foreach(function(tab)
			local hl = tab.is_current() and theme.current_tab or theme.tab
			local wins = tab.wins().foreach(function(win)
				return win.buf().is_changed()
			end)
			return {
				line.sep("", hl, theme.fill),
				tab.current_win().file_icon(),
				"",
				tab.name(),
				string.format("%s", vim.tbl_contains(wins, true) and "" or " "),
				tab.close_btn(""),
				line.sep("", hl, theme.fill),
				hl = hl,
				margin = " ",
			}
		end),
		hl = theme.fill,
	}
end)
