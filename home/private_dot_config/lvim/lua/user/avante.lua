local M = {}

-- This function returns the configuration table that lazy.nvim will pass
-- to the avante.nvim setup function.
function M.get_opts()
    return {
        debug = false,
        ---@alias avante.Mode "agentic" | "legacy"
        ---@type avante.Mode
        mode = "agentic",
        ---@alias avante.ProviderName "claude" | "openai" | "azure" | "gemini" | "vertex" | "cohere" | "copilot" | "bedrock" | "ollama" | string
        ---@type avante.ProviderName
        provider = "copilot",
        -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
        -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
        -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
        auto_suggestions_provider = nil,
        memory_summary_provider = nil,
        ---@alias Tokenizer "tiktoken" | "hf"
        ---@type Tokenizer
        -- Used for counting tokens and encoding text.
        -- By default, we will use tiktoken.
        -- For most providers that we support we will determine this automatically.
        -- If you wish to use a given implementation, then you can override it here.
        tokenizer = "tiktoken",
        ---@type string | (fun(): string) | nil
        system_prompt = nil,
        rag_service = { -- RAG service configuration
            enabled = false, -- Enables the RAG service
            host_mount = os.getenv("HOME"), -- Host mount path for the RAG service (Docker will mount this path)
            runner = "docker", -- The runner for the RAG service (can use docker or nix)
            llm = { -- Configuration for the Language Model (LLM) used by the RAG service
                provider = "openai", -- The LLM provider
                endpoint = "https://api.openai.com/v1", -- The LLM API endpoint
                api_key = "OPENAI_API_KEY", -- The environment variable name for the LLM API key
                model = "gpt-4o-mini", -- The LLM model name
                extra = nil, -- Extra configuration options for the LLM
            },
            embed = { -- Configuration for the Embedding model used by the RAG service
                provider = "openai", -- The embedding provider
                endpoint = "https://api.openai.com/v1", -- The embedding API endpoint
                api_key = "OPENAI_API_KEY", -- The environment variable name for the embedding API key
                model = "text-embedding-3-large", -- The embedding model name
                extra = nil, -- Extra configuration options for the embedding model
            },
            docker_extra_args = "", -- Extra arguments to pass to the docker command
        },
        web_search_engine = {
            provider = "tavily",
            proxy = nil,
            providers = {
                tavily = {
                    api_key_name = "TAVILY_API_KEY",
                    extra_request_body = {
                        include_answer = "basic",
                    },
                    ---@type WebSearchEngineProviderResponseBodyFormatter
                    format_response_body = function(body)
                        return body.answer, nil
                    end,
                },
                serpapi = {
                    api_key_name = "SERPAPI_API_KEY",
                    extra_request_body = {
                        engine = "google",
                        google_domain = "google.com",
                    },
                    ---@type WebSearchEngineProviderResponseBodyFormatter
                    format_response_body = function(body)
                        if body.answer_box ~= nil and body.answer_box.result ~= nil then
                            return body.answer_box.result, nil
                        end
                        if body.organic_results ~= nil then
                            local jsn = vim.iter(body.organic_results)
                                :map(function(result)
                                    return {
                                        title = result.title,
                                        link = result.link,
                                        snippet = result.snippet,
                                        date = result.date,
                                    }
                                end)
                                :take(10)
                                :totable()
                            return vim.json.encode(jsn), nil
                        end
                        return "", nil
                    end,
                },
                searchapi = {
                    api_key_name = "SEARCHAPI_API_KEY",
                    extra_request_body = {
                        engine = "google",
                    },
                    ---@type WebSearchEngineProviderResponseBodyFormatter
                    format_response_body = function(body)
                        if body.answer_box ~= nil then
                            return body.answer_box.result, nil
                        end
                        if body.organic_results ~= nil then
                            local jsn = vim.iter(body.organic_results)
                                :map(function(result)
                                    return {
                                        title = result.title,
                                        link = result.link,
                                        snippet = result.snippet,
                                        date = result.date,
                                    }
                                end)
                                :take(10)
                                :totable()
                            return vim.json.encode(jsn), nil
                        end
                        return "", nil
                    end,
                },
            },
        },
        ---To add support for custom provider, follow the format below
        ---See https://github.com/yetone/avante.nvim/wiki#custom-providers for more details
        ---@type {[string]: AvanteProvider}
        providers = {
            ---@type AvanteSupportedProvider
            openai = {
                endpoint = "https://api.openai.com/v1",
                model = "gpt-4o",
                timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
                extra_request_body = {
                    temperature = 0.75,
                    max_completion_tokens = 16384, -- Increase this to include reasoning tokens (for reasoning models)
                    reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
                },
            },
            ---@type AvanteSupportedProvider
            copilot = {
                endpoint = "https://api.githubcopilot.com",
                model = "gpt-4o-2024-11-20",
                proxy = nil, -- [protocol://]host[:port] Use this proxy
                allow_insecure = false, -- Allow insecure server connections
                timeout = 30000, -- Timeout in milliseconds
                extra_request_body = {
                    temperature = 0.75,
                    max_tokens = 20480,
                },
            },
            ---@type AvanteSupportedProvider
            claude = {
                endpoint = "https://api.anthropic.com",
                model = "claude-3-7-sonnet-20250219",
                timeout = 30000, -- Timeout in milliseconds
                extra_request_body = {
                    temperature = 0.75,
                    max_tokens = 20480,
                },
            },
            ---@type AvanteSupportedProvider
            gemini = {
                endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
                model = "gemini-2.0-flash",
                timeout = 30000, -- Timeout in milliseconds
                extra_request_body = {
                    generationConfig = {
                        temperature = 0.75,
                    },
                },
            },
            ---@type AvanteSupportedProvider
            ollama = {
                endpoint = "http://127.0.0.1:11434",
                timeout = 30000, -- Timeout in milliseconds
                extra_request_body = {
                    options = {
                        temperature = 0.75,
                        num_ctx = 20480,
                        keep_alive = "5m",
                    },
                },
            },
        },
        ---Specify the special dual_boost mode
        ---1. enabled: Whether to enable dual_boost mode. Default to false.
        ---2. first_provider: The first provider to generate response. Default to "openai".
        ---3. second_provider: The second provider to generate response. Default to "claude".
        ---4. prompt: The prompt to generate response based on the two reference outputs.
        ---5. timeout: Timeout in milliseconds. Default to 60000.
        ---How it works:
        --- When dual_boost is enabled, avante will generate two responses from the first_provider and second_provider respectively. Then use the response from the first_provider as provider1_output and the response from the second_provider as provider2_output. Finally, avante will generate a response based on the prompt and the two reference outputs, with the default Provider as normal.
        ---Note: This is an experimental feature and may not work as expected.
        dual_boost = {
            enabled = false,
            first_provider = "openai",
            second_provider = "claude",
            prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
            timeout = 60000, -- Timeout in milliseconds
        },
        ---Specify the behaviour of avante.nvim
        ---1. auto_focus_sidebar              : Whether to automatically focus the sidebar when opening avante.nvim. Default to true.
        ---2. auto_suggestions = false, -- Whether to enable auto suggestions. Default to false.
        ---3. auto_apply_diff_after_generation: Whether to automatically apply diff after LLM response.
        ---                                     This would simulate similar behaviour to cursor. Default to false.
        ---4. auto_set_keymaps                : Whether to automatically set the keymap for the current line. Default to true.
        ---                                     Note that avante will safely set these keymap. See https://github.com/yetone/avante.nvim/wiki#keymaps-and-api-i-guess for more details.
        ---5. auto_set_highlight_group        : Whether to automatically set the highlight group for the current line. Default to true.
        ---6. jump_result_buffer_on_finish = false, -- Whether to automatically jump to the result buffer after generation
        ---7. support_paste_from_clipboard    : Whether to support pasting image from clipboard. This will be determined automatically based whether img-clip is available or not.
        ---8. minimize_diff                   : Whether to remove unchanged lines when applying a code block
        ---9. enable_token_counting           : Whether to enable token counting. Default to true.
        behaviour = {
            auto_focus_sidebar = true,
            auto_suggestions = false, -- Experimental stage
            auto_suggestions_respect_ignore = false,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = false,
            jump_result_buffer_on_finish = false,
            support_paste_from_clipboard = false,
            minimize_diff = true,
            enable_token_counting = true,
            use_cwd_as_project_root = false,
            auto_focus_on_diff_view = false,
            ---@type boolean | string[] -- true: auto-approve all tools, false: normal prompts, string[]: auto-approve specific tools by name
            auto_approve_tool_permissions = false, -- Default: show permission prompts for all tools
            auto_check_diagnostics = true,
        },
        highlights = {
            diff = {
                current = nil,
                incoming = nil,
            },
        },
        img_paste = {
            url_encode_path = true,
            template = "\nimage: $FILE_PATH\n",
        },
        mappings = {
            ---@class AvanteConflictMappings
            diff = {
                ours = "co",
                theirs = "ct",
                all_theirs = "ca",
                both = "cb",
                cursor = "cc",
                next = "]x",
                prev = "[x",
            },
            suggestion = {
                accept = "<M-l>",
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
            },
            jump = {
                next = "]]",
                prev = "[[",
            },
            submit = {
                normal = "<CR>",
                insert = "<C-s>",
            },
            cancel = {
                normal = { "<C-c>", "<Esc>", "q" },
                insert = { "<C-c>" },
            },
            -- NOTE: The following will be safely set by avante.nvim
            ask = "<leader>aa",
            new_ask = "<leader>an",
            edit = "<leader>ae",
            refresh = "<leader>ar",
            focus = "<leader>af",
            stop = "<leader>aS",
            toggle = {
                default = "<leader>at",
                debug = "<leader>ad",
                hint = "<leader>ah",
                suggestion = "<leader>as",
                repomap = "<leader>aR",
            },
            sidebar = {
                apply_all = "A",
                apply_cursor = "a",
                retry_user_request = "r",
                edit_user_request = "e",
                switch_windows = "<Tab>",
                reverse_switch_windows = "<S-Tab>",
                remove_file = "d",
                add_file = "@",
                close = { "q" },
                ---@alias AvanteCloseFromInput { normal: string | nil, insert: string | nil }
                ---@type AvanteCloseFromInput | nil
                close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
            },
            files = {
                add_current = "<leader>ac", -- Add current buffer to selected files
                add_all_buffers = "<leader>aB", -- Add all buffer files to selected files
            },
            select_model = "<leader>a?", -- Select model command
            select_history = "<leader>ah", -- Select history command
            confirm = {
                focus_window = "<C-w>f",
                code = "c",
                resp = "r",
                input = "i",
            },
        },
        windows = {
            ---@alias AvantePosition "right" | "left" | "top" | "bottom" | "smart"
            ---@type AvantePosition
            position = "right",
            fillchars = "eob: ",
            wrap = true, -- similar to vim.o.wrap
            width = 30, -- default % based on available width in vertical layout
            height = 30, -- default % based on available height in horizontal layout
            sidebar_header = {
                enabled = true, -- true, false to enable/disable the header
                align = "center", -- left, center, right for title
                rounded = true,
            },
            input = {
                prefix = "> ",
                height = 8, -- Height of the input window in vertical layout
            },
            edit = {
                border = { " ", " ", " ", " ", " ", " ", " ", " " },
                start_insert = true, -- Start insert mode when opening the edit window
            },
            ask = {
                floating = false, -- Open the 'AvanteAsk' prompt in a floating window
                border = { " ", " ", " ", " ", " ", " ", " ", " " },
                start_insert = true, -- Start insert mode when opening the ask window
                ---@alias AvanteInitialDiff "ours" | "theirs"
                ---@type AvanteInitialDiff
                focus_on_apply = "ours", -- which diff to focus after applying
            },
        },
        --- @class AvanteConflictConfig
        diff = {
            autojump = true,
            --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
            --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
            --- Disable by setting to -1.
            override_timeoutlen = 500,
        },
        --- @class AvanteHintsConfig
        hints = {
            enabled = true,
        },
        --- @class AvanteRepoMapConfig
        repo_map = {
            ignore_patterns = { "%.git", "%.worktree", "__pycache__", "node_modules" }, -- ignore files matching these
            negate_patterns = {}, -- negate ignore files matching these.
        },
        --- @class AvanteFileSelectorConfig
        file_selector = {
            provider = nil,
            -- Options override for custom providers
            provider_opts = {},
        },
        selector = {
            ---@alias avante.SelectorProvider "native" | "fzf_lua" | "mini_pick" | "snacks" | "telescope" | fun(selector: avante.ui.Selector): nil
            ---@type avante.SelectorProvider
            provider = "fzf_lua",
            provider_opts = {},
            exclude_auto_select = {}, -- List of items to exclude from auto selection
        },
        input = {
            provider = "native",
            provider_opts = {},
        },
        suggestion = {
            debounce = 600,
            throttle = 600,
        },
        disabled_tools = {}, ---@type string[]
        ---@type AvanteLLMToolPublic[] | fun(): AvanteLLMToolPublic[]
        custom_tools = {},
        ---@type AvanteSlashCommand[]
        slash_commands = {},
    }
end

return M
