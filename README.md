# compiler-explorer.nvim

Neovim lua plugin used for interacting with
[compiler-explorer](https://godbolt.org/) and supercharged by `vim.ui`,
`vim.notify` and `vim.diagnostic`.

## Demo 
![Preview](https://i.imgur.com/Dy7TnUd.gif)

## Dependencies
- [Neovim](https://neovim.io/) >= 0.7
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/) for the curl module
- [curl](https://curl.se/)

## Optional dependencies
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) or another plugin that overrides `vim.ui`
- [nvim-notify](https://github.com/rcarriga/nvim-notify) or another plugin that overrides `vim.notify`

## Installation

- [packer](https://github.com/wbthomason/packer.nvim)
```lua
require('packer').startup(function()
  use {
    'krady21/compiler-explorer.nvim', requires = { 'nvim-lua/plenary.nvim' }
  }
end
```

- [paq](https://github.com/savq/paq-nvim)
```lua
require("paq") {
  {'krady21/compiler-explorer.nvim'};
  {'nvim-lua/plenary.nvim'};
}
```

- [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'krady21/compiler-explorer.nvim'
Plug 'nvim-lua/plenary.nvim'
```

## Configuration
[compiler-explorer.nvim](https://github.com/krady21/compiler-explorer.nvim)
works out of the box without configuration. If you want to change some of its
options (like using a local instance of compiler-explorer), you can do so
through the `setup()` function. You can find all the options
[here](https://github.com/krady21/compiler-explorer.nvim/blob/7f03a00ab31d1f7de684679cf42d11e035c5f21e/lua/compiler-explorer/config.lua#L3).
```lua
require("compiler-explorer").setup({
  url = "http://localhost:10240",
  open_qflist = true,
  autocmd = {
    enable = true,
    hl = "Search",
  }
})
```

## Commands
- CECompile
- CEFormat
- CEAddLibrary
- CEShowTooltip

## API Coverage:
- [x] `GET  /api/languages`
- [x] `GET  /api/compilers/<lang-id>`
- [x] `GET  /api/libraries/<lang-id>`
- [ ] `GET  /api/shortlinkinfo/<link-id>`
- [x] `POST /api/compiler/<compiler-id>/compile`
- [x] `GET  /api/formats`
- [x] `POST /api/format/<formatter>`
- [x] `GET  /api/asm/<instruction-set>/<instruction>`
- [ ] `GET  /source/builtin/list`
- [ ] `GET  /source/builtin/load/<lang-id>/<example-id>`

## Related projects
- [godbolt.nvim](https://github.com/p00f/godbolt.nvim)

## Inspiration
The async.lua and alert.lua modules are either inspired or taken directly from
[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) .
