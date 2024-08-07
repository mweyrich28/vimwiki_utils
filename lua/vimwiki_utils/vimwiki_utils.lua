local pickers = require "telescope.pickers"
local telescope = require("telescope.builtin")
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require('telescope.previewers')
local utils = require('vimwiki_utils.utils')


local ROUGH_NOTES_DIR = "1_rough_notes"
local TAG_DIR = "3_tags"
local ATOMIC_NOTES_DIR = "4_atomic_notes"

local M = {}

function M.vimwiki_utils_link()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsLink" }
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


function M.ivimwiki_utils_backlinks()
    local current_file = vim.fn.expand('%:t')
    -- Remove the .md extension
    current_file = current_file:gsub("%.md$", "")
    local search_pattern = "\\[*\\]\\(.*" .. current_file .. "[.md\\)|\\)]"

    -- Create a custom picker
    pickers.new({}, {
        prompt_title = "Wiki Backlinks",
        finder = finders.new_oneshot_job(
            {"rg", "--vimgrep", "--no-ignore", "--hidden", search_pattern, "."},
            {
                entry_maker = function(entry)
                    -- Format entries to show only the filename and line info
                    local full_path, lnum, col, text = string.match(entry, "(.-):(%d+):(%d+):(.*)")

                    if full_path and lnum and col and text then
                        -- Extract just the filename from the full path
                        local filename = vim.fn.fnamemodify(full_path, ":t")
                        -- Optionally extract text up to ">"
                        local formatted_text = text:match("^(.-)>") or text

                        return {
                            display = filename .. ":" .. lnum .. ": " .. formatted_text,
                            filename = full_path,
                            lnum = tonumber(lnum),
                            col = tonumber(col),
                            text = text,
                            ordinal = entry,
                        }
                    end
                end
            }
        ),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local filename = entry.filename
                local lnum = entry.lnum or 0

                -- Read the file content
                local file_content = vim.fn.readfile(filename)

                -- Set the buffer content
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, file_content)

                -- Determine filetype from the filename
                local file_extension = filename:match("^.+(%..+)$")
                if file_extension then
                    -- Set the filetype to enable syntax highlighting
                    local filetype = vim.fn.fnamemodify(file_extension, ":e")
                    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)
                end

                -- Center the preview around the matched line
                vim.api.nvim_buf_call(self.state.bufnr, function()
                    vim.fn.cursor(lnum, 0)
                    vim.cmd("normal! zt")
                end)
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.file_edit(prompt_bufnr)
                end
            end)
            return true
        end,
    }):find()
end

function M.vimwiki_utils_backlinks()
    local current_file = vim.fn.expand('%:t')
    -- Remove the .md extension
    current_file = current_file:gsub("%.md$", "")
    local search_pattern = "\\[*\\]\\(.*" .. current_file .. "[.md\\)|\\)]"

    -- Create a custom picker
    pickers.new({}, {
        prompt_title = "Wiki Backlinks",
        finder = finders.new_oneshot_job(
            {"rg", "--vimgrep", "--no-ignore", "--hidden", search_pattern, "."},
            {
                entry_maker = function(entry)
                    -- Format entries to show only the filename and line info
                    local full_path, lnum, col, text = string.match(entry, "(.-):(%d+):(%d+):(.*)")

                    if full_path and lnum and col and text then
                        -- Extract just the filename from the full path
                        local filename = vim.fn.fnamemodify(full_path, ":t")
                        -- Optionally extract text up to ">"
                        local formatted_text = text:match("^(.-)>") or text

                        return {
                            display = filename .. ":" .. lnum .. ": " .. formatted_text,
                            filename = full_path,
                            lnum = tonumber(lnum),
                            col = tonumber(col),
                            text = text,
                            ordinal = entry,
                        }
                    end
                end
            }
        ),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local filename = entry.filename
                local lnum = entry.lnum or 0

                -- Read the file content
                local file_content = vim.fn.readfile(filename)

                -- Set the buffer content
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, file_content)

                -- Determine filetype from the filename
                local file_extension = filename:match("^.+(%..+)$")
                if file_extension then
                    local filetype = file_extension:match("%.(.+)$") or "text"
                    -- Set the filetype to enable syntax highlighting
                    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)
                else
                    -- Default to "text" if no filetype is detected
                    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "text")
                end

                -- Center the preview around the matched line
                vim.api.nvim_buf_call(self.state.bufnr, function()
                    vim.fn.cursor(lnum, 0)
                    vim.cmd("normal! zt")
                end)
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.file_edit(prompt_bufnr)
                end
            end)
            return true
        end,
    }):find()
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

            -- press ctrl enter to generate new tag
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

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', '<C-b>', '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', '<leader>fb', '<cmd>VimwikiUtilsBacklinks<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', '<leader>vr', '<cmd>VimwikiUtilsRough<CR>', { noremap = true, silent = true })
        end,
    })
end

return M
