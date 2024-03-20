# Appendix of nvim-laurel

## LSP: Get fennel-ls support

This is an example to get a support from
[fennel-ls](https://git.sr.ht/~xerool/fennel-ls)
with
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
The code lets `fennel-ls` aware of all the Fennel files under `fnl/` in
`&runtimepath`.

```fennel
(let [globals [:vim]
      extra-globals (table.concat globals " ")
      runtime-fnl-roots (vim.api.nvim_get_runtime_file :fnl true)
      pat-project-root "."
      _ (table.insert runtime-fnl-roots pat-project-root)
      ;; Note: Share the suffix patterns with fennel-path and macro-path since
      ;; I don't need the pattern `?/init-macros.fnl` for macros so far.
      suffix-patterns [:/?.fnl :/?/init.fnl]
      default-patterns (table.concat [:?.fnl
                                      :?/init.fnl
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

## Treesitter: Personalize syntax highlights

_To begin with, do not forget `;; extends` at the top
of your `after/queries/fennel/highlights.scm`
if you don't intend to override those defined by other plugins!_

```query
;; extends
```

### Distinguish keys in table

WIP

<!-- TODO: Paste Screenshot -->

```query
;; In after/queries/fennel/highlight.scm
(table_pair
  key: (string) @variable.member)
```
