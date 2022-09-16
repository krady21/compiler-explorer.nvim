local config = require("compiler-explorer.config")

local api, fn = vim.api, vim.fn

local last_buffer_name = nil

local M = {}

local function generate_bufname(compiler_id)
  return table.concat({ "asm", compiler_id, math.random(100) }, "-")
end

-- Creates a new buffer and window or uses the previous one.
function M.create_window_buffer(compiler_id, new_window)
  local conf = config.get_config()

  -- If this is the first compile or bang was used in the compile command.
  local name
  if new_window or last_buffer_name == nil then
    name = generate_bufname(compiler_id)
    last_buffer_name = name
  else
    name = last_buffer_name
  end

  local asm_bufnr = fn.bufnr(name)
  if asm_bufnr == -1 then
    asm_bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(asm_bufnr, name)
    api.nvim_buf_set_option(asm_bufnr, "ft", "asm")
    api.nvim_buf_set_option(asm_bufnr, "bufhidden", "wipe")
  else
    api.nvim_buf_set_name(asm_bufnr, generate_bufname(compiler_id))
  end

  -- If the buffer is not associated with any window, create a new window.
  if fn.bufwinnr(asm_bufnr) == -1 or new_window then
    if #api.nvim_list_wins() == 1 then
      vim.cmd("vsplit")
    else
      vim.cmd("wincmd b")
      vim.cmd(conf.split)
    end

    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, asm_bufnr)
  end

  return asm_bufnr
end

return M
