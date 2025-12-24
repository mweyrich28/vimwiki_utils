local M = {}

local paths = require("vimwiki_utils.utils.paths")
local templates = require("vimwiki_utils.utils.templates")

---@param tag_name string
---@param tag_dir string
function M.create_new_tag(tag_name, tag_dir)
    local wiki = paths.get_active_wiki()
    local abs_tag_dir = wiki .. tag_dir .. "/" .. tag_name .. ".md"-- TODO: unifiy

    templates.generate_header(abs_tag_dir, tag_name, nil, nil, nil)
end


function M.create_new_note(new_note_name, atomic_note_dir, tag_dir, parent_note)
    local aktive_wiki = paths.get_active_wiki()
    local new_note_path = aktive_wiki .. "/" .. atomic_note_dir .. "/" .. new_note_name -- TODO: unifiy

    templates.choose_template(function(template_path)
        templates.generate_header(new_note_path, new_note_name, template_path, tag_dir, parent_note)
    end)
end

return M
