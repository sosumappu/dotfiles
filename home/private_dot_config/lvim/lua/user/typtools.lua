local M = {}

M.config = function()
    -- Safely require the necessary plugins
    local status_ok, tools = pcall(require, "typescript-tools")
    if not status_ok then
        vim.notify("Plugin 'typescript-tools' not found.", vim.log.levels.WARN)
        return
    end

    local lvim_lsp_ok, lvim_lsp = pcall(require, "lvim.lsp")
    if not lvim_lsp_ok then
        vim.notify("Module 'lvim.lsp' not found.", vim.log.levels.WARN)
        return
    end

    local opts = {
        capabilities = lvim_lsp.common_capabilities(),
        root_dir = function(fname)
            local util = require("lspconfig.util")
            local root_files = {
                "tsconfig.base.json",
                "eslint.config.mjs",
                "nx.json",
                "jest.preset.js",
                "node_modules",
            }
            return util.root_pattern(unpack(root_files))(fname)
                or util.root_pattern(".git")(fname)
                or util.path.dirname(fname)
        end,

        on_attach = function(client, bufnr)
            -- Disable formatting capabilities from tsserver, as you likely use a dedicated formatter like Prettier.
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false

            lvim_lsp.common_on_attach(client, bufnr)
        end,
        settings = {
            -- This is where the magic happens. We pass the calculated path.
            -- If it's nil, the plugin's default behavior is used.
            tsserver_path = nil,

            -- spawn additional tsserver instance to calculate diagnostics on it
            separate_diagnostic_server = true,
            -- "change"|"insert_leave" determine when the client asks the server about diagnostic
            publish_diagnostic_on = "insert_leave",
            -- array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
            -- "remove_unused_imports"|"organize_imports") -- or string "all"
            -- to include all supported code actions
            -- specify commands exposed as code_actions
            expose_as_code_action = {},
            -- specify a list of plugins to load by tsserver, e.g., for support `styled-components`
            -- (see 💅 `styled-components` support section)
            tsserver_plugins = {},
            -- this value is passed to: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes
            -- memory limit in megabytes or "auto"(basically no limit)
            tsserver_max_memory = "auto",
            -- described below
            tsserver_format_options = {},
            tsserver_file_preferences = {},
            -- locale of all tsserver messages, supported locales you can find here:
            -- https://github.com/microsoft/TypeScript/blob/3c221fc086be52b19801f6e8d82596d04607ede6/src/compiler/utilitiesPublic.ts#L620
            tsserver_locale = "en",
            -- mirror of VSCode's `typescript.suggest.completeFunctionCalls`
            complete_function_calls = false,
            include_completions_with_insert_text = true,
            -- CodeLens
            -- WARNING: Experimental feature also in VSCode, because it might hit performance of server.
            -- possible values: ("off"|"all"|"implementations_only"|"references_only")
            code_lens = "off",
            -- by default code lenses are displayed on all referencable values and for some of you it can
            -- be too much this option reduce count of them by removing member references from lenses
            disable_member_code_lens = true,
            -- JSXCloseTag
            -- WARNING: it is disabled by default (maybe you configuration or distro already uses nvim-ts-autotag,
            -- that maybe have a conflict if enable this feature. )
            jsx_close_tag = {
                enable = false,
                filetypes = { "javascriptreact", "typescriptreact" },
            },
        },
    }
    tools.setup(opts)
end

return M
