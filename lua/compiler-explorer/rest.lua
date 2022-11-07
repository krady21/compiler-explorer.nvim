local config = require("compiler-explorer.config")
local http = require("compiler-explorer.http")

local M = {}

M.languages_get = function()
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "languages" }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  return body
end

M.libraries_get = function(lang)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "libraries", lang }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  return body
end

M.tooltip_get = function(arch, instruction)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "asm", arch, instruction }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error({ code = status, msg = body.error })
  end

  return body
end

M.formatters_get = function()
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "formats" }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  return body
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
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "format", formatter_id }, "/")

  local status, body = http.post(url, req_body)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  return body
end

M.compilers_get = function(lang)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compilers" }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  if lang then
    return vim.tbl_filter(function(el)
      return el.lang == lang
    end, body)
  end
  return body
end

M.get_default_body = function()
  return {
    source = "",
    compiler = "",
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
    if vim.tbl_contains(filters, key) then
      body.options.filters[key] = value
    end

    if key == "compiler" or key == "source" then
      body[key] = value
    end

    -- Allow passing flags more than once.
    if key == "flags" then
      body.options.userArguments = body.options.userArguments .. value
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
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compiler", compiler_id, "compile" }, "/")

  local util = require("compiler-explorer.util")
  util.start_spinner()
  local ok, status, body = pcall(http.post, url, req_body)
  util.stop_spinner()

  if not ok then
    error(status)
  end

  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end
  return body
end

M.list_examples_get = function()
  local conf = config.get_config()
  local url = table.concat({ conf.url, "source", "builtin", "list" }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end
  return body
end

M.load_example_get = function(lang, name)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "source", "builtin", "load", lang, name }, "/")

  local status, body = http.get(url)
  if status ~= 200 then
    error(("HTTP request returned status code %d."):format(status))
  end

  return body
end

function M.check_compiler(compiler_id)
  if compiler_id == nil or type(compiler_id) ~= "string" then
    return nil
  end

  local compilers = M.compilers_get()
  local filtered = vim.tbl_filter(function(compiler)
    return compiler.id == compiler_id
  end, compilers)

  if vim.tbl_isempty(filtered) then
    error("incorrect compiler id")
  end
  return filtered[1]
end

return M
