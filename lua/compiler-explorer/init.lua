local rest = require("compiler-explorer.rest")
local config = require("compiler-explorer.config")

local api, fn, cmd = vim.api, vim.fn, vim.cmd

local M = {}

function M.setup(user_config)
  config.setup(user_config or {})
end

function M.compile(compiler_id)
  local conf = config.get_config()

  -- Get contents of current buffer
  local buf_contents = api.nvim_buf_get_lines(0, 0, -1, false)
  local source = table.concat(buf_contents, "\n")

  -- If compiler id is not specified try to smartly prompt user.
  if compiler_id == nil or compiler_id == "" then
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
    -- Make the user choose the language in case the extension is related to more
    -- than one language.
    vim.ui.select(extension_map[extension], {
      prompt = conf.prompt.lang,
      format_item = conf.format_item.lang,
    }, function(lang)
      local compilers = rest.compilers_get(lang.id)
      vim.ui.select(compilers, {
        prompt = conf.prompt.compiler,
        format_item = conf.format_item.compiler,
      }, function(compiler)
        vim.ui.input({ prompt = conf.prompt.compiler_opts }, function(compiler_opts)
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
      end)
    end)
  end
end

-- vim.pretty_print(rest.compilers_get("ocaml"))
-- vim.pretty_print(rest.languages_get())
-- vim.pretty_print(rest.create_compile_body("int a = 3;", "c"))
-- vim.pretty_print(rest.compilers_get())
--   compilerType = "golang",
--   id = "386_gltip",
--   instructionSet = "amd64",
--   lang = "go",
--   name = "386 gc (tip)",
--   semver = "(tip)"

-- M.languages()
-- M.choose_compiler()
-- M.choose_lang()
-- M.compile("g121")
-- M.libraries("c++")
-- M.compilers("go")
-- vim.ui.input({ prompt = 'Enter value for shiftwidth: ' }, function(input)
--  vim.o.shiftwidth = tonumber(input)
-- end)

return M
