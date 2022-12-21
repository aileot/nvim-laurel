<div align="center">

# nvim-laurel 🌿

[![badge/license]][path/to/license]
[![badge/test]][workflow/test]  
_A set of macros for Neovim config_\
_highly inspired by the builtin Nvim Lua standard library and by good old Vim
script_

![image/nvim-laurel-demo]

[![badge/fennel]][url/to/fennel]

[badge/fennel]: https://img.shields.io/badge/Powered_by_Fennel-030281?logo=Lua&style=for-the-badge
[badge/test]: https://img.shields.io/github/actions/workflow/status/aileot/nvim-laurel/test.yml?branch=main&label=Test&logo=github&style=flat-square
[badge/license]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square
[workflow/test]: https://github.com/aileot/nvim-laurel/actions/workflows/test.yml
[path/to/license]: ./LICENSE
[url/to/fennel]: https://fennel-lang.org/
[image/nvim-laurel-demo]: https://user-images.githubusercontent.com/46470475/207041810-4d0afa5e-f9cc-4878-86f2-e607cff20601.png

</div>

## Design

- **Fast:** Each macro is expanded to a few nvim API functions in principle.
- **Intuitive:** Most of the macros imitates the corresponding Vim script
  command or function in syntax: by and large, you can write as if functions
  replaced Ex commands, preceded by left parens `(`. In addition, each macro is
  also a replacement for the corresponding nvim API function, where meaningless
  arguments for end-users are omittable, e.g., `(augroup! :name)` replaces
  `(vim.api.nvim_create_augroup :name {})`.
- **Fzf-Friendly:** Options such as `desc`, `buffer`, `expr`, ..., can be set in
  sequential table instead of key-value table. In this format, options are
  likely to be `format`ted into the same line as nvim-laurel macro starts from.

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
         "--depth=1",
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
   With packer.nvim
   </summary>

   ```lua
   local function prerequisite(name, url)
     -- To manage the version of repo, the path should be where your plugin manager will download it.
     local name = url:gsub("^.*/", "")
     local dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. name
     if not vim.loop.fs_stat(path) then
       vim.fn.system({
         "git",
         "clone",
         "--filter=blob:none",
         "--depth=1",
         url,
         path,
       })
     end
   end

   -- Install your favorite plugin manager.
   prerequisite("https://github.com/wbthomason/packer.nvim")

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
         "--depth=1",
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

2. Manage the version of nvim-laurel by your favorite plugin manager.

   With [lazy.nvim](https://github.com/folke/lazy.nvim)

   ```fennel
   (local lazy (require :lazy))
   (lazy.setup [:aileot/nvim-laurel
                ...]
               {:defaults {:lazy true}})
   ```

   With [packer.nvim](https://github.com/wbthomason/packer.nvim)

   ```fennel
   (local packer (require :packer))
   (packer.startup (fn [use]
                     (use :aileot/nvim-laurel)
                     ...))
   ```

   With [dein.vim](https://github.com/Shougo/dein.vim) in toml

   ```toml
   [[plugins]]
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

3. Add `/path/to/nvim-laurel` to `'runtimepath'` in your Neovim config file.

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
