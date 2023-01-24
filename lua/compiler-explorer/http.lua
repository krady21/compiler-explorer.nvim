local ce = require("compiler-explorer.lazy")

local json = vim.json

local M = {}

M.get = ce.async.void(function(url)
  local data = ce.cache.get()[url]
  if data ~= nil then
    return 200, data
  end

  local args = {
    "-X",
    "GET",
    "-H",
    "Accept: application/json",
    "-w",
    [[\n%{http_code}\n]],
    url,
  }

  local ret = ce.job.start("curl", args)
  ce.async.scheduler()
  if ret.exit ~= 0 then
    error(("curl error:\ncommand: %s\nexit_code: %d\nstderr: %s"):format(ret.cmd, ret.exit, ret.stderr))
  end

  if ret.signal == 9 then
    error("SIGKILL: curl command timed out")
  end

  local split = vim.split(ret.stdout, "\n")
  if #split < 2 then
    error([[curl response does not follow the <body \n\n status_code> pattern]])
  end
  local resp, status = json.decode(split[1]), tonumber(split[2])
  if status == 200 then
    cache.get()[url] = resp
  end
  return status, resp
end)

M.post = ce.async.void(function(url, body)
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
  local ret = ce.job.start("curl", args)
  ce.async.scheduler()
  if ret.exit ~= 0 then
    error(("curl error:\n command: %s \n exit_code %d\n stderr: %s"):format(ret.cmd, ret.exit, ret.stderr))
  end

  if ret.signal == 9 then
    error("SIGKILL: curl command timed out")
  end

  local split = vim.split(ret.stdout, "\n")
  if #split < 2 then
    error([[curl response does not follow the <body \n\n status_code> pattern]])
  end
  local resp, status = json.decode(split[1]), tonumber(split[2])
  return status, resp
end)

return M
