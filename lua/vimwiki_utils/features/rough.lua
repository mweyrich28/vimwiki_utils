local paths = require("vimwiki_utils.utils.paths")
local templates = require("vimwiki_utils.utils.templates")
local config = require("vimwiki_utils.config")

local M = {}

function M.create_rough()
    local new_note_name = vim.fn.input('Create rough note: ') .. ".md" -- TODO: unify
    local wiki = paths.get_active_wiki()
    local note_path = vim.fs.joinpath(wiki, config.options.globals.rough_notes_dir, new_note_name)
    templates.choose_template(function(template_path)
        templates.generate_header(note_path, new_note_name, template_path)
        -- delay editing of newly created note to avoid asynchronous file operations
        vim.defer_fn(function()
            vim.cmd("edit " .. note_path)
        end, 100)
    end)
end

return M
