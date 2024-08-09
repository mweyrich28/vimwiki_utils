local pickers = require "telescope.pickers"
local telescope = require("telescope.builtin")
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
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsLink" }
    opts.file_ignore_patterns = { TAG_DIR }

    local wiki = utils.get_active_wiki()
    local results = vim.fn.systemlist("find " ..  wiki .. " -type f -name '*.md'")
    local processed_results_table = utils.format_results(ATOMIC_NOTES_DIR, results)
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
                wiki_link = utils.link_to_note(file_map[note_name])
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
    local wiki = utils.get_active_wiki()
    local destination = wiki .. ROUGH_NOTES_DIR .. "/" .. rough_note_name
    utils.choose_template(function(template_path)
        utils.generate_header(destination, rough_note_name, template_path)
        -- delay editing of newly created note to avoid asynchronous file operations      
        vim.defer_fn(function()
            vim.cmd("edit " .. destination .. ".md")
        end, 100)
    end)
end


function M.vimwiki_utils_backlinks()
    local current_file = vim.fn.expand('%:t')
    current_file = current_file:gsub(".md", "")
    local backlink_pattern = "\\[*\\]\\(.*" .. current_file .. "[.md\\)|\\)]"

    telescope.live_grep({
        prompt_title = "VimwikiUtilsBacklinks",
        default_text = backlink_pattern,
        no_ignore = true,
        hidden = true,
        entry_maker = function(entry)
            local file, lnum, col, text = string.match(entry, "(.-):(%d+):(%d+):(.*)")
            if file and lnum and col and text then
                local filename = utils.get_path_suffix(file)
                return {
                    display = filename,
                    filename = file,
                    lnum = tonumber(lnum),
                    col = tonumber(col),
                    text = text,
                    ordinal = entry,
                }
            end
        end,
        attach_mappings = function(prompt_bufnr, map)

            -- press opt enter to generate index
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                utils.generate_index(backlink_pattern)
            end)
            actions.select_default:replace(function()
                actions.file_edit(prompt_bufnr)
            end)
            return true
        end,
    })
end


-- local function get_tag(file_name)
--     -- get fist wiki (like this it only works for the first defined wiki in vimwiki_list) TODO
--     local vault_path = vim.g.vimwiki_list[1].path
--     local current_file_path = vim.fn.expand("%:p")
--     
--     -- tag dir
--     local tag_dir = "3_tags/"
--
--     local curr_depht = get_depth(current_file_path)
--     local vault_depth = get_depth(vault_path)
--
--     -- Count the number of directories to go up
--     local relative_path = ""
--     for i=3, curr_depht - vault_depth,1 do
--         relative_path = relative_path .. "../"
--     end
--
--     -- Append the path to the markdown file
--     relative_path = relative_path .. tag_dir .. file_name
--     local wiki_link = "[".. string.gsub(file_name, ".md", "") .."]" .. "(" .. relative_path .. ")"
--
--     return wiki_link
-- end
--
-- local function generate_new_tag(tag_name)
--     Job:new({
--         command = "/home/malte/.config/scripts/vimwiki_link.sh",
--     args = { "/home/malte/documents/zettelkasten/3_tags/" .. tag_name, tag_name},
--     }):start()
-- end
--
--
function M.vimwiki_utils_tags()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsTags" }
    local wiki = utils.get_active_wiki()
    local path_to_tags = wiki .. TAG_DIR
    local results = vim.fn.systemlist("find " ..  path_to_tags.. " -type f -name '*.md'")
    local processed_results_table = utils.format_results(TAG_DIR, results)
    local processed_results = processed_results_table[1]
    local file_table = processed_results_table[2]

    pickers.new(opts, {
        finder = finders.new_table({
            results = processed_results
        }),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)

                -- press opt enter to generate new tag (creates empty file with header in TAG_DIR)
                map('i', '<A-CR>', function()
                    local new_tag_name = action_state.get_current_line()
                    actions.close(prompt_bufnr)
                    utils.create_new_tag(new_tag_name, TAG_DIR)
                    local tag_link = utils.format_rel_md_link(TAG_DIR .. "/" .. new_tag_name .. ".md")
                    vim.api.nvim_put({ tag_link }, "", true, true)
                end)

                -- or link to already existing tag
                map('i', '<CR>', function()
                    local selection = action_state.get_selected_entry()
                    if selection then
                        actions.close(prompt_bufnr)
                        local tag_name = selection.value
                        local tag_link = utils.format_rel_md_link(file_table[tag_name])
                        vim.api.nvim_put({ tag_link }, "", true, true)
                    end
                end)
          
            return true
        end
    }):find()
end


function M.setup()

    vim.api.nvim_create_user_command('VimwikiUtilsLink', function()
        M.vimwiki_utils_link()
    end, {})
    
    vim.api.nvim_create_user_command('VimwikiUtilsRough', function()
        M.vimwiki_utils_rough()
    end, {})
    
    vim.api.nvim_create_user_command('VimwikiUtilsBacklinks', function()
        M.vimwiki_utils_backlinks()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsTags', function()
        M.vimwiki_utils_tags()
    end, {})
    
    vim.api.nvim_create_user_command('VimwikiUtilsTest', function()
        
    end, {})

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', '<C-b>', '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'i', '<C-e>', '<cmd>VimwikiUtilsTags<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', '<leader>nn', '<cmd>VimwikiUtilsRough<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', '<leader>fb', '<cmd>VimwikiUtilsBacklinks<CR>', { noremap = true, silent = true })
        end,
    })
end

return M
