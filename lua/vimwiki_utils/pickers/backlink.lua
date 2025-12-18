
local telescope = require("telescope.builtin")
local actions = require("telescope.actions")

local paths = require("vimwiki_utils.utils.paths")
local tags = require("vimwiki_utils.utils.tags")

local M = {}

function M.open()
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
                local filename = paths.get_path_suffix(file)
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
        attach_mappings = function(prompt_bufnr, map) -- TODO: create separate func for this
            -- press opt enter to generate index
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                tags.generate_tag_index(backlink_pattern)
            end)
            actions.select_default:replace(function()
                actions.file_edit(prompt_bufnr)
            end)

            return true
        end,
    })
end

return M
