local curl = require("plenary.curl")

local M = {}
function M.languages()
  local url = M.get_endpoint("languages")
  local resp = curl.get(url, {
    accept = "application/json",
  })
  local langs = vim.fn.json_decode(resp.body)
  return langs
end

function M.get_endpoint(resource, id)
  -- TODO: Add configuration in case of local instance of compiler explorer.
  local url = "https://godbolt.org/api"
  if resource == "languages" or resource == "formats" then
    url = string.format("%s/%s", url, resource)
  elseif resource == "compilers" or resource == "format" or resource == "shortlinkinfo" then
    url = string.format("%s/%s/%s", url, resource, id)
  elseif resource == "compiler" then
    url = string.format("%s/%s/%s/compile", url, resource, id)
  end
  return url
end

function M.choose_compiler(lang_id)
  local url = M.get_endpoint("compilers", lang_id)
  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end
  local compilers = vim.fn.json_decode(resp.body)

  vim.ui.select(compilers, {
    prompt = "Select compiler",
    format_item = function(compiler)
      return compiler.name
    end,
  }, function(compiler)
    M.compiler_id = compiler.id
  end)
  return M.compiler_id
end

function M.compilers(lang)
  local url = M.get_endpoint("compilers", lang)
  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local compilers = vim.fn.json_decode(resp.body)
  vim.pretty_print(compilers)
end

function M.libraries(lang)
  local endpoint
  if lang then
    endpoint = "/api/libraries/" .. lang
  else
    endpoint = "/api/libraries"
  end

  local url = "https://godbolt.org" .. endpoint
  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local libs = vim.fn.json_decode(resp.body)
  vim.pretty_print(libs)
end

-- TODO
-- function M.shortlinkinfo(link)
-- end

function M.infer_language(extension)
  local extension_map = {}

  -- TODO: Memoize this
  local lang_list = M.languages()
  for _, lang in ipairs(lang_list) do
    for _, ext in ipairs(lang.extensions) do
      if extension_map[ext] == nil then
        extension_map[ext] = {}
      end
      table.insert(extension_map[ext], {id = lang.id, name = lang.name})
    end
  end


  -- Make the user choose the language in case the extension is related to more
  -- than one language.
  vim.ui.select(extension_map[extension], {
    prompt = "Select language",
    format_item = function(lang)
      return lang.name
    end,
  }, function(lang)
    M.chosen_lang_id = lang.id
  end)

  return M.chosen_lang_id
end

function M.compile(compiler_id)
  -- Get contents of current buffer
  local buf_contents = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local source = table.concat(buf_contents, "\n")

  -- If compiler id is not specified try to smartly prompt user.
  if compiler_id == nil or compiler_id == "" then
    -- Infer language based on extension and prompt user.
    local extension = "." .. vim.fn.expand("%:e")
    local lang_id = M.infer_language(extension)

    -- Prompt user for compiler choice
    compiler_id = M.choose_compiler(lang_id)
  end

  local url = M.get_endpoint("compiler", compiler_id)
  print(url)

  local body = {
    source = source,
    compiler = compiler_id,
    allowStoreCodeDebug = true,
    options = {
      filters = {},
      libraries = {},
      tools = {},
      compilerOptions = {},
      userArguments = "",
    },
  }

  local resp = curl.post(url, {
    body = vim.fn.json_encode(body),
    headers = {
      content_type = "application/json",
      accept = "application/json",
    },
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local out = vim.fn.json_decode(resp.body)
  local asm_lines = {}
  for _, line in ipairs(out.asm) do
    table.insert(asm_lines, line.text)
  end

  local name = "asm"
  local buf = vim.fn.bufnr(name)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    vim.api.nvim_buf_set_option(buf, "ft", "asm")
  end

  if vim.fn.bufwinnr(buf) == -1 then
    vim.cmd("vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    -- TODO: Do we need this?
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, {})
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, asm_lines)
  end
end

-- vim.pretty_print(M.infer_language(".asm"))
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
