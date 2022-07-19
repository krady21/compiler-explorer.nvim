local curl = require("plenary.curl")

local M = {}

M.bufnr = nil
function M.languages()
  local endpoint = "/api/languages"
  local url = "https://godbolt.org" .. endpoint
  local resp = curl.get(url, {
    accept = "application/json",
  })
  local contents = vim.fn.json_decode(resp.body)
  vim.pretty_print(contents)
end

function M.choose_lang()
  local endpoint = "/api/languages"
  local url = "https://godbolt.org" .. endpoint
  local resp = curl.get(url, {
    accept = "application/json",
  })
  local content = vim.fn.json_decode(resp.body)
  local langs = {}
  for _, lang in ipairs(content) do
    table.insert(langs, lang.id)
  end

  vim.ui.select(langs, { prompt = "Select language", }, function(choice) M.lang = choice end)
  print(M.lang)
end
function M.compilers(lang)
  local endpoint
  if lang then
    endpoint = "/api/compilers/" .. lang
  else
    endpoint = "/api/compilers"
  end

  local url = "https://godbolt.org" .. endpoint
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

-- TODO
function M.compile()
  local endpoint = "/api/compiler/g82/compile"
  local url = "https://godbolt.org" .. endpoint
  local body = {
    source = "int square(int num) {\n return num * 3;\n}",
    compiler = "g121",
    lang = "c++",
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

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, {})
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, asm_lines)
  else
    vim.cmd(vim.fn.bufwinnr(buf) .. "wincmd w")
  end
end

M.compile()
-- M.libraries("c++")
-- M.compilers("go")
-- vim.ui.input({ prompt = 'Enter value for shiftwidth: ' }, function(input)
--  vim.o.shiftwidth = tonumber(input)
-- end)

return M
