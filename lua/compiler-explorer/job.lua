local ce = require("compiler-explorer.lazy")

local M = {}

local system = function(cmd, args, cb)
  local full_cmd = { cmd, unpack(args) }
  local on_exit = function(obj)
    cb({
      cmd = table.concat(full_cmd, " "),
      exit = obj.code,
      signal = obj.signal,
      stdout = obj.stdout,
      stderr = obj.stderr,
    })
  end
  vim.system(full_cmd, {}, on_exit)
end

local start = ce.async.wrap(system, 3)

setmetatable(M, {
  __index = function(_, key)
    return ce.async.void(function(args) return start(key, args) end)
  end,
})

return M
