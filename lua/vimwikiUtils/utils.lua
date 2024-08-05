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


---@param filename string
---@param header string
function M.generate_header(filename, header)
    local name_formatted = string.gsub(header, "_", " ")
    local vimwiki_header = string.format(
        "# %s\n> **date:** %s  \n> **tags:** \n> **material:**\n\n",
        name_formatted,
        os.date("%F")
    )
    local file = io.open(filename .. ".md", "a")
    file:write(vimwiki_header)
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
    local parent_note_abs_path = vim.fn.expand("%:p")  -- get current file
    local relative_path_prefix = M.gen_rel_prefix(wiki, parent_note_abs_path)
    local formatted_name = string.gsub(string.gsub(M.get_path_suffix(filename), ".md", ""), "_", " ")  -- formatting identifier for md link: [identifier](path/to/child_note)
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
    local dir_child_note = child_note_path.match(child_note_path, "(.*/)")  -- remove the last part of the file identifier (md)
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
    local parent_note_wiki_path = string.match(path, ".*/" .. wiki_suffix .. "/(.*)")  -- gets path based on wiki: /home/usr/wiki/4_atomic_notes/note.md -> 4_atomic_notes/note.md
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

return M
