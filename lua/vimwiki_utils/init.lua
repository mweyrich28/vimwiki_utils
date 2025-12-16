local M = {}

local config = require("vimwiki_utils.config")
local commands = require("vimwiki_utils.commands")
local keymaps = require("vimwiki_utils.keymaps")


vim.api.nvim_create_user_command(
  "VimwikiUtilsTestLink",
  function()
    require("vimwiki_utils.pickers.link").open()
  end,
  {}
)

-- =====================
-- Your existing API
-- =====================

function M.vimwiki_utils_link()
  require("vimwiki_utils.pickers.link").open()
end
function M.vimwiki_utils_tags() end
function M.vimwiki_utils_rough() end
function M.vimwiki_utils_backlinks() end
function M.vimwiki_utils_sc() end
function M.vimwiki_utils_edit_image() end
function M.vimwiki_utils_source() end
function M.vimwiki_utils_embed() end
function M.vimwiki_utils_generate_index() end
function M.vimwiki_utils_rename() end

-- =====================
-- Setup
-- =====================

function M.setup(opts)
  config.setup(opts)
  commands.setup(M)
  keymaps.setup(config.options)
end

M.config = config.options

return M
