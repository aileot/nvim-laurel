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

### With `&default-opts`

#### Define autocmds all over my vimrc!

Traditionally, we create a `MyVimrc` augroup all over my vimrc just once to
clear augroup to start up Vim/Neovim faster.

```vim
" At first,
augroup MyVimrc
  au!
augroup END

" Then, define as many autocmds as needed.
au MyVimrc FileType *.fnl setlocal suffixesadd=.fnl,.lua,.vim
" or
augroup MyVimrc
  au FileType *.fnl setlocal suffixesadd=.fnl,.lua,.vim
augroup END
```

With nvim-laurel, it could be archived in two approaches:

- With `augroup!` wrapper

  1. Define a wrapper macro not to clear augroup by default

  ```fennel
  (fn augroup+ [...]
    "Define augroup without clearing it."
    (augroup! `&default-opts
      {:clear false}
      ...))
  ```

  2. Define autocmds within the wrapper `augroup+`.

  ```fennel
  (augroup+ :MyVimrc
    (au! :FileType ["*.fnl"] #(setlocal! :suffixesAdd [:.fnl :.lua :.vim]))
  ```
