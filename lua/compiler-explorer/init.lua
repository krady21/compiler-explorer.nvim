local async = require("compiler-explorer.async")
local config = require("compiler-explorer.config")
local rest = require("compiler-explorer.rest")

local api, fn, cmd = vim.api, vim.fn, vim.cmd

local M = {}

local custom_select = function(items, opts, cb)
  if items == nil or items == {} then
    return
  end
  if #items == 1 then
    return cb(items[1])
  end
  vim.ui.select(items, opts, cb)
end

M.select = async.wrap(vim.ui.select, 3)
M.input = async.wrap(vim.ui.input, 2)

function M.setup(user_config)
  config.setup(user_config or {})
end

local function create_linehl_dict(asm)
  local source_to_asm, asm_to_source = {}, {}
  local prev_dict = {}
  for asm_idx, line_obj in ipairs(asm) do
    if line_obj.source ~= vim.NIL then
      if line_obj.source.line ~= vim.NIL then
        local source_idx = line_obj.source.line
        if source_to_asm[source_idx] == nil then
          source_to_asm[source_idx] = {}
        end

        table.insert(source_to_asm[source_idx], asm_idx)
        asm_to_source[asm_idx] = source_idx
      end
    end
  end

  -- { 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 22, 23 }
  return source_to_asm, asm_to_source
end

local function create_autocmd(source_bufnr, asm_bufnr, resp)
  local conf = config.get_config()
  local source_to_asm, asm_to_source = create_linehl_dict(resp)

  local gid = api.nvim_create_augroup("CompilerExplorer", { clear = true })
  local ns = api.nvim_create_namespace("CompilerExplorer")
  local ns2 = api.nvim_create_namespace("Comp")

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      -- clear previous highlights
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)

      local line_nr = fn.line(".")
      local hl_ranges = source_to_asm[line_nr]
      if hl_ranges == nil then
        return
      end

      vim.highlight.range(
        asm_bufnr,
        ns,
        conf.autocmd.hl,
        { hl_ranges[1] - 1, 0 },
        { hl_ranges[#hl_ranges] - 1, -1 },
        "linewise",
        true
      )
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      -- clear previous highlights
      api.nvim_buf_clear_namespace(source_bufnr, ns2, 0, -1)

      local line_nr = fn.line(".")
      local hl_ranges = asm_to_source[line_nr]
      if hl_ranges == nil then
        return
      end

      vim.highlight.range(
        source_bufnr,
        ns2,
        conf.autocmd.hl,
        { hl_ranges - 1, 0 },
        { hl_ranges - 1, -1 },
        "linewise",
        true
      )
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      api.nvim_buf_clear_namespace(source_bufnr, ns2, 0, -1)
    end,
  })
end

M.show_tooltip = function()
  local doc = rest.tooltip_get(vim.b.arch, fn.expand("<cword>"))
  vim.lsp.util.open_floating_preview({ doc.tooltip }, "markdown", {
    wrap = true,
    close_events = { "CursorMoved" },
    border = "single",
  })
end

M.compile = async.void(function(start, finish)
  local conf = config.get_config()

  -- Get buffer number of the source code buffer
  local source_bufnr = fn.bufnr("%")

  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(source_bufnr, start - 1, finish, false)
  local source = table.concat(buf_contents, "\n")

  -- Infer language based on extension and prompt user.
  local extension = "." .. fn.expand("%:e")
  local extension_map = {}

  -- TODO: Memoize this
  local lang_list = rest.languages_get()
  for _, lang in ipairs(lang_list) do
    for _, ext in ipairs(lang.extensions) do
      if extension_map[ext] == nil then
        extension_map[ext] = {}
      end
      table.insert(extension_map[ext], { id = lang.id, name = lang.name })
    end
  end

  if extension_map[extension] == nil then
    vim.notify(string.format("File type not supported by compiler-explorer", extension), vim.log.levels.ERROR)
    return
  end

  -- Choose language
  local lang = M.select(extension_map[extension], {
    prompt = conf.prompt.lang,
    format_item = conf.format_item.lang,
  })

  -- Choose compiler
  local compilers = rest.compilers_get(lang.id)
  local compiler = M.select(compilers, {
    prompt = conf.prompt.compiler,
    format_item = conf.format_item.compiler,
  })

  -- Choose compiler options
  local compiler_opts = M.input({ prompt = conf.prompt.compiler_opts })

  -- Compile
  local body = rest.create_compile_body(compiler.id, compiler_opts, source)
  local out = rest.compile_post(compiler.id, body)
  local asm_lines = {}
  for _, line in ipairs(out.asm) do
    table.insert(asm_lines, line.text)
  end

  local name = "asm"
  local asm_bufnr = fn.bufnr(name)
  if asm_bufnr == -1 then
    asm_bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(asm_bufnr, name)
    api.nvim_buf_set_option(asm_bufnr, "ft", "asm")
  end

  if fn.bufwinnr(asm_bufnr) == -1 then
    cmd("vsplit")
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, asm_bufnr)
  end

  api.nvim_buf_set_lines(asm_bufnr, 0, -1, false, asm_lines)
  vim.notify(string.format("Compilation done %s", compiler.name))

  local is_full_buffer = function(start, finish)
    return (start == 1) and (finish == fn.line("$"))
  end

  vim.b[asm_bufnr].arch = compiler.instructionSet
  if conf.autocmd.enable and is_full_buffer(start, finish) then
    create_autocmd(source_bufnr, asm_bufnr, out.asm)
  end
end)

M.format = async.void(function()
  local conf = config.get_config()

  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(0, 0, -1, false)
  local source = table.concat(buf_contents, "\n")

  -- Select formatter
  local formatters = rest.formatters_get()
  local formatter = M.select(formatters, {
    prompt = conf.prompt.formatter,
    format_item = conf.format_item.formatter,
  })

  local style = formatter.styles[1] or "__DefaultStyle"
  if #formatter.styles > 0 then
    style = M.select(formatter.styles, {
      prompt = conf.prompt.formatter_style,
      format_item = conf.format_item.formatter_style,
    })
  end

  local body = rest.create_format_body(formatter.type, source, style)
  local out = rest.format_post(formatter.type, body)

  -- Split by newlines
  local lines = vim.split(out.answer, "\n")

  -- Replace lines of the current buffer with formatted text
  api.nvim_buf_set_lines(0, 0, -1, false, lines)

  -- TODO: Find how to make the text appear at the proper time.
  vim.notify(string.format("Text formatted using %s and style %s", formatter.name, style))
end)

-- vim.pretty_print(rest.compilers_get("c++"))
-- vim.pretty_print(rest.tooltip_get("amd64", "ret"))
return M
