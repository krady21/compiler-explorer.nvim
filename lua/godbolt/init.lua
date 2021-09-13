local config = require("config")

local M = {}

function M.setup(opts)
    config.setup(opts or {})
end

return M


