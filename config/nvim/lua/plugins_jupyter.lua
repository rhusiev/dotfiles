local plugins = {
	{
		"kiyoon/jupynium.nvim",
		build = "source "
			.. vim.g.jupyter_venv
			.. "/bin/activate; source "
			.. vim.g.jupyter_venv
			.. "/bin/activate.fish; pip install .",
		-- build = "conda run --no-capture-output -n jupynium pip install .",
		-- enabled = vim.fn.isdirectory(vim.fn.expand "~/miniconda3/envs/jupynium"),
		config = {
			python_host = vim.g.jupyter_venv .. "/bin/python3",
			jupyter_command = vim.g.jupyter_venv .. "/bin/jupyter",
		},
	},
}

return plugins
