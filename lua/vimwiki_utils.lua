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
    screenshot_dir = "assets/SCREENSHOTS",
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
}

local M = {}

function M.vimwiki_utils_link()
    local opts = require("telescope.themes").get_dropdown { prompt_title = "VimwikiUtilsLink" }
    opts.file_ignore_patterns = { globals.tag_dir}

    local wiki = utils.get_active_wiki()
    local results = vim.fn.systemlist("find " ..  wiki .. " -type f -name '*.md'")
    local processed_results_table = utils.format_results(globals.atomic_notes_dir, results)
    -- table for notes to display
    local processed_results = processed_results_table[1]
    -- table for actual note paths
    local file_map = processed_results_table[2]


    local note_name = ""
    local wiki_link = ""

    pickers.new(opts, {

        finder = finders.new_table({
            results = processed_results
        }),

        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)

            -- default action
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                note_name = selection.value
                wiki_link = utils.link_to_note(file_map[note_name])
                vim.api.nvim_put({ wiki_link }, "", true, true)
            end)
            -- creates new file based on a selected template 
            map('i', '<A-CR>', function()
                actions.close(prompt_bufnr)
                note_name = action_state.get_current_line()
                wiki_link = utils.format_md_link(note_name)
                vim.api.nvim_put({ wiki_link }, "", true, true)
                utils.create_new_note(note_name)
            end)

            return true
        end
    }):find()
end


function M.vimwiki_utils_rough()
    local rough_note_name = vim.fn.input('Create rough note: ')
    local wiki = utils.get_active_wiki()
    local destination = wiki .. globals.rough_notes_dir .. "/" .. rough_note_name
    utils.choose_template(function(template_path)
        utils.generate_header(destination, rough_note_name, template_path)
        -- delay editing of newly created note to avoid asynchronous file operations      
        vim.defer_fn(function()
            vim.cmd("edit " .. destination .. ".md")
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
    local results = vim.fn.systemlist("find " ..  path_to_tags.. " -type f -name '*.md'")
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
                    vim.api.nvim_put({ tag_link }, "", true, true)
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
    local sc_dir = wiki .. "/" .. globals.source_dir
    local script_path = plugin_dir .. '/scripts/vimwiki_better_sc.sh'

    if image_name ~= "" then
        job:new({
            command = script_path,
            args = { image_name, sc_dir},
        }):start()

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
    local opts = require("telescope.themes").get_dropdown {
        prompt_title = "VimwikiUtilsSource",
        file_ignore_patterns = {},
    }

    local sources  = utils.get_active_wiki() .. globals.source_dir
    -- print(utils.get_active_wiki() .. SOURCE_DIR)
    local results = vim.fn.systemlist("find " ..  sources .. " -type f")
    local processed_results_table = utils.format_results(globals.source_dir, results)
    -- table for notes to display
    local processed_results = processed_results_table[1]
    -- table for actual note paths
    local file_map = processed_results_table[2]


    local note_name = ""
    local wiki_link = ""

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
                wiki_link = utils.link_to_note(file_map[note_name])
                wiki_link = string.gsub(wiki_link, "%(", "(file:")  -- formatting for vimwiki
                vim.api.nvim_put({ wiki_link }, "", true, true)
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
    local confirm = vim.fn.input("Embed " .. note_name .. " → " .. globals.atomic_notes_dir .. "? (y/n): ")

    if confirm:lower() == 'y' then
        vim.fn.rename(current_file, new_path)
        vim.cmd('edit ' .. new_path)
        vim.cmd('bd! ' .. current_file)
    end
end


function M.vimwiki_utils_generate_index()
    local wiki = utils.get_active_wiki()
    local results = vim.fn.systemlist("find " ..  wiki .. globals.tag_dir .. " -type f -name '*.md'")

    local index = "# Main Index"
    vim.api.nvim_put({ index }, "l", true, true)
    for _, file_path in ipairs(results) do
        local rel_path = utils.convert_abs_to_rel(file_path)
        local wiki_link = utils.format_rel_md_link(rel_path)
        vim.api.nvim_put({ "- " .. wiki_link }, "l", true, true) -- listing all links
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

    vim.api.nvim_create_user_command('VimwikiUtilsTest', function()
        M.vimwiki_utils_generate_index()
    end, {})

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        callback = function()
            vim.api.nvim_buf_set_keymap(0, 'i', keymaps.vimwiki_utils_link_key, '<cmd>VimwikiUtilsLink<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'i', keymaps.vimwiki_utils_tags_key, '<cmd>VimwikiUtilsTags<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_rough_key, '<cmd>VimwikiUtilsRough<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_backlinks_key, '<cmd>VimwikiUtilsBacklinks<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_sc_key, '<cmd>VimwikiUtilsSc<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_edit_image_key, '<cmd>VimwikiUtilsEditImage<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_source_key, '<cmd>VimwikiUtilsSource<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_embed_key, '<cmd>VimwikiUtilsEmbed<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(0, 'n', keymaps.vimwiki_utils_generate_index_key, '<cmd>VimwikiUtilsGenerateIndex<CR>', { noremap = true, silent = true })
        end,
    })
end

return M