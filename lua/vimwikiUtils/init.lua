local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require('vimwikiUtils.utils')

local TAG_DIR = "3_tags"
local ATOMIC_NOTES_DIR = "4_atomic_notes"

local M = {}

function link_to_note(child_note_wiki_path, wiki)
    local parent_note_abs_path = vim.fn.expand("%:p")  -- get current file

    local same_level = utils.same_level(parent_note_abs_path, child_note_wiki_path, wiki)
    print(same_level)

    if same_level then
        return utils.format_md_link(utils.get_path_suffix(child_note_wiki_path))
    end
    
    return utils.format_rel_md_link(child_note_wiki_path, wiki)
end


function M.create_new_wiki(curr_file)
    local wiki_link = utils.format_md_link(curr_file)
    local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
    local wiki_md = current_dir .. "/" .. curr_file
    local markdown_name = curr_file.match(curr_file, "[^/]+$")

    utils.generate_header(wiki_md, markdown_name)
    return wiki_link
end


function M.vimwiki_link()
    
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiLink" }
    
    -- ignore tags
    opts.file_ignore_patterns = { TAG_DIR }

    -- TODO: get current wiki
    local wiki = vim.g.vimwiki_list[1].path
    
    -- get all md files in wiki
    local results = vim.fn.systemlist("find " ..  wiki .. " -type f -name '*.md'")
    local processed_results = {}  -- table for notes to display
    local file_map = {}  -- table for actual note paths

    -- requred for formatting
    local wiki_suffix = utils.get_path_suffix(wiki)

    -- strip all results of their leading relative path
    for _, path in ipairs(results) do
        local markdown_file = string.match(path, ".*/" .. wiki_suffix .. "/" .. ATOMIC_NOTES_DIR .. "/(.*)")
        if markdown_file then
            table.insert(processed_results, markdown_file)
            file_map[markdown_file] = string.match(path, wiki_suffix .. "/(.*)") -- map the displayed name to path relative to wiki
        end
    end

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
                wiki_link = link_to_note(file_map[note_md_name], wiki)
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)

            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                note_md_name = action_state.get_current_line()
                wiki_link = M.create_new_wiki(note_md_name)
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)

            return true
        end
    }):find()
end

return M
