local curl = require("plenary.curl")
local config = require("compiler-explorer.config")

local json = vim.json

local M = {}

M.cache = {
  langs = {},
  compilers = {},
  libs = {},
  formatters = {},
}

function M.languages_get()
  if not vim.tbl_isempty(M.cache.langs) then
    return M.cache.langs
  end

  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "languages" }, "/")

  local resp = curl.get(url, {
    accept = "application/json",
  })

  M.cache.langs = json.decode(resp.body)
  return M.cache.langs
end

function M.libraries_get(lang)
  if not vim.tbl_isempty(M.cache.libs) then
    if lang then
      return M.cache.libs[lang] or {}
    end
    return M.cache.libs
  end

  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "libraries" }, "/")

  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  M.cache.libs = json.decode(resp.body)
  if lang then
    return M.cache.libs[lang] or {}
  end
  return M.cache.libs
end

function M.tooltip_get(arch, instruction)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "asm", arch, instruction }, "/")

  local resp = curl.get(url, {
    accept = "application/json",
  })

  local decoded = json.decode(resp.body)
  if resp.status ~= 200 then
    error({ code = resp.status, msg = decoded.error })
  end

  return decoded
end

function M.formatters_get()
  if not vim.tbl_isempty(M.cache.formatters) then
    return M.cache.formatters
  end
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "formats" }, "/")

  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  M.cache.formatters = json.decode(resp.body)
  return M.cache.formatters
end

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

function M.format_post(formatter_id, body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "format", formatter_id }, "/")

  local resp = curl.post(url, {
    body = json.encode(body),
    headers = {
      content_type = "application/json",
      accept = "application/json",
    },
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local out = json.decode(resp.body)
  return out
end

function M.compilers_get(lang)
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

  local resp = curl.get(url, {
    accept = "application/json",
  })
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
end

function M.create_compile_body(compiler_id, compiler_opts, source)
  vim.validate({
    source = { source, "string" },
    compiler_id = { compiler_id, "string" },
  })

  local libs = {}
  for id, version in pairs(vim.b.libs or {}) do
    table.insert(libs, { id = id, version = version })
  end

  return {
    source = source,
    compiler = compiler_id,
    allowStoreCodeDebug = true,
    options = {
      filters = {},
      libraries = libs,
      tools = {},
      compilerOptions = {},
      userArguments = compiler_opts,
    },
  }
end

function M.compile_post(compiler_id, body)
  local conf = config.get_config()
  local url = table.concat({ conf.url, "api", "compiler", compiler_id, "compile" }, "/")

  local resp = curl.post(url, {
    body = json.encode(body),
    headers = {
      content_type = "application/json",
      accept = "application/json",
    },
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local out = json.decode(resp.body)
  return out
end

return M
