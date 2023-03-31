local ce = require("compiler-explorer.lazy")

local api, fn = vim.api, vim.fn
local json = vim.json

local M = {}

M.state = {}
M.buffers = {}

M.create = function()
  local sessions = {}
  local id = 1
  for source_bufnr, asm_data in pairs(M.state) do
    if api.nvim_buf_is_loaded(source_bufnr) then
      local compilers = {}
      for asm_bufnr, data in pairs(asm_data) do
        if api.nvim_buf_is_loaded(asm_bufnr) then
          table.insert(compilers, data)
        end
      end

      local lines = api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
      local source = table.concat(lines, "\n")

      table.insert(sessions, {
        language = compilers[1].lang,
        id = id,
        source = source,
        compilers = compilers,
      })
      id = id + 1
    end
  end

  if vim.tbl_isempty(sessions) then return nil end

  return ce.base64.encode(json.encode({ sessions = sessions }))
end

M.save_info = function(source_bufnr, asm_bufnr, body)
  M.state[source_bufnr] = M.state[source_bufnr] or {}

  M.state[source_bufnr][asm_bufnr] = {
    lang = body.lang,
    id = body.compiler,
    options = body.options.userArguments,
    filters = body.options.filters,
    libs = vim.tbl_map(
      function(lib) return { name = lib.id, ver = lib.version } end,
      body.options.libraries
    ),
  }
end

M.get_last_bufwinid = function(source_bufnr)
  for _, asm_buffer in ipairs(vim.tbl_keys(M.state[source_bufnr] or {})) do
    local winid = fn.bufwinid(asm_buffer)
    if winid ~= -1 then return winid end
  end
  return nil
end

return M
