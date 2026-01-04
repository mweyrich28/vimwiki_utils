local M = {}

local links = require('vimwiki_utils.utils.links')

function M.generate_tag_index()
    local current_file = vim.fn.expand('%:t')
    current_file = current_file:gsub(".md", "")
    local search_pattern = "\\[*\\]\\(.*" .. current_file .. "[.md\\)|\\)]"
    local results = vim.fn.systemlist("rg --vimgrep " .. vim.fn.shellescape(search_pattern))

    table.sort(results, function(a, b)
        return a:lower() < b:lower()
    end)

    for _, result in ipairs(results) do
        local file_path = string.gsub(result, ":.*", "")         -- get path like 4_atomic_notes/MARKDOWN.md
        if file_path ~= "README.md" then
            local parent_note = vim.fn.expand("%:p")
            local wiki_link = links.format_rel_md_link(file_path, parent_note)
            vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all links
        end
    end
end

return M
