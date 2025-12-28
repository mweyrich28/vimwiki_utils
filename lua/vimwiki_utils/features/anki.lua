local M = {}

local text = require("vimwiki_utils.utils.text")

function M.create_cloze()

    local selection = text.get_visual_selection()
    local type = vim.fn.input([[
    Increment type:
      ''  → none
      0   → all
      1   → line
    Choose: ]])
    local transform = text.cloze_transform(selection, type)

    print("\n\n--------------------------------------------")
    print(transform)
    print("--------------------------------------------\n\n")
    print("Copied to sys clipboard")
    vim.fn.setreg("+", transform)
end

return M
