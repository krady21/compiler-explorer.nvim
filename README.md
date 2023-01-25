# compiler-explorer.nvim
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Compile your code and explore assembly from Neovim using the
[compiler-explorer](https://godbolt.org/) REST API. Supercharged by `vim.ui`,
`vim.notify` and `vim.diagnostic`.

[Install](#installation) • [Features](#features) • [Commands](#commands) • [Configuration](#configuration)

## Demo
![Preview](https://i.imgur.com/Dy7TnUd.gif)
This is what it looks like using the `vim.ui.select/input` provided by
dressing.nvim (fzf-lua) and the `vim.notify` provided by nvim-notify.

## Dependencies
### Required
- [Neovim](https://neovim.io/) >= 0.7
- [curl](https://curl.se/)

### Recommended
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) or another plugin that overrides `vim.ui`

### Optional
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
- Select compiler interactively using `vim.ui.select` or pass it as a vim
  command parameter.
- Compile visual selections.
- Send compiler warnings and errors to the quickfix list.
- Highlight matching lines between source code and assembly.
- Show binary output (opcodes and address) using virtual text.
- Format code.
- Add libraries.
- Show tooltips about specific instructions.
- Jump to label definitions.
- Load example code.
- Open the website with the local state (source code and compilers).

## Commands
`:h compiler-explorer-commands`

- CECompile
- CECompileLive
- CEFormat
- CEAddLibrary
- CELoadExample
- CEOpenWebsite
- CEDeleteCache
- CEShowTooltip (local to assembly buffer)
- CEGotoLabel (local to assembly buffer)

### Examples
- `:CECompile` will prompt the user to select the compiler and flags
  interactively using `vim.ui.select` and `vim.ui.input`.
- `:CECompile compiler=g121 flags=-O2 flags=-Wall` specify the
  compiler and flags as command arguments.
- `':<,'>CECompile` will compile a visual selection.
- `:CECompile!` will open the assembly output in a new window. Not adding
  bang (!) will reuse the last assembly window.
- `:CECompile inferLang=false` do not infer possible language (based on file
  extension). Will prompt user to select the language before selecting the
  compiler.
- `:CECompile binary=true` show binary opcodes and address using virtual text.
- `:CECompile intel=false` use AT&T syntax instead of intel.
- `:CECompileLive` creates an autcommand that runs `:CECompile` every time
  the buffer is saved (`BufWritePost`).


## Configuration
[compiler-explorer.nvim](https://github.com/krady21/compiler-explorer.nvim)
works out of the box without configuration. If you want to change some of its
options (like using a local instance of compiler-explorer), you can do so
through the `setup()` function. You can find all the options
[here](https://github.com/krady21/compiler-explorer.nvim/blob/master/lua/compiler-explorer/config.lua).

```lua
require("compiler-explorer").setup({
  url = "https://godbolt.org",
  infer_lang = true, -- Try to infer possible language based on file extension.
  binary_hl = "Comment", -- Highlight group for binary extmarks/virtual text.
  autocmd = {
    enable = false, -- Enable highlighting matching lines between source and assembly windows.
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
  job_timeout = 25000, -- Timeout for libuv job in milliseconds.
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

You can find the full API docs [here](https://github.com/compiler-explorer/compiler-explorer/blob/main/docs/API.md).

## Related projects
- [godbolt.nvim](https://github.com/p00f/godbolt.nvim)

## Inspiration
- The async.lua and alert.lua modules are inspired from [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) .
- The base64.lua module is taken from [lbase64](https://github.com/iskolbin/lbase64)
