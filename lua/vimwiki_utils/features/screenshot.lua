local job = require('plenary.job')

local paths = require("vimwiki_utils.utils.paths")
local config = require("vimwiki_utils.config")
local links = require("vimwiki_utils.utils.links")

local M = {}

function M.take_screenshot()
    local image_name = vim.fn.input('Image name: ')
    local image_file = image_name .. ".png"
    local wiki = paths.get_active_wiki()
    local image_path = vim.fs.joinpath(wiki, config.options.globals.screenshot_dir, image_file)
    local parent_note = vim.fn.expand("%:p")
    local rel_path = paths.convert_abs_to_rel(image_path)

    if image_name ~= "" then
        if vim.fn.filereadable(image_path) == 1 then
            print("Image already exists!")
        else
            vim.cmd("sleep 3")

            vim.fn.system({
                "gnome-screenshot",
                "-af",
                image_path,
            })

            local link_to_sc = "!" .. links.format_rel_md_link(rel_path, parent_note)
            links.put_link(link_to_sc)
        end
    end
end

return M
