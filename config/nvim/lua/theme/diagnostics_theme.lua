-- Diagnostics sources
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        spacing = 0,
        source = false,
        suffix = "",
        -- Format to remove the error code from the message
        format = function(_)
            -- format = function(diag)
            -- return string.gsub(diag.message, "%a+%d+ ", "%0")
            return ""
        end,
    },
    float = {
        source = "always",
        -- Format to put a "," after the error code(or the plugin name that gives the error)
        format = function(diag)
            return string.gsub(diag.message, "%a+%d+", "%0")
        end,
    },
})

-- Diagnostics signs
local signs = { Error = "󰜺 ", Warn = " ", Hint = "󰌶 ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

