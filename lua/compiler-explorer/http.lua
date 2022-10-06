local job = require("compiler-explorer.job")
local alert = require("compiler-explorer.alert")
local async = require("compiler-explorer.async")

local json = vim.json
local api, fn = vim.api, vim.fn

local M = {}

local cache = {
  in_memory = {},
  filename = fn.stdpath("cache") .. "/compiler-explorer-cache.json",
  loaded_from_file = false,
}

setmetatable(cache, {
  __index = function(t, key)
    local value = rawget(t.in_memory, key)
    if value ~= nil then
      return value
    else
      if t.loaded_from_file then
        return nil
      end

      api.nvim_create_autocmd({ "VimLeavePre" }, {
        group = api.nvim_create_augroup("ce-cache", { clear = true }),
        callback = function()
          local file = io.open(cache.filename, "w+")
          file:write(json.encode(t.in_memory))
          file:close()
        end,
      })

      local ok, file = pcall(io.open, cache.filename, "r")
      if not ok or not file then
        return nil
      end
      local data = file:read("*a")
      file:close()
      t.in_memory = json.decode(data)
      t.loaded_from_file = true
      return rawget(t.in_memory, key)
    end
  end,
  __newindex = function(t, key, value)
    rawset(t.in_memory, key, value)
  end,
})

M.get = async.void(function(url)
  local data = cache[url]
  if data ~= nil then
    return 200, data
  end

  local args = { "-X", "GET", "-H", "Accept: application/json", "-w", [[\n%{http_code}\n]], url }

  local exit, stdout, stderr = job.start("curl", args)
  if exit ~= 0 then
    local cmd = table.concat({ "curl", unpack(args) }, " ")
    alert.error("curl error:\ncommand: %s\nexit_code: %d\nstderr: %s", cmd, exit, stderr)
    return
  end

  local split = vim.split(stdout, "\n")
  local resp, status = json.decode(split[1]), tonumber(split[2])
  if status == 200 then
    cache[url] = resp
  end
  return status, resp
end)

M.post = async.void(function(url, body)
  local args = {
    "-s",
    "-X",
    "POST",
    "-H",
    "Accept: application/json",
    "-H",
    "Content-Type: application/json",
    "-d",
    json.encode(body),
    "-w",
    [[\n%{http_code}\n]],
    url,
  }

  local exit, stdout, stderr = job.start("curl", args)
  if exit ~= 0 then
    local cmd = table.concat({ "curl", unpack(args) }, " ")
    alert.error("curl error:\n command: %s \n exit_code %d\n stderr: %s", cmd, exit, stderr)
    return
  end

  local split = vim.split(stdout, "\n")
  local resp, status = json.decode(split[1]), tonumber(split[2])
  return status, resp
end)

M.delete_cache = function()
  cache.in_memory = {}
  os.remove(fn.stdpath("cache") .. "/compiler-explorer-cache.json")
  alert.info("Cache file has been deleted.")
end

return M
