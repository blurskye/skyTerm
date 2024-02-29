-- init.lua

local M = {}

M.term_buf = nil

M.term_buf = nil
M.config = { -- Initialize M.config
    toggle_key = '<F8>',
}

function M.setup(config)
    M.config = vim.tbl_extend('force', M.config, config or {})

    vim.api.nvim_set_keymap('n', M.config.toggle_key, '<cmd>lua require("realTerm").toggle_term()<CR>',
        { noremap = true, silent = true })
    vim.api.nvim_set_keymap('t', M.config.toggle_key, '<cmd>lua require("realTerm").toggle_term()<CR>',
        { noremap = true, silent = true })

    vim.cmd([[
      command! -nargs=1 SendToTerminal lua require('realTerm').send_to_term(<q-args>)
    ]])
end

function M.toggle_term()
    if vim.api.nvim_buf_get_name(0) == " TERMINAL" then
        -- Store the current mode
        M.term_mode = vim.api.nvim_get_mode().mode
        vim.api.nvim_win_hide(M.term_win)
        M.term_win = nil
    elseif M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
        M.term_buf = vim.api.nvim_create_buf(false, true)
        M.term_win = vim.api.nvim_open_win(M.term_buf, true, {
            relative = "editor",
            width = vim.o.columns,
            height = vim.o.lines - 1, -- Subtract 1 to leave space for the status line
            col = 0,
            row = 0,
        })
        vim.api.nvim_buf_set_option(M.term_buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(M.term_buf, 'bufhidden', 'hide')
        vim.fn.termopen("$SHELL")

        -- Set buffer name to "TERMINAL"
        vim.api.nvim_buf_set_name(M.term_buf, " TERMINAL")

        -- Hide line numbers in the terminal window
        vim.api.nvim_win_set_option(M.term_win, 'number', false)
        vim.api.nvim_win_set_option(M.term_win, 'relativenumber', false)
    else
        if M.term_win ~= nil and vim.api.nvim_win_is_valid(M.term_win) then
            vim.api.nvim_win_hide(M.term_win)
            M.term_win = nil
        else
            M.term_win = vim.api.nvim_open_win(M.term_buf, true, {
                relative = "editor",
                width = vim.o.columns,
                height = vim.o.lines - 1, -- Subtract 1 to leave space for the status line
                col = 0,
                row = 0,
            })
        end
    end
    vim.cmd('startinsert')
end

function M.send_to_term(cmd)
    if M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
        M.toggle_term()
        vim.fn.chansend(vim.api.nvim_buf_get_option(M.term_buf, 'channel'), cmd .. "\n")
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
