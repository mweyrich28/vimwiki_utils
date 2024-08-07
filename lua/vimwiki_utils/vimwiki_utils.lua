local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require('vimwiki_utils.utils')


local ROUGH_NOTES_DIR = "1_rough_notes"
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


    local note_name = ""
    local wiki_link = ""

    pickers.new(opts, {

        finder = finders.new_table({
            results = processed_results
        }),

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)

            -- default action
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_name = selection.value
                wiki_link = utils.link_to_note(file_map[note_name], wiki)
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)
            -- creates new file based on a selected template 
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                note_name = action_state.get_current_line()
                wiki_link = utils.format_md_link(note_name)
                vim.api.nvim_put({ wiki_link }, "", true, true)
                utils.create_new_note(note_name)
            end)

            return true
        end
    }):find()
end


function M.vimwiki_utils_rough()
    local rough_note_name = vim.fn.input('Create rough note: ')
    -- normalizing path, this handels the case where the wiki path defined in vim.g.vimwiki_list has a "~" as prefix
    local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
    local wiki_suffix = utils.get_path_suffix(current_dir)
    local wiki = string.match(current_dir,  "(.-" .. wiki_suffix .. ")")
    local destination = wiki .. "/" .. ROUGH_NOTES_DIR .. "/" .. rough_note_name
    utils.choose_template(function(template_path)
        utils.generate_header(destination, rough_note_name, template_path)
        -- delay editing of newly created note to avoid asynchronous file operations      
        vim.defer_fn(function()
            vim.cmd("edit " .. destination .. ".md")
        end, 100)
    end)
end


function M.setup()

    vim.api.nvim_create_user_command('VimwikiUtilsLink', function()
        M.vimwiki_utils_link()
    end, {})
    
    vim.api.nvim_create_user_command('VimwikiUtilsRough', function()
        M.vimwiki_utils_rough()
    end, {})

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', '<C-b>', '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', '<leader>vr', '<cmd>VimwikiUtilsRough<CR>', { noremap = true, silent = true })
        end,
    })
end

return M
