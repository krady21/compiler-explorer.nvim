if !has('nvim-0.5')
  echohl Error
  echoerr "godbolt.nvim requires at least nvim-0.5"
  echohl clear
  finish
endif

if exists('g:loaded_godbolt')
  finish
endif
let g:loaded_godbolt = 1
