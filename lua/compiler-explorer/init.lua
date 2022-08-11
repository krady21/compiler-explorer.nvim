local rest = require("compiler-explorer.rest")
local config = require("compiler-explorer.config")
local awrap = require("compiler-explorer.async").wrap
local void = require("compiler-explorer.async").void
local scheduler = require("compiler-explorer.async").scheduler

local api, fn, cmd = vim.api, vim.fn, vim.cmd

local M = {}

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

  local compiler_opts = M.input({ prompt = conf.prompt.compiler_opts })

  -- Compile
  local body = rest.create_compile_body(source, compiler_opts, compiler.id)
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

    api.nvim_buf_set_lines(buf, 0, -1, false, {})
    api.nvim_buf_set_lines(buf, 0, -1, false, asm_lines)
  end
end)

return M
