local curl = require("plenary.curl")

local function get_endpoint(resource, id)
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

local M = {}

function M.languages_get()
  local url = get_endpoint("languages")
  local resp = curl.get(url, {
    accept = "application/json",
  })
  local langs = vim.fn.json_decode(resp.body)
  return langs
end

function M.compilers_get(lang)
  local url = M.get_endpoint("compilers", lang)
  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local compilers = vim.fn.json_decode(resp.body)
  return compilers
end

function M.libraries_get(lang)
  local url = get_endpoint("libraries", lang)
  local resp = curl.get(url, {
    accept = "application/json",
  })
  if resp.status ~= 200 then
    error("bad request")
  end

  local libs = vim.fn.json_decode(resp.body)
  return libs
end


function M.compile_post(compiler_id, body)
  local url = M.get_endpoint("compiler", compiler_id)

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
  return out
end
return M
