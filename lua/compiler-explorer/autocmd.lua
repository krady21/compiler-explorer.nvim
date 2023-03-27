local ce = require("compiler-explorer.lazy")

local api, fn = vim.api, vim.fn

local M = {}

local function create_matching_lines_dicts(asm, offset)
  local source_to_asm, asm_to_source = {}, {}
  for asm_idx, line_obj in ipairs(asm) do
    if line_obj.source ~= vim.NIL and line_obj.source.line ~= vim.NIL and line_obj.source.file == vim.NIL then
      local source_idx = line_obj.source.line + offset
      if source_to_asm[source_idx] == nil then
        source_to_asm[source_idx] = {}
      end

      table.insert(source_to_asm[source_idx], asm_idx)
      asm_to_source[asm_idx] = source_idx
    end
  end

  return source_to_asm, asm_to_source
end

M.create_autocmd = function(source_bufnr, asm_bufnr, resp, offset)
  local source_to_asm, asm_to_source = create_matching_lines_dicts(resp, offset)
  if vim.tbl_isempty(source_to_asm) or vim.tbl_isempty(asm_to_source) then
    return
  end

  local conf = ce.config.get_config()
  local hl_group = conf.autocmd.hl
  local gid = api.nvim_create_augroup("CompilerExplorer" .. asm_bufnr, { clear = true })
  local ns = api.nvim_create_namespace("ce-autocmds")

  local line_match_cb = function(other_buf, matching_lines)
    if not api.nvim_buf_is_loaded(other_buf) then
      api.nvim_clear_autocmds({ group = gid })
      api.nvim_del_augroup_by_id(gid)
      return
    end

    api.nvim_buf_clear_namespace(other_buf, ns, 0, -1)

    local line_nr = fn.line(".")
    local hl_list = matching_lines[line_nr]
    if not hl_list then
      return
    end

    if type(hl_list) ~= "table" then
      hl_list = { hl_list }
    end

    for _, linenr in ipairs(hl_list) do
      -- highlight the matching line
      pcall(api.nvim_buf_add_highlight, other_buf, ns, hl_group, linenr - 1, 0, -1)
    end

    local winid = fn.bufwinid(other_buf)
    -- move cursor to first matching line
    pcall(api.nvim_win_set_cursor, winid, { hl_list[1], 0 })
  end

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      line_match_cb(asm_bufnr, source_to_asm)
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      line_match_cb(source_bufnr, asm_to_source)
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      pcall(api.nvim_buf_clear_namespace, asm_bufnr, ns, 0, -1)
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      pcall(api.nvim_buf_clear_namespace, source_bufnr, ns, 0, -1)
    end,
  })

  api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      api.nvim_buf_clear_namespace(source_bufnr, ns, 0, -1)
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)
      api.nvim_clear_autocmds({ group = gid })
    end,
  })
end

return M
