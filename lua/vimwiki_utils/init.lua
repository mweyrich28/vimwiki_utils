local M = {}

local config = require("vimwiki_utils.config")
local commands = require("vimwiki_utils.commands")
local keymaps = require("vimwiki_utils.keymaps")

function M.vimwiki_utils_link()
  require("vimwiki_utils.pickers.linking_ui").link_note()
end

function M.vimwiki_utils_tags()
  require("vimwiki_utils.pickers.linking_ui").link_tag()
end

function M.vimwiki_utils_rough()
  require("vimwiki_utils.features.linking").create_rough()
end

function M.vimwiki_utils_backlinks()
  require("vimwiki_utils.pickers.linking_ui").display_backlinks()
end

function M.vimwiki_utils_sc()
  require("vimwiki_utils.features.images").take_screenshot()
end

function M.vimwiki_utils_edit_image()
  require("vimwiki_utils.features.images").edit_image()
end

function M.vimwiki_utils_source()
  require("vimwiki_utils.pickers.media_ui").link_source()
end

function M.vimwiki_utils_embed()
  require("vimwiki_utils.features.linking").embed_rough_note()
end

function M.vimwiki_utils_generate_index()
  require("vimwiki_utils.features.linking").generate_index()
end

function M.vimwiki_utils_rename()
  require("vimwiki_utils.features.linking").rename()
end

function M.vimwiki_utils_anki_cloze()
  require("vimwiki_utils.features.anki").create_cloze()
end

function M.setup(opts)
  config.setup(opts)
  commands.setup(M)
  keymaps.setup(config.options)
end

M.config = config.options

return M
