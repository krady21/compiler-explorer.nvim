local curl = require("plenary.curl")
local config = require("compiler-explorer.config")
local async = require("compiler-explorer.async")

local json = vim.json

local post_wrapped = async.wrap(function(url, opts, callback)
  opts.callback = callback
  curl.post(url, opts)
end, 3)

local get_wrapped = async.wrap(function(url, opts, callback)
  opts.callback = callback
  curl.get(url, opts)
end, 3)

local string_to_bool = {
  ["true"] = true,
  ["false"] = false,
}

local M = {}

M.filters = {
  binary = false,
  commentOnly = true,
  demangle = true,
  directives = true,
  execute = false,
  intel = true,
  labels = true,
  libraryCode = true,
  trim = false,
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

  local resp = get_wrapped(url, {
    accept = "application/json",
  })
  async.scheduler()

  M.cache.langs = json.decode(resp.body)
  return M.cache.langs
end)

M.libraries_get = async.void(function(lang)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "libraries", lang }, "/")

  local resp = get_wrapped(url, {
    accept = "application/json",
  })
  async.scheduler()
  if resp.status ~= 200 then
    error("bad request")
  end

  local libs = json.decode(resp.body)
  return libs
end)

M.tooltip_get = async.void(function(arch, instruction)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "asm", arch, instruction }, "/")

  local resp = get_wrapped(url, {
    accept = "application/json",
  })
  async.scheduler()

  local decoded = json.decode(resp.body)
  if resp.status ~= 200 then
    error({ code = resp.status, msg = decoded.error })
  end

  return decoded
end)

M.formatters_get = async.void(function()
  if not vim.tbl_isempty(M.cache.formatters) then
    return M.cache.formatters
  end
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "formats" }, "/")

  local resp = get_wrapped(url, {
    accept = "application/json",
  })
  async.scheduler()
  if resp.status ~= 200 then
    error("bad request")
  end

  M.cache.formatters = json.decode(resp.body)
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

M.format_post = async.void(function(formatter_id, body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "format", formatter_id }, "/")

  local resp = post_wrapped(url, {
    body = json.encode(body),
    headers = {
      content_type = "application/json",
      accept = "application/json",
    },
  })
  async.scheduler()
  if resp.status ~= 200 then
    error("bad request")
  end

  local out = json.decode(resp.body)
  return out
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

  local resp = get_wrapped(url, {
    accept = "application/json",
  })
  async.scheduler()
  if resp.status ~= 200 then
    error("bad request")
  end

  M.cache.compilers = json.decode(resp.body)
  if lang then
    return vim.tbl_filter(function(el)
      return el.lang == lang
    end, M.cache.compilers)
  end
  return M.cache.compilers
end)

function M.create_compile_body(compiler_id, compiler_opts, source, fargs)
  vim.validate({
    source = { source, "string" },
    compiler_id = { compiler_id, "string" },
  })

  local libs = {}
  for id, version in pairs(vim.b.libs or {}) do
    table.insert(libs, { id = id, version = version })
  end

  local tools = {}
  for _, tool in ipairs(vim.b.tools or {}) do
    table.insert(tools, { args = "", stdin = "", id = tool })
  end

  local filters = M.filters
  for _, f in ipairs(fargs) do
    local split_arg = vim.split(f, "=")
    if #split_arg == 1 then
      filters[split_arg[1]] = true
    elseif #split_arg == 2 then
      filters[split_arg[1]] = string_to_bool[split_arg[2]]
    end
  end

  return {
    source = source,
    compiler = compiler_id,
    allowStoreCodeDebug = true,
    options = {
      compilerOptions = {},
      filters = filters,
      libraries = libs,
      tools = tools,
      userArguments = compiler_opts,
    },
  }
end

M.compile_post = async.void(function(compiler_id, body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compiler", compiler_id, "compile" }, "/")

  local resp = post_wrapped(url, {
    body = json.encode(body),
    headers = {
      content_type = "application/json",
      accept = "application/json",
    },
  })
  async.scheduler()
  if resp.status ~= 200 then
    error("bad request")
  end

  local out = json.decode(resp.body)
  return out
end)

return M
