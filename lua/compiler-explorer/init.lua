local alert = require("compiler-explorer.alert")
local async = require("compiler-explorer.async")
local autocmd = require("compiler-explorer.autocmd")
local config = require("compiler-explorer.config")
local rest = require("compiler-explorer.rest")
local stderr = require("compiler-explorer.stderr")
local util = require("compiler-explorer.util")

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

M.compile = async.void(function(opts)
  local conf = config.get_config()
  local args = util.parse_args(opts.fargs)

  -- Get window handle of the source code window.
  local source_winnr = api.nvim_get_current_win()

  -- Get buffer number of the source code buffer.
  local source_bufnr = fn.bufnr("%")

  -- Get contents of the selected lines.
  local buf_contents = api.nvim_buf_get_lines(source_bufnr, opts.line1 - 1, opts.line2, false)
  args.source = table.concat(buf_contents, "\n")

  local ok, compiler = pcall(util.check_compiler, args.compiler)
  if not ok then
    alert.error("Could not compile code with compiler id %s", args.compiler)
    return
  end

  if not compiler then
    local lang_list = rest.languages_get()
    local possible_langs = lang_list

    -- Infer language based on extension and prompt user.
    if args.inferLang then
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
        prompt = "Select language> ",
        format_item = function(item)
          return item.name
        end,
      })
    end

    -- Choose compiler
    local compilers = rest.compilers_get(lang.id)
    compiler = vim_select()(compilers, {
      prompt = "Select compiler> ",
      format_item = function(item)
        return item.name
      end,
    })

    -- Choose compiler options
    args.flags = vim_input()({ prompt = "Select compiler options> ", default = conf.compiler_flags })
    args.compiler = compiler.id
  end

  -- Compile
  local body = rest.create_compile_body(args)
  util.start_spinner()
  local response = rest.compile_post(compiler.id, body)
  util.stop_spinner()

  local asm_lines = vim.tbl_map(function(line)
    return line.text
  end, response.asm)

  local asm_bufnr = util.create_window_buffer(compiler.id, opts.bang)
  api.nvim_buf_clear_namespace(asm_bufnr, -1, 0, -1)

  api.nvim_buf_set_option(asm_bufnr, "modifiable", true)
  api.nvim_buf_set_lines(asm_bufnr, 0, -1, false, asm_lines)

  if response.code == 0 then
    alert.info("Compilation done with %s compiler.", compiler.name)
  else
    alert.error("Could not compile code with %s", compiler.name)
  end

  if args.binary then
    util.set_binary_extmarks(response.asm, asm_bufnr)
  end

  -- Return to source window
  api.nvim_set_current_win(source_winnr)

  api.nvim_buf_set_option(asm_bufnr, "modifiable", false)

  stderr.parse_errors(response.stderr, source_bufnr, opts.line1 - 1)
  if conf.autocmd.enable and not args.binary then
    autocmd.create_autocmd(source_bufnr, asm_bufnr, response.asm, opts.line1 - 1)
  end

  api.nvim_buf_set_var(asm_bufnr, "arch", compiler.instructionSet) -- used by show_tooltips
  api.nvim_buf_set_var(asm_bufnr, "labels", response.labelDefinitions) -- used by goto_label

  api.nvim_buf_create_user_command(asm_bufnr, "CEShowTooltip", require("compiler-explorer").show_tooltip, {})
  api.nvim_buf_create_user_command(asm_bufnr, "CEGotoLabel", require("compiler-explorer").goto_label, {})

  return args.compiler, args.flags
end)

-- WARN: Experimental
M.compile_live = async.void(function(opts)
  local compiler, flags = M.compile(opts)

  api.nvim_create_autocmd({ "BufWritePost" }, {
    group = api.nvim_create_augroup("CompilerExplorerLive", { clear = true }),
    buffer = fn.bufnr("%"),
    callback = function()
      M.compile({
        line1 = 1,
        line2 = fn.line("$"),
        fargs = { "compiler=" .. compiler, flags and "flags=" .. flags },
      })
    end,
  })
end)

M.add_library = async.void(function()
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
      prompt = "Select language> ",
      format_item = function(item)
        return item.name
      end,
    })
  end

  local libs = rest.libraries_get(lang.id)
  if vim.tbl_isempty(libs) then
    alert.info("No libraries are available for %.", lang.name)
    return
  end

  -- Choose library
  local lib = vim_select()(libs, {
    prompt = "Select library> ",
    format_item = function(item)
      return item.name
    end,
  })

  -- Choose version
  local version = vim_select()(lib.versions, {
    prompt = "Select library version> ",
    format_item = function(item)
      return item.version
    end,
  })

  -- Add lib to buffer variable, overwriting previous library version if already present
  vim.b.libs = vim.tbl_deep_extend("force", vim.b.libs or {}, { [lib.id] = version.version })

  alert.info("Added library %s version %s", lib.name, version.version)
end)

M.format = async.void(function()
  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(0, 0, -1, false)
  local source = table.concat(buf_contents, "\n")

  -- Select formatter
  local formatters = rest.formatters_get()
  local formatter = vim_select()(formatters, {
    prompt = "Select formatter> ",
    format_item = function(item)
      return item.name
    end,
  })

  local style = formatter.styles[1] or "__DefaultStyle"
  if #formatter.styles > 0 then
    style = vim_select()(formatter.styles, {
      prompt = "Select formatter style> ",
      format_item = function(item)
        return item
      end,
    })
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

M.load_example = async.void(function()
  local examples = rest.list_examples_get()

  local examples_by_lang = {}
  for _, example in ipairs(examples) do
    if examples_by_lang[example.lang] == nil then
      examples_by_lang[example.lang] = { example }
    else
      table.insert(examples_by_lang[example.lang], example)
    end
  end

  local langs = vim.tbl_keys(examples_by_lang)
  table.sort(langs)

  local lang_id = vim_select()(langs, {
    prompt = "Select language> ",
    format_item = function(item)
      return item
    end,
  })

  local example = vim_select()(examples_by_lang[lang_id], {
    prompt = "Select example> ",
    format_item = function(item)
      return item.name
    end,
  })
  local response = rest.load_example_get(lang_id, example.file)
  local lines = vim.split(response.file, "\n")

  langs = rest.languages_get()
  local filtered = vim.tbl_filter(function(el)
    return el.id == lang_id
  end, langs)
  local extension = filtered[1].extensions[1]
  local bufname = example.file .. extension

  vim.cmd("tabedit")
  api.nvim_buf_set_lines(0, 0, -1, false, lines)
  api.nvim_buf_set_name(0, bufname)
  api.nvim_buf_set_option(0, "bufhidden", "wipe")

  vim.filetype.match(bufname, 0)
end)

return M
