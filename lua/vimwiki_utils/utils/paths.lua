local M = {}

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

---@param parent_note string
---@return string
function M.gen_rel_prefix(parent_note)
    local wiki = M.get_active_wiki()
    local curr_depht = M.get_depth(parent_note)
    local wiki_depth = M.get_depth(vim.fn.expand(wiki))

    -- Count the number of directories to go up
    local relative_path = ""
    local i = 0
    for _ = 2, curr_depht - wiki_depth, 1 do
        relative_path = relative_path .. "../"
        i = i+1
    end

    return relative_path
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

---@param path string
---@return string
function M.get_path_suffix(path)
    if not string.find(path, "/") then
        return path
    end

    local path_components = M.split_path(path)
    return path_components[#path_components]
end

return M
