local M = {}

local ft = require('plenary.filetype')

local function current_win_buf()
    return vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
end

---@param split_size number
---@param direction string
local function open_scratch_buffer(split_size, direction)
    if direction == "vertical" then
        vim.cmd('rightbelow vsplit')
    else
        vim.cmd('rightbelow split')
    end
    local win_id = vim.api.nvim_get_current_win()
    if direction == "vertical" then
        vim.api.nvim_win_set_width(win_id, split_size)
    else
        vim.api.nvim_win_set_height(win_id, split_size)
    end
    local buf_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf_id)
    return win_id, buf_id
end

function M._chat_exists()
    if M._chat_win_id == nil or M._chat_buf_id == nil then
        return false
    end
    local win_exists = vim.fn.win_id2win(M._chat_win_id) ~= 0
    local buf_exists = vim.fn.bufexists(M._chat_buf_id) == 1
    return win_exists and buf_exists
end

function M._chat_focus()
    vim.api.nvim_set_current_win(M._chat_win_id)
    vim.api.nvim_set_current_buf(M._chat_buf_id)
end

function M._chat_unfocus()
    vim.api.nvim_set_current_win(M._req_win_id)
end

function M._set_request_win_buf()
    M._req_win_id, M._req_buf_id = current_win_buf()
end

---@param mode string
---@return string[]
function M.get_visual_text(mode)
    local _, start_row, start_col = unpack(vim.fn.getpos('v'))
    local _, end_row, end_col = unpack(vim.fn.getpos('.'))
    print(start_row, start_col, end_row, end_col)
    if mode == "v" then
        if start_row < end_row or (start_row == end_row and start_col <= end_col) then
            return vim.api.nvim_buf_get_text(0, start_row- 1, start_col - 1, end_row - 1, end_col, {})
        else
            return vim.api.nvim_buf_get_text(0, end_row - 1, end_col - 1, start_row - 1, start_col - 1, {})
        end
    else
        if mode == "V" then
            if start_row > end_row then
                return vim.api.nvim_buf_get_lines(0, end_row - 1, start_row, true)
            else
                return vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, true)
            end
        end
    end
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local pos = vim.api.nvim_win_get_cursor(win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, pos[1], true)
    return lines
end

function M.set_prompt()
    local mode = vim.api.nvim_get_mode().mode
    local currently_visual = false
    if mode == "v" or mode == "V" then
        currently_visual = true
    end
    M._set_request_win_buf()
    local visual_text = M.get_visual_text(mode)
    M.prompt = visual_text
    if currently_visual then
        vim.cmd('normal! gv')
    end
end


function M._init()
    M._set_request_win_buf()
    M.filetype = ft.detect(debug.getinfo(2,'S').source, {})
    M.set_prompt()
end

---
--- public
---

---@type setup_opts
---@class setup_opts
---@field split_size integer
---@field split_direction string

---@param opts setup_opts
function M.setup(opts)
    M.split_size = opts.split_size
    M.split_direction = opts.split_direction
    M._init()
end

function M.open_chat()
    if M._chat_exists() then
        M._chat_focus()
        return
    end
    M._chat_win_id, M._chat_buf_id = open_scratch_buffer(M.split_size, M.split_direction)
end

function M.replace_and_prompt()
    M.cwd = vim.fn.expand(vim.fn.getcwd(M._req_win_id, 0)) -- TODO: check tab number
    M.called_from = vim.fn.expand("%:p")
    M.filetype = ft.detect(M.called_from, {})
    M.set_prompt()
    if not M._chat_exists() then
        M.open_chat()
    end
    M._chat_focus()
    if M.prompt ~= nil then
        vim.api.nvim_buf_set_lines(M._chat_buf_id, 0, -1, false, M.prompt)
    end
    M.prompt = nil
end

return M
