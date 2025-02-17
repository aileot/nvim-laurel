<div align="center">

# nvim-laurel 🌿

[![badge/test][]][url/to/workflow/test]
[![badge/semver][]][url/to/semver]
[![badge/license][]][url/to/license]\
_A set of Fennel macros for Neovim config_\
_inspired by the builtin Nvim Lua-Vimscript bridge on metatable_
_and by good old Vim script_

![image/nvim-laurel-demo](https://user-images.githubusercontent.com/46470475/207041810-4d0afa5e-f9cc-4878-86f2-e607cff20601.png)

[![badge/fennel][]][url/to/fennel]

<!--
NOTE: The colors come from the palette of catppuccin-mocha:
https://github.com/catppuccin/catppuccin/tree/v0.2.0?tab=readme-ov-file#-palettes
-->

[badge/test]: https://img.shields.io/github/actions/workflow/status/aileot/nvim-laurel/test.yml?branch=main&label=Test&logo=github&style=for-the-badge&logo=neovim&logoColor=CDD6F4&labelColor=1E1E2E&color=a6e3a1
[badge/semver]: https://img.shields.io/github/v/release/aileot/nvim-laurel?style=for-the-badge&logo=starship&logoColor=CDD6F4&labelColor=1E1E2E&&color=cdd6f4&include_prerelease&sort=semver
[badge/license]: https://img.shields.io/github/license/aileot/nvim-laurel?style=for-the-badge&logoColor=CDD6F4&labelColor=1E1E2E&color=89dceb
[badge/fennel]: https://img.shields.io/badge/Powered_by_Fennel-030281?&style=for-the-badge&logo=lua&logoColor=cdd6f4&label=Lua&labelColor=1E1E2E&color=cba6f7
[url/to/workflow/test]: https://github.com/aileot/nvim-laurel/actions/workflows/test.yml
[url/to/license]: ./LICENSE
[url/to/semver]: https://github.com/aileot/nvim-laurel/releases/latest
[url/to/fennel]: https://fennel-lang.org/

</div>

> [!WARNING]
> Some breaking changes are planned until v1.0.0.
> (The version would be released after nvim v1.0.)\
> If you encounter breaking changes
> and the deprecation notices that precede them,
> [COOKBOOK.md](./docs/cookbook.md)
> will help you update as painlessly as possible;
> see [REFERENCE.md](./docs/reference.md)
> for usage of [`g:laurel_deprecated`](./docs/reference.md#glaurel_deprecated),
> which would also help you update them as
> long as they are deprecated, but not abolished yet.

## 📚 Documentations

- The [Reference](./docs/reference.md) lists out the nvim-laurel interfaces.
  Note that the interfaces are not limited to Fennel macros.
- The [Cookbook](./docs/cookbook.md) demonstrates practical codes on the
  nvim-laurel interfaces.
- The [Appendix](./docs/appendix.md) shows extra knowledge not limited to
  nvim-laurel, but useful to write nvim config files in Fennel:
  LSP, Treesitter, etc. Happy Coding!
- The [Changelog](./docs/changelog.md).
  _See also the [Cookbook](./docs/cookbook.md)_
  for tips how to update features and usages deprecated or removed in
  nvim-laurel.

## 🎨 Design

- **Fast:** Each macro is expanded to a few nvim API functions in principle.
- **Less:** The syntax is as little, but flexible and extensible as possible.
- **Fzf-Friendly:** Options such as `desc`, `buffer`, `expr`, ..., can be set
  in sequential table instead of key-value table. In this format, options are
  likely to be `format`ted into the same line where nvim-laurel macro starts
  from.

## ✔️ Requirements

- Neovim 0.9.5+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## 📦 Installation

### With a compiler plugin (recommended)

1. Add nvim-laurel to `'runtimepath'`, before registering it with your plugin
   manager, to use nvim-laurel macros as early as possible.

   <details>
   <summary>
   With lazy.nvim
   </summary>

   ```lua
   local function prerequisite(name, url)
     -- To manage the version of repo, the path should be where your plugin
     -- manager will download it.
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
     -- To manage the version of repo, the path should be where your plugin
     -- manager will download it.
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
       -- v0.7.1 <= {version} < v0.8.0
       -- Note: v0.7.0 has a backward compatibility issue.
       version = "~v0.7.1",
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
                 ;; v0.7.1 <= {version} < v0.8.0
                 ;; Note: v0.7.0 has a backward compatibility issue.
                 :version "~v0.7.0"}
                ;; and other plugins
                ]
               {:defaults {:lazy true
                           ;; Note: Not to remove nvim-laurel from &rtp, and
                           ;; not to encounter any other potential issues,
                           ;; it's UNRECOMMENDED to reset &rtp unless you
                           ;; don't mind the extra cost to maintain the
                           ;; "paths" properly.
                           :performance {:rtp {:reset false}}}})
   ```

   With [dein.vim](https://github.com/Shougo/dein.vim) in toml,

   ```toml
   [[plugins]]
   repo = "aileot/nvim-laurel"
   # Note: v0.7.0 has a backward compatibility issue.
   rev = "v0.7.*"
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

## 🚀 Usage

```fennel
(import-macros {: set! : map! : augroup! : au! ...} :laurel.macros)
```

See [REFERENCE.md](./docs/reference.md) for each macro usage in details.

### 🔥 Macro List

- [Autocmd](./docs/reference.md#autocmd)

  - [`augroup!`](./docs/reference.md#augroup):
    A replacement of `vim.api.nvim_create_augroup`
  - [`autocmd!`](./docs/reference.md#autocmd-1):
    A replacement of `vim.api.nvim_create_autocmd`
  - [`au!`](./docs/reference.md#au):
    An alias of `autocmd!`

- [Keymap](./docs/reference.md#Keymap)

  - [`map!`](./docs/reference.md#map): A replacement of `vim.keymap.set`,
    but compiles into `vim.api.nvim_set_keymap`.
  - [`unmap!`](./docs/reference.md#unmap): A replacement of `vim.keymap.del`,
    but compiles into `vim.api.nvim_del_keymap`.
  - [`<Cmd>`](./docs/reference.md#Cmd)
  - [`<C-u>`](./docs/reference.md#C-u)

- [Option](./docs/reference.md#Option)

  - [`let!`](./docs/reference.md#let):
    A replacement of
    `vim.opt`, `vim.opt_local`, `vim.opt_global`,
    `vim.o`, `vim.bo`, `vim.wo`,
    but compiles into `vim.api.nvim_set_option_value`.\
    You can wrap this macro into [`set!`, `setlocal!`, ...](./docs/cookbook.md#set-setlocal-setglobal-the-dedicated-macros-to-set-vim-options),
    [`set+`, `set-`, ...](./docs/cookbook.md#set-set--set--the-dedicated-macros-to-appendremoveprepend-vim-options),
    [`bo!`, `wo!`](./docs/cookbook.md#bowo-the-dedicated-macros-to-set-bufferwindow-local-vim-options),
    and so on.\
    Follow the links for the details.

- [Variable](./docs/reference.md#Variable)

  - [`g!`](./docs/reference.md#g)
  - [`b!`](./docs/reference.md#b)
  - [`w!`](./docs/reference.md#w)
  - [`t!`](./docs/reference.md#t)
  - [`v!`](./docs/reference.md#v)
  - [`env!`](./docs/reference.md#env)

- [Others](./docs/reference.md#Others)
  - [`command!`](./docs/reference.md#command):
    A replacement of `vim.api.nvim_create_user_command`
  - [`feedkeys!`](./docs/reference.md#feedkeys)
  - [`highlight!`](./docs/reference.md#highlight)
  - [`hi!`](./docs/reference.md#hi)

## 🔄 Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [nvim-anisole-macros](https://github.com/katawful/nvim-anisole-macros)
- [nyoom.nvim](https://github.com/shaunsingh/nyoom.nvim)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
