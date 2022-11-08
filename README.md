# nvim-laurel 🌿

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![test](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml/badge.svg)](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml)

nvim-laurel provides syntax sugar macros for Neovim. The macros are developed
with [fennel-language-server][fennel-language-server], and tested with
[vusted][vusted].

![nvim-laurel-demo](https://user-images.githubusercontent.com/46470475/200104542-629da3b9-41de-435c-b665-b609199a5fd4.png)

## Motivation

Neovim configuration powered by Fennel has the following advantages at least:

- **Speed**: Fennel is as fast as Lua since Fennel codes are compiled to Lua, or
  faster with effective macros.
- **Syntax:** Fennel lets us compose in a more comfortable style with our great
  legacies written in Vim script, i.e., we prefer `(vim.fn.foo#bar)` to
  `vim.fn["foo#bar"]()`, right?
- **Maintainability:** Fennel keeps our codes compact; everything is an
  expression and returns value, and it is worth mentioning that we don't have to
  write `function() return true end` but `#true`. That will enhance the
  maintainability of our config files.

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
(import-macros {: setglobal! : augroup! : au! ...} :nvim-laurel.macros)
```

See [doc/MACROS.md](./doc/MACROS.md) for each macro usage in details.
[Discussions][Discussions] would inspire you, too.

## Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [nyoom.nvim](https://github.com/shaunsingh/nyoom.nvim)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[fennel-language-server]: https://github.com/rydesun/fennel-language-server
[vusted]: https://github.com/notomo/vusted
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[Discussions]: https://github.com/aileot/nvim-laurel/discussions/
