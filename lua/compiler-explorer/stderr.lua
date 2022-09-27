local config = require("compiler-explorer.config")

local api = vim.api

local M = {}

local severity_map = {
  [1] = vim.diagnostic.severity.INFO,
  [2] = vim.diagnostic.severity.WARN,
  [3] = vim.diagnostic.severity.ERROR,
}

local function is_full_err(err)
  if not err.tag then
    return false
  end

  if err.tag.column and err.tag.line and err.tag.severity and err.tag.text and err.tag.text ~= "" then
    return true
  end
  return false
end

local function trim_msg_severity(err)
  local pos1, pos2 = string.find(err, ": ")
  if pos1 then
    return string.sub(err, pos2 + 1, -1)
  else
    return ""
  end
end

M.parse_errors = function(stderr, bufnr, offset)
  -- stderr can be vim.NIL (ex: for golang) which is of type userdata
  if type(stderr) ~= "table" then
    return
  end

  local conf = config.get_config()
  local ns = api.nvim_create_namespace("ce-diagnostics")
  vim.diagnostic.config({ underline = false, virtual_text = false, signs = false }, ns)

  local diagnostics = {}
  for _, err in ipairs(stderr) do
    if is_full_err(err) then
      table.insert(diagnostics, {
        lnum = err.tag.line + offset - 1,
        col = err.tag.column - 1,
        message = trim_msg_severity(err.tag.text),
        bufnr = bufnr,
        severity = severity_map[err.tag.severity],
      })
    end
  end

  vim.diagnostic.reset(ns)
  vim.diagnostic.set(ns, bufnr, diagnostics)
  vim.diagnostic.setqflist({ namespace = ns, open = conf.open_qflist, title = "Compiler Explorer" })
end

return M
