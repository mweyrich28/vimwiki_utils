local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require('vimwiki_utils.utils')


local TAG_DIR = "3_tags"
local ATOMIC_NOTES_DIR = "4_atomic_notes"

local M = {}


function M.vimwiki_utils_link()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiLink" }
    -- ignore tags
    opts.file_ignore_patterns = { TAG_DIR }

    -- TODO: get current wiki
    local wiki = vim.g.vimwiki_list[1].path
    -- get all md files in wiki
    local results = vim.fn.systemlist("find " ..  wiki .. " -type f -name '*.md'")

    local processed_results_table = utils.format_results(ATOMIC_NOTES_DIR, wiki, results)
    -- table for notes to display
    local processed_results = processed_results_table[1]
    -- table for actual note paths
    local file_map = processed_results_table[2]


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
                wiki_link = utils.format_md_link(note_md_name)
                vim.api.nvim_put({ wiki_link }, "", true, true)
                
                -- creates new file based on a selected template 
                utils.create_new_wiki(note_md_name)

            end)

            return true
        end
    }):find()
end

function M.setup()

    vim.api.nvim_create_user_command('VimwikiUtilsLink', function()
        M.vimwiki_utils_link()
    end, {})

    -- vim.api.nvim_set_keymap('i', '<C-b>', '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
    -- Create an autocommand to set keymap for viki files
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',  -- Adjust this pattern if your filetype is named differently
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', '<C-b>', '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
        end,
    })
end

return M
