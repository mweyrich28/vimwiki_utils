local M = {}

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local config = require("vimwiki_utils.config")
local paths = require('vimwiki_utils.utils.paths')
local links = require('vimwiki_utils.utils.links')

local TEMPLATE_DIR = config.defaults.templates.dir or "templates"
local DEFAULT_TEMPLATE_HEADER = config.defaults.templates.default_header or "# HEADER\n- **date:** DATE  \n\n"

---@param new_note_path string
---@param new_note_name string
---@param template_filename string|nil
---@param tag_dir string|nil
---@param source_file string|nil
function M.generate_header(new_note_path, new_note_name, template_filename, tag_dir, source_file)
    local template_content = nil

    if template_filename == nil then
        template_content = DEFAULT_TEMPLATE_HEADER
    else
        local file, _ = io.open(template_filename, "r")
        if file == nil then
            print("Template " .. template_filename .. " does not exist!")
            return
        else
            template_content = file:read("*all")
            file:close()
        end
    end

    -- replace DATE
    local formatted_date = os.date("%Y-%m-%d")
    template_content = string.gsub(template_content, "DATE", formatted_date)

    -- replace HEADER
    local name_formatted = new_note_name:gsub("%.md$", ""):gsub("_", " ")
    template_content = template_content:gsub("HEADER", name_formatted)

    -- if a note is created from within a tag file, automatically add a link of that tag in the template
    if source_file ~= nil then
        local path_components = paths.split_path(source_file)
        local source_note_dir = path_components[#path_components - 1]
        local source_note_name = path_components[#path_components]
        if source_note_dir == tag_dir then

            local tag_path = vim.fs.joinpath(tag_dir, source_note_name)
            -- local tag_link = links.format_rel_md_link("../" .. tag_dir .. "/" .. source_note_name)
            local tag_link = links.format_rel_md_link(tag_path, source_file)
            template_content = string.gsub(template_content, "- %*%*Tags:%*%*", "- **Tags:** " .. tag_link .. "  ")
        end
    end

    -- open new empty note
    local file, err = io.open(new_note_path, "w+")
    if file == nil then
        print("Error opening new file: " .. err)
        return
    end

    -- dump template content into new note
    local success, write_err = file:write(template_content)
    if not success then
        print("Error writing to new file: " .. write_err)
    end

    file:close()
end


function M.choose_template(callback)
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsTemplates" }

    local wiki = paths.get_active_wiki()
    -- get all templates
    local results = vim.fn.systemlist("find " .. wiki .. TEMPLATE_DIR .. " -type f -name '*.md'")

    local processed_results_table = paths.format_results(TEMPLATE_DIR, results)
    local processed_results = processed_results_table[1]
    local file_map = processed_results_table[2]

    pickers.new(opts, {
        finder = finders.new_table({
            results = processed_results
        }),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                local selected_template_name = selection[1]
                local selected_template_path = file_map[selected_template_name]

                if callback then
                    callback(selected_template_path)
                end

                actions.close(prompt_bufnr)
            end)
            return true
        end
    }):find()
end

return M
