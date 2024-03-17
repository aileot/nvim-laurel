# Cookbook with nvim-laurel

## Recipes

### Create wrapper macros

The codes in examples below are supposed to import and export all the
nvim-laurel macros properly.

<details>

<summary>
An example to import and export nvim-laurel macros
</summary>

In a macro definition file, say my-macros.fnl,

```fennel
(local {: set!
        : setlocal!
        : setglobal!
        : go!
        : bo!
        : wo!
        : g!
        : b!
        : w!
        : t!
        : v!
        : env!
        : map!
        : unmap!
        : <C-u>
        : <Cmd>
        : command!
        : augroup!
        : au!
        : autocmd!
        : feedkeys!
        : highlight!} (require :nvim-laurel.macros))

```

And export them at the bottom of the file:

```fennel

{: set!
 : setlocal!
 : setglobal!
 : go!
 : bo!
 : wo!
 : g!
 : b!
 : w!
 : t!
 : v!
 : env!
 : map!
 : unmap!
 : <C-u>
 : <Cmd>
 : command!
 : augroup!
 : au!
 : autocmd!
 : feedkeys!
 : highlight!}
```

Then, at the top of example codes,
(For convenience sake only. `require-macros` is officially deprecated in
favor of `import-macros` in Fennel v0.4.0.)

```fennel
(require-macros :my-macros)
```

</details>
<br>

Here is a practical wrappers: https://github.com/aileot/nvim-fnl/blob/main/my/macros.fnl

### Define autocmds all over my vimrc

<details>
<summary>
_Traditionally, a lot of spartan Vimmers have created a monolithtic augroup "MyVimrc" in Vim script..._
</summary>

```vim
" At first,
augroup MyVimrc
  au!
augroup END

" Then, define as many autocmds as needed.
au MyVimrc FileType *.fnl setlocal suffixesadd=.fnl,.lua,.vim
" or in another format,
augroup MyVimrc
  au FileType *.fnl setlocal suffixesadd=.fnl,.lua,.vim
augroup END
```

</details>

<br>

With nvim-laurel, it could be implemented in some approaches:

#### The simplest approach

1. Define an `augroup` at first in a runtime file.

```fennel
(augroup! :MyVimrc)
```

2. Define `autocmd`s with the `group` in the first argument.

```fennel
(au! :MyVimrc :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim]))
;; or if you don't mind to set the option to each augroup.
(augroup! :MyVimrc {:clear false}
  (au! :MyVimrc :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim])))
```

#### Another approach with `augroup!` wrapper

1. In a macro definition file, define and export a wrapper macro not to clear
   `augroup` by default.

```fennel
(fn augroup+ [...]
  "Define augroup without clearing it."
  (augroup! `&default-opts {:clear false}
    ...))
```

2. Define an `augroup` at first in runtime file.

```fennel
(augroup! :MyVimrc)
```

3. Define `autocmd`s within the wrapper `augroup+`.

```fennel
(augroup+ :MyVimrc
  (au! :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim]))
```

#### (Optional) An idea to define `autocmd`s with `group` in Integer id

1. Define an `augroup` in runtime file, but assign its `id` to an global
   variable either `_G` or `vim.g`.

```fennel
(set _G.my-augroup (augroup! :MyAugroup))
```

2. Define autocmds with the `id`.

```fennel
(au! _G.my-augroup :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim]))
;; or with predefined `augroup+` macro
(augroup+ _G.my-augroup
  (au! :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim]))
```

## Appendix

### Get LSP support on fennel-ls

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

### Personalize syntax highlights on Treesitter

_To begin with, do not forget `;; extends` at the top
of your `after/queries/fennel/highlights.scm`
if you don't intend to override those defined by other plugins!_

```query
;; extends
```

#### Distinguish keys in table

WIP

<!-- TODO: Paste Screenshot -->

```query
;; In after/queries/fennel/highlight.scm
(table_pair
  key: (string) @variable.member)
```
