local INPUT_CANCELLED = "~~~INPUT-CANCELLED~~~"

--- Prompt user for an input. Returns nil if canceled, otherwise a string (possibly empty).
---
---@param prompt string
---@param opts { completion: string|?, default: string|? }|?
---
---@return string|?
local getInput = function(prompt, opts)
    opts = opts or {}

    if not vim.endswith(prompt, " ") then
        prompt = prompt .. " "
    end

    local input = vim.trim(vim.fn.input({
        prompt = prompt,
        completion = opts.completion,
        default = opts.default,
        cancelreturn = INPUT_CANCELLED,
    }))

    if input ~= INPUT_CANCELLED then
        return input
    else
        return nil
    end
end

return {
    "the8bitbass/obsidian.nvim",
    dev = true,
    branch = "dragon-glass",
    -- lazy = true,
    -- ft = "markdown",
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
    },
    opts = {
        workspaces = {
            {
                name = "pint",
                path = os.getenv("HOME") .. "/personal/pint",
            },
        },
        legacy_commands = false,
        archive_subdir = "Archive",
        notes_subdir = "Inbox",
        note_path_func = function(spec)
            local function camelize(input)
                return input
                    :gsub("(%s)(%a)", function(_, letter) return letter:upper() end) -- uppercase letters after spaces
                    :gsub("^%a", string.upper) -- uppercase the first character if it's a letter
                    :gsub("%s+", "") -- remove all spaces
            end
            if spec.title then
                local path = spec.dir / camelize(tostring(spec.title))
                return path:with_suffix(".md")
            else
                -- This is equivalent to the default behavior.
                local path = spec.dir / tostring(spec.id)
                return path:with_suffix(".md")
            end
        end,
        statusline = {
            enabled = false,
        },
        disable_frontmatter = function(filename)
            print(filename)
            local fn = string.lower(filename)
            if string.find(fn, "shoppinglist") or string.find(fn, "inbox") then
                return true
            else
                return false
            end
        end,
        -- Optional, for templates (see https://github.com/obsidian-nvim/obsidian.nvim/wiki/Using-templates)
        templates = {
            folder = "Templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
            -- A map for custom variables, the key should be the variable and the value a function.
            -- Functions are called with obsidian.TemplateContext objects as their sole parameter.
            -- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#substitutions
            substitutions = {},

            -- A map for configuring unique directories and paths for specific templates
            --- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#customizations
            customizations = {
                conversation = {
                    notes_subdir = "Communications/Conversations",
                },
                email = {
                    notes_subdir = "Communications/Emails",
                },
                interview = {
                    notes_subdir = "Communications/Interviews",
                },
                meeting = {
                    notes_subdir = "Communications/Meetings",
                },
                phonecall = {
                    notes_subdir = "Communications/PhoneCalls",
                },
                article = {
                    notes_subdir = "Media/Articles",
                },
                boardgame = {
                    notes_subdir = "Media/BoardGames",
                },
                book = {
                    notes_subdir = "Media/Books",
                },
                movie = {
                    notes_subdir = "Media/Movies",
                },
                show = {
                    notes_subdir = "Media/Shows",
                },
                video = {
                    notes_subdir = "Media/Videos",
                },
                videogame = {
                    notes_subdir = "Media/VideoGames",
                },
                idea = {
                    notes_subdir = "Ideas"
                },
                person = {
                    notes_subdir = "People",
                },
                recipe = {
                    notes_subdir = "Recipes",
                },
            },
        },
        -- Optional, define your own callbacks to further customize behavior.
        callbacks = {
            post_setup = function(client)
                vim.keymap.set( "n", "<leader>on", function() vim.cmd("Obsidian new") end, { desc = "New Note" })
                vim.keymap.set( "n", "<leader>ot", function() vim.cmd("Obsidian new_from_template") end, { desc = "New note from template" })
                vim.keymap.set( "n", "<leader>op", function() vim.cmd("Obsidian new_from_template person") end, { desc = "New Person" })
                vim.keymap.set( "n", "<leader>oi", function() vim.cmd("Obsidian new_from_template idea") end, { desc = "New Idea" })
                vim.keymap.set( "n", "<leader>or", function() vim.cmd("Obsidian new_from_template recipe") end, { desc = "New Recipe" })
                vim.keymap.set( "n", "<leader>occ", function() vim.cmd("Obsidian new_from_template Communications/conversation") end, { desc = "New Recipe" })
            end,
            enter_note = function(client, note)
                local bufnr = note.bufnr
                vim.keymap.set("n", "<leader>T", function()
                    local success, tags = pcall(getInput, "Enter space separated Tags:", { completion = "file" })
                    if not success or not tags then
                        return
                    end
                    for tag in string.gmatch(tags, "%S+") do
                        local trimmed = vim.trim(tag)
                        if trimmed ~= "" then
                            note:add_tag(trimmed)
                        end
                    end
                    -- note:add_tag(tag)
                    note:force_update_frontmatter(bufnr)
                end, { buffer = bufnr, remap = false, desc = "Add Tags" })
            end,
        },
        daily_notes = {
            -- Optional, if you keep daily notes in a separate directory.
            folder = "Journal",
            -- Optional, if you want to change the date format for the ID of daily notes.
            date_format = "%Y/%m-%B/%Y-%m-%d",
            -- Optional, if you want to change the date format of the default alias of daily notes.
            -- alias_format = "%B %-d, %Y",
            -- Optional, default tags to add to each new daily note created.
            -- default_tags = { "daily-notes" },
            -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
            -- template = nil,
            -- Optional, if you want `Obsidian yesterday` to return the last work day or `Obsidian tomorrow` to return the next work day.
            workdays_only = false,
        },
    },
}
