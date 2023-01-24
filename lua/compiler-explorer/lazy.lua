return setmetatable({}, {
  __index = function(_, key)
    return require("compiler-explorer." .. key)
  end,
})
