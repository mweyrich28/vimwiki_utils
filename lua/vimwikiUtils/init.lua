local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require('vimwikiUtils.utils')

local TAG_DIR = "3_tags"
local ATOMIC_NOTES_DIR = "4_atomic_notes"

local M = {}

function M.vimwikiUtils_link()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiLink" }
    -- ignore tags
    opts.file_ignore_patterns = { TAG_DIR }

    -- TODO: get current wiki
    local wiki = vim.g.vimwiki_list[1].path
    -- get all md files in wiki
    local results = vim.fn.systemlist("find " ..  wiki .. " -type f -name '*.md'")
    -- table for notes to display
    local processed_results = {}
    -- table for actual note paths
    local file_map = {}

    -- requred for formatting
    local wiki_suffix = utils.get_path_suffix(wiki)

    -- strip all results of their leading relative path
    -- NOTE: currently only searching for atomic notes in ATOMIC_NOTES_DIR
    for _, path in ipairs(results) do
        local markdown_file = string.match(path, ".*/" .. wiki_suffix .. "/" .. ATOMIC_NOTES_DIR .. "/(.*)")
        if markdown_file then
            table.insert(processed_results, markdown_file)
            -- map the displayed name to path relative to wiki
            file_map[markdown_file] = string.match(path, wiki_suffix .. "/(.*)")
        end
    end

    -- restore order to results
    table.sort(processed_results, function(a, b)
        return a:lower() < b:lower()
    end)

    local note_md_name = ""
    local wiki_link = ""

    pickers.new(opts, {
        finder = finders.new_table({
            results = processed_results
        }),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_md_name = selection.value
                -- links file
                wiki_link = utils.link_to_note(file_map[note_md_name], wiki)
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)

            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                note_md_name = action_state.get_current_line()
                -- creates new file with a template and also creates a link
                wiki_link = utils.create_new_wiki(note_md_name)
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)

            return true
        end
    }):find()
end

return M
