local async = require("compiler-explorer.async")
local config = require("compiler-explorer.config")

local uv = vim.loop

local M = {}

local function close_pipes(...)
  for _, pipe in ipairs({ ... }) do
    if not pipe:is_closing() then
      pipe:close()
    end
  end
end

local function close_timer(timer)
  timer:stop()
  if not timer:is_closing() then
    timer:close()
  end
end

local function read_stop_pipes(...)
  for _, pipe in ipairs({ ... }) do
    pipe:read_stop()
  end
end

local spawn = function(cmd, args, cb)
  local conf = config.get_config()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local stdout_data, stderr_data = {}, {}
  local full_cmd = table.concat({ "curl", unpack(args) }, " ")

  local handle, timer
  handle, _ = uv.spawn(cmd, {
    args = args,
    stdio = { nil, stdout, stderr },
  }, function(code, signal)
    close_timer(timer)
    handle:close()

    read_stop_pipes(stdout, stderr)
    close_pipes(stdout, stderr)

    local stdout_result = table.concat(stdout_data)
    local stderr_result = table.concat(stderr_data)

    cb({
      cmd = full_cmd,
      exit = code,
      signal = signal,
      stdout = stdout_result,
      stderr = stderr_result,
    })
  end)

  if not handle then
    close_pipes(stdout, stderr)
    error(("Failed to start the process: %s"):format(table.concat({ cmd, unpack(args) }, " ")))
  end

  timer = uv.new_timer()
  timer:start(conf.job_timeout, 0, function()
    handle:kill("sigkill")
  end)

  stdout:read_start(function(_, data)
    table.insert(stdout_data, data)
  end)
  stderr:read_start(function(_, data)
    table.insert(stderr_data, data)
  end)
end

M.start = async.wrap(spawn, 3)

return M
