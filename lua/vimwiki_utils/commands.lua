local M = {}

function M.setup(api)
  local cmd = vim.api.nvim_create_user_command

  cmd("VimwikiUtilsLink", api.vimwiki_utils_link, {})
  cmd("VimwikiUtilsRough", api.vimwiki_utils_rough, {})
  cmd("VimwikiUtilsBacklinks", api.vimwiki_utils_backlinks, {})
  cmd("VimwikiUtilsTags", api.vimwiki_utils_tags, {})
  cmd("VimwikiUtilsSc", api.vimwiki_utils_sc, {})
  cmd("VimwikiUtilsEditImage", api.vimwiki_utils_edit_image, {})
  cmd("VimwikiUtilsSource", api.vimwiki_utils_source, {})
  cmd("VimwikiUtilsEmbed", api.vimwiki_utils_embed, {})
  cmd("VimwikiUtilsGenerateIndex", api.vimwiki_utils_generate_index, {})
  cmd("VimwikiUtilsRename", api.vimwiki_utils_rename, {})
end

return M
