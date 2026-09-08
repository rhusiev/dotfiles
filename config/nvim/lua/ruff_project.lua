local M = {}

local RUFF_CONFIG_MARKERS = { "ruff.toml", ".ruff.toml" }

local function has_ruff_section_in_pyproject(dir)
	local pyproject = dir .. "/pyproject.toml"
	if vim.uv.fs_stat(pyproject) == nil then
		return false
	end
	for line in io.lines(pyproject) do
		if line:match("^%s*%[tool%.ruff") then
			return true
		end
	end
	return false
end

function M.has_project_ruff_config(bufnr)
	bufnr = bufnr or 0
	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return false
	end
	local start_dir = vim.fs.dirname(filename)

	local found = vim.fs.find(RUFF_CONFIG_MARKERS, {
		path = start_dir,
		upward = true,
		type = "file",
	})
	if #found > 0 then
		return true
	end

	for dir in vim.fs.parents(filename) do
		if has_ruff_section_in_pyproject(dir) then
			return true
		end
	end
	return false
end

return M
