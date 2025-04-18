local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

local capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)
-- capabilities.offsetEncoding = { "utf-16" }

local underline_symbol = function(client, bufnr)
	if client.server_capabilities.documentHighlightProvider then
		vim.cmd([[
    hi! LspReferenceRead cterm=underline gui=underline
    hi! LspReferenceText cterm=underline gui=underline
    hi! LspReferenceWrite cterm=underline gui=underline
  ]])
		vim.api.nvim_create_augroup("lsp_document_highlight", {
			clear = false,
		})
		vim.api.nvim_clear_autocmds({
			buffer = bufnr,
			group = "lsp_document_highlight",
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = "lsp_document_highlight",
			buffer = bufnr,
			callback = function()
				if client.supports_method("textDocument/documentHighlight") then
					pcall(vim.lsp.buf.document_highlight)
				end
			end,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = "lsp_document_highlight",
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end
end

local underline_and_hint = function(client, buffer)
	underline_symbol(client, buffer)
	if client.name ~= "ruff" then
		client.server_capabilities.hoverProvider = false
		-- vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
	end
end

-- Set up servers
lspconfig.basedpyright.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
	single_file_support = true,
	settings = {
		basedpyright = {
			disableTaggedHints = false,
			analysis = {
				diagnosticSeverityOverrides = {
					reportUnusedCallResult = false,
				},
			},
		},
	},
})
lspconfig.ruff.setup({
	capabilities = capabilities,
	init_options = {
		settings = {
			args = { "--config", os.getenv("HOME") .. "/dotfiles/config/ruff/my_config.toml" },
		},
	},
})

lspconfig.rust_analyzer.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

local root_files_lua = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  -- '.git', -- if uncommented, dotfiles and nvim config are considered as lua proj 
}
lspconfig.lua_ls.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
    root_dir = util.root_pattern(root_files_lua),
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if
				path ~= vim.fn.stdpath("config")
                and path ~= vim.fn.expand("$HOME/dotfiles") -- added by me
				and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
			then
				return
			end
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = {
				-- Tell the language server which version of Lua you're using
				-- (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
			},
			-- Make the server aware of Neovim runtime files
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					-- Depending on the usage, you might want to add additional paths here.
					-- "${3rd}/luv/library"
					-- "${3rd}/busted/library",
				},
				-- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
				-- library = vim.api.nvim_get_runtime_file("", true)
			},
			hint = {
				enable = true,
				setType = true,
				arrayIndex = true,
				semicolon = "SameLine",
			},
		})
	end,
	settings = {
		Lua = {},
	},
})

lspconfig.bashls.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

-- lspconfig.ts_ls.setup({
-- 	on_attach = underline_and_hint,
-- 	capabilities = capabilities,
-- 	settings = {
-- 		javascript = {
-- 			inlayHints = {
-- 				includeInlayEnumMemberValueHints = true,
-- 				includeInlayFunctionLikeReturnTypeHints = true,
-- 				includeInlayFunctionParameterTypeHints = true,
-- 				includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
-- 				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
-- 				includeInlayPropertyDeclarationTypeHints = true,
-- 				includeInlayVariableTypeHints = true,
-- 			},
-- 		},
-- 		typescript = {
-- 			inlayHints = {
-- 				includeInlayEnumMemberValueHints = true,
-- 				includeInlayFunctionLikeReturnTypeHints = true,
-- 				includeInlayFunctionParameterTypeHints = true,
-- 				includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
-- 				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
-- 				includeInlayPropertyDeclarationTypeHints = true,
-- 				includeInlayVariableTypeHints = true,
-- 			},
-- 		},
-- 	},
-- })
lspconfig.denols.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})
vim.g.markdown_fenced_languages = {
	"ts=typescript",
}
local cssls_capabilities = vim.lsp.protocol.make_client_capabilities()
cssls_capabilities.textDocument.completion.completionItem.snippetSupport = true
lspconfig.cssls.setup({
	on_attach = underline_symbol,
	capabilities = cssls_capabilities,
})
lspconfig.html.setup({
	on_attach = underline_symbol,
	capabilities = capabilities,
})
lspconfig.tailwindcss.setup({
	capabilities = capabilities,
})

lspconfig.clangd.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--offset-encoding=utf-16",
	},
})
lspconfig.neocmake.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

lspconfig.glsl_analyzer.setup({
	on_attach = underline_symbol,
	capabilities = capabilities,
})

lspconfig.jsonls.setup({
	on_new_config = function(new_config)
		new_config.settings.json.schemas = new_config.settings.json.schemas or {}
		vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
	end,
	settings = {
		json = {
			format = {
				enable = true,
			},
			validate = { enable = true },
		},
	},
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

-- local home = os.getenv("HOME")
-- lspconfig.jdtls.setup({
--     on_attach = underline_symbol,
-- 	capabilities = capabilities,
-- 	cmd = {
-- 		home .. "/.local/share/nvim/mason/bin/jdtls",
-- 		"--jvm-arg=-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
-- 	},
-- })

-- Set hover popup with documentation border
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, POPUP)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, POPUP)
