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
    -- Diagnostics signs. Since nvim 0.11, sign_define("DiagnosticSign*") is
    -- ignored: the core handler only reads signs.text from here, and otherwise
    -- falls back to the first letter of the severity name ("E", "W", ...).
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰜺 ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
            [vim.diagnostic.severity.INFO] = " ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        },
    },
})
