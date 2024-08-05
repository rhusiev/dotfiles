local lspconfig = require("lspconfig")
local capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)
-- capabilities.offsetEncoding = { "utf-16" }
local inlay_hints = require("inlay-hints")
inlay_hints.setup({
	renderer = "inlay-hints/render/eol",
})

local underline_symbol = function(client, bufnr)
	-- client.server_capabilities.documentFormattingProvider = false
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
		-- inlay_hints.on_attach(client, buffer) -- TODO: replace with lower, when neovim supports eol inlay hints
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
                }
            }
		},
	},
})
lspconfig.ruff.setup({
	capabilities = capabilities,
	init_options = {
		settings = {
			args = { "--config", os.getenv("HOME") .. "/.dotfiles/config/ruff/my_config.toml" },
		},
	},
})

lspconfig.rust_analyzer.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

lspconfig.lua_ls.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc") then
			client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
						},
					},
					hint = {
						enable = true,
						setType = true,
						arrayIndex = true,
						semicolon = "SameLine",
					},
				},
			})

			client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		end
		return true
	end,
})

lspconfig.bashls.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
})

lspconfig.tsserver.setup({
	on_attach = underline_and_hint,
	capabilities = capabilities,
	settings = {
		javascript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
			},
		},
		typescript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
			},
		},
	},
})
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

lspconfig.glsl_analyzer.setup({
	on_attach = underline_symbol,
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
