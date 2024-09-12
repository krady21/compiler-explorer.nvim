local ce = require("compiler-explorer.lazy")

local M = {}

local get = function(url)
  local status, body = ce.http.get(url)
  if status ~= 200 then
    error(("GET %s returned %d. %s"):format(url, status, body.error), 0)
  end
  return body
end

local post = function(url, req_body, spinner_text)
  ce.util.start_spinner(spinner_text)
  local ok, status, body = pcall(ce.http.post, url, req_body)
  ce.util.stop_spinner()

  if not ok then error(status) end

  if status ~= 200 then
    error(("POST %s returned %d. %s"):format(url, status, body.error), 0)
  end
  return body
end

M.languages_get = function()
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "languages" }, "/")

  return get(url)
end

M.libraries_get = function(lang)
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "libraries", lang }, "/")

  return get(url)
end

M.tooltip_get = function(arch, instruction)
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "asm", arch, instruction }, "/")

  return get(url)
end

M.formatters_get = function()
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "formats" }, "/")

  return get(url)
end

function M.create_format_body(source, style)
  return {
    base = style,
    source = source,
    tabWidth = 4,
    useSpaces = true,
  }
end

M.format_post = function(formatter_id, req_body)
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "format", formatter_id }, "/")

  return post(url, req_body, "Formatting")
end

M.compilers_get = function(lang)
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "api", "compilers" }, "/")

  local body = get(url)
  if lang then
    return vim.tbl_filter(function(el) return el.lang == lang end, body)
  end
  return body
end

M.get_default_body = function()
  return {
    source = "",
    compiler = "",
    lang = "",
    allowStoreCodeDebug = true,
    options = {
      compilerOptions = {
        produceCfg = false,
        produceDevice = false,
        produceGccDump = {},
        produceLLVMOptPipeline = false,
        producePp = false,
      },
      filters = {
        binary = false,
        commentOnly = true,
        demangle = true,
        directives = true,
        execute = false,
        intel = true,
        labels = true,
        libraryCode = true,
        trim = false,
      },
      libraries = {},
      tools = {},
      userArguments = "",
    },
  }
end

local function body_from_args(args)
  local body = M.get_default_body()

  local filters = vim.tbl_keys(body.options.filters)

  for key, value in pairs(args) do
    if vim.tbl_contains(filters, key) then body.options.filters[key] = value end

    if key == "compiler" or key == "source" or key == "lang" then
      body[key] = value
    end

    -- Allow passing flags more than once.
    if key == "flags" then
      body.options.userArguments = body.options.userArguments .. " " .. value
    end
  end
  return body
end

function M.create_compile_body(args)
  local body = body_from_args(args)

  for id, version in pairs(vim.b.libs or {}) do
    table.insert(body.options.libraries, { id = id, version = version })
  end

  for _, tool in ipairs(vim.b.tools or {}) do
    table.insert(body.options.tools, { args = "", stdin = "", id = tool })
  end

  return body
end

M.compile_post = function(compiler_id, req_body)
  local conf = ce.config.get_config()
  local url =
    table.concat({ conf.url, "api", "compiler", compiler_id, "compile" }, "/")

  return post(url, req_body, "Compiling")
end

M.list_examples_get = function()
  local conf = ce.config.get_config()
  local url = table.concat({ conf.url, "source", "builtin", "list" }, "/")

  return get(url)
end

M.load_example_get = function(lang, name)
  local conf = ce.config.get_config()
  local url =
    table.concat({ conf.url, "source", "builtin", "load", lang, name }, "/")

  return get(url)
end

function M.check_compiler(compiler_id)
  if compiler_id == nil or type(compiler_id) ~= "string" then return nil end

  local compilers = M.compilers_get()
  local filtered = vim.tbl_filter(
    function(compiler) return compiler.id == compiler_id end,
    compilers
  )

  if vim.tbl_isempty(filtered) then error("incorrect compiler id") end
  return filtered[1]
end

return M
