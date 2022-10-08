# nvim-laurel 🌿

nvim-laurel provides a syntax sugar macro collection to write neovim config in
[Fennel][Fennel], developped with [parinfer-rust][parinfer-rust],
[fnlfmt][fnlfmt] and [fennel-language-server][fennel-language-server], and
tested with [vusted][vusted].

## Requirements

- Neovim 0.8.0+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## Installation

Unless you compiles fennel files before loading `init.lua`, the installation
should run without any plugin manager which usually doesn't care plugin
installation order. Add such scripts to install nvim-laurel to your `init.lua`.

```lua
local url = "https://github.com/aileot/nvim-laurel"
local name = url:match("[^/]+$")
local pack = foo
local path = vim.fn.stdpath("data") .. "/site/pack/" .. pack .. "/start/" .. name
if vim.fn.isdirectory(path) == 0 then
  vim.notify("Installing " .. name .. " to " .. path .. "...")
  vim.fn.system({"git", "clone", "--depth", "1", url, path})
  vim.cmd.redraw()
  vim.notify("Finished installing " .. name)
end
```

But you can manage version of nvim-laurel by your favorite package manager:

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use "aileot/nvim-laurel"
```

[dein.vim](https://github.com/Shougo/dein.vim) in toml:

```toml
[[plugin]]
repo = "aileot/nvim-laurel"
path = "/path/to/install"
```

## Usage

```fennel
(import-macros {: nnoremap! : augroup! :au! ...} :nvim-laurel.macros)
```

### Examples

[Fennel]: https://github.com/bakpakin/Fennel
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[fnlfmt]: https://git.sr.ht/~technomancy/fnlfmt
[fennel-language-server]: https://github.com/rydesun/fennel-language-server
[vusted]: https://github.com/notomo/vusted
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
