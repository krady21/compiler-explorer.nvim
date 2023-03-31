local ce = require("compiler-explorer.lazy")

local fn = vim.fn
local health = vim.health

local M = {}

local has_nvim_version, has_curl, is_reachable

local run_checks = ce.async.void(function()
  has_nvim_version = fn.has("nvim-0.7") > 0
  has_curl = fn.executable("curl") > 0

  if not has_curl then
    is_reachable = false
    return
  end

  -- Ensure the next call is not cached.
  ce.cache.delete()
  is_reachable = pcall(ce.rest.languages_get)
end)

M.check = function()
  run_checks()
  vim.wait(2000, function() return is_reachable ~= nil end)

  health.report_start("compiler-explorer.nvim report")

  if not has_nvim_version then
    health.report_error("neovim version >=0.7 is required")
  else
    health.report_ok("neovim has version 0.7 or later")
  end

  if not has_curl then
    health.report_error("curl executable not found.", {
      "linux: sudo apt-get install curl",
      "mac: brew install curl",
    })
    return
  else
    health.report_ok("curl executable was found.")
  end

  local hostname = ce.config.get_config().url
  if not is_reachable then
    health.report_error(
      ("GET %s/api/languages failed. Server is unreachable."):format(hostname),
      {
        "check if the hostname is in the correct format",
      }
    )
  else
    health.report_ok(
      ("GET %s/api/languages successful. Server is reachable."):format(hostname)
    )
  end
end

return M
