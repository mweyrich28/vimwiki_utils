local pickers = require "telescope.pickers"
local telescope = require("telescope.builtin")
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require('utils')
local job = require('plenary.job')

local globals = {
    rough_notes_dir = "1_rough_notes",
    source_dir = "2_source_material",
    tag_dir = "3_tags",
    atomic_notes_dir = "4_atomic_notes",
    screenshot_dir = "assets/screenshots",
    kolourpaint = "/snap/bin/kolourpaint "
}

local default_keymaps = {
    vimwiki_utils_link_key = '<C-b>',
    vimwiki_utils_tags_key = '<C-e>',
    vimwiki_utils_rough_key = '<leader>nn',
    vimwiki_utils_backlinks_key = '<leader>fb',
    vimwiki_utils_sc_key = '<leader>sc',
    vimwiki_utils_edit_image_key = '<leader>ii',
    vimwiki_utils_source_key = '<leader>sm',
    vimwiki_utils_embed_key = '<leader>m',
    vimwiki_utils_generate_index_key = '<leader>wm',
    vimwiki_utils_rename = '<leader>wr',
}

local M = {}

function M.vimwiki_utils_link()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsLink" }
    opts.file_ignore_patterns = { globals.tag_dir }

    local wiki = utils.get_active_wiki()
    local results = vim.fn.systemlist("find " .. wiki .. " -type f -name '*.md'")
    local processed_results_table = utils.format_results(globals.atomic_notes_dir, results)
    -- table for notes to display
    local processed_results = processed_results_table[1]
    -- table for actual note paths
    local file_map = processed_results_table[2]

    local note_name = ""
    local wiki_link = ""

    -- this captures the actual abs path of the note where the telescope promt is called.
    -- this is necessary in order to add already existing tags to notes that have a tag as parent note
    local source_file = vim.fn.expand("%:p")

    pickers.new(opts, {

        finder = finders.new_table({
            results = processed_results
        }),

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
            local function paste_selected_entry()
                local selection = action_state.get_selected_entry()
                if selection then
                    local file_name = selection.value
                    file_name = file_name:gsub(".md", "")
                    action_state.get_current_picker(prompt_bufnr):reset_prompt(file_name)
                end
            end

            -- default action
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_name = selection.value
                wiki_link = utils.format_rel_md_link(file_map[note_name])
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)
            -- creates new file based on a selected template
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                note_name = action_state.get_current_line()
                wiki_link = utils.format_rel_md_link(globals.atomic_notes_dir .. "/" .. note_name .. ".md")
                vim.api.nvim_put({ wiki_link }, "", true, true)
                utils.create_new_note(note_name, globals.atomic_notes_dir, globals.tag_dir, source_file)
            end)

            map('i', '<Tab>', function()
                paste_selected_entry()
            end)

            return true
        end
    }):find()
end

function M.vimwiki_utils_rough()
    local new_note_name = vim.fn.input('Create rough note: ')
    local wiki = utils.get_active_wiki()
    local new_note = wiki .. globals.rough_notes_dir .. "/" .. new_note_name
    utils.choose_template(function(template_path)
        utils.generate_header(new_note, new_note_name, template_path)
        -- delay editing of newly created note to avoid asynchronous file operations
        vim.defer_fn(function()
            vim.cmd("edit " .. new_note .. ".md")
        end, 100)
    end)
end

function M.vimwiki_utils_backlinks()
    local current_file = vim.fn.expand('%:t')
    current_file = current_file:gsub(".md", "")
    local backlink_pattern = "\\[*\\]\\(.*" .. current_file .. "[.md\\)|\\)]"

    telescope.live_grep({
        prompt_title = "VimwikiUtilsBacklinks",
        default_text = backlink_pattern,
        no_ignore = true,
        hidden = true,
        entry_maker = function(entry)
            local file, lnum, col, text = string.match(entry, "(.-):(%d+):(%d+):(.*)")
            if file and lnum and col and text then
                local filename = utils.get_path_suffix(file)
                return {
                    display = filename,
                    filename = file,
                    lnum = tonumber(lnum),
                    col = tonumber(col),
                    text = text,
                    ordinal = entry,
                }
            end
        end,
        attach_mappings = function(prompt_bufnr, map)
            -- press opt enter to generate index
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                utils.generate_tag_index(backlink_pattern)
            end)
            actions.select_default:replace(function()
                actions.file_edit(prompt_bufnr)
            end)
            return true
        end,
    })
end

function M.vimwiki_utils_tags()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsTags" }
    local wiki = utils.get_active_wiki()
    local path_to_tags = wiki .. globals.tag_dir
    local results = vim.fn.systemlist("find " .. path_to_tags .. " -type f -name '*.md'")
    local processed_results_table = utils.format_results(globals.tag_dir, results)
    local processed_results = processed_results_table[1]
    local file_table = processed_results_table[2]

    pickers.new(opts, {
        finder = finders.new_table({
            results = processed_results
        }),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            -- press opt enter to generate new tag (creates empty file with header in TAG_DIR)
            map('i', '<A-CR>', function()
                local new_tag_name = action_state.get_current_line()
                actions.close(prompt_bufnr)
                utils.create_new_tag(new_tag_name, globals.tag_dir)
                local tag_link = utils.format_rel_md_link(globals.tag_dir .. "/" .. new_tag_name .. ".md")
                vim.api.nvim_put({ tag_link .. "   " }, "", true, true)
            end)

            -- or link to already existing tag
            map('i', '<CR>', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    local tag_name = selection.value
                    local tag_link = utils.format_rel_md_link(file_table[tag_name])
                    vim.api.nvim_put({ tag_link }, "", true, true)
                end
            end)
            return true
        end
    }):find()
end

function M.vimwiki_utils_sc()
    local image_name = vim.fn.input('Image name: ')
    local plugin_dir = vim.fn.stdpath('data') .. "/site/pack/packer/start/vimwiki_utils"
    local wiki = utils.get_active_wiki()
    local sc_dir = wiki .. "/" .. globals.screenshot_dir
    local script_path = plugin_dir .. '/scripts/vimwiki_better_sc.sh'

    if image_name ~= "" then
        job:new({
            command = script_path,
            args = { image_name, sc_dir },
            on_exit = function(j, return_val)
                if return_val == 1 then
                    print("File already exists: " .. image_name .. ".png")
                end
            end
        }):start()

        -- Insert the markdown link into the buffer if successful
        local link_to_sc = "!" .. utils.format_rel_md_link(globals.screenshot_dir .. "/" .. image_name .. ".png")
        vim.api.nvim_put({ link_to_sc }, "", true, true)
    end
end

function M.vimwiki_utils_edit_image()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_number = cursor[1]
    local line_content = vim.api.nvim_buf_get_lines(buf, line_number - 1, line_number, false)[1]
    local link_content = line_content:match("%((.-)%)")
    link_content = link_content:gsub("%.%.%/", "")
    link_content = utils.get_active_wiki() .. link_content
    vim.fn.system(globals.kolourpaint .. " " .. link_content)
end

function M.vimwiki_utils_source()
    local opts                    = require("telescope.themes").get_dropdown {
        prompt_title = "VimwikiUtilsSource",
        file_ignore_patterns = {},
    }

    local sources                 = utils.get_active_wiki() .. globals.source_dir
    -- print(utils.get_active_wiki() .. SOURCE_DIR)
    local results                 = vim.fn.systemlist("find " .. sources .. " -type f")
    local processed_results_table = utils.format_results(globals.source_dir, results)
    -- table for notes to display
    local processed_results       = processed_results_table[1]
    -- table for actual note paths
    local file_map                = processed_results_table[2]
    local note_name               = ""
    local wiki_link               = ""
    pickers.new(opts, {

        finder = finders.new_table({
            results = processed_results
        }),

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_name = selection.value
                wiki_link = utils.format_rel_md_link(file_map[note_name])
                wiki_link = string.gsub(wiki_link, "%(", "(./") -- formatting for vimwiki
                vim.api.nvim_put({ "!" .. wiki_link .. "   " }, "", true, true)
            end)

            return true
        end
    }):find()
end

function M.vimwiki_utils_embed()
    local current_file = vim.fn.expand('%:p')
    local note_name = utils.get_path_suffix(current_file)
    local file_name = vim.fn.fnamemodify(current_file, ':t')
    local new_path = vim.fn.fnamemodify(globals.atomic_notes_dir, ':p') .. file_name
    if vim.fn.filereadable(new_path) == 1 then
        print("Error: Cannot embed file '" .. new_path .. "', it already exists!")
        return
    end
    local confirm = vim.fn.input("Embed " .. note_name .. " → " .. globals.atomic_notes_dir .. "? (y/n): ")
    if confirm:lower() == 'y' then
        vim.fn.rename(current_file, new_path)
        vim.cmd('edit ' .. new_path)
        vim.cmd('bd! ' .. current_file)
    end
end

function M.vimwiki_utils_generate_index()
    local wiki = utils.get_active_wiki()
    local results = vim.fn.systemlist("find " .. wiki .. globals.tag_dir .. " -type f -name '*.md'")

    local index = "# Main Index"

    table.sort(results, function(a, b)
        return a:lower() < b:lower()
    end)

    vim.api.nvim_put({ index }, "c", true, true)
    for _, file_path in ipairs(results) do
        local rel_path = utils.convert_abs_to_rel(file_path)
        local wiki_link = utils.format_rel_md_link(rel_path)
        vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all tags
    end
end

function M.vimwiki_utils_rename()
    -- save current buffers
    vim.cmd("wall")

    local old_filepath = vim.fn.expand('%:p')
    local old_filename = utils.get_path_suffix(old_filepath)
    local formatted_old_filename = string.gsub(old_filename, "%.md$", "")

    local confirm = vim.fn.input("Rename " .. string.gsub(old_filename, ".md", "") .. "? (y/n): ")

    local dir = nil

    if string.find(old_filepath, globals.atomic_notes_dir) then
        dir = globals.atomic_notes_dir
    elseif string.find(old_filepath, globals.tag_dir) then
        dir = globals.tag_dir
    elseif string.find(old_filepath, globals.rough_notes_dir) then
        dir = globals.rough_notes_dir
    else
        print("No dir found")
        return
    end


    if confirm:lower() == 'y' then
        local new_filename = vim.fn.input(formatted_old_filename .. " → ", formatted_old_filename)

        if new_filename == "" then
            print("Rename canceled.")
            return
        end

        if new_filename:sub(-3) ~= ".md" then
            new_filename = new_filename .. ".md"
        end


        local new_path = vim.fn.fnamemodify(dir, ':p') .. new_filename

        if vim.fn.filereadable(new_path) == 1 then
            print("Error: Cannot rename file to'" .. new_path .. "', it already exists!")
            return
        end

        local new_filename_identifier = string.gsub(new_filename, ".md", "")

        -- Strategy: [note name](../path/to/note_name.md) → [new note name](../dir/new_note_name.md)
        -- base case where identifier == gsub(note_name, "_", " ") (the default pattern when creating a new file with VimwikiUtilsLink)
        local strict_pattern = "\\[" ..
            string.gsub(formatted_old_filename, "_", " ") .. "\\](..\\/" .. dir .. "\\/" .. old_filename .. ")"
        local strict_replacement = "\\[" ..
            string.gsub(new_filename_identifier, "_", " ") .. "\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy: [unique identifier](../path/to/note_name.md) → [unique identifier](../dir/new_note_name.md)
        -- Unique identifier + link formatted with "../" prefix
        local uniq_pattern = "\\[\\(.*\\)\\](..\\/" .. dir .. "\\/" .. old_filename .. ")"
        local uniq_replacement = "\\[\\1\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy: [unique identifier](note_name.md) → [unique identifier](../dir/new_note_name.md)
        -- Unique identifier + link formatted without "../" prefix
        local uniq_pattern_1 = "\\[\\(.*\\)\\](" .. old_filename .. ")"
        local uniq_replacement_1 = "\\[\\1\\](..\\/" .. dir .. "\\/" .. new_filename .. ")"

        -- Strategy for files linked from within index/README: [note name](dir/note_name.md) → [new note name](dir/new_note_name.md)
        local index_pattern = "\\[.*\\](" .. dir .. "\\/" .. old_filename .. ")"
        local index_replacement = "\\[" ..
            string.gsub(new_filename_identifier, "_", " ") .. "\\](" .. dir .. "\\/" .. new_filename .. ")"

        utils.gsub_dir(globals.atomic_notes_dir, strict_pattern, strict_replacement)
        utils.gsub_dir(globals.atomic_notes_dir, uniq_pattern, uniq_replacement)
        utils.gsub_dir(globals.atomic_notes_dir, uniq_pattern_1, uniq_replacement_1)

        utils.gsub_dir(globals.tag_dir, strict_pattern, strict_replacement)
        utils.gsub_dir(globals.tag_dir, uniq_pattern, uniq_replacement)
        utils.gsub_dir(globals.tag_dir, uniq_pattern_1, uniq_replacement_1)

        utils.gsub_dir(".", index_pattern, index_replacement)


        vim.fn.rename(old_filepath, new_path)
        vim.cmd('edit ' .. new_path)
    end
end

function M.setup(opts)
    opts = opts or {}
    opts.global = opts.global or {}
    globals.rough_notes_dir = opts.global.rough_notes_dir or globals.rough_notes_dir
    globals.source_dir = opts.global.source_dir or globals.source_dir
    globals.tag_dir = opts.global.tag_dir or globals.tag_dir
    globals.atomic_notes_dir = opts.global.atomic_notes_dir or globals.atomic_notes_dir
    globals.screenshot_dir = opts.global.screenshot_dir or globals.screenshot_dir
    globals.kolourpaint = opts.global.kolourpaint or globals.kolourpaint

    local keymaps = opts.keymaps or {}
    for key, default_value in pairs(default_keymaps) do
        keymaps[key] = keymaps[key] or default_value
    end

    vim.api.nvim_create_user_command('VimwikiUtilsLink', function()
        M.vimwiki_utils_link()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsRough', function()
        M.vimwiki_utils_rough()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsBacklinks', function()
        M.vimwiki_utils_backlinks()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsTags', function()
        M.vimwiki_utils_tags()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsSc', function()
        M.vimwiki_utils_sc()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsEditImage', function()
        M.vimwiki_utils_edit_image()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsSource', function()
        M.vimwiki_utils_source()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsEmbed', function()
        M.vimwiki_utils_embed()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsGenerateIndex', function()
        M.vimwiki_utils_generate_index()
    end, {})

    vim.api.nvim_create_user_command('VimwikiUtilsRename', function()
        M.vimwiki_utils_rename()
    end, {})

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', keymaps.vimwiki_utils_link_key, '<cmd>VimwikiUtilsLink<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'i', keymaps.vimwiki_utils_tags_key, '<cmd>VimwikiUtilsTags<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_rough_key, '<cmd>VimwikiUtilsRough<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_backlinks_key, '<cmd>VimwikiUtilsBacklinks<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_sc_key, '<cmd>VimwikiUtilsSc<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_edit_image_key, '<cmd>VimwikiUtilsEditImage<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_source_key, '<cmd>VimwikiUtilsSource<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_embed_key, '<cmd>VimwikiUtilsEmbed<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_generate_index_key,
                '<cmd>VimwikiUtilsGenerateIndex<CR>',
                { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_rename, '<cmd>VimwikiUtilsRename<CR>',
                { noremap = true, silent = true })
        end,
    })
end

return M
