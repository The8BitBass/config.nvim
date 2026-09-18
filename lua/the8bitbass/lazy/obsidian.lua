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

local newFromTemplate = function(template)
    local title = getInput("Enter " .. vim.fs.basename(template) .. " title or path (optional):", { completion = "file" })
    if title == nil then
        return
    end

    require("obsidian.actions").new_from_template(title, template, function(note) note:open({ sync = true }) end)
end

return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    -- lazy = true,
    -- ft = "markdown",
    opts = {
        workspaces = {
            {
                name = "pint",
                path = os.getenv("HOME") .. "/personal/pint",
            },
        },
        legacy_commands = false,
        notes_subdir = "Inbox",
        footer = {
            enabled = true,
        },
        frontmatter = {
            enabled = function(filename)
                local name = string.lower(filename or "")
                return not name:find("shoppinglist", 1, true) and not name:find("inbox", 1, true)
            end,
        },
        -- Optional, for templates (see https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template)
        templates = {
            folder = "Templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
            -- A map for custom variables, the key should be the variable and the value a function.
            -- Functions receive an obsidian.TemplateContext and an optional format suffix.
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
                contact = {
                    notes_subdir = "People",
                },
                recipe = {
                    notes_subdir = "Recipes",
                },
                topic = {
                    notes_subdir = "Topics",
                },
            },
        },
        -- Optional, define your own callbacks to further customize behavior.
        callbacks = {
            create_note = function(note, opts)
                if opts.scope == "plain" and note.title and note.title ~= note.id then
                    note:add_alias(note.title)

                    local filename = note.title
                        :gsub("(%s)(%a)", function(_, letter) return letter:upper() end)
                        :gsub("^%a", string.upper)
                        :gsub("%s+", "")
                    note.path = (assert(note.path:parent()) / filename):with_suffix(".md", true)
                end
            end,
            post_setup = function()
                vim.keymap.set("n", "<leader>on", function() vim.cmd("Obsidian new") end, { desc = "New [N]ote" })
                vim.keymap.set("n", "<leader>of", function() vim.cmd("Obsidian new_from_template") end, { desc = "New note [F]rom template" })
                vim.keymap.set("n", "<leader>op", function() newFromTemplate("contact") end, { desc = "New [P]erson" })
                vim.keymap.set("n", "<leader>oi", function() newFromTemplate("idea") end, { desc = "New [I]dea" })
                vim.keymap.set("n", "<leader>or", function() newFromTemplate("recipe") end, { desc = "New [R]ecipe" })
                vim.keymap.set("n", "<leader>ot", function() newFromTemplate("topic") end, { desc = "New [T]opic" })
                vim.keymap.set("n", "<leader>occ", function() newFromTemplate("Communications/conversation") end, { desc = "New [C]onversation" })
                vim.keymap.set("n", "<leader>oce", function() newFromTemplate("Communications/email") end, { desc = "New [E]mail" })
                vim.keymap.set("n", "<leader>oci", function() newFromTemplate("Communications/interview") end, { desc = "New [I]nterview" })
                vim.keymap.set("n", "<leader>ocm", function() newFromTemplate("Communications/meeting") end, { desc = "New [M]eeting" })
                vim.keymap.set("n", "<leader>ocp", function() newFromTemplate("Communications/phonecall") end, { desc = "New [P]honeCall" })
                vim.keymap.set("n", "<leader>oma", function() newFromTemplate("Media/article") end, { desc = "New [A]rticle" })
                vim.keymap.set("n", "<leader>omt", function() newFromTemplate("Media/boardgame") end, { desc = "New [T]abletop/board game" })
                vim.keymap.set("n", "<leader>omb", function() newFromTemplate("Media/book") end, { desc = "New [B]ook" })
                vim.keymap.set("n", "<leader>omm", function() newFromTemplate("Media/movie") end, { desc = "New [M]ovie" })
                vim.keymap.set("n", "<leader>oms", function() newFromTemplate("Media/show") end, { desc = "New [S]how" })
                vim.keymap.set("n", "<leader>omv", function() newFromTemplate("Media/video") end, { desc = "New [V]ideo" })
                vim.keymap.set("n", "<leader>omg", function() newFromTemplate("Media/videogame") end, { desc = "New Video [G]ame" })
            end,
            enter_note = function(note)
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
                    note:update_frontmatter(bufnr)
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
