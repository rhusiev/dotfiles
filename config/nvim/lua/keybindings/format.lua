--
-- Format
--
KEYMAP("n", "<Leader>c", function()
	vim.print("Formatting...")
	vim.lsp.buf.format()
	require("conform").format({ timeout_ms = 2000 })
end, GET_OPTIONS("Format: Format code"))
-- Quote, put into brackets selected
KEYMAP("v", "<Leader>q", "c''<Esc>Pl", GET_OPTIONS("Format: [Q]uote selected in '"))
KEYMAP("v", "<Leader>Q", 'c""<Esc>Pl', GET_OPTIONS('Format: [Q]uote selected in "'))
KEYMAP("v", "<Leader>`", "c``<Esc>Pl", GET_OPTIONS("Format: Quote selected in [`]"))
KEYMAP("v", "<Leader>9", "c()<Esc>Pl", GET_OPTIONS("Format: Put selected into ("))
KEYMAP("v", "<Leader>[", "c[]<Esc>Pl", GET_OPTIONS("Format: Put selected into ["))
KEYMAP("v", "<Leader>{", "c{}<Esc>Pl", GET_OPTIONS("Format: Put selected into {"))
KEYMAP("v", "<Leader>0", "c\\(\\)<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\("))
KEYMAP("v", "<Leader>}", "c\\{\\}<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\{"))
KEYMAP("v", "<Leader>]", "c\\[\\]<Esc>hP2l", GET_OPTIONS("Format: Put selected into \\["))
KEYMAP("v", "<Leader>8", "c**<Esc>Pl", GET_OPTIONS("Format: Put selected into *"))
KEYMAP("v", "<Leader>*", "c****<Esc>hPl", GET_OPTIONS("Format: Put selected into **"))
KEYMAP("v", "<Leader>=", "c====<Esc>hPl", GET_OPTIONS("Format: Put selected into =="))
KEYMAP("v", "<Leader>`", "c~~~~<Esc>hPl", GET_OPTIONS("Format: Put selected into ~~"))
KEYMAP("v", "<Leader>u", "ygvlohp", GET_OPTIONS("Format: [u]nquote selected"))
KEYMAP("v", "<Leader>U", "ygv2lo2hp", GET_OPTIONS("Format: [U]quote selected from 2-symbol outline"))

local function replace_optional()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local changed = false

  for i, line in ipairs(lines) do
    local current = line
    local iteration_changed = true

    while iteration_changed do
      iteration_changed = false
      local opt_start = current:find("Optional%[")

      if opt_start then
        local depth = 0
        local inner_start = opt_start + 9  -- first char after "Optional["
        local close_pos = nil

        for k = opt_start + 8, #current do  -- start at the "[" of "Optional["
          local ch = current:sub(k, k)
          if ch == "[" then
            depth = depth + 1
          elseif ch == "]" then
            depth = depth - 1
            if depth == 0 then
              close_pos = k
              break
            end
          end
        end

        if close_pos then
          local inner = current:sub(inner_start, close_pos - 1)
          current = current:sub(1, opt_start - 1) .. inner .. " | None" .. current:sub(close_pos + 1)
          iteration_changed = true
          changed = true
        end
      end
    end

    lines[i] = current
  end

  if changed then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
end

KEYMAP("n", "<leader>o", replace_optional, GET_OPTIONS("Replace [O]ptional with pipe"))
