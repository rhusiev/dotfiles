require("sets")

require("keybindings.keybindings")

-- Add ~/.local/bin to PATH
vim.cmd('let $PATH .= ":" . $HOME . "/.local/bin"')
-- Clean old undo files
vim.api.nvim_create_user_command("Clean", function()
		vim.cmd('silent exec "!nohup python3 ~/.local/share/nvim/undodir/cleanup.py &>/dev/null & disown"')
	end, {}
)

-- Disable concealing quotes in json
vim.g.vim_json_conceal = 0

-- Create a new command that does 'require("ensure")'
vim.api.nvim_create_user_command("Ensure", function()
	require("ensure")
end, {})

