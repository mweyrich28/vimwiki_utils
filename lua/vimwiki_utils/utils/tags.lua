local M = {}

local links = require('vimwiki_utils.utils.links')

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
            local wiki_link = links.format_rel_md_link(file_path)
            vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all links
        end
    end
end

return M
