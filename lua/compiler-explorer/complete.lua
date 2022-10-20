local cache = require("compiler-explorer.cache")
local M = {}

M.complete_fn = function(arg_lead)
  local list
  if vim.startswith(arg_lead, "compiler=") then
    local extension = "." .. vim.fn.expand("%:e")
    local compilers = cache.get_compilers(extension)
    list = vim.tbl_map(function(c)
      return [[compiler=]] .. c.id
    end, compilers)
  else
    list = {
      "binary",
      "commentOnly",
      "demangle",
      "directives",
      "execute",
      "intel",
      "labels",
      "libraryCode",
      "trim",
      "compiler",
      "flags",
      "inferLang",
    }
  end

  return vim.tbl_filter(function(el)
    return string.sub(el, 1, #arg_lead) == arg_lead
  end, list)
end
return M
