local command = vim.api.nvim_create_user_command

if vim.fn.has("nvim-0.7") ~= 1 then
  vim.api.nvim_err_writeln("compiler-explorer.nvim requires at least nvim-0.7")
end

if vim.g.loaded_compiler_explorer == 1 then
  return
end
vim.g.loaded_compiler_explorer = 1

command("CECompile", function(opts)
  require("compiler-explorer").compile(opts, false)
end, {
  range = "%",
  bang = true,
  nargs = "*",
  complete = function(arg_lead, _, _)
    return require("compiler-explorer.cache").complete_fn(arg_lead)
  end,
})

command("CECompileLive", function(opts)
  require("compiler-explorer").compile(opts, true)
end, {
  range = "%",
  nargs = "*",
  complete = function(arg_lead, _, _)
    return require("compiler-explorer.cache").complete_fn(arg_lead)
  end,
})

command("CEFormat", function()
  require("compiler-explorer").format()
end, {})

command("CEAddLibrary", function()
  require("compiler-explorer").add_library()
end, {})

command("CELoadExample", function()
  require("compiler-explorer").load_example()
end, {})

command("CEOpenWebsite", function()
  require("compiler-explorer").open_website()
end, {})

command("CEDeleteCache", function()
  require("compiler-explorer.cache").delete()
end, {})
