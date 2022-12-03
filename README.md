<div align="center">

# nvim-laurel 🌿

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![test](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml/badge.svg)](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml)

> A set of macros to write readable Neovim config, highly inspired by the Lua
> modules built in Neovim and by good old Vim script

![nvim-laurel-demo](https://user-images.githubusercontent.com/46470475/207041810-4d0afa5e-f9cc-4878-86f2-e607cff20601.png)

</div>

## Design

- **Fast:** Each macro is expanded to a few nvim API functions in principle. A
  typical exception: the optimal results with fewer overheads, but messy, would
  step aside at runtime in favor of small wrappers with a few overheads, but
  concise.
- **Intuitive:** Most of the macros imitates the corresponding Vim script
  command or function in syntax: by and large, you can write as if functions
  replaced Ex commands, preceded by left parens `(`. In addition, each macro is
  also a replacement for the corresponding nvim API function, where meaningless
  arguments for end-users are omittable, e.g., `(augroup! :name)` replaces
  `(vim.api.nvim_create_augroup :name {})`.
- **Clean:** nvim-laurel provides no macros unrelated to Neovim stuff: such
  general macros or functions as `nil?`, `if-not`, `++`, ..., won't be exposed.

## Requirements

- Neovim 0.8.0+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## Installation

### With a compiler plugin (recommended)

Install nvim-laurel by your favorite plugin manager.

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use "aileot/nvim-laurel"
```

[dein.vim](https://github.com/Shougo/dein.vim) in toml:

```toml
[[plugin]]
repo = "aileot/nvim-laurel"
```

### To compile outside Neovim

1. Download nvim-laurel where you feel like

   ```sh
   git clone https://github.com/aileot/nvim-laurel /path/to/install
   ```

2. Compile your fennel files with macro path and package path for nvim-laurel.
   For example, in your Makefile,

   ```make
   %.lua: %.fnl
     fennel \
       --add-macro-path "/path/to/nvim-laurel/fnl/?.fnl;/path/to/nvim-laurel/fnl/?/init.fnl" \
       --add-package-path "/path/to/nvim-laurel/lua/?.lua;/path/to/nvim-laurel/lua/?/init.lua" \
       --compile $< > $@
   ```

3. Add `/path/to/nvim-laurel` to `&runtimepath` in your Neovim config file.

   ```lua
   vim.go.rtp:append("/path/to/nvim-laurel")
   ```

## Usage

```fennel
(import-macros {: set! : map! : augroup! : au! ...} :nvim-laurel.macros)
```

See [MACROS.md](./doc/MACROS.md) for each macro usage in details.

### Macro List

- [Autocmd](./doc/MACROS.md#Autocmd)
  - [`augroup!`](./doc/MACROS.md#augroup)
  - [`augroup+`](./doc/MACROS.md#augroup-1)
  - [`autocmd!`](./doc/MACROS.md#autocmd)
  - [`au!`](./doc/MACROS.md#au)

- [Keymap](./doc/MACROS.md#Keymap)
  - [`map!`](./doc/MACROS.md#map): A replacement of `vim.keymap.set`
  - [`unmap!`](./doc/MACROS.md#unmap): A replacement of `vim.keymap.del`
  - [`<Cmd>`](./doc/MACROS.md#Cmd)
  - [`<C-u>`](./doc/MACROS.md#C-u)

- [Variable](./doc/MACROS.md#Variable)
  - [`g!`](./doc/MACROS.md#g)
  - [`b!`](./doc/MACROS.md#b)
  - [`w!`](./doc/MACROS.md#w)
  - [`t!`](./doc/MACROS.md#t)
  - [`v!`](./doc/MACROS.md#v)
  - [`env!`](./doc/MACROS.md#env)

- [Option](./doc/MACROS.md#Option)

| Set (`!`)                 | Append (`+`)              | Prepend (`^`)             | Remove (`-`)              |
| :------------------------ | :------------------------ | :------------------------ | :------------------------ |
| [`set!`][set]             | [`set+`][set]             | [`set^`][set]             | [`set-`][set]             |
| [`setglobal!`][setglobal] | [`setglobal+`][setglobal] | [`setglobal^`][setglobal] | [`setglobal-`][setglobal] |
| [`setlocal!`][setlocal]   | [`setlocal+`][setlocal]   | [`setlocal^`][setlocal]   | [`setlocal-`][setlocal]   |
| [`go!`][go]               | [`go+`][go]               | [`go^`][go]               | [`go-`][go]               |
| [`bo!`][bo]               | --                        | --                        | --                        |
| [`wo!`][wo]               | --                        | --                        | --                        |

- [Others](./doc/MACROS.md#Others)
  - [`command!`](./doc/MACROS.md#command)
  - [`feedkeys!`](./doc/MACROS.md#feedkeys)
  - [`highlight!`](./doc/MACROS.md#highlight)
  - [`hi!`](./doc/MACROS.md#hi)

## Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [nyoom.nvim](https://github.com/shaunsingh/nyoom.nvim)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[set]: ./doc/MACROS.md#setsetsetset-
[setglobal]: ./doc/MACROS.md#setglobalsetglobalsetglobalsetglobal-
[setlocal]: ./doc/MACROS.md#setlocalsetlocalsetlocalsetlocal-
[go]: ./doc/MACROS.md#gogogogo-
[wo]: ./doc/MACROS.md#wo
[bo]: ./doc/MACROS.md#bo
