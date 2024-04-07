# Cookbook

_Demonstrations with practical snippets._

<!-- panvimdoc-ignore-start -->

- [Recipes](#recipes)
  - [Create wrapper macros](#create-wrapper-macros)
    - [`augroup+`: _An augroup macro without clearing itself by default_](#augroup-an-augroup-macro-without-clearing-itself-by-default)
    - [`set+`, `set-`, `set^`, ...: _The dedicated macros to append/remove/prepend Vim options_](#set-set--set--the-dedicated-macros-to-appendremoveprepend-vim-options)
  - [Back to the good and old Vim script era](#back-to-the-good-and-old-vim-script-era)
    - [Create autocmds in a monolithic augroup all over my vimrc](#create-autocmds-in-a-monolithic-augroup-all-over-my-vimrc)
      - [The simplest approach](#the-simplest-approach)
      - [Another approach with `augroup!` wrapper](#another-approach-with-augroup-wrapper)
      - [(Optional) An idea to define `autocmd`s with `group` in Integer id](#optional-an-idea-to-define-autocmds-with-group-in-integer-id)
- [Anti-Patterns](#anti-patterns)
  - [`&default-opts`](#default-opts)
    - [Define macro wrappers](#define-macro-wrappers)
      - [Anti-Pattern](#anti-pattern)
      - [Pattern](#pattern)
  - [`autocmd!`](#autocmd)
    - [`pcall` in the end of callback](#pcall-in-the-end-of-callback)
      - [Anti-Pattern](#anti-pattern-1)
      - [Pattern](#pattern-1)
    - [Nested hash functions in callback](#nested-hash-functions-in-callback)
      - [Anti-Pattern](#anti-pattern-2)
      - [Pattern](#pattern-2)

<!-- panvimdoc-ignore-end -->

## Recipes

### Create wrapper macros

The codes in examples below are supposed to import and export all the
nvim-laurel macros properly.

<details>
<summary>
<i>
An example to import and export nvim-laurel macros
</i>
</summary>

In a macro definition file, say `my-macros.fnl`,

```fennel
(local {: let!
        : set!
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
{: let!
 : set!
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

```fennel
;; Note: This is only for convenience sake; `require-macros` is officially deprecated
;; in favor of `import-macros` in Fennel v0.4.0.
(require-macros :my-macros)
```

</details>

<!-- panvimdoc-ignore-start -->

#### `augroup+`: _An augroup macro without clearing itself by default_

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
augroup+                                                     *laurel-augroup+*
-->

```fennel
(fn augroup+ [...]
  "Define augroup without clearing it."
  (augroup! `&default-opts {:clear false}
    ...))

;; (Optional) At the end of my-macros.fnl to export it as `augroup!`.
{:augroup! augroup+}
```

<!-- panvimdoc-ignore-start -->

#### `set+`, `set-`, `set^`, ...: _The dedicated macros to append/remove/prepend Vim options_

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
set+                                                             *laurel-set+*
set-                                                             *laurel-set-*
set^                                                             *laurel-set^*
setlocal+                                                   *laurel-setlocal+*
setlocal-                                                   *laurel-setlocal-*
setlocal^                                                   *laurel-setlocal^*
setglobal+                                                 *laurel-setglobal+*
setglobal-                                                 *laurel-setglobal-*
setglobal^                                                 *laurel-setglobal^*
go+                                                               *laurel-go+*
go-                                                               *laurel-go-*
go^                                                               *laurel-go^*
-->

```fennel
(lambda set+ [name val]
  (let! :opt name `+ val)))
(lambda set- [name val]
  (let! :opt name `- val)))
(lambda set^ [name val]
  (let! :opt name `^ val)))
```

Replace "set", as you need, with "setlocal", "setglobal", etc.

### Back to the good and old Vim script era

<!-- panvimdoc-ignore-start -->

#### Create autocmds in a monolithic augroup all over my vimrc

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
monolithic-augroup                                 *laurel-monolithic-augroup*
-->

<details>
<summary>
<i>
Traditionally, spartan Vimmers have created a monolithtic augroup in Vim script to reduce startup time...
</i>
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

##### The simplest approach

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

##### Another approach with `augroup!` wrapper

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

##### (Optional) An idea to define `autocmd`s with `group` in Integer id

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

## Anti-Patterns

<!-- panvimdoc-ignore-start -->

### [`&default-opts`](#default-opts)

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
                                          *laurel-anti-patterns-&default-opts*
-->

#### Define macro wrappers

To create wrapper of nvim-laurel macro, it is unrecommended to wrap them in
runtime function; instead, wrap them in macro.
Fennel macros cannot parse the contents of `varargs` (`...`) which is only
determined at runtime.

##### Anti-Pattern

```fennel
;; bad
(autocmd! group [:FileType]
  (fn []
    (let [buf-au! (fn [...]
                    (autocmd! &default-opts {:buffer 0} ...))]
      (buf-au! [:InsertEnter] #(do :something))
      (buf-au! [:BufWritePre] #(do :other))))
```

##### Pattern

```fennel
;; good
(import-macros {: autocmd!} :nvim-laurel)

(macro buf-au! [...]
  `(autocmd! &default-opts {:buffer 0} ,...))

(autocmd! group [:FileType]
  (fn []
     (buf-au! [:InsertEnter] #(do :something))
     (buf-au! [:BufWritePre] #(do :other))))
```

or

```fennel
;; good
;; in my/macros.fnl
(local {: autocmd!} (require :nvim-laurel))

(fn buf-au! [...]
  (autocmd! `&default-opts {:buffer 0} ...))

{: buf-au!}
```

```fennel
;; in foobar.fnl (another file)
(import-macros {: autocmd!} :nvim-laurel)
(import-macros {: buf-au!} :my.macros)

(autocmd! group [:FileType]
  #(do
     (buf-au! [:InsertEnter] (do :something))
     (buf-au! [:BufWritePre] (do :other))))
```

<!-- panvimdoc-ignore-start -->

### [`autocmd!`](#autocmd)

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
                                               *laurel-anti-patterns-autocmd!*
-->

#### `pcall` in the end of callback

It could be an unexpected behavior that `autocmd` whose callback ends with
`pcall` is executed only once because of the combination:

- Fennel `list` returns the last value.
- `pcall` returns `true` when the call succeeds without errors.
- `nvim_create_autocmd()` destroys itself when its callback function returns
  `true` in nvim < v0.10; In nvim >= v0.10, it destroys the autocmd itself
  when its callback function returns any value other than `false` or `nil`.

##### Anti-Pattern

```fennel
;; bad
(autocmd! group events #(pcall foobar))
(autocmd! group events (fn []
                         ;; Do something else
                         (pcall foobar)))
```

##### Pattern

```fennel
;; good
(macro ->nil [...]
  "Make sure to return `nil`."
  `(do
     ,...
     nil))

(autocmd! group events #(->nil (pcall foobar)))
(autocmd! group events (fn []
                         ;; Do something else
                         (pcall foobar)
                         ;; Return any other value than `true`.
                         nil))
```

#### Nested hash functions in callback

`$` in the outermost hash function represents the single table argument from
`nvim_create_autocmd()`; on the other hand, `$` in any hash functions included
in another hash function is meaningless in many cases.

##### Anti-Pattern

```fennel
;; bad
(autocmd! group events #(vim.schedule #(nnoremap [:buffer $.buf] :lhs :rhs)))
(autocmd! group events (fn []
                         (vim.schedule #(nnoremap [:buffer $.buf] :lhs :rhs))))
```

##### Pattern

```fennel
;; good
(autocmd! group events #(vim.schedule (fn []
                                        (nnoremap [:buffer $.buf] :lhs :rhs))))
```

[augroup+]: #augroup-an-augroup-macro-without-clearing-itself-by-default
