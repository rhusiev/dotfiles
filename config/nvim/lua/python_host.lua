-- Prefer a dedicated venv with pynvim; otherwise the system python, so that venvs still see system packages
local NVIM_VENV_PYTHON = os.getenv("HOME") .. "/.local/share/venvs/nvim_venv/bin/python3"
local SYSTEM_PYTHON = "/usr/bin/python3"

local python = vim.fn.executable(NVIM_VENV_PYTHON) == 1 and NVIM_VENV_PYTHON or SYSTEM_PYTHON
vim.g.python_host_prog = python
vim.g.python3_host_prog = python
