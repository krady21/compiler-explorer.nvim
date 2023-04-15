local M = {}

M.defaults = {
  url = "https://godbolt.org",
  infer_lang = true, -- Try to infer possible language based on file extension.
  line_match = {
    highlight = false,
    jump = false,
  },
  open_qflist = false, --  Open qflist after compilation if there are diagnostics.
  split = "split", -- How to split the window after the second compile (split/vsplit).
  compiler_flags = "",
  job_timeout_ms = 25000, -- Timeout for libuv job in milliseconds.
  languages = { -- Language specific default compiler/flags
    --c = {
    --  compiler = "g121",
    --  compiler_flags = "-O2 -Wall",
    --},
  },
}

M._config = M.defaults

function M.setup(user_config)
  local conf = vim.tbl_deep_extend("force", M._config, user_config)

  vim.validate({
    url = { conf.url, "string" },
    infer_lang = { conf.infer_lang, "boolean" },
    ["line_match.highlight"] = { conf.line_match.highlight, "boolean" },
    ["line_match.jump"] = { conf.line_match.jump, "boolean" },
    open_qflist = { conf.open_qflist, "boolean" },
    split = {
      conf.split,
      function(s) return s == "split" or s == "vsplit" end,
      "split or vsplit",
    },
    compiler_flags = { conf.compiler_flags, "string" },
    job_timeout_ms = { conf.job_timeout_ms, "number" },
    languages = { conf.languages, "table" },
  })

  M._config = conf
end

function M.get_config() return M._config end

return M
