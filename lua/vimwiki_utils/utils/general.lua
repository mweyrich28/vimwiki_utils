local M = {}

---@param dir string
---@param pattern string
---@param replacement string
function M.gsub_dir(dir, pattern, replacement)
    local command = "sed -i '' -e 's/" .. pattern .. "/" .. replacement .. "/g' " .. dir .. "/*.md"
    vim.fn.system(command)
end

return M
