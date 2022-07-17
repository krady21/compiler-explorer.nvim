local curl = require "plenary.curl"

local M = {}

function M.languages()
    local endpoint = "/api/languages"
    local url =  "https://godbolt.org" .. endpoint
    local resp = curl.get(url, {
        accept = "application/json",
    })
    local contents = vim.fn.json_decode(resp.body)
    vim.pretty_print(contents)
end

function M.compilers(lang)
    local endpoint
    if lang then
        endpoint = "/api/compilers/" .. lang
    else
        endpoint = "/api/compilers"
    end

    local url =  "https://godbolt.org" .. endpoint
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

    local url =  "https://godbolt.org" .. endpoint
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
    local url =  "https://godbolt.org" .. endpoint
    local body = {
        source = "int main () { return 1; }",
        compiler = "g82",
        options = {
            userArguments = "-O3",
            executeParameters = {
                args = { "arg1", "arg2" },
                stdin = "hello, world!"
            },
            compilerOptions = {
                executorRequest = true
            },
            filters = {
                execute = true
            },
            tools = { },
            libraries = { {
                id = "openssl",
                version = "111c"
            } }
        },
        lang = "c++",
        allowStoreCodeDebug = true
    }

    local resp = curl.post(url, {
        body = vim.fn.json_encode(body),
        headers = {
          content_type = "application/json",
          accept = "application/json",
          accept_encoding= ''
        },
    })
    if resp.status ~= 200 then
        error("bad request")
    end
    local libs = vim.fn.json_decode(resp.body)
    vim.pretty_print(libs)
end

M.compile()
-- M.libraries("c++")
-- M.compilers("go")
-- vim.ui.input({ prompt = 'Enter value for shiftwidth: ' }, function(input)
--  vim.o.shiftwidth = tonumber(input)
-- end)

return M
