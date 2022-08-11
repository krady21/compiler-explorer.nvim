if !has('nvim-0.5')
  echohl Error
  echoerr "compiler-explorer.nvim requires at least nvim-0.5"
  echohl clear
  finish
endif

lua << EOF
-- :Compile <compiler-id> args=
vim.api.nvim_create_user_command("CEListLangs", function() 
  require("compiler-explorer").languages() 
end, { nargs = 0 })
vim.api.nvim_create_user_command("CEListCompilers", function(opts) 
  local lang = opts.args
  require("compiler-explorer").compilers(lang) 
end, { nargs = "?" })
vim.api.nvim_create_user_command("CECompile", function(opts) 
  require("compiler-explorer").compile()
end, { nargs = "?" })
EOF

if exists('g:loaded_compiler_explorer')
  finish
endif
let g:loaded_compiler_explorer = 1
