local M = {}

M.defaults = {
  url = "https://godbolt.org"
}
M._config = M.defaults

function M.setup(user_config)
  M._config = vim.tbl_deep_extend("force", M._config, user_config)
end

function M.get_config()
  return M._config
end
return M
