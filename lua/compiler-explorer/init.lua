local rest = require("compiler-explorer.rest")
local config = require("compiler-explorer.config")
local awrap = require("compiler-explorer.async").wrap
local void = require("compiler-explorer.async").void
local scheduler = require("compiler-explorer.async").scheduler

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

M.select = awrap(vim.ui.select, 3)
M.input = awrap(vim.ui.input, 2)

function M.setup(user_config)
  config.setup(user_config or {})
end

M.compile = void(function()
  local conf = config.get_config()

  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(0, 0, -1, false)
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
  local buf = fn.bufnr(name)
  if buf == -1 then
    buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, name)
    api.nvim_buf_set_option(buf, "ft", "asm")
  end

  if fn.bufwinnr(buf) == -1 then
    cmd("vsplit")
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, buf)
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, asm_lines)
end)

M.format = void(function()
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
  -- if formatter.styles ~= {} then
  --    style = M.select(formatter.styles, {
  --     prompt = conf.prompt.formatter_style,
  --     format_item = conf.format_item.formatter_style,
  --   })
  -- end

  local body = rest.create_format_body(formatter.type, source, style)
  local out = rest.format_post(formatter.type, body)

  -- Split by newlines
  local lines = {}
  for line in string.gmatch(out.answer, "([^\n]*)\n?") do
    table.insert(lines, line)
  end

  -- Replace lines of the current buffer with formatted text
  api.nvim_buf_set_lines(0, 0, -1, false, lines)

  -- TODO: Find how to make the text appear at the proper time.
  scheduler()
  vim.notify(string.format("Text formatted using %s and style %s", formatter.name, style))
end)

return M
