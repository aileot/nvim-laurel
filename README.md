<div align="center">

# nvim-laurel 🌿

[![badge/license](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)][path/to/license]
[![badge/test](https://img.shields.io/github/actions/workflow/status/aileot/nvim-laurel/test.yml?branch=main&label=Test&logo=github&style=flat-square)][workflow/test]
[![badge/semver](https://img.shields.io/github/release/aileot/nvim-laurel?display_name=tag&sort=semver&label=Release)][path/to/semver]\
_A set of macros for Neovim config_\
_inspired by the builtin Nvim Lua-Vimscript bridge on metatable and by good old Vim script_

![image/nvim-laurel-demo](https://user-images.githubusercontent.com/46470475/207041810-4d0afa5e-f9cc-4878-86f2-e607cff20601.png)

[![badge/fennel](https://img.shields.io/badge/Powered_by_Fennel-030281?logo=Lua&style=for-the-badge)][url/to/fennel]

[workflow/test]: https://github.com/aileot/nvim-laurel/actions/workflows/test.yml
[path/to/license]: ./LICENSE
[path/to/semver]: https://github.com/aileot/nvim-laurel/releases/latest
[url/to/fennel]: https://fennel-lang.org/

</div>

> [!WARNING]
> Some breaking changes are planned until v1.0.0.  
> [COOKBOOK.md](./COOKBOOK.md) contains how to update them as painlessly as
> possible; see [REFERENCE.md](./REFERENCE.md) for usage of
> `g:laurel_deprecated`, which would also help you update them as long as they
> are deprecated, but not abolished yet.

## Documentations

- The [Reference](./REFERENCE.md) lists out the nvim-laurel interfaces.
  Note that the interfaces are not limited to Fennel macros.
- The [Cookbook](./COOKBOOK.md) demonstrates practical codes on the
  nvim-laurel interfaces.
- The [Appendix](./APPENDIX.md) shows extra knowledge not limited to
  nvim-laurel, but useful to write nvim config files in Fennel:
  LSP, Treesitter, etc. Happy Coding!
- The [Changelog](./CHANGELOG.md).
  _See also the [Cookbook](./COOKBOOK.md)_
  for tips how to update features and usages deprecated or removed in
  nvim-laurel.

## Design

- **Fast:** Each macro is expanded to a few nvim API functions in principle.
- **Less:** The syntax is as little, but flexible and extensible as possible.
- **Fzf-Friendly:** Options such as `desc`, `buffer`, `expr`, ..., can be set
  in sequential table instead of key-value table. In this format, options are
  likely to be `format`ted into the same line where nvim-laurel macro starts
  from.

## Requirements

- Neovim 0.9.5+
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
         -- Comment out below to use `os`, `vim`, etc. at compile time,
         -- but UNRECOMMENDED with nvim-laurel.
         -- compilerEnv = _G,
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

   With [lazy.nvim](https://github.com/folke/lazy.nvim),

   ```lua
   require("lazy.nvim").setup({
     {
       "aileot/nvim-laurel", {
       -- v0.6.0 <= {version} < v0.7.0
       version = "~v0.6.0",
     },
     ... -- and other plugins
   }, {
       defaults = {
         lazy = true,
       },
       performance = {
         rtp = {
           -- Note: Not to remove nvim-laurel from &rtp, and not to encounter any
           -- other potential issues, it's UNRECOMMENDED to reset &rtp unless you
           -- don't mind the extra cost to maintain the "paths" properly.
           reset = false,
         }
       }
     })
   ```

   or, if you are confident in writing plugin specs in Fennel,

   ```fennel
   (local lazy (require :lazy))
   (lazy.setup [{1 :aileot/nvim-laurel
                 ;; v0.6.0 <= {version} < v0.7.0
                 :version "~v0.6.0"
                ...] ;; and other plugins
               {:defaults {:lazy true
                           ;; Note: Not to remove nvim-laurel from &rtp, and not to encounter any
                           ;; other potential issues, it's UNRECOMMENDED to reset &rtp unless you
                           ;; don't mind the extra cost to maintain the "paths" properly.
                           :performance {:rtp {:reset false}}}})
   ```

   With [dein.vim](https://github.com/Shougo/dein.vim) in toml,

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

See [REFERENCE.md](./doc/REFERENCE.md) for each macro usage in details.

### Macro List

- [Autocmd](./doc/REFERENCE.md#Autocmd)

  - [`augroup!`](./doc/REFERENCE.md#augroup)
  - [`autocmd!`](./doc/REFERENCE.md#autocmd)
  - [`au!`](./doc/REFERENCE.md#au)

- [Keymap](./doc/REFERENCE.md#Keymap)

  - [`map!`](./doc/REFERENCE.md#map): A replacement of `vim.keymap.set`
  - [`unmap!`](./doc/REFERENCE.md#unmap): A replacement of `vim.keymap.del`
  - [`<Cmd>`](./doc/REFERENCE.md#Cmd)
  - [`<C-u>`](./doc/REFERENCE.md#C-u)

- [Option](./doc/REFERENCE.md#Option)

  - [`let!`](./doc/REFERENCE.md#let)
  - [`set!`](./doc/REFERENCE.md#set)
  - [`setglobal!`](./doc/REFERENCE.md#setglobal)
  - [`setlocal!`](./doc/REFERENCE.md#setlocal)
  - [`go!`](./doc/REFERENCE.md#go)
  - [`bo!`](./doc/REFERENCE.md#bo)
  - [`wo!`](./doc/REFERENCE.md#wo)

- [Variable](./doc/REFERENCE.md#Variable)

  - [`g!`](./doc/REFERENCE.md#g)
  - [`b!`](./doc/REFERENCE.md#b)
  - [`w!`](./doc/REFERENCE.md#w)
  - [`t!`](./doc/REFERENCE.md#t)
  - [`v!`](./doc/REFERENCE.md#v)
  - [`env!`](./doc/REFERENCE.md#env)

- [Others](./doc/REFERENCE.md#Others)
  - [`command!`](./doc/REFERENCE.md#command)
  - [`feedkeys!`](./doc/REFERENCE.md#feedkeys)
  - [`highlight!`](./doc/REFERENCE.md#highlight)
  - [`hi!`](./doc/REFERENCE.md#hi)

## Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [nvim-anisole-macros](https://github.com/katawful/nvim-anisole-macros)
- [nyoom.nvim](https://github.com/shaunsingh/nyoom.nvim)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
