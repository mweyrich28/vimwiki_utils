local M = {}

local paths = require("vimwiki_utils.utils.paths")
local templates = require("vimwiki_utils.utils.templates")
local config = require('vimwiki_utils.config')

---@param tag_name string
function M.create_new_tag(tag_name)
    local wiki = paths.get_active_wiki()
    local abs_tag_dir = vim.fs.joinpath(wiki, config.options.globals.tag_dir, tag_name)

    templates.generate_header(abs_tag_dir, tag_name , nil, nil)
end

-- TODO: fix params
function M.create_new_note(new_note_name, parent_note)
    local aktive_wiki = paths.get_active_wiki()
    local new_note_path = vim.fs.joinpath(aktive_wiki, config.options.globals.atomic_notes_dir, new_note_name)

    if config.options.templates.use_templates then
        templates.choose_template(function(template_path)
            templates.generate_header(new_note_path, new_note_name, template_path, parent_note)
        end)
    else
        templates.generate_header(new_note_path, new_note_name, "", parent_note)
    end
end

return M
