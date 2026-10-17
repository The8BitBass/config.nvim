local ensure_installed = {
    "bash",
    "c",
    "diff",
    "html",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "query",
    "vim",
    "vimdoc",
}

local indent_disabled = {
    "ruby",
}

return {
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local treesitter = require("nvim-treesitter")
            local available = treesitter.get_available()

            treesitter.install(ensure_installed)

            local function start(buf, language)
                if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, language) then
                    return
                end

                local ok, indent_query = pcall(vim.treesitter.query.get, language, "indents")
                if not vim.list_contains(indent_disabled, language) and ok and indent_query then
                    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("TreesitterConfig", { clear = true }),
                callback = function(args)
                    local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
                    if not language or not vim.list_contains(available, language) then
                        return
                    end

                    if vim.list_contains(treesitter.get_installed("parsers"), language) then
                        start(args.buf, language)
                        return
                    end

                    treesitter.install(language):await(function(err, installed)
                        if not err and installed then
                            vim.schedule(function() start(args.buf, language) end)
                        end
                    end)
                end,
            })
        end,
        -- There are additional nvim-treesitter modules that you can use to interact
        -- with nvim-treesitter. You should go explore a few and see what interests you:
        --
        --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
        --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
        --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    },
}
