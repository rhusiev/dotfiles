-- if KEYMAP is not defined
if not KEYMAP then
    KEYMAP = vim.keymap.set
    GET_OPTIONS = function(desc)
        local options = { remap = false, silent = true }
        if desc then
            options.desc = desc
        end
        return options
    end
    GET_OPTIONS_REMAP = function(desc)
        local options = { remap = true, silent = true }
        if desc then
            options.desc = desc
        end
        return options
    end
end
