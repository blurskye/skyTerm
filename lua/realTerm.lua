-- init.lua

local M = {}

M.term_buf = nil

M.term_buf = nil
M.config = { -- Initialize M.config
    toggle_key = '<F8>',
}

function M.setup(config)
    M.config = vim.tbl_extend('force', M.config, config or {})

    vim.api.nvim_set_keymap('n', M.config.toggle_key, ':lua require("realTerm").toggle_term()<CR>',
        { noremap = true, silent = true })

    vim.cmd([[
      command! -nargs=1 SendToTerminal lua require('realTerm').send_to_term(<q-args>)
    ]])
end

-- function M.toggle_term()
--     if M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
--         M.term_buf = vim.api.nvim_create_buf(false, true)
--         local win_id = vim.api.nvim_open_win(M.term_buf, true, {
--             relative = "editor",
--             width = vim.o.columns,
--             height = vim.o.lines - 1, -- Subtract 1 to leave space for the status line
--             col = 0,
--             row = 0,
--         })
--         vim.api.nvim_buf_set_option(M.term_buf, 'buftype', 'nofile')
--         vim.api.nvim_buf_set_option(M.term_buf, 'bufhidden', 'hide')
--         vim.fn.termopen("$SHELL")

--         -- Set buffer name to "TERMINAL"
--         vim.api.nvim_buf_set_name(M.term_buf, "TERMINAL")

--         -- Hide line numbers in the terminal window
--         vim.api.nvim_win_set_option(win_id, 'number', false)
--         vim.api.nvim_win_set_option(win_id, 'relativenumber', false)
--     else
--         local windows = vim.api.nvim_list_wins()
--         for _, win_id in ipairs(windows) do
--             if vim.api.nvim_win_get_buf(win_id) == M.term_buf then
--                 vim.api.nvim_win_close(win_id, true)
--                 break
--             end
--         end
--         M.term_buf = nil
--     end
-- end

-- Add a flag to check if the terminal has been opened before
M.term_opened = false

function M.toggle_term()
    -- Check if the terminal buffer is already open in a window
    local bufwinid = vim.fn.bufwinid(M.term_buf)
    if bufwinid ~= -1 then
        -- If it is, hide the window
        vim.api.nvim_win_close(bufwinid, true)
    else
        -- If it's not, check if the terminal buffer is valid
        if M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
            -- If it's not, create a new terminal buffer
            M.term_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(M.term_buf, 'buftype', 'nofile')
            vim.api.nvim_buf_set_option(M.term_buf, 'bufhidden', 'hide')
            vim.fn.termopen("$SHELL")
            vim.api.nvim_buf_set_name(M.term_buf, "TERMINAL")
        end

        -- Open the terminal in a new window
        local win_id = vim.api.nvim_open_win(M.term_buf, true, {
            relative = "editor",
            width = vim.o.columns,
            height = vim.o.lines - 1, -- Subtract 1 to leave space for the status line
            col = 0,
            row = 0,
        })

        -- Hide line numbers in the terminal window
        vim.api.nvim_win_set_option(win_id, 'number', false)
        vim.api.nvim_win_set_option(win_id, 'relativenumber', false)
    end
end

function M.send_to_term(cmd)
    if M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
        print("No terminal found. Open terminal first.")
    else
        vim.fn.chansend(vim.api.nvim_buf_get_option(M.term_buf, 'channel'), cmd .. "\n")
    end
end

-- vim.cmd([[
--   command! -nargs=1 SendToTerminal lua require('init').send_to_term(<q-args>)
-- ]])

-- vim.api.nvim_set_keymap('n', '<F5>', ':lua require("init").toggle_term()<CR>', { noremap = true, silent = true })
print("M")
return M
