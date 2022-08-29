# compiler-explorer.nvim

Neovim lua plugin used for interacting with
[compiler-explorer](https://godbolt.org/) and supercharged by `vim.ui.select`,
`vim.ui.input`, `vim.notify` and `vim.diagnostic`.

## Requirements
- [Neovim](https://neovim.io/) >= 0.6
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/) for the curl module
- [curl](https://curl.se/)

## Installation

<details>
<summary>packer</summary>

```lua
require('packer').startup(function()
  use {
    'krady21/compiler-explorer.nvim', requires = { 'nvim-lua/plenary.nvim' }
  }
end
```
</details>

<details>
<summary>paq</summary>

```lua
require("paq") {
  {'krady21/compiler-explorer.nvim'};
  {'nvim-lua/plenary.nvim'};
}
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug 'krady21/compiler-explorer.nvim'
Plug 'nvim-lua/plenary.nvim'
```

</details>

## Commands
- CECompile
- CEFormat
- CETooltip

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

