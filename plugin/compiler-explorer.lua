local command = vim.api.nvim_create_user_command

if vim.fn.has("nvim-0.7") ~= 1 then
  vim.api.nvim_err_writeln("compiler-explorer.nvim requires at least nvim-0.7")
end

if vim.g.loaded_compiler_explorer == 1 then
  return
end
vim.g.loaded_compiler_explorer = 1

command("CECompile", function(opts)
  require("compiler-explorer").compile(opts)
end, {
  range = "%",
  bang = true,
  nargs = "*",
  complete = function(arg_lead, _, _)
    return require("compiler-explorer.complete").complete_fn(arg_lead)
  end,
})

command("CECompileLive", function(opts)
  require("compiler-explorer").compile_live(opts)
end, {
  range = "%",
  nargs = "*",
  complete = function(arg_lead, _, _)
    return require("compiler-explorer.complete").complete_fn(arg_lead)
  end,
})

command("CEFormat", require("compiler-explorer").format, {})
command("CEAddLibrary", require("compiler-explorer").add_library, {})
command("CELoadExample", require("compiler-explorer").load_example, {})
command("CEOpenWebsite", require("compiler-explorer").open_website, {})
command("CEDeleteCache", require("compiler-explorer.cache").delete, {})
