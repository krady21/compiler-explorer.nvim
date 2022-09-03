-- Module was inspired from a similar module in gitsigns.nvim
local M = {}

local plugin_title = "compiler-explorer"

M.error = vim.schedule_wrap(function(s, ...)
  vim.notify(s:format(...), vim.log.levels.ERROR, { title = plugin_title })
end)

M.warn = vim.schedule_wrap(function(s, ...)
  vim.notify(s:format(...), vim.log.levels.WARN, { title = plugin_title })
end)

M.info = vim.schedule_wrap(function(s, ...)
  vim.notify(s:format(...), vim.log.levels.WARN, { title = plugin_title })
end)

return M
