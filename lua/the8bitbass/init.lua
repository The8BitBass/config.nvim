require("the8bitbass.set")
require("the8bitbass.remap")
require("the8bitbass.lazy_init")
print("hello world")

vim.cmd("let filetype_fs = 'fsharp'")
vim.cmd("let filetype_fsx = 'fsharp'")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local SearchGroup = augroup("vimrc_incsearch_highlight", { clear = true })

autocmd("CmdlineEnter", {
    group = SearchGroup,
    pattern = { "/", "?" },
    command = "set hlsearch",
})

autocmd("CmdlineLeave", {
    group = SearchGroup,
    pattern = { "/", "?" },
    command = "set nohlsearch",
})

local The8BitBassGroup = augroup("The8BitBass", { clear = true })
local YankGroup = augroup("HighlightYank", { clear = true })
-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = YankGroup,
    callback = function() vim.highlight.on_yank() end,
})

-- autocmd("BufEnter", {
--     group = The8BitBassGroup,
--     callback = function()
--         if vim.bo.filetype == "lua" then
--             print("function says lua")
--         else
--             print("function says not lua")
--         end
--     end,
-- })

-- stylua: ignore
autocmd("LspAttach", {
    group = The8BitBassGroup,
    callback = function(e)
        local keymap = function (mode, keys, func, desc)
            local opts = { buffer = e.buf, desc = desc }
            vim.keymap.set(mode, keys, func, opts)
        end
        keymap("n", "gd", function() vim.lsp.buf.definition() end, "[G]oto [D]efinition")
        keymap("n", "<leader>nd", function() vim.lsp.buf.definition() end, "[N]avigate to [D]efinition")
        keymap("n", "<leader>nD", function() vim.lsp.buf.declaration() end, "[N]avigate to [D]eclaration")
        keymap("n", "<leader>nr", function() vim.lsp.buf.references() end, "[N]avigate to [R]eferences")
        keymap("n", "<leader>ni", function() vim.lsp.buf.implementation() end, "[N]avigate to [I]mplementation")
        keymap("n", "<leader>nt", function() vim.lsp.buf.type_definition() end, "[N]avigate to [T]ype")
        keymap("n", "<leader>ns", function() vim.lsp.buf.workspace_symbol() end, "[N]avigate to [S]ymbol")
        keymap("n", "<leader>nh", function() vim.lsp.buf.hover() end, "[N]avigate show [H]over")

        keymap("n", "<leader>ds", function() vim.diagnostic.open_float() end, "[D]ebug [S]how")

        keymap("n", "<leader>rr", function() vim.lsp.buf.rename() end, "[R]efactor [R]ename")
        keymap("n", "<leader>ra", function() vim.lsp.buf.code_action() end, "[R]efactor [A]ction")

        -- keymap("n", "K", function() vim.lsp.buf.hover() end, "Hover")
        -- vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        -- vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        -- vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
        -- vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
        -- vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
        -- vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        -- vim.keymap.set("n", "[d", function() vim.diagnostic.jump({count = 1, float = true}) end, opts)
        -- vim.keymap.set("n", "]d", function() vim.diagnostic.jump({count = -1, float = true}) end, opts)
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
        ---@param client vim.lsp.Client
        ---@param method vim.lsp.protocol.Method
        ---@param bufnr? integer some lsp support methods only in specific files
        ---@return boolean
        local function client_supports_method(client, method, bufnr)
            if vim.fn.has("nvim-0.11") == 1 then
                return client:supports_method(method, bufnr)
            else
                return client.supports_method(method, { bufnr = bufnr })
            end
        end

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if
            client
            and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
        then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event2)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                end,
            })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map(
                "<leader>th",
                function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })) end,
                "[T]oggle Inlay [H]ints"
            )
        end
    end,
})

vim.g.netrw_bufsettings = 'noma nomod nu rnu nobl nowrap ro'
vim.g.netrw_browse_split = 0
-- vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
