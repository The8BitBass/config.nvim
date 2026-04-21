function ColorMyPencils(color)
    color = color or "knight-life"
    vim.cmd.colorscheme(color)

    -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
    {
        "the8bitbass/knight-life.nvim",
        name = "knight-life",
        lazy = false,
        priority = 1000,
        dev = true,
        config = function()
            require("knight-life").setup({
                on_highlights = function(hl,c)
                        hl.TelescopeBorder = { bg = c.none }
                        hl.TelescopeNormal = { bg = c.none }
                        hl.TelescopePromptNormal = { bg = c.bg }
                        hl.TelescopeResultsNormal = { fg = c.text.unfocused, bg = c.none }
                        hl.TelescopeSelection = { fg = c.text.default, bg = c.bg_highlight }
                end,
                transparent = true,
                styles = {
                    italic = false,
                    transparency = true,
                },
            })

            ColorMyPencils()
        end,
    },
}
