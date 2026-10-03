-- Per-project ty settings that live in this config instead of in the project repo.
--
-- Keys are absolute project roots (as resolved by ty's `root_markers`).
-- Values use the ty.toml schema (https://docs.astral.sh/ty/reference/configuration/)
-- and are handed to the server as `initializationOptions.configuration`.
-- Relative paths inside a value are resolved against the project root.
-- Entries come from the untracked `work.ty_projects` module when it exists.

local M = {}

M.overrides = require("optional_module").load("work.ty_projects") or {}

---@param root_dir string?
---@return table?
function M.get(root_dir)
	if root_dir == nil then
		return nil
	end
	return M.overrides[vim.fs.normalize(root_dir)]
end

return M
