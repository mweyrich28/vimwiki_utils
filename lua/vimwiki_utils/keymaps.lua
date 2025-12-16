local M = {}

function M.setup(config)
  local km = config.keymaps

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "vimwiki",
    callback = function()
      local function map(mode, lhs, rhs)
        if not lhs then return end
        vim.keymap.set(mode, lhs, rhs, {
          buffer = true,
          silent = true,
          noremap = true,
        })
      end

      map("i", km.vimwiki_utils_link_key, "<cmd>VimwikiUtilsLink<CR>")
      map("i", km.vimwiki_utils_tags_key, "<cmd>VimwikiUtilsTags<CR>")
      map("n", km.vimwiki_utils_rough_key, "<cmd>VimwikiUtilsRough<CR>")
      map("n", km.vimwiki_utils_backlinks_key, "<cmd>VimwikiUtilsBacklinks<CR>")
      map("n", km.vimwiki_utils_sc_key, "<cmd>VimwikiUtilsSc<CR>")
      map("n", km.vimwiki_utils_edit_image_key, "<cmd>VimwikiUtilsEditImage<CR>")
      map("n", km.vimwiki_utils_source_key, "<cmd>VimwikiUtilsSource<CR>")
      map("n", km.vimwiki_utils_embed_key, "<cmd>VimwikiUtilsEmbed<CR>")
      map("n", km.vimwiki_utils_generate_index_key, "<cmd>VimwikiUtilsGenerateIndex<CR>")
      map("n", km.vimwiki_utils_rename, "<cmd>VimwikiUtilsRename<CR>")
    end,
  })
end

return M
