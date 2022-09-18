local alert = require("compiler-explorer.alert")
local async = require("compiler-explorer.async")
local autocmd = require("compiler-explorer.autocmd")
local config = require("compiler-explorer.config")
local rest = require("compiler-explorer.rest")
local stderr = require("compiler-explorer.stderr")
local window = require("compiler-explorer.window")

local api, fn = vim.api, vim.fn

local M = {}

-- Return a function to avoid caching the vim.ui functions
local vim_select = function()
  return async.wrap(vim.ui.select, 3)
end
local vim_input = function()
  return async.wrap(vim.ui.input, 2)
end

M.setup = function(user_config)
  config.setup(user_config or {})
end

M.show_tooltip = async.void(function()
  local ok, response = pcall(rest.tooltip_get, vim.b.arch, fn.expand("<cword>"))
  if not ok then
    alert.error(response.msg)
    return
  end

  vim.lsp.util.open_floating_preview({ response.tooltip }, "markdown", {
    wrap = true,
    close_events = { "CursorMoved" },
    border = "single",
  })
end)

M.goto_label = function()
  local word_under_cursor = fn.expand("<cWORD>")
  local label = vim.b.labels[word_under_cursor]
  if label == nil then
    alert.error("No label found with the name %s", word_under_cursor)
    return
  end

  vim.cmd("norm m'")
  fn.setcursorcharpos(label, 0)
end

local function to_bool(s)
  if s == "true" then
    return true
  elseif s == "false" then
    return false
  else
    return s
  end
end

local function parse_args(fargs)
  local args = {}
  for _, f in ipairs(fargs) do
    local split = vim.split(f, "=")
    if #split == 1 then
      args[split[1]] = true
    elseif #split == 2 then
      args[split[1]] = to_bool(split[2])
    end
  end

  return args
end

local function is_correct_compiler(compiler_id)
  if compiler_id == nil or type(compiler_id) ~= "string" then
    return nil
  end

  local compilers = rest.compilers_get()
  local filtered = vim.tbl_filter(function(compiler)
    return compiler.id == compiler_id
  end, compilers)

  if vim.tbl_isempty(filtered) then
    error("incorrect compiler id")
  end
  return filtered[1]
end

M.compile = async.void(function(opts)
  local conf = config.get_config()

  local last_line = fn.line("$")
  local is_full_buffer = function(first, last)
    return (first == 1) and (last == last_line)
  end

  local args = parse_args(opts.fargs)

  -- Get window handle of the source code window.
  local source_winnr = api.nvim_get_current_win()

  -- Get buffer number of the source code buffer.
  local source_bufnr = fn.bufnr("%")

  -- Get contents of the selected lines.
  local buf_contents = api.nvim_buf_get_lines(source_bufnr, opts.line1 - 1, opts.line2, false)
  args.source = table.concat(buf_contents, "\n")

  local ok, compiler = pcall(is_correct_compiler, args.compiler)
  if not ok then
    alert.error("Could not compile code with compiler id %s", args.compiler)
    return
  end

  if not compiler then
    local lang_list = rest.languages_get()
    local possible_langs = lang_list

    -- Do not infer language when compiling only a visual selection.
    if is_full_buffer(opts.line1, opts.line2) then
      -- Infer language based on extension and prompt user.
      local extension = "." .. fn.expand("%:e")

      possible_langs = vim.tbl_filter(function(el)
        return vim.tbl_contains(el.extensions, extension)
      end, lang_list)

      if vim.tbl_isempty(possible_langs) then
        alert.error("File extension %s not supported by compiler-explorer", extension)
        return
      end
    end

    local lang
    if #possible_langs == 1 then
      lang = possible_langs[1]
    else
      -- Choose language
      lang = vim_select()(possible_langs, {
        prompt = conf.prompt.lang,
        format_item = conf.format_item.lang,
      })

      if lang == nil or vim.tbl_isempty(lang) then
        return
      end
    end

    -- Choose compiler
    local compilers = rest.compilers_get(lang.id)
    compiler = vim_select()(compilers, {
      prompt = conf.prompt.compiler,
      format_item = conf.format_item.compiler,
    })

    if compiler == nil or vim.tbl_isempty(compiler) then
      return
    end

    -- Choose compiler options
    args.flags = vim_input()({ prompt = conf.prompt.compiler_opts })
    args.compiler = compiler.id
  end

  -- Compile
  local body = rest.create_compile_body(args)
  local out = rest.compile_post(compiler.id, body)

  local asm_lines = {}
  for _, line in ipairs(out.asm) do
    table.insert(asm_lines, line.text)
  end

  local asm_bufnr = window.create_window_buffer(compiler.id, opts.bang)

  vim.bo[asm_bufnr].modifiable = true
  api.nvim_buf_set_lines(asm_bufnr, 0, -1, false, asm_lines)

  if out.code == 0 then
    alert.info("Compilation done with %s compiler.", compiler.name)
  else
    alert.error("Could not compile code with %s", compiler.name)
  end

  -- Return to source window
  api.nvim_set_current_win(source_winnr)

  vim.bo[asm_bufnr].modifiable = false

  -- Used by tooltips
  vim.b[asm_bufnr].arch = compiler.instructionSet

  -- Used by goto_label
  vim.b[asm_bufnr].labels = out.labelDefinitions

  if is_full_buffer(opts.line1, opts.line2) then
    stderr.parse_errors(out.stderr, source_bufnr)
    if conf.autocmd.enable then
      autocmd.create_autocmd(source_bufnr, asm_bufnr, out.asm)
    end
  end

  vim.api.nvim_buf_create_user_command(asm_bufnr, "CEShowTooltip", require("compiler-explorer").show_tooltip, {})
  vim.api.nvim_buf_create_user_command(asm_bufnr, "CEGotoLabel", require("compiler-explorer").goto_label, {})
end)

M.add_library = async.void(function()
  local conf = config.get_config()

  local lang_list = rest.languages_get()

  -- Infer language based on extension and prompt user.
  local extension = "." .. fn.expand("%:e")

  local possible_langs = vim.tbl_filter(function(el)
    return vim.tbl_contains(el.extensions, extension)
  end, lang_list)

  if vim.tbl_isempty(possible_langs) then
    alert.error("File extension %s not supported by compiler-explorer.", extension)
    return
  end

  local lang
  if #possible_langs == 1 then
    lang = possible_langs[1]
  else
    -- Choose language
    lang = vim_select()(possible_langs, {
      prompt = conf.prompt.lang,
      format_item = conf.format_item.lang,
    })

    if lang == nil or vim.tbl_isempty(lang) then
      return
    end
  end

  local libs = rest.libraries_get(lang.id)
  if vim.tbl_isempty(libs) then
    alert.info("No libraries are available for %.", lang.name)
    return
  end

  -- Choose library
  local lib = vim_select()(libs, {
    prompt = conf.prompt.lib,
    format_item = conf.format_item.lib,
  })

  if lib == nil or vim.tbl_isempty(lib) then
    return
  end

  -- Choose language
  local version = vim_select()(lib.versions, {
    prompt = conf.prompt.lib_version,
    format_item = conf.format_item.lib_version,
  })

  if version == nil or vim.tbl_isempty(version) then
    return
  end

  -- Add lib to buffer variable, overwriting previous library version if already present
  vim.b.libs = vim.tbl_deep_extend("force", vim.b.libs or {}, { [lib.id] = version.version })

  alert.info("Added library %s version %s", lib.name, version.version)
end)

M.format = async.void(function()
  local conf = config.get_config()

  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(0, 0, -1, false)
  local source = table.concat(buf_contents, "\n")

  -- Select formatter
  local formatters = rest.formatters_get()
  local formatter = vim_select()(formatters, {
    prompt = conf.prompt.formatter,
    format_item = conf.format_item.formatter,
  })

  if formatter == nil or vim.tbl_isempty(formatter) then
    return
  end

  local style = formatter.styles[1] or "__DefaultStyle"
  if #formatter.styles > 0 then
    style = vim_select()(formatter.styles, {
      prompt = conf.prompt.formatter_style,
      format_item = conf.format_item.formatter_style,
    })

    if style == nil then
      return
    end
  end

  local body = rest.create_format_body(formatter.type, source, style)
  local out = rest.format_post(formatter.type, body)

  if out.exit ~= 0 then
    alert.error("Could not format code with %s", formatter.name)
    return
  end

  -- Split by newlines
  local lines = vim.split(out.answer, "\n")

  -- Replace lines of the current buffer with formatted text
  api.nvim_buf_set_lines(0, 0, -1, false, lines)

  alert.info("Text formatted using %s and style %s", formatter.name, style)
end)

return M
