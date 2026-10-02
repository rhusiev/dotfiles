-- Loads a module that exists only on some machines, such as the untracked `work.*` modules.
-- Returns nil when the module is absent; errors inside a present module still surface.

local M = {}

---@param name string
---@return boolean
local function exists(name)
	local path = name:gsub("%.", "/")
	return #vim.api.nvim_get_runtime_file("lua/" .. path .. ".lua", false) > 0
		or #vim.api.nvim_get_runtime_file("lua/" .. path .. "/init.lua", false) > 0
end

---@param name string
---@return any
function M.load(name)
	if not exists(name) then
		return nil
	end
	return require(name)
end

return M
