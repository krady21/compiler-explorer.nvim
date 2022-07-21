# godbolt.nvim
Neovim lua plugin for interacting with [compiler-explorer](https://godbolt.org/)

## TODO
### Api Coverage:
- [x] GET /api/languages
- [x] GET /api/compilers/<lang-id>
- [x] GET /api/libraries/<lang-id>
- [ ] GET /api/shortlinkinfo/<link-id>
- [x] POST /api/compiler/<compiler-id>/compile
- [ ] GET /api/formats
- [ ] POST /api/format/<formatter>

### Various features
- [x] Infer language based on file extension.
- [ ] Allow compiling parts of a file through visual selection
- [ ] Allow using a local instance of compiler-explorer
- [ ] Lines and cursor position tracking between source code and assembly
- [ ] Autocmd that compiles on save/buffer change
- [ ] Multi file output (useful for comparing two compilers or optimization flags)

### Commands
- Compile
- CompileWithSettings
- CESettings


