# Appendix

_Extra knowledge not limited to nvim-laurel, but useful to write nvim config in
Fennel._

<!-- panvimdoc-ignore-start -->

- [Caveat](#caveat)
- [LSP](#lsp)
  - [LSP: _Get fennel-ls support_](#lsp-get-fennel-ls-support)
- [Treesitter](#treesitter)
  - [Treesitter: _Distinguish keys in table_](#treesitter-distinguish-keys-in-table)
  - [Treesitter: _Highlight scope in nvim-laurel macro `let!`_](#treesitter-highlight-scope-in-nvim-laurel-macro-let)
  - [Treesitter: _Inject Vim syntax highlight to Vim command in nvim-laurel macros_](#treesitter-inject-vim-syntax-highlight-to-vim-command-in-nvim-laurel-macros)
- [Hotpot.nvim](#hotpotnvim)
  - [Hotpot.nvim: _Clear compiled Lua cache_](#hotpotnvim-clear-compiled-lua-cache)

<!-- panvimdoc-ignore-end -->

## Caveat

This page might contain usage beyond the plugin authors intend.
If the plugin authors say it is unrecommended, it is unrecommended;
if the plugin authors request removal of a related article, it should be
removed.

_Please adopt or adjust the snippets at your own risk._

## LSP

_(last edited at nvim-lspconfig [9619e53d](https://github.com/neovim/nvim-lspconfig/commit/9619e53d3f99f0ca4ea3b88f5d97fce703131820))_

### LSP: _Get fennel-ls support_

This is an example to get a support from
[fennel-ls](https://git.sr.ht/~xerool/fennel-ls)
with
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
The code lets `fennel-ls` aware of all the Fennel files under `fnl/` in
`&runtimepath`, including nvim-laurel macros.

```fennel
(let [globals [:vim]
      extra-globals (table.concat globals " ")
      runtime-fnl-roots (vim.api.nvim_get_runtime_file :fnl true)
      pat-project-root "."
      _ (table.insert runtime-fnl-roots pat-project-root)
      ;; Note: It shares the suffix patterns with fennel-path and macro-path.
      ;; Another step is required if you also need `?/init-macros.fnl`.
      suffix-patterns [:/?.fnl :/?/init.fnl]
      default-patterns (table.concat [:?.fnl
                                      :?/init.fnl
                                      ;; Note: The following src/ patterns are
                                      ;; merely community convention, but
                                      ;; recommended.
                                      :src/?.fnl
                                      :src/?/init.fnl]
                                     ";")
      fnl-patterns (accumulate [patterns default-patterns ;
                                _ root (ipairs runtime-fnl-roots)]
                     (do
                       (each [_ suffix (ipairs suffix-patterns)]
                         (set patterns (.. patterns ";" root "/" suffix)))
                       patterns))
      fennel-path fnl-patterns
      macro-path fnl-patterns
      config {:settings {:fennel-ls {: extra-globals
                                     : fennel-path
                                     : macro-path}}}]
      lspconfig (require :lspconfig)
 (lspconfig.setup config)
```

## Treesitter

_(last edited at nvim-treesitter [e6cd337e](https://github.com/nvim-treesitter/nvim-treesitter/commit/e6cd337e30962cc0982d51fa03beedcc6bc70e3d))_

_To begin with, do not forget `;; extends` at the top of your
`after/queries/fennel/<type>.scm`
if you don't intend to override queries defined by other plugins!_

```query
;; extends
```

The following example queries are ready to be used on the latest
tree-sitter-fennel parser supported by nvim-treesitter.
However, it's obviously recommended to select and edit queries as your need,
rather than indiscriminately copy and paste them.

The capture names in the examples below follow the nvim-treesitter convention,
on which most of nvim colorscheme plugins are expected to define highlight
links to the captures.
Since the capture names in the examples are just examples, you should change
them as per your preference.

### Treesitter: _Distinguish keys in table_

<!-- TODO: Paste Screenshot -->

```query
;; in after/queries/fennel/highlight.scm
(table_pair
  key: (string) @variable.member)
```

### Treesitter: _Highlight scope in nvim-laurel macro `let!`_

<!-- TODO: Paste Screenshot -->

```query
;; in after/quries/fennel/highlight.scm
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

### Treesitter: _Inject Vim syntax highlight to Vim command in nvim-laurel macros_

```query
;; in after/quries/fennel/injection.scm

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

## Hotpot.nvim

_(last edited at hotpot.nvim [5c96b423](https://github.com/rktjmp/hotpot.nvim/commit/5c96b423a6663c91c47d6184f810acf1dacf4615))_

### Hotpot.nvim: _Clear compiled Lua cache_

Probably because I often run multiple nvim instances in editing nvim config
files, hotpot.nvim is sometimes unaware of the latest changes. In such cases,
the following codes would be useful.

```fennel
(command! :HotpotCacheClear
  [:desc "[hotpot] clear compiled Lua cache"]
  #(let [{: clear-cache} (require :hotpot.api.cache)]
     (clear-cache)))

(command! :HotpotCacheForceUpdate
  [:desc "[hotpot] clear & recache compiled Lua"]
  #(let [{: clear-cache} (require :hotpot.api.cache)]
     (clear-cache)
     (vim.fn.system [:nvim :--headless :+q])))
```
