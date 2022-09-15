local rest = require("compiler-explorer.rest")

local M = {}

M.filters_completer = function(arg_lead, _, _)
  local list = vim.tbl_keys(rest.filters)
  return vim.tbl_filter(function(el)
    return string.sub(el, 1, #arg_lead) == arg_lead
  end, list)
end

return M
