local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local paths = require("vimwiki_utils.utils.paths")
local notes = require("vimwiki_utils.utils.notes")
local links = require("vimwiki_utils.utils.links")
local config = require("vimwiki_utils.config")

local M = {}

function M.open()
  local opts = themes.get_dropdown {
    prompt_title = "VimwikiUtilsLink",
  }

  opts.file_ignore_patterns = {
    config.options.globals.tag_dir,
  }

  local globals = config.options.globals
  local wiki = paths.get_active_wiki()

  local results = vim.fn.systemlist(
    "find " .. wiki .. " -type f -name '*.md'"
  )

  local processed, file_map =
    unpack(paths.format_results(globals.atomic_notes_dir, results))

  local source_file = vim.fn.expand("%:p")

  pickers.new(opts, {
    finder = finders.new_table {
      results = processed,
    },

    sorter = conf.file_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      local function paste_selected_entry()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local file_name = selection.value:gsub("%.md$", "")
        action_state
          .get_current_picker(prompt_bufnr)
          :reset_prompt(file_name)
      end

      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local note_name
        if selection then
          note_name = selection.value
        else
          note_name = action_state.get_current_line()
          notes.create_new_note(
            note_name,
            globals.atomic_notes_dir,
            globals.tag_dir,
            source_file
          )
        end

        local file_path = vim.fs.joinpath(globals.atomic_notes_dir, note_name)
        local parent_note = vim.fn.expand("%:p")
        local wiki_link = links.format_rel_md_link(file_path, parent_note)

        links.put_link(wiki_link)
      end)

      map("i", "<A-CR>", function()
        actions.close(prompt_bufnr)

        local note_name = action_state.get_current_line() .. ".md"
        local file_path = vim.fs.joinpath(globals.atomic_notes_dir, note_name)
        local parent_note = vim.fn.expand("%:p")
        local wiki_link = links.format_rel_md_link(file_path, parent_note)
        links.put_link(wiki_link)

        notes.create_new_note(
          note_name,
          globals.atomic_notes_dir,
          globals.tag_dir,
          source_file
        )
      end)

      map("i", "<Tab>", paste_selected_entry)

      return true
    end,
  }):find()
end



return M
