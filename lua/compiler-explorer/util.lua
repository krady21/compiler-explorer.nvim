local config = require("compiler-explorer.config")

local uv = vim.loop
local api, fn = vim.api, vim.fn

local last_buffer_name = nil

local M = {}

-- Creates a new buffer and window or uses the previous one.
function M.create_window_buffer(compiler_id, new_window)
  local conf = config.get_config()

  -- If this is the first compile or bang was used in the compile command.
  local name
  if new_window or last_buffer_name == nil then
    name = table.concat({ "asm", compiler_id, math.random(100) }, "-")
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
  end

  -- If the buffer is not associated with any window, create a new window.
  if fn.bufwinnr(asm_bufnr) == -1 then
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

function M.set_binary_extmarks(lines, bufnr)
  local conf = config.get_config()
  local ns = api.nvim_create_namespace("ce-binary")

  for i, line in ipairs(lines) do
    if line.address ~= nil then
      local address = string.format("%x", line.address)
      local opcodes = " " .. table.concat(line.opcodes, " ")

      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        virt_lines_above = true,
        virt_lines = { { { opcodes, conf.binary_hl } } },
        virt_text = { { address, conf.binary_hl } },
      })
    end
  end
end

local function to_bool(s)
  if s == "true" then
    return true
  elseif s == "false" then
    return false
  else
    return s
  end
end

function M.parse_args(fargs)
  local conf = config.get_config()
  local args = {}
  args.inferLang = conf.infer_lang

  for _, f in ipairs(fargs) do
    local split = vim.split(f, "=")
    if #split == 1 then
      args[split[1]] = true
    elseif #split == 2 then
      args[split[1]] = to_bool(split[2])
    end
  end

  return args
end

function M.start_spinner()
  local conf = config.get_config()
  local frames = conf.spinner_frames
  local interval = conf.spinner_interval

  local i = 1
  M.timer = uv.new_timer()
  M.timer:start(0, interval, function()
    i = (i == #frames) and 1 or (i + 1)
    local msg = string.format(" Compiling %s", frames[i])
    vim.schedule(function()
      api.nvim_echo({ { msg, "None" } }, false, {})
    end)
  end)
end

function M.stop_spinner()
  api.nvim_echo({ { "", "None" } }, false, {})
  M.timer:stop()
  M.timer:close()
end

return M
