<div align="center">

# nvim-laurel 🌿

[![badge/license](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)][path/to/license]
[![badge/test](https://img.shields.io/github/actions/workflow/status/aileot/nvim-laurel/test.yml?branch=main&label=Test&logo=github&style=flat-square)][workflow/test]
[![badge/semver](https://img.shields.io/github/release/aileot/nvim-laurel?display_name=tag&sort=semver&label=Release)][path/to/semver]\
_A set of macros for Neovim config_\
_inspired by the builtin Nvim Lua standard library and by good old Vim script_

![image/nvim-laurel-demo](https://user-images.githubusercontent.com/46470475/207041810-4d0afa5e-f9cc-4878-86f2-e607cff20601.png)

[![badge/fennel](https://img.shields.io/badge/Powered_by_Fennel-030281?logo=Lua&style=for-the-badge)][url/to/fennel]

[workflow/test]: https://github.com/aileot/nvim-laurel/actions/workflows/test.yml
[path/to/license]: ./LICENSE
[path/to/semver]: https://github.com/aileot/nvim-laurel/releases/latest
[url/to/fennel]: https://fennel-lang.org/

</div>

## Design

- **Fast:** Each macro is expanded to a few nvim API functions in principle.
- **Intuitive:** Most of the macros imitates the corresponding Vim script
  command or function in syntax: by and large, you can write as if functions
  replaced Ex commands, preceded by left parens `(`. In addition, each macro
  is also a replacement for the corresponding nvim API function, where
  meaningless arguments for end-users are omittable, e.g., `(augroup! :name)`
  replaces `(vim.api.nvim_create_augroup :name {})`.
- **Fzf-Friendly:** Options such as `desc`, `buffer`, `expr`, ..., can be set
  in sequential table instead of key-value table. In this format, options are
  likely to be `format`ted into the same line as nvim-laurel macro starts
  from.

## Requirements

- Neovim 0.8.0+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## Installation

### With a compiler plugin (recommended)

1. Add nvim-laurel to `'runtimepath'`, before registering it with your plugin
   manager, to use nvim-laurel macros as early as possible.

   <details>
   <summary>
   With lazy.nvim
   </summary>

   ```lua
   local function prerequisite(name, url)
     -- To manage the version of repo, the path should be where your plugin manager will download it.
     local name = url:gsub("^.*/", "")
     local path = vim.fn.stdpath("data") .. "/lazy/" .. name
     if not vim.loop.fs_stat(path) then
       vim.fn.system({
         "git",
         "clone",
         "--filter=blob:none",
         "--single-branch",
         url,
         path,
       })
     end
     vim.opt.runtimepath:prepend(path)
   end

   -- Install your favorite plugin manager.
   prerequisite("https://github.com/folke/lazy.nvim")

   -- Install nvim-laurel
   prerequisite("https://github.com/aileot/nvim-laurel")

   -- Install a runtime compiler
   prerequisite("https://github.com/rktjmp/hotpot.nvim")

   require("hotpot").setup({
     compiler = {
       macros = {
         env = "_COMPILER",
         allowedGlobals = false,
       },
     },
   })

   -- Then, you can write config in Fennel with nvim-laurel.
   require("your.core")
   ```

   </details>

   <details>
   <summary>
   With dein.vim
   </summary>

   ```lua
   local function prerequisite(url)
     -- To manage the version of repo, the path should be where your plugin manager will download it.
     local path = "~/.cache/dein/repos/" .. url:gsub("^.*://", "")
     if not vim.loop.fs_stat(path) then
       vim.fn.system({
         "git",
         "clone",
         "--filter=blob:none",
         "--single-branch",
         url,
         path,
       })
     end
     vim.opt.runtimepath:prepend(path)
   end

   -- Install your favorite plugin manager.
   prerequisite("https://github.com/Shougo/dein.vim")

   -- Install nvim-laurel
   prerequisite("https://github.com/aileot/nvim-laurel")

   -- Install a runtime compiler
   prerequisite("https://github.com/rktjmp/hotpot.nvim")

   require("hotpot").setup({
     compiler = {
       macros = {
         env = "_COMPILER",
         allowedGlobals = false,
       },
     },
   })

   -- Then, you can write config in Fennel with nvim-laurel.
   require("your.core")
   ```

   </details>

2. Manage the version of nvim-laurel by your favorite plugin manager. It's
   recommended to specify a version range to avoid unexpected breaking
   changes.

   With [lazy.nvim](https://github.com/folke/lazy.nvim)

   ```fennel
   (local lazy (require :lazy))
   (lazy.setup [{1 :aileot/nvim-laurel
                 ;; v0.6.0 <= {version} < v0.7.0
                 :version "~v0.6.0"}
                ...]
               {:defaults {:lazy true}})
   ```

   With [dein.vim](https://github.com/Shougo/dein.vim) in toml

   ```toml
   [[plugins]]
   repo = "aileot/nvim-laurel"
   rev = "v0.6.*"
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

3. Add `/path/to/nvim-laurel` to `'runtimepath'` in your Neovim config file.

   ```lua
   vim.opt.rtp:append("/path/to/nvim-laurel")
   ```

## Usage

```fennel
(import-macros {: set! : map! : augroup! : au! ...} :nvim-laurel.macros)
```

See [laurel.md](./doc/laurel.md) for each macro usage in details.

### Macro List

- [Autocmd](./doc/laurel.md#Autocmd)

  - [`augroup!`](./doc/laurel.md#augroup)
  - [`autocmd!`](./doc/laurel.md#autocmd)
  - [`au!`](./doc/laurel.md#au)

- [Keymap](./doc/laurel.md#Keymap)

  - [`map!`](./doc/laurel.md#map): A replacement of `vim.keymap.set`
  - [`unmap!`](./doc/laurel.md#unmap): A replacement of `vim.keymap.del`
  - [`<Cmd>`](./doc/laurel.md#Cmd)
  - [`<C-u>`](./doc/laurel.md#C-u)

- [Variable](./doc/laurel.md#Variable)

  - [`g!`](./doc/laurel.md#g)
  - [`b!`](./doc/laurel.md#b)
  - [`w!`](./doc/laurel.md#w)
  - [`t!`](./doc/laurel.md#t)
  - [`v!`](./doc/laurel.md#v)
  - [`env!`](./doc/laurel.md#env)

- [Option](./doc/laurel.md#Option)

| Set (`!`)                 | Append (`+`)              | Prepend (`^`)             | Remove (`-`)              |
| :------------------------ | :------------------------ | :------------------------ | :------------------------ |
| [`set!`][set]             | [`set+`][set]             | [`set^`][set]             | [`set-`][set]             |
| [`setglobal!`][setglobal] | [`setglobal+`][setglobal] | [`setglobal^`][setglobal] | [`setglobal-`][setglobal] |
| [`setlocal!`][setlocal]   | [`setlocal+`][setlocal]   | [`setlocal^`][setlocal]   | [`setlocal-`][setlocal]   |
| [`go!`][go]               | [`go+`][go]               | [`go^`][go]               | [`go-`][go]               |
| [`bo!`][bo]               | --                        | --                        | --                        |
| [`wo!`][wo]               | --                        | --                        | --                        |

- [Others](./doc/laurel.md#Others)
  - [`command!`](./doc/laurel.md#command)
  - [`feedkeys!`](./doc/laurel.md#feedkeys)
  - [`highlight!`](./doc/laurel.md#highlight)
  - [`hi!`](./doc/laurel.md#hi)

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [nyoom.nvim](https://github.com/shaunsingh/nyoom.nvim)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
[set]: ./doc/laurel.md#setsetsetset-
[setglobal]: ./doc/laurel.md#setglobalsetglobalsetglobalsetglobal-
[setlocal]: ./doc/laurel.md#setlocalsetlocalsetlocalsetlocal-
[go]: ./doc/laurel.md#gogogogo-
[wo]: ./doc/laurel.md#wo
[bo]: ./doc/laurel.md#bo
