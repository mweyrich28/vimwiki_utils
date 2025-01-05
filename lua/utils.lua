local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

TEMPLATE_DIR = "templates"
DEFAULT_TEMPLATE_HEADER = "# HEADER\n> **date:** DATE  \n\n"

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
function M.generate_tag_index(search_pattern)
    local results = vim.fn.systemlist("rg --vimgrep " .. vim.fn.shellescape(search_pattern))

    table.sort(results, function(a, b)
        return a:lower() < b:lower()
    end)

    local index = "## Index"
    vim.api.nvim_put({ index }, "c", true, true)
    for _, result in ipairs(results) do
        local file_path = string.gsub(result, ":.*", "")         -- get path like 4_atomic_notes/MARKDOWN.md
        if file_path ~= "README.md" then
            local wiki_link = M.format_rel_md_link(file_path)
            vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all links
        end
    end
end

---@return string
function M.get_active_wiki()
    local current_dir = vim.fn.expand("%:p:h")
    local vimwiki_list = vim.g.vimwiki_list
    local best_match = ""
    local max_length = 0

    if not current_dir:match("/$") then
        current_dir = current_dir .. "/"
    end

    for _, wiki in ipairs(vimwiki_list) do
        local path = vim.fn.expand(wiki.path)
        if current_dir:sub(1, #path) == path then
            if #path > max_length then
                best_match = path
                max_length = #path
            end
        end
    end

    return best_match
end

function M.choose_template(callback)
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsTemplates" }

    local wiki = M.get_active_wiki()
    -- get all templates
    local results = vim.fn.systemlist("find " .. wiki .. TEMPLATE_DIR .. " -type f -name '*.md'")

    local processed_results_table = M.format_results(TEMPLATE_DIR, results)
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
---@param results table
function M.format_results(prefix, results)
    local wiki = M.get_active_wiki()
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

    return { processed_results, file_map }
end

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
    local name_formatted = string.gsub(new_note_name, "_", " ")
    template_content = string.gsub(template_content, "HEADER", name_formatted)

    -- if a note is created from within a tag file, automatically add a link of that tag in the template
    if source_file ~= nil then
        local path_components = M.split_path(source_file)
        local source_note_dir = path_components[#path_components - 1]
        local source_note_name = path_components[#path_components]
        if source_note_dir == tag_dir then
            local tag_link = M.format_rel_md_link("../" .. tag_dir .. "/" .. source_note_name)
            template_content = string.gsub(template_content, "> %*%*tags:%*%*", "> **tags:** " .. tag_link .. "  ")
        end
    end

    -- open new empty note
    local file, err = io.open(new_note_path .. ".md", "w+")
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

---@param filename string
---@return string
function M.format_rel_md_link(filename)
    local parent_note = vim.fn.expand("%:p")
    local relative_path_prefix = M.gen_rel_prefix(parent_note)

    -- formatting identifier for md link: [identifier](path/to/note) (also removing unwanted suffixes)
    local formatted_name = string.gsub(
        string.gsub(
            string.gsub(M.get_path_suffix(filename), "%.md$", ""),
            "%.png$", ""
        ),
        "_", " "
    )
    return "[" .. formatted_name .. "]" .. "(" .. relative_path_prefix .. filename .. ")"
end

---@param path string
---@return string
function M.get_path_suffix(path)
    if not string.find(path, "/") then
        return path
    end

    local path_components = M.split_path(path)
    return path_components[#path_components]
end

---@param path string
---@return string
function M.convert_abs_to_rel(path)
    local wiki = M.get_active_wiki()
    local wiki_suffix = M.get_path_suffix(wiki)

    -- gets path based on wiki: /home/usr/wiki/4_atomic_notes/note.md -> 4_atomic_notes/note.md
    local parent_note_wiki_path = string.match(path, ".*/" .. wiki_suffix .. "/(.*)")
    return parent_note_wiki_path
end

---@param parent_note string
---@return string
function M.gen_rel_prefix(parent_note)
    local wiki = M.get_active_wiki()
    local curr_depht = M.get_depth(parent_note)
    local wiki_depth = M.get_depth(vim.fn.expand(wiki))

    -- Count the number of directories to go up
    local relative_path = ""
    for _ = 2, curr_depht - wiki_depth, 1 do
        relative_path = relative_path .. "../"
    end

    return relative_path
end

---@param new_note_name string
---@param atomic_note_dir string
---@param tag_dir string
---@param parent_note string
function M.create_new_note(new_note_name, atomic_note_dir, tag_dir, parent_note)
    local aktive_wiki = M.get_active_wiki()
    local new_note_path = aktive_wiki .. "/" .. atomic_note_dir .. "/" .. new_note_name

    M.choose_template(function(template_path)
        M.generate_header(new_note_path, new_note_name, template_path, tag_dir, parent_note)
    end)
end

---@param tag_name string
---@param tag_dir string
function M.create_new_tag(tag_name, tag_dir)
    local wiki = M.get_active_wiki()
    local abs_tag_dir = wiki .. tag_dir .. "/" .. tag_name

    M.generate_header(abs_tag_dir, tag_name, nil, nil, nil)
end

---@param dir string
---@param pattern string
---@param replacement string
function M.gsub_dir(dir, pattern, replacement)
    local command = "sed -i '' -e 's/" .. pattern .. "/" .. replacement .. "/g' " .. dir .. "/*.md"
    vim.fn.system(command)
end

return M
