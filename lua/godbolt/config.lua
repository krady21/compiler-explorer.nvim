local M = {}

M.defaults = {
    lang_detect = true,
}

M.config = M.defaults

function M.setup(opts)
    opts = opts or {} 
    M.config = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
