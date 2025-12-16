local M = {}

local paths = require("vimwiki_utils.utils.paths")

---@param formatted_link string
function M.put_link(formatted_link)
    vim.api.nvim_put({ formatted_link }, "", true, true)
end

---@param filename string
---@return string
function M.format_rel_md_link(filename)
    local parent_note = vim.fn.expand("%:p")
    local relative_path_prefix = paths.gen_rel_prefix(parent_note)

    -- formatting identifier for md link: [identifier](path/to/note) (also removing unwanted suffixes)
    local formatted_name = string.gsub(
        string.gsub(
            string.gsub(paths.get_path_suffix(filename), "%.md$", ""),
            "%.png$", ""
        ),
        "_", " "
    )
    return "[" .. formatted_name .. "]" .. "(" .. relative_path_prefix .. filename .. ")"
end


return M
