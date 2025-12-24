local pickers = require("telescope.pickers")
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local links = require("vimwiki_utils.utils.links")
local paths = require("vimwiki_utils.utils.paths")
local config = require("vimwiki_utils.config")

local M = {}

function M.link_source()
    local opts = require("telescope.themes").get_dropdown {
        prompt_title = "VimwikiUtilsSource",
        file_ignore_patterns = {},
    }

    local sources = paths.get_active_wiki() .. config.options.globals.source_dir
    local results = vim.fn.systemlist("find " .. sources .. " -type f")
    local processed_results_table = paths.format_results(config.options.globals.source_dir, results)
    -- table for notes to display
    local processed_results = processed_results_table[1]
    -- table for actual note paths
    local file_map = processed_results_table[2]
    local note_name = ""
    local wiki_link = ""
    local parent_note = vim.fn.expand("%:p")

    pickers.new(opts, {

        finder = finders.new_table({
            results = processed_results
        }),

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_name = selection.value
                wiki_link = links.format_rel_md_link(file_map[note_name], parent_note)
                wiki_link = "!" .. string.gsub(wiki_link, "%(", "(./") -- formatting for vimwiki
                links.put_link(wiki_link)
            end)

            -- open pdf 
            map('i', '<S-CR>', function()
                local selection = action_state.get_selected_entry()
                if not selection then return end
                actions.close(prompt_bufnr)

                local note_name = selection.value
                local pdf_path = file_map[note_name]
                if pdf_path then
                    local open_cmd
                    if vim.fn.has('macunix') == 1 then
                        open_cmd = "open " .. vim.fn.shellescape(pdf_path)
                    elseif vim.fn.has('unix') == 1 then
                        open_cmd = "xdg-open " .. vim.fn.shellescape(pdf_path)
                    elseif vim.fn.has('win32') == 1 then
                        open_cmd = "start " .. vim.fn.shellescape(pdf_path)
                    end

                    if open_cmd then
                        vim.fn.jobstart(open_cmd, { detach = true })
                    else
                        vim.notify("Cannot determine system open command", vim.log.levels.ERROR)
                    end
                end
            end)

            return true
        end
    }):find()
end


return M
