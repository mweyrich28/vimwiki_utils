local M = {}

local paths = require("vimwiki_utils.utils.paths")

---@param formatted_link string
---@param new_line? boolean
function M.put_link(formatted_link, new_line)
    if new_line then
        vim.api.nvim_put({ formatted_link }, "l", true, true)
    else
        vim.api.nvim_put({ formatted_link }, "", true, true)
    end
end

---@param filename string
---@return string
function M.format_rel_md_link(filename, source_file)
    local relative_path_prefix = paths.gen_rel_prefix(source_file)

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
