local ce = require("compiler-explorer.lazy")

local fn = vim.fn
local health = vim.health

local M = {}

M.check = function()
  health.report_start("compiler-explorer.nvim report")

  if fn.has("nvim-0.7") ~= 1 then
    health.report_error("compiler-explorer.nvim requires at least nvim-0.7")
  end

  if fn.executable("curl") ~= 1 then
    health.report_error("curl executable is missing", {
      "linux: sudo apt-get install curl",
      "mac: brew install curl",
    })
  else
    health.report_ok("curl executable was found")
  end

  if fn.executable("ping") then
    local config = ce.config.get_config()
    local hostname = config.url:match("^%w+://([^/]+)") -- TODO: test this match

    fn.system({ "ping", "-w", "3", "-c", "1", hostname })

    if vim.v.shell_error ~= 0 then
      health.report_error(string.format("Compiler Explorer instance at %s is not reachable", hostname))
    else
      health.report_ok(string.format("Compiler Explorer instance at %s is reachable", hostname))
    end
  end
end

return M
