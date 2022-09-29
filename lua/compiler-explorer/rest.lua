local config = require("compiler-explorer.config")
local async = require("compiler-explorer.async")
local http = require("compiler-explorer.http")

local M = {}

M.default_body = {
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

M.cache = {
  langs = {},
  compilers = {},
  libs = {},
  formatters = {},
}

M.languages_get = async.void(function()
  if not vim.tbl_isempty(M.cache.langs) then
    return M.cache.langs
  end

  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "languages" }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  M.cache.langs = body
  return M.cache.langs
end)

M.libraries_get = async.void(function(lang)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "libraries", lang }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  return body
end)

M.tooltip_get = async.void(function(arch, instruction)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "asm", arch, instruction }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error({ code = status, msg = body.error })
  end

  return body
end)

M.formatters_get = async.void(function()
  if not vim.tbl_isempty(M.cache.formatters) then
    return M.cache.formatters
  end
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "formats" }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  M.cache.formatters = body
  return M.cache.formatters
end)

function M.create_format_body(formatter_id, source, style)
  vim.validate({
    source = { source, "string" },
    formatter_id = { formatter_id, "string" },
  })

  return {
    base = style,
    source = source,
    tabWidth = 4,
    useSpaces = true,
  }
end

M.format_post = async.void(function(formatter_id, req_body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "format", formatter_id }, "/")

  local status, body = http.post(url, req_body)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  return body
end)

M.compilers_get = async.void(function(lang)
  if not vim.tbl_isempty(M.cache.compilers) then
    if lang then
      return vim.tbl_filter(function(el)
        return el.lang == lang
      end, M.cache.compilers)
    end
    return M.cache.compilers
  end

  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compilers" }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  M.cache.compilers = body
  if lang then
    return vim.tbl_filter(function(el)
      return el.lang == lang
    end, M.cache.compilers)
  end
  return M.cache.compilers
end)

local function body_from_args(args)
  local body = vim.deepcopy(M.default_body)

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

M.compile_post = async.void(function(compiler_id, req_body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compiler", compiler_id, "compile" }, "/")

  local status, body = http.post(url, req_body)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  return body
end)

M.list_examples_get = async.void(function()
  local conf = config.get_config()
  local url = table.concat({ conf.url, "source", "builtin", "list" }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  return body
end)

M.load_example_get = async.void(function(lang, name)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "source", "builtin", "load", lang, name }, "/")

  local status, body = http.get(url)
  async.scheduler()

  if status ~= 200 then
    error("bad request")
  end

  return body
end)

return M
