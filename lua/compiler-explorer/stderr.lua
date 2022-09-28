local config = require("compiler-explorer.config")

local api = vim.api

local M = {}

local severity_map = {
  [1] = vim.diagnostic.severity.INFO,
  [2] = vim.diagnostic.severity.WARN,
  [3] = vim.diagnostic.severity.ERROR,
}

local function is_full_err(err)
  return err.tag and err.tag.column and err.tag.line and err.tag.severity and err.tag.text
end

local function trim_msg_severity(err)
  local pos1, pos2 = string.find(err, ": ")
  return pos1 and string.sub(err, pos2 + 1, -1) or ""
end

M.parse_errors = function(stderr, bufnr, offset)
  if stderr == vim.NIL or stderr == nil then
    return
  end

  local conf = config.get_config()
  local ns = api.nvim_create_namespace("ce-diagnostics")

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
  vim.diagnostic.set(ns, bufnr, diagnostics, conf.diagnostics)
  vim.diagnostic.setqflist({ namespace = ns, open = conf.open_qflist, title = "Compiler Explorer" })
end

return M
