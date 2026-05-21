return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git Status" })
        vim.keymap.set("n", "<leader>gf", vim.cmd.Git("fetch --all"), { desc = "Git Fetch" })
        vim.keymap.set("n", "<leader>gl", vim.cmd.Git("pull"), { desc = "Git Pull" })

        local The8BitBass_Fugitive = vim.api.nvim_create_augroup("The8BitBass_Fugitive", {})

        local autocmd = vim.api.nvim_create_autocmd
        autocmd("BufWinEnter", {
            group = The8BitBass_Fugitive,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()

                local function map(lhs, rhs, desc)
                    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, remap = false, desc = desc, })
                end

                local function git(args)
                    vim.cmd.Git(args)
                end

                map("<leader>F", git("fetch --all"), "fetch")

                map("<leader>H", git("push"), "push")

                -- rebase always
                map("<leader>L", git("pull --rebase"), "pull")

                -- NOTE: It allows me to easily set the branch i am pushing and any tracking
                -- needed if i did not set the branch up correctly
                map("<leader>T", ":Git push -u origin ", "push set upstream")

                require("which-key").add({ "<leader>S", group = "Git [S]ubmodule", buffer = bufnr })
                map("<leader>SI", git("submodule update --init --recursive"), "submodule init")
                map("<leader>SL", git("submodule update --remote --rebase --recursive"), "submodule get latest")
                map("<leader>SH", git("push --recurse-submodules=on-demand"), "submodule push on-demand")

            end,
        })

        vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
        vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
    end,
}
