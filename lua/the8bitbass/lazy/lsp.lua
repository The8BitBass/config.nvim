return {
    {
        -- Main LSP Configuration
        "neovim/nvim-lspconfig",
        dependencies = {
            { "stevearc/conform.nvim", opts = {} },
            -- Automatically install LSPs and related tools to stdpath for Neovim
            -- Mason must be loaded before its dependents so we need to set it up here.
            -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
            { "williamboman/mason.nvim", opts = {} },
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- Allows extra capabilities provided by nvim-cmp
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp-signature-help",

            "hrsh7th/nvim-cmp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",

            -- Useful status updates for LSP.
            { "j-hui/fidget.nvim", opts = {} },
            { "DrKJeff16/wezterm-types", version = false },

            -- Other tools for langauges
            -- F#
            -- { "ionide/Ionide-vim", opts = {} },
            -- { "WillEhrendreich/Ionide-nvim", opts = {} },
        },
        config = function()
            require("conform").setup({
                formatters_by_ft = {},
            })
            -- See `:help cmp`
            local cmp = require("cmp")
            local cmp_lsp = require("cmp_nvim_lsp")

            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. Available keys are:
            --  - cmd (table): Override the default command used to start the server
            --  - filetypes (table): Override the default list of associated filetypes for the server
            --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
            --  - settings (table): Override the default settings passed when initializing the server.
            --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
            -- require("ionide").setup()

            local weztermTypesPath = require("lazy.core.config").plugins["wezterm-types"].dir
            local servers = {
                -- clangd = {},
                -- gopls = {},
                -- pyright = {},
                -- rust_analyzer = {},
                -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
                --
                -- Some languages (like typescript) have entire language plugins that can be useful:
                --    https://github.com/pmizio/typescript-tools.nvim
                --
                -- But for many setups, the LSP (`ts_ls`) will work just fine
                -- ts_ls = {},
                --
                -- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/fsautocomplete.lua
                fsautocomplete = {
                    root_dir = function(bufnr, on_dir)
                        local fname = vim.api.nvim_buf_get_name(bufnr)
                        on_dir(require("lspconfig.util").root_pattern("*.sln", "*.fsproj", ".git", "*.fsx")(fname))
                    end,
                },

                powershell_es = {
                    settings = {
                        powershell = {
                            codeFormatting = {
                                preset = "Custom",
                                openBraceOnSameLine = true,
                                newLineAfterOpenBrace = true,
                                newLineAfterCloseBrace = false,
                            },
                        },
                    },
                },
                -- ionide = {
                --     flags = {
                --         debounce_text_changes = 150,
                --     },
                -- },
                lua_ls = {
                    -- cmd = { ... },
                    -- filetypes = { ... },
                    -- capabilities = {},
                    settings = {
                        Lua = {
                            checkThirdParty = false,
                            workspace = {
                                library = {
                                    vim.env.VIMRUNTIME,
                                    "${3rd}/luv/library",
                                    weztermTypesPath,
                                },
                            },
                            completion = {
                                callSnippet = "Replace",
                            },
                            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                            -- diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
            }

            -- Ensure the servers and tools above are installed
            --
            -- To check the current status of installed tools and/or manually install
            -- other tools, you can run
            --    :Mason
            --
            -- You can press `g?` for help in this menu.
            --
            -- `mason` had to be setup earlier: to configure its options see the
            -- `dependencies` table for `nvim-lspconfig` above.
            --
            -- You can add other tools here that you want Mason to install
            -- for you, so that they are available from within Neovim.
            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                "stylua", -- Used to format Lua code
            })
            require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

            require("mason-lspconfig").setup({
                ensure_installed = {}, -- populates installs via mason-tool-installer
                automatic_installation = false,
            })

            for server_name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                vim.lsp.config(server_name, server)
                -- ionide = function(_, opts)
                --     print("setup ionide")
                --     require("ionide").setup(opts)
                -- end,
                -- -- NOTE: returning true will make sure fsautocomplete is not setup with neovim, which is what we want if we're using Ionide-nvim
                -- fsautocomplete = function() end,
            end

            cmp.setup({
                snippet = {
                    expand = function(args) require("luasnip").lsp_expand(args.body) end,
                },
                -- completion = { completeopt = "menu,menuone,noinsert" },

                -- For an understanding of why these mappings were
                -- chosen, you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                mapping = cmp.mapping.preset.insert({
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-l>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    -- {
                    --     name = "lazydev",
                    --     -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
                    --     group_index = 0,
                    -- },
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "nvim_lsp_signature_help" },
                }),
            })

            -- Diagnostic Config
            -- See :help vim.diagnostic.Opts
            vim.diagnostic.config({
                severity_sort = true,
                float = { border = "rounded", source = "if_many" },
                underline = { severity = vim.diagnostic.severity.ERROR },
                signs = vim.g.have_nerd_font and {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "󰅚 ",
                        [vim.diagnostic.severity.WARN] = "󰀪 ",
                        [vim.diagnostic.severity.INFO] = "󰋽 ",
                        [vim.diagnostic.severity.HINT] = "󰌶 ",
                    },
                } or {},
                virtual_text = {
                    source = "if_many",
                    spacing = 2,
                    format = function(diagnostic)
                        local diagnostic_message = {
                            [vim.diagnostic.severity.ERROR] = diagnostic.message,
                            [vim.diagnostic.severity.WARN] = diagnostic.message,
                            [vim.diagnostic.severity.INFO] = diagnostic.message,
                            [vim.diagnostic.severity.HINT] = diagnostic.message,
                        }
                        return diagnostic_message[diagnostic.severity]
                    end,
                },
            })
        end,
    },
}
