local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

TEMPLATE_HEADER = "# %s\n> **date:** %s  \n> **tags:** \n> **material:**\n\n"
TEMPLATE_DIR = "templates"

local M = {}

---@param path string
---@return table
function M.split_path(path)
    local parts = {}
    -- Match any sequence of characters between slashes
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

---@param search_pattern string 
function M.generate_index(search_pattern)
    local wiki = vim.g.vimwiki_list[1].path
    local results = vim.fn.systemlist("rg --vimgrep " .. vim.fn.shellescape(search_pattern))

    table.sort(results, function(a, b)
        return a:lower() < b:lower()
    end)

    local index = "# Index"
    vim.api.nvim_put({ index }, "l", true, true)
    for _, result in ipairs(results) do
        local file_path = string.gsub(result, ":.*", "") -- get path like 4_atomic_notes/MARKDOWN.md
        local wiki_link = M.format_rel_md_link(file_path, wiki)
        vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all links
    end
end


function M.choose_template(callback)
    local opts = require("telescope.themes").get_dropdown { prompt_title = "Templates" }

    local wiki = vim.g.vimwiki_list[1].path
    -- get all templates
    local results = vim.fn.systemlist("find " ..  wiki .. TEMPLATE_DIR .. " -type f -name '*.md'")

    local processed_results_table = M.format_results(TEMPLATE_DIR, wiki, results)
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


---@param path string
---@return number
function M.get_depth(path)
    local path_table = M.split_path(path)
    local depth = 0
    for _, _ in ipairs(path_table) do
        depth = depth + 1
    end
    return depth
end


---@param prefix string
---@param wiki string
---@param results table
function M.format_results(prefix, wiki, results)
    local processed_results = {}
    local file_map = {}
    local wiki_suffix = M.get_path_suffix(wiki)
    for _, path in ipairs(results) do
        local markdown_file = string.match(path, ".*/" .. prefix .. "/(.*)")
        if markdown_file then
            table.insert(processed_results, markdown_file)
            -- map the displayed name to path relative to wiki
            file_map[markdown_file] = string.match(path, wiki_suffix .. "/(.*)")
        end
    end

    -- restore order to results
    table.sort(processed_results, function(a, b)
        return a:lower() < b:lower()
    end)

    return {processed_results, file_map}
end


---@param abs_path_new_file string
---@param header_new_file string
---@param template_filename string
function M.generate_header(abs_path_new_file, header_new_file, template_filename)
    local file, err = io.open(template_filename, "r")
    if file == nil then
        print("Error opening template file: " .. err)
        return
    end

    local template_content = file:read("*all")
    file:close()

    -- replace DATE
    local formatted_date = os.date("%Y-%m-%d")
    template_content = string.gsub(template_content, "DATE", formatted_date)

    -- replace HEADER
    local name_formatted = string.gsub(header_new_file, "_", " ")
    template_content = string.gsub(template_content, "HEADER", name_formatted)
    print(abs_path_new_file)
    file, err = io.open(abs_path_new_file .. ".md", "w+")
    if file == nil then
        print("Error opening new file: " .. err)
        return
    end

    local success, write_err = file:write(template_content)
    if not success then
        print("Error writing to new file: " .. write_err)
    end

    file:close()
end


---@param filename string
---@return string
function M.format_md_link(filename)
    local markdown_name = filename.match(filename, "[^/]+$")
    local wiki_md_link = "[" .. string.gsub(markdown_name, "_", " ") .. "]" .. "(" .. filename.. ".md)"
    return wiki_md_link
end


---@param filename string
---@return string
function M.format_rel_md_link(filename, wiki)
    local parent_note_abs_path = vim.fn.expand("%:p")
    local relative_path_prefix = M.gen_rel_prefix(wiki, parent_note_abs_path)
    -- formatting identifier for md link: [identifier](path/to/child_note)
    local formatted_name = string.gsub(string.gsub(M.get_path_suffix(filename), ".md", ""), "_", " ")
    return "[" .. formatted_name .. "]" .. "(" ..relative_path_prefix .. filename.. ")"
end


---@param path string
---@return string
function M.get_path_suffix(path)
    local path_components = M.split_path(path)
    return path_components[#path_components]
end


---@param parent_note_path string
---@param child_note_path string
---@param wiki string
---@return boolean
function M.same_level(parent_note_path, child_note_path, wiki)
    local parent_note_wiki_path = M.convert_abs_to_rel(wiki, parent_note_path)
    -- check if parent_note is located in same dir as child_note
    -- remove the last part of the file identifier (md)
    local dir_child_note = child_note_path.match(child_note_path, "(.*/)")
    local dir_parent_note = parent_note_path.match(parent_note_wiki_path, "(.*/)")

    if dir_child_note == dir_parent_note then
        return true
    end

    return false
end


---@param wiki string
---@param path string
---@return string
function M.convert_abs_to_rel(wiki, path)
    local wiki_suffix = M.get_path_suffix(wiki)

    -- gets path based on wiki: /home/usr/wiki/4_atomic_notes/note.md -> 4_atomic_notes/note.md
    local parent_note_wiki_path = string.match(path, ".*/" .. wiki_suffix .. "/(.*)")
    return parent_note_wiki_path
end


---@param wiki string
---@param parent_note_abs_path string
---@return string
function M.gen_rel_prefix(wiki, parent_note_abs_path)
    local curr_depht = M.get_depth(parent_note_abs_path)
    local wiki_depth = M.get_depth(wiki)

    -- adjsut depth based on wiki path in vim.g.vimwiki_list
    if string.sub(wiki, 1, 1) == "~" then
        wiki_depth = wiki_depth + 1
    end

    -- Count the number of directories to go up
    local relative_path = ""
    for _=2, curr_depht - wiki_depth,1 do
        relative_path = relative_path .. "../"
    end

    return relative_path
end


---@param child_note_wiki_path string
---@param wiki string
---@return string
function M.link_to_note(child_note_wiki_path, wiki)
    local parent_note_abs_path = vim.fn.expand("%:p")

    if M.same_level(parent_note_abs_path, child_note_wiki_path, wiki) then
        return M.format_md_link(M.get_path_suffix(child_note_wiki_path))
    end

    return M.format_rel_md_link(child_note_wiki_path, wiki)
end


---@param curr_file string 
function M.create_new_note(curr_file)
    local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
    local abs_path_new_note = current_dir .. "/" .. curr_file
    local markdown_name = curr_file.match(curr_file, "[^/]+$")

    M.choose_template(function(template_path)
        M.generate_header(abs_path_new_note, markdown_name, template_path)
    end)
end


---@param path string 
---@return string
function M.normalize_wiki_path(path)
    local wiki_suffix = M.get_path_suffix(path)
    local normalized_path = string.match(path,  "(.-" .. wiki_suffix .. ")")
    return normalized_path
end

return M
