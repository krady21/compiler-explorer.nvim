local ce = require("compiler-explorer.lazy")

local uv = vim.loop
local api = vim.api

local M = {}

-- Creates a new buffer and window or uses the previous one.
function M.create_window_buffer(source_bufnr, compiler_id, new_window)
  local conf = ce.config.get_config()

  local winid = ce.clientstate.get_last_bufwinid(source_bufnr)
  if winid == nil then
    vim.cmd("vsplit")
  else
    api.nvim_set_current_win(winid)
    if new_window then vim.cmd(conf.split) end
  end

  local asm_bufnr = api.nvim_create_buf(false, true)
  local name = "compiler-explorer://" .. compiler_id .. "-" .. math.random(100)
  api.nvim_buf_set_name(asm_bufnr, name)
  api.nvim_buf_set_option(asm_bufnr, "ft", "asm")
  api.nvim_buf_set_option(asm_bufnr, "bufhidden", "wipe")

  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, asm_bufnr)

  return asm_bufnr
end

function M.set_binary_extmarks(lines, bufnr)
  local ns = api.nvim_create_namespace("ce-binary")

  for i, line in ipairs(lines) do
    if line.address ~= nil then
      local address = string.format("%x", line.address)
      local opcodes = " " .. table.concat(line.opcodes, " ")

      api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        virt_lines_above = true,
        virt_lines = { { { opcodes, "Comment" } } },
        virt_text = { { address, "Comment" } },
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
  local conf = ce.config.get_config()
  local args = {}
  args.inferLang = conf.infer_lang

  for _, f in ipairs(fargs) do
      if f:find("=") then
          local key, val = f:match("(.-)%".. "=" .."(.+)")
          args[key] = to_bool(val)
      else
          args[f] = true
      end
  end

  return args
end

function M.start_spinner(text)
  local frames = { "⣼", "⣹", "⢻", "⠿", "⡟", "⣏", "⣧", "⣶" }
  local interval = 100

  local i = 1
  M.timer = uv.new_timer()
  M.timer:start(0, interval, function()
    i = (i == #frames) and 1 or (i + 1)
    local msg = text .. " " .. frames[i]
    vim.schedule(function() api.nvim_echo({ { msg, "None" } }, false, {}) end)
  end)
end

function M.stop_spinner()
  api.nvim_echo({ { "", "None" } }, false, {})
  M.timer:stop()
  M.timer:close()
end

return M
