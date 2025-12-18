local M = {}

function M.get_visual_selection()
    local bufnr = 0
    
    -- Get current visual selection positions (works while in visual mode)
    local srow, scol = unpack(vim.fn.getpos("v"), 2, 3)
    local erow, ecol = unpack(vim.fn.getpos("."), 2, 3)
    
    -- Ensure start comes before end
    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end
    
    -- Convert to 0-indexed
    srow = srow - 1
    erow = erow - 1
    
    local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
    local mode = vim.fn.mode()
    
    if mode == "v" then  -- characterwise visual
        lines[1] = string.sub(lines[1], scol)
        lines[#lines] = string.sub(lines[#lines], 1, ecol)
    elseif mode == "V" then  -- linewise visual
        -- Keep all lines as-is
    elseif mode == "\22" then  -- block visual (Ctrl-V)
        -- Handle block mode if needed
    end
    
    return table.concat(lines, "\n")
end

function M.cloze_transform(text, type)
    local out = {}
    local is_start = true
    local cloze_id = 1
    local seen_cloz_in_line = false

    local chars = vim.fn.split(text, "\\zs")

    for _, ch in ipairs(chars) do
        if ch == "`" then
            seen_cloz_in_line = true
            if is_start then
                out[#out + 1] = "{{c" .. cloze_id .. "::`"
                is_start = false
                if type == "0" then
                    cloze_id = cloze_id + 1 -- incremet every cloze
                end
            else
                out[#out + 1] = "`}}"
                is_start = true
            end
        else
            out[#out + 1] = ch
        end

        -- increment line wise
        if ch == "\n" then
            if type == "1" and seen_cloz_in_line then
                cloze_id = cloze_id + 1
            end
            seen_cloz_in_line = false
        end
    end

    return table.concat(out)
end

return M
