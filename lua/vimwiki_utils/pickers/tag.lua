local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local paths = require("vimwiki_utils.utils.paths")
local notes = require("vimwiki_utils.utils.notes")
local tags = require("vimwiki_utils.utils.tags")
local links = require("vimwiki_utils.utils.links")
local config = require("vimwiki_utils.config")

local M = {}

function M.open()
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

return M
