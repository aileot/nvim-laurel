# Appendix

_Extra knowledge not limited to nvim-laurel, but useful to write nvim config in
Fennel._

<!-- panvimdoc-ignore-start -->

- [Caveat](#caveat)
- [LSP](#lsp)
  - [LSP: _Get fennel-ls support over `&rtp`, or `&runtimepath`_](#lsp-get-fennel-ls-support-over-rtp-or-runtimepath)
- [Treesitter](#treesitter)
  - [Treesitter: _Distinguish keys in table_](#treesitter-distinguish-keys-in-table)
  - [Treesitter: _Highlight scope in nvim-laurel macro `let!`_](#treesitter-highlight-scope-in-nvim-laurel-macro-let)
  - [Treesitter: _Highlight name of `augroup`, `command`, and `highlight`_](#treesitter-highlight-name-of-augroup-command-and-highlight)
  - [Treesitter: _Inject Vim syntax highlight to Vim command in nvim-laurel macros_](#treesitter-inject-vim-syntax-highlight-to-vim-command-in-nvim-laurel-macros)

<!-- panvimdoc-ignore-end -->

## Caveat

This page might contain usage beyond the plugin authors intend.
If the plugin authors say it is unrecommended, it is unrecommended;
if the plugin authors request removal of a related article, it should be
removed.

_Please adopt or adjust the snippets at your own risk._

## LSP

_(last edited at nvim-lspconfig [48a9b4dc](https://github.com/neovim/nvim-lspconfig/commit/48a9b4dcd9a3611edddd51972d8abb1a289c7724))_

### LSP: _Get fennel-ls support over `&rtp`, or `&runtimepath`_

Get a support from
[fennel-ls][]
with
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
(or you could suppress errors with `"unknown identifier"` at least.)

1. Add `flsproject.fnl` to `stdpath("config")`, or `$XDG_CONFIG_HOME/nvim`,
   with the following contents:

   ```fennel
   {:lua-version "lua5.1"
    ;; NOTE: For the libraries, you should preinstall the docsets like
    ;; `curl https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua -o $HOME/.local/share/fennel-ls/docsets/nvim.lua`
    :libraries {:nvim true}
    :macro-path "fnl/?.fnl;fnl/?/init.fnl"
    :fennel-path "fnl/?.fnl;fnl/?/init.fnl"}
    ;; Or, with nvim-thyme, you might want this instead.
    ;; :macro-path "lua/?.fnl;lua/?/init.fnl;fnl/?.fnl;fnl/?/init.fnl"
    ;; :fennel-path "lua/?.fnl;lua/?/init.fnl;fnl/?.fnl;fnl/?/init.fnl"}
   ```

2. Add the `fnl/` directories on [&runtimepath][] to [fennel-ls][] workspace folders:

   ```lua
   -- In ~/.config/nvim/after/lsp/fennel_ls.lua
   local workspace_folders_on_rtp = vim.tbl_map(function(path)
     return {
       uri = "file://" .. path,
       name = vim.fs.basename(vim.fs.dirname(path)),
     }
   end, vim.api.nvim_get_runtime_file("fnl", true))

   return {
     workspace_folders = workspace_folders_on_rtp,
   }
   ```

## Treesitter

_(last edited at nvim-treesitter [e6cd337e](https://github.com/nvim-treesitter/nvim-treesitter/commit/e6cd337e30962cc0982d51fa03beedcc6bc70e3d))_

_To begin with, do not forget `;; extends` at the top of your
`after/queries/fennel/<type>.scm`
if you don't intend to override queries defined by other plugins._

```query
;; extends
```

- Unless otherwise noted, the treesitter query snippets should be written in
  after/queries/fennel/highlight.scm.

- The following example queries are ready to be used on the latest
  tree-sitter-fennel parser supported by nvim-treesitter.
  However, it's obviously recommended to select and edit queries as your need,
  rather than indiscriminately copy and paste them.

- The capture names in the examples below follow the nvim-treesitter convention,
  on which most of nvim colorscheme plugins are expected to define highlight
  links to the captures.
  Since the capture names in the examples are just examples, you should change
  them as per your preference.

### Treesitter: _Distinguish keys in table_

<!-- TODO: Paste Screenshot -->

```query
(table_pair
  key: (string) @variable.member)
```

### Treesitter: _Highlight scope in nvim-laurel macro `let!`_

<!-- TODO: Paste Screenshot -->

```query
;; nvim-laurel: (let! :bo ...), etc.
(list
  . (symbol) @_call
  (#eq? @_call "let!")
  . (string
      (string_content) @module)
  (#any-of? @module
    "g"
    "b"
    "w"
    "t"
    "v"
    "env"
    "o"
    "go"
    "bo"
    "wo"
    "opt"
    "opt_local"
    "opt_global"))
```

### Treesitter: _Highlight name of `augroup`, `command`, and `highlight`_

```query
;; nvim-laurel: (augroup! :title), etc.
(list
  . (symbol) @_call
  . (string
      (string_content) @label)
  (#any-of? @_call
    "augroup!"
    "command!"
    "highlight!"
    "hi!"))
```

### Treesitter: _Inject Vim syntax highlight to Vim command in nvim-laurel macros_

```query
;; in after/queries/fennel/injection.scm

;; without api-opts
((list
   . (symbol) @_call
   (string
     (string_content) @injection.content)
   .)
 (#any-of? @_call
  "au!"
  "autocmd!"
  "command!")
 (#set! injection.language "vim"))

;; with api-opts
((list
   . (symbol) @_call
   (string
     (string_content) @injection.content)
   . [(table) (symbol)] ;; api-opts
   .)
 (#any-of? @_call
  "au!"
  "autocmd!"
  "command!")
(#set! injection.language "vim"))
```

Note: Vim script syntax to be injected is Vim command syntax.
It does not make sense to inject Vim syntax into `map!` macro.

[fennel-ls]: https://git.sr.ht/~xerool/fennel-ls
[&runtimepath]: https://vim-jp.org/vimdoc-ja/options.html#'runtimepath'
