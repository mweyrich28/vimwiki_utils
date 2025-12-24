local paths = require("vimwiki_utils.utils.paths")
local templates = require("vimwiki_utils.utils.templates")
local config = require("vimwiki_utils.config")
local utils = require("vimwiki_utils.utils.general")

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


function M.rename()
    -- save current buffers
    vim.cmd("wall")

    local old_filepath = vim.fn.expand('%:p')
    local old_filename = paths.get_path_suffix(old_filepath)
    local formatted_old_filename = string.gsub(old_filename, "%.md$", "")

    local confirm = vim.fn.input("Rename " .. string.gsub(old_filename, ".md", "") .. "? (y/n): ")

    local dir = nil

    if string.find(old_filepath, config.options.globals.atomic_notes_dir) then
        dir = config.options.globals.atomic_notes_dir
    elseif string.find(old_filepath, config.options.globals.tag_dir) then
        dir = config.options.globals.tag_dir
    elseif string.find(old_filepath, config.options.globals.rough_notes_dir) then
        dir = config.options.globals.rough_notes_dir
    else
        print("No dir found")
        return
    end


    if confirm:lower() == 'y' then
        local new_filename = vim.fn.input(formatted_old_filename .. " → ", formatted_old_filename)

        if new_filename == "" then
            print("Rename canceled.")
            return
        end

        if new_filename:sub(-3) ~= ".md" then -- TODO: Unify
            new_filename = new_filename .. ".md"
        end


        local new_path = vim.fn.fnamemodify(dir, ':p') .. new_filename

        if vim.fn.filereadable(new_path) == 1 then
            print("Error: Cannot rename file to'" .. new_path .. "', it already exists!")
            return
        end

        local new_filename_identifier = string.gsub(new_filename, ".md", "")

        -- Strategy: [note name](../path/to/note_name.md) → [new note name](../dir/new_note_name.md)
        -- base case where identifier == gsub(note_name, "_", " ") (the default pattern when creating a new file with VimwikiUtilsLink)
        -- TODO: Unify
        local strict_pattern = "\\[" ..
            string.gsub(formatted_old_filename, "_", " ") .. "\\](..\\/" .. dir .. "\\/" .. old_filename .. ")"
        local strict_replacement = "\\[" ..
            string.gsub(new_filename_identifier, "_", " ") .. "\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy: [unique identifier](../path/to/note_name.md) → [unique identifier](../dir/new_note_name.md)
        -- Unique identifier + link formatted with "../" prefix
        local uniq_pattern = "\\[\\(.*\\)\\](..\\/" .. dir .. "\\/" .. old_filename .. ")"
        local uniq_replacement = "\\[\\1\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy: [unique identifier](note_name.md) → [unique identifier](../dir/new_note_name.md)
        -- Unique identifier + link formatted without "../" prefix
        local uniq_pattern_1 = "\\[\\(.*\\)\\](" .. old_filename .. ")"
        local uniq_replacement_1 = "\\[\\1\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy for files linked from within index/README: [note name](dir/note_name.md) → [new note name](dir/new_note_name.md)
        local index_pattern = "\\[.*\\](" .. dir .. "\\/" .. old_filename .. ")"
        local index_replacement = "\\[" ..
            string.gsub(new_filename_identifier, "_", " ") .. "\\](" .. dir .. "\\/" .. new_filename .. ")"

        utils.gsub_dir(config.options.globals.atomic_notes_dir, strict_pattern, strict_replacement)
        utils.gsub_dir(config.options.globals.atomic_notes_dir, uniq_pattern, uniq_replacement)
        utils.gsub_dir(config.options.globals.atomic_notes_dir, uniq_pattern_1, uniq_replacement_1)

        utils.gsub_dir(config.options.globals.tag_dir, strict_pattern, strict_replacement)
        utils.gsub_dir(config.options.globals.tag_dir, uniq_pattern, uniq_replacement)
        utils.gsub_dir(config.options.globals.tag_dir, uniq_pattern_1, uniq_replacement_1)

        utils.gsub_dir(".", index_pattern, index_replacement)


        vim.fn.rename(old_filepath, new_path)
        vim.cmd('edit ' .. new_path)
    end
end

return M
