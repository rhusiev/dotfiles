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
vim.lsp.config("basedpyright", {
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
vim.lsp.enable("basedpyright")
vim.lsp.config("ruff", {
	capabilities = capabilities,
	init_options = {
		settings = {
			args = { "--config", os.getenv("HOME") .. "/dotfiles/config/ruff/my_config.toml" },
		},
	},
})
vim.lsp.enable("ruff")

vim.lsp.config("rust_analyzer", {
	on_attach = underline_and_hint,
	capabilities = capabilities,
})
vim.lsp.enable("rust_analyzer")

local root_files_lua = {
	".luarc.json",
	".luarc.jsonc",
	".luacheckrc",
	".stylua.toml",
	"stylua.toml",
	"selene.toml",
	"selene.yml",
	-- '.git', -- if uncommented, dotfiles and nvim config are considered as lua proj
}
vim.lsp.config("lua_ls", {
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
vim.lsp.enable("lua_ls")

vim.lsp.config("bashls", {
	on_attach = underline_and_hint,
	capabilities = capabilities,
})
vim.lsp.enable("bashls")

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
vim.lsp.config("denols", {
	on_attach = underline_and_hint,
	capabilities = capabilities,
})
vim.lsp.enable("denols")
vim.g.markdown_fenced_languages = {
	"ts=typescript",
}
local cssls_capabilities = vim.lsp.protocol.make_client_capabilities()
cssls_capabilities.textDocument.completion.completionItem.snippetSupport = true
vim.lsp.config("cssls", {
	on_attach = underline_symbol,
	capabilities = cssls_capabilities,
})
vim.lsp.enable("cssls")
vim.lsp.config("html", {
	on_attach = underline_symbol,
	capabilities = capabilities,
})
vim.lsp.enable("html")
vim.lsp.config("tailwindcss", {
	capabilities = capabilities,
})
vim.lsp.enable("tailwindcss")

vim.lsp.config("clangd", {
	on_attach = underline_and_hint,
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--offset-encoding=utf-16",
	},
})
vim.lsp.enable("clangd")
vim.lsp.config("neocmake", {
	on_attach = underline_and_hint,
	capabilities = capabilities,
})
vim.lsp.enable("neocmake")

-- lspconfig.glsl_analyzer.setup({
-- 	on_attach = underline_symbol,
-- 	capabilities = capabilities,
-- })

vim.lsp.config("jsonls", {
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
vim.lsp.enable("jsonls")

vim.lsp.enable("docker_compose_language_service")
vim.lsp.enable("dockerls")

-- local home = os.getenv("HOME")
-- lspconfig.jdtls.setup({
--     on_attach = underline_symbol,
-- 	capabilities = capabilities,
-- 	cmd = {
-- 		home .. "/.local/share/nvim/mason/bin/jdtls",
-- 		"--jvm-arg=-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
-- 	},
-- })

