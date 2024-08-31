local M = {}

local function current_win_buf()
    return vim.api.nvim_get_current_win(),vim.api.nvim_get_current_buf()
end

local function open_scratch_buffer()
  vim.cmd('rightbelow vsplit')
  local win_id = vim.api.nvim_get_current_win()
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

function M._set_request_postition()
    M._set_request_win_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(M._req_win_id)
    print("setting current pos to ", vim.inspect(cursor_pos))
end

function M.setup()
    M._set_request_win_buf()
end

function M.open_chat()
    if M._chat_exists() then
        M._chat_focus()
        return
    end
    M._chat_win_id, M._chat_buf_id = open_scratch_buffer()
end

function M.replace_and_prompt()
    M._set_request_postition()
end

return M
