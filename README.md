# compiler-explorer.nvim

Neovim lua plugin used for interacting with
[compiler-explorer](https://godbolt.org/) and supercharged by `vim.ui`,
`vim.notify` and `vim.diagnostic`.

## Demo 
![Preview](https://i.imgur.com/Dy7TnUd.gif)

## Dependencies
- [Neovim](https://neovim.io/) >= 0.7
- [curl](https://curl.se/)

## Optional dependencies
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) or another plugin that overrides `vim.ui`
- [nvim-notify](https://github.com/rcarriga/nvim-notify) or another plugin that overrides `vim.notify`

## Installation

- [packer](https://github.com/wbthomason/packer.nvim)
```lua
require('packer').startup(function()
  use {'krady21/compiler-explorer.nvim'}
end
```

- [paq](https://github.com/savq/paq-nvim)
```lua
require("paq") {
  {'krady21/compiler-explorer.nvim'};
}
```

- [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'krady21/compiler-explorer.nvim'
```

## Features
- Compile code asynchronously using `vim.loop`.
- Select compiler interactively(`vim.ui.select`) or pass it as the command parameter.
- Compile visual selections.
- Highlight matching lines between source code and assembly.
- Show binary output(opcodes and address) using virtual text.
- Format code.
- Add libraries.
- Show tooltips about specific instructions.
- Jump to label definitions.
- Load example code.
- Open the website with the local state (source code and compilers).

## Commands
- CECompile
- CECompileLive
- CEFormat
- CEAddLibrary
- CELoadExample
- CEOpenWebsite
- CEDeleteCache
- CEShowTooltip (local to assembly buffer)
- CEGotoLabel (local to assembly buffer)

## Configuration
[compiler-explorer.nvim](https://github.com/krady21/compiler-explorer.nvim)
works out of the box without configuration. If you want to change some of its
options (like using a local instance of compiler-explorer), you can do so
through the `setup()` function. You can find all the options
[here](https://github.com/krady21/compiler-explorer.nvim/blob/master/lua/compiler-explorer/config.lua).

```lua
require("compiler-explorer").setup({
  url = "https://godbolt.org",
  open_qflist = false, -- Open qflist after compile.
  infer_lang = true, -- Try to infer possible language based on file extension.
  binary_hl = "Comment", -- Highlight group for binary extmarks/virtual text.
  autocmd = {
    enable = false, -- Enable assembly to source and source to assembly highlighting.
    hl = "Cursorline", -- Highlight group used for line match highlighting.
  },
  diagnostics = { -- vim.diagnostic.config() options for the ce-diagnostics namespace.
    underline = false,
    virtual_text = false,
    signs = false,
  },
  split = "split", -- How to split the window after the second compile (split/vsplit).
  spinner_frames = { "⣼", "⣹", "⢻", "⠿", "⡟", "⣏", "⣧", "⣶" }, -- Compiling... spinner settings.
  spinner_interval = 100,
  compiler_flags = "", -- Default flags passed to the compiler.
})
```

## API Coverage:
- [x] `GET  /api/languages`
- [x] `GET  /api/compilers/<lang-id>`
- [x] `GET  /api/libraries/<lang-id>`
- [ ] `GET  /api/shortlinkinfo/<link-id>`
- [x] `POST /api/compiler/<compiler-id>/compile`
- [x] `GET  /api/formats`
- [x] `POST /api/format/<formatter>`
- [x] `GET  /api/asm/<instruction-set>/<instruction>`
- [x] `GET  /source/builtin/list`
- [x] `GET  /source/builtin/load/<lang-id>/<example-id>`
- [x] `GET  /clientstate/<base64>`

## Related projects
- [godbolt.nvim](https://github.com/p00f/godbolt.nvim)

## Inspiration
- The async.lua and alert.lua modules are inspired from [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) .
- The base64.lua module is taken from [lbase64](https://github.com/iskolbin/lbase64)
