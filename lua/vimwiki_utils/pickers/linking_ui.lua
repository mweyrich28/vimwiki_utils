local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local tags = require("vimwiki_utils.utils.tags")
local telescope = require("telescope.builtin")
local themes = require("telescope.themes")


local links = require("vimwiki_utils.utils.links")
local notes = require("vimwiki_utils.utils.notes")
local paths = require("vimwiki_utils.utils.paths")
local config = require("vimwiki_utils.config")

local M = {}

function M.link_tag()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsTags" }
    local wiki = paths.get_active_wiki()
    local path_to_tags = wiki .. config.options.globals.tag_dir
    local results = vim.fn.systemlist("find " .. path_to_tags .. " -type f -name '*.md'")
    local processed_results_table = paths.format_results(config.options.globals.tag_dir, results)
    local processed_results = processed_results_table[1]
    local file_table = processed_results_table[2]
    local parent_note = vim.fn.expand("%:p")

    pickers.new(opts, {
        finder = finders.new_table({
            results = processed_results
        }),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    -- link to already existing tag
                    actions.close(prompt_bufnr)
                    local tag_name = selection.value
                    local tag_link = links.format_rel_md_link(file_table[tag_name], parent_note)
                    links.put_link(tag_link)
                else
                    -- or creat new tag
                    local new_tag_name = action_state.get_current_line()
                    actions.close(prompt_bufnr)
                    notes.create_new_tag(new_tag_name, config.options.globals.tag_dir)

                    local tag_file = new_tag_name .. ".md" -- TODO: maybe add func to dynamically check/add ext
                    local tag_path = vim.fs.joinpath(config.options.globals.tag_dir, tag_file)
                    local tag_link = links.format_rel_md_link(tag_path, parent_note)
                    links.put_link(tag_link)
                end
            end)

            local function paste_selected_entry()
                local selection = action_state.get_selected_entry()
                if selection then
                    local file_name = selection.value
                    file_name = file_name:gsub(".md", "")
                    action_state.get_current_picker(prompt_bufnr):reset_prompt(file_name)
                end
            end

            map('i', '<Tab>', function()
                paste_selected_entry()
            end)


            -- or forcefully create new tag (even if there's a selection)
            map('i', '<A-CR>', function()
                local new_tag_name = action_state.get_current_line()
                actions.close(prompt_bufnr)
                notes.create_new_tag(new_tag_name, config.options.globals.tag_dir)

                local tag_file = new_tag_name .. ".md" -- TODO: maybe add func to dynamically check/add ext
                local tag_path = vim.fs.joinpath(config.options.globals.tag_dir, tag_file)
                local tag_link = links.format_rel_md_link(tag_path, parent_note)
                links.put_link(tag_link)
            end)

            return true
        end
    }):find()
end

function M.link_note()
    local opts = themes.get_dropdown {
        prompt_title = "VimwikiUtilsLink",
    }

    opts.file_ignore_patterns = {
        config.options.globals.tag_dir,
    }

    local globals = config.options.globals
    local wiki = paths.get_active_wiki()

    local results = vim.fn.systemlist(
        "find " .. wiki .. " -type f -name '*.md'"
    )

    local processed, file_map =
        unpack(paths.format_results(globals.atomic_notes_dir, results))

    local source_file = vim.fn.expand("%:p")

    pickers.new(opts, {
        finder = finders.new_table {
            results = processed,
        },

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
            local function paste_selected_entry()
                local selection = action_state.get_selected_entry()
                if not selection then return end

                local file_name = selection.value:gsub("%.md$", "")
                action_state
                    .get_current_picker(prompt_bufnr)
                    :reset_prompt(file_name)
            end

            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local note_name

                if selection then
                    note_name = selection.value
                else
                    note_name = action_state.get_current_line() .. ".md"
                end

                local file_path = vim.fs.joinpath(globals.atomic_notes_dir, note_name)
                local parent_note = vim.fn.expand("%:p")
                local wiki_link = links.format_rel_md_link(file_path, parent_note)

                links.put_link(wiki_link)

                if not selection then
                    notes.create_new_note(
                        note_name,
                        globals.atomic_notes_dir,
                        globals.tag_dir,
                        source_file
                    )
                end
            end)

            map("i", "<A-CR>", function()
                actions.close(prompt_bufnr)

                local note_name = action_state.get_current_line() .. ".md"
                local file_path = vim.fs.joinpath(globals.atomic_notes_dir, note_name)
                local parent_note = vim.fn.expand("%:p")
                local wiki_link = links.format_rel_md_link(file_path, parent_note)
                links.put_link(wiki_link)

                notes.create_new_note(
                    note_name,
                    globals.atomic_notes_dir,
                    globals.tag_dir,
                    source_file
                )
            end)

            map("i", "<Tab>", paste_selected_entry)

            return true
        end,
    }):find()
end

function M.display_backlinks()
    local current_file = vim.fn.expand("%:t:r")
    local backlink_pattern =
        "\\[*\\]\\(.*" .. current_file .. ".md"

    local results = vim.fn.systemlist(
        "rg --vimgrep " .. vim.fn.shellescape(backlink_pattern)
    )

    pickers.new({}, {
        prompt_title = "VimwikiUtilsBacklinks",
        finder = finders.new_table {
            results = results,
            entry_maker = function(entry)
                local file, lnum, col, text =
                    entry:match("^(.-):(%d+):(%d+):(.*)$")

                if not file then return nil end

                return {
                    value = entry,
                    filename = file,
                    lnum = tonumber(lnum),
                    col = tonumber(col),
                    text = text,
                    display = function()
                        return paths.get_path_suffix(file) .. ": [l." .. lnum .. "]"
                    end,
                    ordinal = file .. " " .. text,
                }
            end,
        },

        sorter = conf.generic_sorter({}),

        previewer = conf.grep_previewer({}),

        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local entry = action_state.get_selected_entry()

                vim.cmd.edit(entry.filename)
                vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
            end)
            return true
        end,
    }):find()
end

return M
