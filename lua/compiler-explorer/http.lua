local cache = require("compiler-explorer.cache")
local job = require("compiler-explorer.job")
local alert = require("compiler-explorer.alert")
local async = require("compiler-explorer.async")

local json = vim.json

local M = {}

M.get = async.void(function(url)
  local data = cache.get()[url]
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
    cache.get()[url] = resp
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

return M
