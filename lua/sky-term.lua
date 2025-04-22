-- init.lua

local M = {}

M.term_buf = nil
M.config = { -- Initialize M.config
    toggle_key = '<F8>',
    shell = vim.o.shell or "/bin/bash", -- Use system default shell
    auto_resize = true,
    debug = false,
    close_on_exit = true,
}

function M.debug_print(...)
    if M.config.debug then
        print("[sky-term]", ...)
    end
end

function M.setup(config)
    M.config = vim.tbl_extend('force', M.config, config or {})

    local modes = { 'n', 'i', 'v', 's', 'c', 'o', 't' }
    for _, mode in ipairs(modes) do
        vim.api.nvim_set_keymap(mode, M.config.toggle_key, '<cmd>lua require("sky-term").toggle_term_wrapper()<CR>',
            { noremap = true, silent = true })
    end

    vim.cmd([[
      command! -nargs=1 SendToSkyTerm lua require('sky-term').send_to_term(<q-args>)
      command! ToggleSkyTerm lua require('sky-term').toggle_term_wrapper()
    ]])

    -- Set up auto-resize handler
    if M.config.auto_resize then
        vim.cmd([[
            augroup SkyTermResize
            autocmd!
            autocmd VimResized * lua require('sky-term').handle_resize()
            augroup END
        ]])
    end
end

function M.handle_resize()
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
        M.debug_print("Resizing terminal window")
        vim.api.nvim_win_set_config(M.term_win, {
            relative = "editor",
            width = vim.o.columns,
            height = vim.o.lines - 1,
            col = 0,
            row = 0,
        })
    end
end

function M.toggle_term_wrapper()
    local bufnr = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

    if buftype == 'terminal' then
        M.toggle_term()

        if (M.userMode == "i") then
            vim.defer_fn(function() vim.cmd('startinsert') end, 100)
        end
    else
        M.userMode = vim.api.nvim_get_mode().mode
        M.toggle_term()
    end
end

function M.toggle_term()
    if vim.api.nvim_buf_get_name(0) == " TERMINAL" then
        -- Store the current mode
        M.term_mode = vim.api.nvim_get_mode().mode
        vim.api.nvim_win_hide(M.term_win)
        vim.api.nvim_set_current_buf(M.prev_buf)
    elseif M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) then
        M.debug_print("Creating new terminal buffer")
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
        
        -- Use system shell directly
        M.debug_print("Opening terminal with shell:", M.config.shell)
        local term_chan
        local success, err = pcall(function()
            term_chan = vim.fn.termopen(M.config.shell)
        end)
        
        if not success then
            M.debug_print("Failed to open terminal:", err)
            vim.api.nvim_err_writeln("SkyTerm error: Failed to open terminal: " .. tostring(err))
            vim.api.nvim_buf_delete(M.term_buf, { force = true })
            M.term_buf = nil
            M.term_win = nil
            return
        end
        
        -- Only set the TermClose autocmd if close_on_exit is enabled
        if M.config.close_on_exit then
            vim.cmd('autocmd TermClose <buffer> lua require("sky-term").handle_term_close()')
        end
        
        vim.api.nvim_buf_set_keymap(M.term_buf, 't', '<Esc>', '<C-\\><C-n>', 
            {noremap = true, silent = true})

        -- Set buffer name to "TERMINAL"
        vim.api.nvim_buf_set_name(M.term_buf, " TERMINAL")

        -- Hide line numbers in the terminal window
        vim.api.nvim_win_set_option(M.term_win, 'number', false)
        vim.api.nvim_win_set_option(M.term_win, 'relativenumber', false)
    else
        M.debug_print("Reusing existing terminal buffer")
        M.prev_buf = vim.api.nvim_get_current_buf()

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
    
    -- Enter insert mode in terminal
    vim.cmd('startinsert')
end

-- Handle terminal close event
function M.handle_term_close()
    M.debug_print("Terminal closed")
    -- Use pcall to avoid errors if buffer is invalid
    pcall(function()
        vim.cmd('bd!')
    end)
    M.term_buf = nil
end

function M.send_to_term(cmd)
    local current_buf = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_buf_get_option(current_buf, 'buftype')

    if M.term_buf == nil or not vim.api.nvim_buf_is_valid(M.term_buf) or buftype ~= "terminal" then
        M.toggle_term()
        vim.fn.chansend(vim.api.nvim_buf_get_option(M.term_buf, 'channel'), cmd .. "\n")
    else
        vim.fn.chansend(vim.api.nvim_buf_get_option(M.term_buf, 'channel'), cmd .. "\n")
    end
end

return M
