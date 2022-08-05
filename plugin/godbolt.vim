if !has('nvim-0.5')
  echohl Error
  echoerr "godbolt.nvim requires at least nvim-0.5"
  echohl clear
  finish
endif

lua << EOF
-- :Compile <compiler-id> args=
vim.api.nvim_create_user_command("CEListLangs", function() 
  require("godbolt").languages() 
end, { nargs = 0 })
vim.api.nvim_create_user_command("CEListCompilers", function(opts) 
  local lang = opts.args
  require("godbolt").compilers(lang) 
end, { nargs = "?" })
vim.api.nvim_create_user_command("CECompile", function(opts) 
  local compiler = opts.args
  require("godbolt").compile(compiler)
end, { nargs = "?" })
EOF

if exists('g:loaded_godbolt')
  finish
endif
let g:loaded_godbolt = 1
