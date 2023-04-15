# compiler-explorer.nvim
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Compile your code and explore assembly from Neovim using the
[compiler-explorer](https://godbolt.org/) REST API. Supercharged by `vim.ui`,
`vim.notify` and `vim.diagnostic`.

[Features](#features) • [Dependencies](#dependencies) • [Install](#installation) • [Commands](#commands) • [Configuration](#configuration)

## Demo
![Preview](https://i.imgur.com/Dy7TnUd.gif)
This is what the interface looks like using the `vim.ui` provided
by [dressing.nvim](https://github.com/stevearc/dressing.nvim) with the
[fzf-lua](https://github.com/ibhagwan/fzf-lua) backend and the `vim.notify`
provided by [nvim-notify](https://github.com/rcarriga/nvim-notify).

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

## Dependencies
You can verify these dependencies by running `:checkhealth compiler-explorer`

- [Neovim](https://neovim.io/) >= 0.7
- [curl](https://curl.se/)

<details>
<summary>Recommended</summary>
<br>
<a href="https://github.com/stevearc/dressing.nvim">dressing.nvim</a> or another plugin that overrides <code>vim.ui</code>
</details>

<details>
<summary>Optional</summary>
<br>
<a href="https://github.com/rcarriga/nvim-notify">nvim-notify</a> or another plugin that overrides <code>vim.notify</code>
</details>

## Installation

[packer](https://github.com/wbthomason/packer.nvim)
```lua
require('packer').startup(function()
  use {'krady21/compiler-explorer.nvim'}
end
```

[paq](https://github.com/savq/paq-nvim)
```lua
require("paq") {
  {'krady21/compiler-explorer.nvim'};
}
```

[vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'krady21/compiler-explorer.nvim'
```

## Commands
The suggested way to use
[compiler-explorer.nvim](https://github.com/krady21/compiler-explorer.nvim) is
through the vim commands it provides. You can refer to `:h
compiler-explorer-commands` or the table below:

| Command | Description | Called from |
| --- | --- | --- |
| `:CECompile` | Compile the source code in the current buffer and dump assembly output to a new window. Also accepts a visual selection. | source code buffer |
| `:CECompileLive` | Same as `:CECompile`, but it will also try to recompile the source code every time the buffer is saved. | source code buffer |
| `:CEFormat` | Format the source code. | source code buffer |
| `:CEAddLibrary` | Add a library to be used by future calls of `:CECompile`. | source code buffer |
| `:CELoadExample` | Load an existing code example to a new tab. | any buffer |
| `:CEOpenWebsite` | Open the website using the source code and compilers from previous `:CECompile` calls. | any buffer |
| `:CEDeleteCache` | Clear the json cache where the compilers and languages are stored. | any buffer |
| `:CEShowTooltip` | Show information about a specific instruction under cursor. | assembly buffer |
| `:CEGotoLabel` | Jump to the label definition under cursor. | assembly buffer |

<details>
<summary>Examples</summary>

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

</details>



## Configuration
[compiler-explorer.nvim](https://github.com/krady21/compiler-explorer.nvim)
works out of the box without configuration. If you want to change some of its
options (like using a local instance of compiler-explorer), you can do so
through the `setup()` function.

<details>
<summary>Default options</summary>

```lua
require("compiler-explorer").setup({
  url = "https://godbolt.org",
  infer_lang = true, -- Try to infer possible language based on file extension.
  line_match = {
    highlight = false, -- highlight the matching line(s) in the other buffer.
    jump = false, -- move the cursor in the other buffer to the first matching line.
  },
  open_qflist = false, --  Open qflist after compilation if there are diagnostics.
  split = "split", -- How to split the window after the second compile (split/vsplit).
  compiler_flags = "", -- Default flags passed to the compiler.
  job_timeout_ms = 25000, -- Timeout for libuv job in milliseconds.
  languages = { -- Language specific default compiler/flags
    --c = {
    --  compiler = "g121",
    --  compiler_flags = "-O2 -Wall",
    --},
  },
})
```
</details>


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
