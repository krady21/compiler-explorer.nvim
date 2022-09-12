local command = vim.api.nvim_create_user_command

if vim.fn.has("nvim-0.7") ~= 1 then
  vim.api.nvim_err_writeln("compiler-explorer.nvim requires at least nvim-0.7")
end

if vim.g.loaded_compiler_explorer == 1 then
  return
end
vim.g.loaded_compiler_explorer = 1

command("CECompile", function(opts)
  require("compiler-explorer").compile(opts.line1, opts.line2, opts.bang == true)
end, { range = "%", bang = true })

command("CEFormat", function(_)
  require("compiler-explorer").format()
end, {})

command("CEAddLibrary", function(_)
  require("compiler-explorer").add_library()
end, {})
