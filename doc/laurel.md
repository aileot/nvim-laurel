# nvim-laurel

nvim-laurel provides a set of macros for Neovim config, inspired by the
builtin Nvim Lua-Vimscript bridge on metatable and by good old Vim script.

<!-- panvimdoc-ignore-start -->

- [CAUTION](#CAUTION)
- [Terminology](#Terminology)
- [Macros](#Macros)
- [Anti-Patterns](#Anti-Patterns)
- [Deprecated Features](#Deprecated-Features)

<!-- panvimdoc-ignore-end -->

## CAUTION

Each macro might be more flexible than documented, but of course, undocumented
usages are subject to change without notifications.

## Terminology

- [For Convenience Sake](#For-Convenience-Sake)
- [Reserved Symbol](#Reserved-Symbol)

### For Convenience Sake

The terminology is introduced to describe the interfaces of nvim-laurel rather
than a standard one.

#### `lhs`

An abbreviation of left-hand-side.

#### `rhs`

An abbreviation of right-hand-side.

#### `#({expr})`

Hash function, where `$1` through `$9` and `$...` are available as the
argument. `$` is an alias for `$1`. Read the official
[Fennel reference](https://fennel-lang.org/reference#hash-function-literal-shorthand)
for the detail.

#### `sequence`

An alias of sequential table `[]`.

#### `kv-table`

An alias of key/value table `{}`.

#### `bare-{type}`

It describes the `{type}` value must be neither symbol nor list in compile
time. For example,

- `:foobar` is a `bare-string`.
- `(.. :foo :bar)` is not a `bare-string`.
- `[:foo :bar]` is a `bare-sequence` and also a `bare-string[]`.
- `[baz]` where `baz` is either symbol or list is a `bare-sequence`, but not a
  `bare-string[]`.
- `(icollect [_ val (ipairs [:foo :bar])] val)` is neither a `bare-sequence`
  nor `bare-string[]`.

#### `?{name}`

It represents `{name}` is omittable rather than nilable in nvim-laurel
contexts.

#### `api-opts`

It is kv-table `{}` option for the api functions, `vim.api.nvim_foo()`. Unless
otherwise noted, this option has the following features:

- It only accepts the same key/value described in `api.txt`.
- Its values have the highest priority over those set in the other arguments
  if conflicted.

#### `extra-opts`

An alternative form for `api-opts`. Unless otherwise noted, this option has
the following features:

- It is bare-sequence `[]`, but is interpreted as if kv-table `{}` in the
  following manner:
  - Items for keys must be bare-strings; items for values can be of any
    type.
  - Boolean key/value for `api-opts` is set to `true` by key itself; the other
    keys expects the next items as their values respectively.
  - To set `false` to boolean key/value, set it in `api-opts` instead.
- It is intended as shorthand; for complicated usage, use `api-opts` instead
  or use them together.
- It could accept some additional keys which are unavailable in `api-opts`.

### Reserved Symbol

The symbols are reserved to be used as arguments in `list`s of nvim-laurel
macros to extend their functionalities.

#### `&vim`

_(Since v0.5.3)_

A reserved symbol to set Vim script callback in symbol or list.  
Basically, symbol and list are interpreted as Lua callback function in the
lists of nvim-laurel macros.
With `&vim` in the list of nvim-laurel macro, they are interpreted as Vim
script command.

List of macros in which `&vim` makes sense:

- [`autocmd!`][], [`au!`][]
- [`map!`][]
- [`command!`][]: only for parity. `&vim` is uncecessary.

#### `&default-opts`

_(Since v0.6.1)_

A reserved symbol to set default values of `api-opts` fields.  
It indicates that the bare `kv-table` next to the symbol `&default-opts`
contains default values for `api-opts`, but it also interprets the additional
keys available in `extra-opts`.
To set boolean option, it requires to set to either `true` or
`false` in spite of the syntax of `extra-opts` itself.
See also its [Anti-Patterns](#default-opts-1).

List of macros in which `&default-opts` is available:

- [`augroup!`][]
- [`autocmd!`][], [`au!`][]
- [`map!`][]
- [`command!`][]
- [`highlight!`][], [`hi!`][]

Note that quote position depends on where the wrapper macros are defined:

- To define a wrapper `macro` to be expanded _in the same file_, quote the
  entire `list` of the imported macro (and unquote as you need). For example,

  ```fennel
  ;; in foobar.fnl
  (import-macros {: map!} :nvim-laurel)

  (macro buf-map! [...]
    `(map! &default-opts {:buffer 0} ,...))

  (buf-map! :lhs :rhs)
  ```

- To define a wrapper `function` to be imported as a macro _in another
  file_, just quote `&default-opts`. For example,

  ```fennel
  ;; in my/macros.fnl
  (local {: map!} (require :nvim-laurel))

  (fn buf-map! [...]
    (map! `&default-opts {:buffer 0} ...))

  {: buf-map!}
  ```

  ```fennel
  ;; in foobar.fnl (another file)
  (import-macros {: buf-map!} :my.macros)

  (buf-map! :lhs :rhs)
  ```

## Macros

- [Autocmd](#Autocmd)
- [Keymap](#Keymap)
- [Variable](#Variable)
- [Option](#Option)
- [Others](#Others)

### Autocmd

- [`augroup!`](#augroup)
- [`autocmd!`](#autocmd)
- [`au!`](#au)

#### `augroup!`

Create or get an augroup, or override an existing augroup.
(`&default-opts` is available.)

```fennel
(augroup! name ?api-opts-for-augroup) ; Only this format returns the augroup id.
(augroup! name ?api-opts-for-augroup
  [events ?pattern ?extra-opts callback ?api-opts]
  ...)
(augroup! name ?api-opts-for-augroup
  ;; Wrap args in `autocmd!` or `au!` instead of brackets.
  (autocmd! events ?pattern ?extra-opts callback ?api-opts)
  ...)
```

- `?api-opts-for-augroup`: (kv-table) `:h nvim_create_augroup()`. You cannot
  use macro/function named `au!` or `autocmd!` here.
- `name`: (string) The name of autocmd group.
- `events`: (string|string[]) The event or events to register this autocmd.
- `?pattern`: (bare-sequence) Patterns to match against. To set `pattern` in
  symbol or list, set it in either `extra-opts` or `api-opts` instead. The
  first pattern in string cannot be any of the keys used in `?extra-opts`.
- `?extra-opts`: (bare-sequence) Additional option:
  - `<buffer>`: Create autocmd to current buffer by itself.
- `callback`: (string|function) Set either callback function or Ex command. A
  callback is interpreted as Lua function by default. To set Ex command, you
  have three options:

  - Set it in bare-string.
  - Insert `&vim` symbol just before the callback.
  - Name the first symbol for the callback to match `^<.+>` in Lua pattern.

  Note: Set `vim.fn.foobar` to call Vim script function `foobar` without table
  argument from `nvim_create_autocmd()`; on the other hand, set
  `#(vim.fn.foobar $)` to call `foobar` with the table argument.

- `?api-opts`: (kv-table) `:h nvim_create_autocmd()`.

```fennel
(augroup! :sample-augroup
  [:TextYankPost #(vim.highlight.on_yank {:timeout 450 :on_visual false})]
  (autocmd! [:InsertEnter :InsertLeave]
      [:<buffer> :desc "call foo#bar() without any args"] vim.fn.foo#bar)
  (autocmd! :VimEnter [:once :nested :desc "call baz#qux() with <amatch>"]
      #(vim.fn.baz#qux $.match)))
  (autocmd! :LspAttach
      #(au! $.group :CursorHold [:buffer $.buf] vim.lsp.buf.document_highlight))
```

is equivalent to

```vim
augroup sample-augroup
  autocmd!
  autocmd TextYankPost * lua vim.highlight.on_yank {timeout=450, on_visual=false}
  autocmd InsertEnter,InsertLeave <buffer> call foo#bar()
  autocmd VimEnter * ++once ++nested call baz#qux(expand('<amatch>'))
  autocmd LspAttach * au sample-augroup CursorHold <buffer>
  \ lua vim.lsp.buf.document_highlight()
augroup END
```

```lua
local id = vim.api.nvim_create_augroup("sample-augroup", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = id,
  callback = function()
   vim.highlight.on_yank {timeout=450, on_visual=false}
  end,
})
vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave"}, {
  group = id,
  buffer = 0,
  desc = "call foo#bar() without any args",
  callback = "foo#bar",
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = id,
  once = true,
  nested = true,
  desc = "call baz#qux() with <amatch>",
  callback = function(args)
    vim.fn["baz#qux"](args.match)
  end,
})
vim.api.nvim_create_autocmd("LspAttach", {
  group = id,
  callback = function(args)
    vim.api.nvim_create_autocmd("CursorHold", {
      group = args.group,
      buffer = args.buf,
      callback = vim.lsp.buf.document_highlight,
    })
  end,
})
```

c.f. [`autocmd!`](#autocmd)

#### `autocmd!`

Create an autocmd.
(`&default-opts` is available.)

```fennel
(autocmd! events api-opts) ; Just as an alias of `nvim_create_autocmd()`.
(autocmd! name-or-id events ?pattern ?extra-opts callback ?api-opts)
```

- `name-or-id`: (string|integer|nil) The autocmd group name or id to match
  against. It is necessary unlike `nvim_create_autocmd()` unless this
  `autocmd!` macro is within either `augroup!`. Set it to `nil` to define
  `autocmd`s affiliated with no augroup.

See [`augroup!`](#augroup) for the rest.

#### `au!`

An alias of [`autocmd!`](#autocmd).
(`&default-opts` is available.)

### Keymap

- [`map!`](#map): A replacement of `vim.keymap.set`
- [`unmap!`](#unmap): A replacement of `vim.keymap.del`
- [`<Cmd>`](#Cmd)
- [`<C-u>`](#C-u)

#### `map!`

Map `lhs` to `rhs` in `modes`, non-recursively by default.
(`&default-opts` is available.)

```fennel
(map! modes ?extra-opts lhs rhs ?api-opts)
(map! modes lhs ?extra-opts rhs ?api-opts)
```

- `modes`: (string|string[]) Mode short-name (map command prefix: "n", "i",
  "v", "x", …) or "!" for `:map!`, or empty string for `:map`. As long as in
  bare-string, multi modes can be set in a string like `:nox` instead of
  `[:n :o :x]`.
- `?extra-opts`: (bare-sequence) Additional option:
  - `remap`: Make the mapping recursive. This is the inverse of the "noremap"
    option from `nvim_set_keymap()`.
  - `literal`: Disable `replace_keycodes`, which is automatically enabled when
    `expr` is set in `extra-opts`.
  - `<buffer>`: Map `lhs` in current buffer by itself.
  - `buffer`: Map `lhs` to a buffer of the next value.
- `lhs`: (string) Left-hand-side of the mapping.
- `rhs`: (string|function) Right-hand-side of the mapping. Set either callback
  function or Key sequence. A callback is interpreted as Lua function by
  default. To set Ex command, you have three options:

  - Set it in bare-string.
  - Insert `&vim` symbol just before the callback.
  - Name the first symbol for the callback to match `^<.+>` in Lua pattern.

- `?api-opts`: (kv-table) `:h nvim_set_keymap()`.

```fennel
(map! :i :jk :<Esc>)
(map! :n :lhs [:desc "call foo#bar()"] #(vim.fn.foo#bar))
(map! [:n :x] [:remap :expr :literal] :d "&readonly ? '<Plug>(readonly-d)' : '<Plug>(noreadonly-d)'")
(map! [:n :x] [:remap :expr] :u #(if vim.bo.readonly
                                     "<Plug>(readonly-u)"
                                     "<Plug>(noreadonly-u)"))
```

is equivalent to

```vim
inoremap jk <Esc>
nnoremap lhs <Cmd>call foo#bar()<CR>
nmap <expr> d &readonly ? "\<Plug>(readonly-d)" : "\<Plug>(noreadonly-d)"
xmap <expr> u &readonly ? "\<Plug>(readonly-u)" : "\<Plug>(noreadonly-u)"
```

```lua
vim.api.nvim_set_keymap("i", "jk", "<Esc>", {})
vim.api.nvim_set_keymap("n", "lhs", "", {
  -- callback = vim.fn["foo#bar"], -- If you don't care autoload.
  callback = function()
    vim.fn["foo#bar"]()
end})
vim.api.nvim_set_keymap("n", "d", "&readonly ? '<Plug>(readonly-d)' : '<Plug>(noreadonly-d)'", {
  expr = true,
  replace_keycodes = false,
})
vim.api.nvim_set_keymap("x", "d", "&readonly ? '<Plug>(readonly-d)' : '<Plug>(noreadonly-d)'", {
  expr = true,
  replace_keycodes = false,
})
vim.api.nvim_set_keymap("n", "u", "", {
  expr = true,
  callback = function()
    return vim.bo.readonly and "<Plug>(readonly-u)" or "<Plug>(noreadonly-u)"
  end,
})
vim.api.nvim_set_keymap("x", "u", "", {
  expr = true,
  callback = function()
    return vim.bo.readonly and "<Plug>(readonly-u)" or "<Plug>(noreadonly-u)"
  end,
})
-- or with vim.keymap.set wrapper,
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "lhs", function()
  vim.fn["foo#bar"]()
end)
vim.keymap.set({ "n", "x" }, "d", "&readonly ? '<Plug>(readonly-d)' : '<Plug>(noreadonly-d)'", {
  remap = true,
  expr = true,
  replace_keycodes = false,
})
vim.keymap.set({ "n", "x" }, "u", function()
  return vim.bo.readonly and "<Plug>(readonly-u)" or "<Plug>(noreadonly-u)"
end, {
  remap = true,
  expr = true,
})
```

#### `unmap!`

Delete keymap.

```fennel
(unmap! ?bufnr mode lhs)
```

- `?bufnr`: (number) Optional buffer handle, or 0 for current buffer.
- `mode`: (string) Mode to unmap.
- `lhs`: (string) Left-hand-side key to unmap.

```fennel
(unmap! :n :foo)
(unmap! 0 :o :bar)
(unmap! 10 :x :baz)
```

is equivalent to

```vim
nunmap foo
ounmap <buffer> bar
" No simple command to delete keymap in specific buffer.
```

```lua
vim.api.nvim_del_keymap("n", "foo")
vim.api.nvim_buf_del_keymap(0, "o", "bar")
vim.api.nvim_buf_del_keymap(10, "x", "baz")
```

#### `<Cmd>`

Generate `<Cmd>foobar<CR>` in string. Useful for `rhs` in keymap macro.

```fennel
(<Cmd> text)
```

- `text`: (string)

#### `<C-u>`

Generate `:<C-u>foobar<CR>` in string. Useful for `rhs` in keymap macro.

```fennel
(<C-u> text)
```

- `text`: (string)

### Variable

- [`g!`](#g)
- [`b!`](#b)
- [`w!`](#w)
- [`t!`](#t)
- [`v!`](#v)
- [`env!`](#env)

#### `g!`

Set global (`g:`) editor variable.

```fennel
(g! name val)
```

- `name`: (string) Variable name.
- `val`: (any) Variable value.

#### `b!`

Set buffer-scoped (`b:`) variable for the current buffer. Can be indexed with
an integer to access variables for specific buffer.

```fennel
(b! ?id name val)
```

- `?id`: (integer) Buffer handle, or 0 for current buffer.
- `name`: (string) Variable name.
- `val`: (any) Variable value.

```fennel
(b! :foo :bar)
(b! 8 :baz :qux)
```

is equivalent to

```lua
vim.api.nvim_buf_set_var(0, "foo", "bar")
vim.api.nvim_buf_set_var(8, "foo", "bar")
-- Or with `vim.b`,
vim.b.foo = "bar"
vim.b[8].baz = "qux"
```

```vim
let b:foo = 'bar'
call setbufvar(8, 'baz', 'qux')
```

#### `w!`

Set window-scoped (`w:`) variable for the current window. Can be indexed with
an integer to access variables for specific window.

```fennel
(w! ?id name val)
```

- `?id`: (integer) Window handle, or 0 for current window.
- `name`: (string) Variable name.
- `val`: (any) Variable value.

#### `t!`

Set tabpage-scoped (`t:`) variable for the current tabpage. Can be indexed
with an integer to access variables for specific tabpage.

```fennel
(t! ?id name val)
```

- `?id`: (integer) Tabpage handle, or 0 for current tabpage.
- `name`: (string) Variable name.
- `val`: (any) Variable value.

#### `v!`

Set `v:` variable if not readonly.

```fennel
(v! name val)
```

- `name`: (string) Variable name.
- `val`: (any) Variable value.

#### `env!`

Set environment variable in the editor session.

```fennel
(env! name val)
```

- `name`: (string) Variable name. A bare-string can starts with `$` (ignored
  internally), which helps `gf` jump to the path.
- `val`: (any) Variable value.

```fennel
(env! :$NVIM_CACHE_HOME (vim.fn.stdpath :cache))
(env! :$NVIM_CONFIG_HOME (vim.fn.stdpath :config))
(env! :$NVIM_DATA_HOME (vim.fn.stdpath :data))
(env! :$NVIM_STATE_HOME (vim.fn.stdpath :state))
(env! :$PLUGIN_CACHE_HOME (vim.fs.normalize :$NVIM_CACHE_HOME/to/plugin/home))
```

is equivalent to

```lua
vim.env.NVIM_CACHE_HOME = vim.fn.stdpath "cache"
vim.env.NVIM_CONFIG_HOME = vim.fn.stdpath "config"
vim.env.NVIM_DATA_HOME = vim.fn.stdpath "data"
vim.env.NVIM_STATE_HOME = vim.fn.stdpath "state"
vim.env.PLUGIN_CACHE_HOME vim.fs.normalize "$NVIM_CACHE_HOME/to/plugin/home"
```

```vim
let $NVIM_CACHE_HOME = stdpath('cache')
let $NVIM_CONFIG_HOME = stdpath('config')
let $NVIM_DATA_HOME = stdpath('data')
let $NVIM_STATE_HOME = stdpath('state')
let $PLUGIN_CACHE_HOME = expand('$NVIM_CACHE_HOME/to/plugin/home')
```

### Option

- [`set!`](#set)
- [`setglobal!`](#setglobal)
- [`setlocal!`](#setlocal)
- [`go!`](#go)
- [`bo!`](#bo)
- [`wo!`](#wo)

#### `set!`

Set, append, prepend, or remove, value to the option. Almost equivalent to
`:set` in Vim script.

```fennel
(set! name ?flag ?val)
```

- `name`: (string) Option name. As long as the option name is bare-string,
  option name is case-insensitive; you can improve readability a bit with
  camelCase/PascalCase. Since `:h {option}` is also case-insensitive,
  `(setlocal! :keywordPrg ":help")` for fennel still makes sense.
- `?flag`: (symbol) Omittable flag. Set one of `+`, `^`, or `-` to append,
  prepend, or remove, value to the option.
- `?val`: (boolean|number|string|table) New option value. If not provided, the
  value is supposed to be `true` (experimental).

```fennel
(set! :number true)
(set! :formatOptions [:1 :2 :c :B])
(set! :completeOpt [:menu :menuone :noselect])
(set! :listChars {:space :_ :tab: ">~"})

(set! :colorColumn + :+1)
(set! :rtp ^ [:/path/to/another/dir])

(local val :yes)
(set! :signColumn val)
(local opt :wrap)
(set! opt false)
```

is equivalent to

```vim
set number
set signcolumn=yes
set formatoptions=12cB
set completeopt=menu,menuone,noselect
set listchars=space:_,tab:>~

set colorcolumn+=+1
set rtp^=/path/to/another/dir

let val = 'yes'
let &signcolumn = val
let opt = 'wrap'
execute 'set no'. opt
```

```lua
vim.api.nvim_set_option_value("number", true)
vim.api.nvim_set_option_value("signcolumn", "yes")
vim.api.nvim_set_option_value("formatoptions", "12cB")
vim.api.nvim_set_option_value("completeopt", "menu,menuone,noselect")
vim.api.nvim_set_option_value("listchars", "space:_,tab:>~")
-- Or either with `vim.go` or with `vim.opt_global`,
vim.go.number = true
vim.go.signcolumn = "yes"
vim.go.formatoptions = "12cB"
vim.go.completeopt = {"menu", "menuone", "noselect"}
vim.go.listchars = {
  space = "_",
  tab = ">~",
}

vim.opt_global.colorcolumn:append("+1")
vim.opt_global.rtp:prepend("/path/to/another/dir")

local val = "yes"
vim.opt.signcolumn = val
local opt = "wrap"
vim.opt[opt] = false
```

Note: There is no plan to support option prefix either `no` or `inv`; instead,
set `false` or `(not vim.go.foo)` respectively.

#### `setglobal!`

Set, append, prepend, or remove, global value to the option. Almost equivalent
to `:setglobal` in Vim script.

```fennel
(setglobal! name ?flag ?val)
```

See [`set!`](#set) for the details.

#### `setlocal!`

Set, append, prepend, or remove, local value to the option. Almost equivalent
to `:setlocal` in Vim script.

```fennel
(setlocal! name ?flag ?val)
```

See [`set!`](#set) for the details.

#### `go!`

Alias of [`setglobal!`](#setglobal).

```fennel
(go! name value)
```

#### `bo!`

Set a buffer option value. `:h nvim_buf_set_option()`.

```fennel
(bo! ?id name value)
```

- `?id`: (integer) Buffer handle, or 0 for current buffer.
- `name`: (string) Option name. Case-insensitive as long as in bare-string.
- `value`: (any) Option value.

```fennel
(bo! :fileType :fennel)
(bo! 10 :bufType :nofile)
```

is equivalent to

```lua
vim.api.nvim_buf_set_option(0, "filetype", "fennel")
vim.api.nvim_buf_set_option(10, "buftype", "nofile")
-- Or with `vim.bo`
vim.bo.filetype = "fennel"
vim.bo[10].buftype = "nofile"
```

```vim
call setbufvar(0, '&filetype', 'fennel')
call setbufvar(10, '&buftype', 'nofile')
```

#### `wo!`

Set a window option value. `:h nvim_win_set_option()`.

```fennel
(wo! ?id name value)
```

- `?id`: (integer) Window handle, or 0 for current window.
- `name`: (string) Option name. Case-insensitive as long as in bare-string.
- `value`: (any) Option value.

```fennel
(wo! :number false)
(wo! 10 :signColumn :no)
```

is equivalent to

```lua
vim.api.nvim_win_set_option(0, "number", false)
vim.api.nvim_win_set_option(10, "signcolumn", "no")
-- Or with `vim.wo`
vim.wo.number = false
vim.wo[10].signcolumn = "no"
```

```vim
call setwinvar(0, '&number', v:false)
call setwinvar(10, '&signcolumn', 'no')
```

### Others

- [`command!`](#command)
- [`feedkeys!`](#feedkeys)
- [`highlight!`](#highlight)
- [`hi!`](#hi)

#### `command!`

Create a user command.
(`&default-opts` is available.)

```fennel
(command! ?extra-opts name command ?api-opts)
(command! name ?extra-opts command ?api-opts)
```

- `?extra-opts`: (bare-sequence) Optional command attributes.
  Additional attributes:
  - `<buffer>`: Create command in current buffer by itself.
  - `buffer`: Create command in the buffer of the next value.
- `name`: (string) Name of the new user command. It must begin with an
  uppercase letter.
- `command`: (string|function) Replacement command.
- `?api-opts`: (kv-table) Optional command attributes. The same
  as `opts` for `nvim_create_user_command()`.

```fennel
(command! :SayHello "echo 'Hello world!'")
(command! :Salute [:bar :<buffer> :desc "Salute!"] #(print "Hello world!"))
```

is equivalent to

```vim
command! SayHello echo 'Hello world!'
command! -bar -buffer Salute echo 'Hello world!'
```

```lua
vim.api.nvim_create_user_command("SayHello", "echo 'Hello world!'", {})
vim.api.nvim_buf_create_user_command(0, "Salute", function()
  print("Hello world!")
end, {
  bar = true,
  desc = "Salute!",
})
```

#### `feedkeys!`

`:h feedkeys()`

```fennel
(feedkeys! string ?flags)
```

```fennel
(feedkeys! :foo<CR> :ni)
(feedkeys! :foo<lt>CR> :ni)
```

is equivalent to

```vim
call feedkeys("foo\<CR>", 'ni')
call feedkeys('foo<CR>', 'ni')
```

```lua
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("foo<CR>", true, true, true) "ni", false)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("foo<lt>CR>", true, true, true) "ni", false)
```

#### `highlight!`

Set a highlight group.
(`&default-opts` is available.)

```fennel
(highlight! ?ns-id name api-opts)
```

- `?ns-id`: (number) Namespace id for this highlight
  `nvim_create_namespace()`.
- `name`: (string) Highlight group name, e.g., "ErrorMsg".
- `api-opts`: (kv-table) Highlight definition map. `:h nvim_set_hl()`. As long as
  the keys are bare-strings, `cterm` attribute map can contain `fg`/`bg`
  instead of `ctermfg`/`ctermbg` key.

```fennel
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :ctermfg 103 :cterm {:bold true :italic true}})
;; or (as long as `api-opts` keys are bare-strings)
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :cterm {:fg 103 :bold true :italic true}})
```

is equivalent to

```vim
highlight! Foo guifg=#8d9eb2 gui=bold,italic ctermfg=103 cterm=bold,italic
```

```lua
nvim_set_nl(0, "Foo", {
  fg = "#8d9eb2",
  ctermfg = 103,
  bold = true,
  italic = true,
  cterm = {
    bold = true,
    italic = true,
  }
})
```

#### `hi!`

An alias of [`highlight!`](#highlight).
(`&default-opts` is available.)

## Anti-Patterns

### [`&default-opts`](#default-opts)

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

### [`autocmd!`](#autocmd)

#### pcall in the end of callback

It could be an unexpected behavior that `autocmd` whose callback ends with
`pcall` is executed only once because of the combination:

- Fennel `list` returns the last value.
- `pcall` returns `true` when the call succeeds without errors.
- `nvim_create_autocmd()` deletes itself when its callback function returns
  `true`.

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

#### Nested anonymous function in callback

`$` in the outermost hash function represents the single table argument from
`nvim_create_autocmd()`; on the other hand, `$` in any hash functions included
in another anonymous function is meaningless in many cases.

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

## Deprecated Features

### Semantic Versioning

This project nvim-laurel follows [Semantic Versioning 2.0.0][semver]. It
should issue at least one version prior to a version where deprecated features
are removed, i.e., before any breaking changes.

### Deprecated Feature Handling

If you were unfortunately in trouble due to some breaking changes, please read
[The Last Resort](#the-last-resort). If you get deprecation notices,
[g:laurel_deprecated](#glaurel_deprecated) and its guidance would help you.

It's strongly recommended to manage your vimrc by version control system like
`git`; otherwise, breaking changes on nvim-laurel could lead you to a dead end
where you could not launch nvim with any part of your vimrc until you resolve
them.

#### The Last Resort

Before introducing how to avoid breaking changes, it is necessary to describe
how to resolve the dead end, where you have few or none of Lua files because
you have unexpectedly recompiled all the Fennel files that includes some
features removed from nvim-laurel. Breaking Changes could prevent you from
launching nvim itself. In this case, you have two choices:

- Downgrade nvim-laurel according to [Semantic Versioning 2.0.0][semver];
  then, update your vimrc with deprecation notices of nvim-laurel. You should
  know the path where you download nvim-laurel: if you have lazy.nvim manage
  the version of nvim-laurel, it should be downloaded to
  `stdpath('config') .. '/lazy/nvim-laurel'` by default; packer.nvim, to
  `stdpath('data') .. '/pack/packer/start/nvim-laurel'`. Downgrade it by
  `git checkout <tag>` in your local nvim-laurel repository.

- Update your vimrcs anyway apart from your vimrc with the [-u] flag, e.g.,
  run `nvim -u NONE` in your terminal.

#### `g:laurel_deprecated`

This variable is designed to help you update your codes with [Quickfix]. It
will collect lines where deprecated features are detected.

Note: It's strongly recommended to compile your Fennel codes with
`--correlate` flag because the detection runs on compiled Lua codes at
runtime.

##### Steps to update deprecated features before breaking changes

0. Make sure you can update your vimrcs on stable environment: launch multiple
   instances of Neovim which have already loaded your stable config, i.e.,
   detached from the unstable vimrcs about to undergoing changes.

1. Update deprecated features

   This is a list of useful commands:

   - With [`:cdo`] or [`:cfdo`],
     - [`:norm`][`:normal`] or [`:normal`]
     - [`:g`][`:global`] or [`:global`]
     - [`:s`][`:substitute`] or [`:substitute`]
   - With recording keys,
     1. [`:cfirst`]
     2. [`q`] to record keys into register
     3. [`:cnext`]
     4. [`@`] or [`Q`] to repeat keys in register

   Here is a basic example to rename deprecated macro `old-macro` to new
   compatible macro `new-macro`. Please adjust commands yourself as necessary.
   You don't have to do it in the smartest way, of course. Slow and steady
   wins the race.

   ```vim
   :cexpr g:laurel_deprecated " Reset Quickfix list.
   :packadd cfilter " Enable builtin cfilter. `:h :Cfilter` for the details.
   :Cfilter /old-macro/ " Pick up related detections.
   :cfdo! %s/(old-macro /(new-macro /gec " Roughly update macro names.
   :cfdo update
   ```

2. Nowadays, your vimrcs are supposed to be under git control...

   ```vim
   :cd ~/.config/nvim " Make sure current directory is in your config repository.
   :!git reset --mixed HEAD
   :cfdo !git add %
   :!git commit -m 'refactor(laurel): update macros'
   ```

## Changelog

<!-- panvimdoc-ignore-start -->

See [CHANGELOG.md](../CHANGELOG.md), including the previous breaking changes.

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
See [CHANGELOG.md](../CHANGELOG.md),
or https://github.com/aileot/nvim-laurel/blob/main/CHANGELOG.md
-->

[`augroup!`]: #augroup
[`autocmd!`]: #autocmd
[`au!`]: #au
[`map!`]: #map
[`command!`]: #command
[`highlight!`]: #highlight
[`hi!`]: #hi
[-u]: https://neovim.io/doc/user/starting.html#-u
[Quickfix]: https://neovim.io/doc/user/quickfix.html
[`:cdo`]: https://neovim.io/doc/user/quickfix.html#%3Acdo
[`:cfdo`]: https://neovim.io/doc/user/quickfix.html#%3Acfdo
[`:cfirst`]: https://neovim.io/doc/user/quickfix.html#%3Acfirst
[`:cnext`]: https://neovim.io/doc/user/quickfix.html#%3Acnext
[`:global`]: https://neovim.io/doc/user/quickfix.html#%3Aglobal
[`:substitute`]: https://neovim.io/doc/user/quickfix.html#%3Asubstitute
[`:normal`]: https://neovim.io/doc/user/quickfix.html#%3Anormal
[`q`]: https://neovim.io/doc/user/repeat.html#q
[`@`]: https://neovim.io/doc/user/repeat.html#%40
[`Q`]: https://neovim.io/doc/user/repeat.html#Q
[semver]: https://semver.org/spec/v2.0.0.html
