local ce = require("compiler-explorer.lazy")

local api, fn = vim.api, vim.fn
local hi = vim.highlight

local M = {}

local function highlight_line(bufnr, linenr, ns, higroup)
  if fn.has("nvim-0.8") then
    hi.range(bufnr, ns, higroup, { linenr, 0 }, { linenr, 3000 }, { inclusive = true, regtype = "linewise" })
  else
    hi.range(bufnr, ns, higroup, { linenr, 0 }, { linenr, -1 }, "linewise", true)
  end
end

local function create_linehl_dict(asm, offset)
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
  local source_to_asm, asm_to_source = create_linehl_dict(resp, offset)
  if vim.tbl_isempty(source_to_asm) or vim.tbl_isempty(asm_to_source) then
    return
  end

  local conf = ce.config.get_config()
  local hl_group = conf.autocmd.hl
  local gid = api.nvim_create_augroup("CompilerExplorer" .. asm_bufnr, { clear = true })
  local ns = api.nvim_create_namespace("ce-autocmds")

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      if fn.bufloaded(asm_bufnr) == 0 then
        api.nvim_clear_autocmds({ group = gid })
        api.nvim_del_augroup_by_id(gid)
        return
      end
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)

      local line_nr = fn.line(".")
      local hl_list = source_to_asm[line_nr]
      if hl_list then
        for _, hl in ipairs(hl_list) do
          highlight_line(asm_bufnr, hl - 1, ns, hl_group)
        end
        local winid = fn.bufwinid(asm_bufnr)
        if winid ~= -1 then
          pcall(api.nvim_win_set_cursor, winid, { hl_list[1], 0 })
        end
      end
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      if not fn.bufloaded(source_bufnr) == 0 then
        api.nvim_clear_autocmds({ group = gid })
        api.nvim_del_augroup_by_id(gid)
        return
      end
      api.nvim_buf_clear_namespace(source_bufnr, ns, 0, -1)

      local line_nr = fn.line(".")
      local hl = asm_to_source[line_nr]
      if hl then
        highlight_line(source_bufnr, hl - 1, ns, hl_group)

        local winid = fn.bufwinid(source_bufnr)
        if winid ~= -1 then
          pcall(api.nvim_win_set_cursor, winid, { hl, 0 })
        end
      end
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
