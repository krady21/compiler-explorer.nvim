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
    local list
    if vim.startswith(arg_lead, "compiler=") then
      local extension = "." .. vim.fn.expand("%:e")
      local compilers = require("compiler-explorer.cache").get_compilers(extension)
      list = vim.tbl_map(function(c)
        return [[compiler=]] .. c.id
      end, compilers)
    else
      local compile_body = require("compiler-explorer.rest").default_body
      list = vim.tbl_keys(compile_body.options.filters)
      vim.list_extend(list, { "compiler", "flags", "inferLang" })
    end

    return vim.tbl_filter(function(el)
      return string.sub(el, 1, #arg_lead) == arg_lead
    end, list)
  end,
})

command("CECompileLive", function(opts)
  require("compiler-explorer").compile_live(opts)
end, {
  range = "%",
  nargs = "*",
  complete = function(arg_lead, _, _)
    local list
    if vim.startswith(arg_lead, "compiler=") then
      local extension = "." .. vim.fn.expand("%:e")
      local compilers = require("compiler-explorer.cache").get_compilers(extension)
      list = vim.tbl_map(function(c)
        return [[compiler=]] .. c.id
      end, compilers)
    else
      local compile_body = require("compiler-explorer.rest").default_body
      list = vim.tbl_keys(compile_body.options.filters)
      vim.list_extend(list, { "compiler", "flags", "inferLang" })
    end

    return vim.tbl_filter(function(el)
      return string.sub(el, 1, #arg_lead) == arg_lead
    end, list)
  end,
})

command("CEFormat", require("compiler-explorer").format, {})
command("CEAddLibrary", require("compiler-explorer").add_library, {})
command("CELoadExample", require("compiler-explorer").load_example, {})
command("CEOpenWebsite", require("compiler-explorer").open_website, {})
command("CEDeleteCache", require("compiler-explorer.cache").delete, {})
