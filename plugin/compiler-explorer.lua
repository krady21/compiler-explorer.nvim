local command = vim.api.nvim_create_user_command

if vim.fn.has("nvim-0.7") ~= 1 then
  vim.api.nvim_err_writeln("compiler-explorer.nvim requires at least nvim-0.7")
end

if vim.g.loaded_compiler_explorer == 1 then
  return
end
vim.g.loaded_compiler_explorer = 1

command("CECompile", function(opts)
  -- require("compiler-explorer").compile(opts.line1, opts.line2, opts.bang == true)
  require("compiler-explorer").compile(opts)
end, {
  range = "%",
  bang = true,
  nargs = "*",
  complete = function(arg_lead, cmd_line, _)
    local list = vim.tbl_keys(require("compiler-explorer.rest").default_body.options.filters)
    vim.list_extend(list, { "compiler", "flags" })
    return vim.tbl_filter(function(el)
      return string.sub(el, 1, #arg_lead) == arg_lead
    end, list)
  end,
})

command("CEFormat", function(_)
  require("compiler-explorer").format()
end, {})

command("CEAddLibrary", function(_)
  require("compiler-explorer").add_library()
end, {})
