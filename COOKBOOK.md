# Cookbook with nvim-laurel

## Recipes

In examples below, the codes are supposed to import and export all the
nvim-laurel macros properly.

<details>

<summary>
Sample code to import and export nvim-laurel macros
</summary>

```fennel
;; In a macro definition file, say my-macros.fnl,
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

;; Define other macros including wrappers.
...

;; And export them, too.
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
 : highlight!
 ;; And the other wrapper macros
 ...}
```

Then, at the top of example codes,
(For convenience sake only. `require-macros` is officially deprecated in
favor of `import-macros` in Fennel v0.4.0.)

```fennel
(require-macros :my-macros)
```

</details>

Here is a practical wrappers: https://github.com/aileot/nvim-fnl/blob/main/my/macros.fnl

### TOC

- [Define autocmds all over my vimrc](#define-autocmds-all-over-my-vimrc)

### Define autocmds all over my vimrc

Traditionally, we create a `MyVimrc` augroup all over my vimrc just once to
clear augroup to start up Vim/Neovim faster in Vim script:

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
