local M = {}

M.defaults = {
  url = "https://godbolt.org",
  open_qflist = false,
  infer_lang = true, -- Try to infer possible language based on file extension.
  binary_hl = "Comment",
  autocmd = {
    enable = false,
    hl = "Cursorline",
  },
  diagnostics = { -- vim.diagnostic.config() options for the ce-diagnostics namespace.
    underline = false,
    virtual_text = false,
    signs = false,
  },
  split = "split", -- How to split the window after the second compile (split/vsplit).
  spinner_frames = { "⣼", "⣹", "⢻", "⠿", "⡟", "⣏", "⣧", "⣶" },
  spinner_interval = 100,
  compiler_flags = "",
}

M._config = M.defaults

function M.setup(user_config)
  M._config = vim.tbl_deep_extend("force", M._config, user_config)
end

function M.get_config()
  return M._config
end

return M
