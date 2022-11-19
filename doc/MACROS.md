# nvim-laurel macros

- [CAUTION](#CAUTION)
- [Terminology](#Terminology)
- [Macros](#Macros)
- [Anti-Patterns](#Anti-Patterns)

## CAUTION

Each macro might be more flexible than documented, but of course, undocumented
usages are subject to change without notifications.

## Terminology

### lhs

An abbreviation of left-hand-side.

### rhs

An abbreviation of right-hand-side.

### #({expr})

Hash function, where `$1` through `$9` and `$...` are available as the argument.
`$` is an alias for `$1`. See the
[reference](https://fennel-lang.org/reference#hash-function-literal-shorthand)
for the detail.

### sequence

An alias of sequential table `[]`.

### kv-table

An alias of key/value table `{}`.

### bare-{type}

It describes the `{type}` value must be neither symbol nor list in compile time.
For example,

- `:foobar` is a `bare-string`.
- `(.. :foo :bar)` is not a `bare-string`.
- `[:foo :bar]` is a `bare-sequence` and also a `bare-string[]`.
- `[baz]` where `baz` is either symbol or list is a `bare-sequence`, but not a
  `bare-string[]`.
- `(icollect [_ val (ipairs [:foo :bar])] val)` is neither a `bare-sequence` nor
  `bare-string[]`.

### ?{name}

`{name}` is omittable.

### api-opts

It is kv-table `{}` option for the api functions, `vim.api.nvim_foo`. Unless
otherwise noted, this option has the following features:

- It only accepts the same key/value described in `api.txt`.
- Its values have the highest priority over those set in the other arguments if
  conflicted.

### extra-opts

An alternative form for `api-opts`. Unless otherwise noted, this option has the
following features:

- It is bare-sequence `[]`, but is interpreted as if kv-table `{}` in the
  following manner:
  - Items for keys **must** be bare-strings; items for values can be of any
    type.
  - Boolean key/value for `api-opts` is set to `true` by key itself; the other
    keys expects the next items as their values respectively.
  - To set `false` to boolean key/value, set it in `api-opts` instead.
- It is intended as shorthand; for complicated usage, use `api-opts` instead or
  use them together.
- It could accept some additional keys which are unavailable in `api-opts`.

## Macros

- [Autocmd](#Autocmd)
- [Option](#Option)
- [Variable](#Variable)
- [Keymap](#Keymap)
- [Others](#Others)

### Autocmd

- [`augroup!`](#augroup)
- [`augroup+`](#augroup-1)
- [`autocmd!`](#autocmd)
- [`au!`](#au)

#### `augroup!`

Create or get an augroup, or override an existing augroup.

```fennel
(augroup! name) ; Only this format returns the augroup id.
(augroup! name
  [events ?pattern ?extra-opts callback ?api-opts]
  ...)
(augroup! name
  ;; Wrap args in `autocmd!` or `au!` instead of brackets.
  (autocmd! events ?pattern ?extra-opts callback ?api-opts)
  ...)
```

- `name`: (string) The name of autocmd group.
- `events`: (string|string[]) The event or events to register this autocmd.
- `?pattern`: (bare-sequence) Patterns to match against. To set `pattern` in
  symbol or list, set it in either `extra-opts` or `api-opts` instead. The first
  pattern in string cannot be any of the keys used in `?extra-opts`.
- [`?extra-opts`](#extra-opts): (bare-sequence) Additional option:
  - `<buffer>`: Create autocmd to current buffer by itself.
  - `<command>`: It indicates that `callback` must be Ex command by itself.
  - `ex`: An alias of `<command>` key.
  - `<callback>`: It indicates that `callback` must be callback function by
    itself.
  - `cb`: An alias of `<callback>` key.
- `callback`: (string|function) Set either callback function or vim Ex command.
  Symbol, and anonymous function constructed by `fn`, `hashfn`, `lambda`, and
  `partial`, is regared as Lua function; otherwise, as Ex command.

  Note: Insert `<command>` key in `extra-opts` to set string via symbol.

  Note: Set `vim.fn.foobar`, or set `:foobar` to `callback` with `<command>` key
  in `extra-opts`, to call Vim script function `foobar` without table arg from
  `nvim_create_autocmd`; instead, set `#(vim.fn.foobar $)` to call `foobar` with
  the table arg.
- [`?api-opts`](#api-opts): (kv-table) `:h nvim_create_autocmd`.

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

c.f. [`augroup+`](#augroup-1), [`autocmd!`](#autocmd)

#### `augroup+`

Create or get an augroup. This macro also lets us add `autocmd`s in an existing
`augroup` without clearing `autocmd`s already defined there.

```fennel
(augroup+ name) ; This format returns existing augroup id.
(augroup+ name
  [events ?pattern ?extra-opts callback ?api-opts]
  ...)
(augroup+ name
  (autocmd! events ?pattern ?extra-opts callback ?api-opts)
  ...)
```

c.f. [`augroup!`](#augroup), [`autocmd!`](#autocmd)

#### `autocmd!`

Create an autocmd.

```fennel
(autocmd! events api-opts) ; Just as an alias of `nvim_create_autocmd`.
(autocmd! name-or-id events ?pattern ?extra-opts callback ?api-opts)
```

- `name-or-id`: (string|integer|nil) The autocmd group name or id to match
  against. It is necessary unlike `vim.api.nvim_create_autocmd` unless this
  `autocmd!` macro is within either `augroup!` or `augroup+`. Set it to `nil` to
  define `autocmd`s affiliated with no augroup.

See [`augroup!`](#augroup) for the rest.

#### `au!`

An alias of [`autocmd!`](#autocmd).

### Option

- [`set!`](#set)
- [`set+`](#set-1)
- [`set-`](#set-)
- [`set^`](#set-2)
- [`setglobal!`](#setglobal)
- [`setglobal+`](#setglobal-1)
- [`setglobal-`](#setglobal-)
- [`setglobal^`](#setglobal-2)
- [`setlocal!`](#setlocal)
- [`setlocal+`](#setlocal-1)
- [`setlocal-`](#setlocal-)
- [`setlocal^`](#setlocal-2)

#### `set!`

Set value to the option. Almost equivalent to `:set` in Vim script.

```fennel
(set! name-?flag ?val)
```

- `name-?flag`: (string) Option name. As long as the option name is bare-string,
  i.e., neither symbol nor list, this macro has two advantages:

  1. A flag can be appended to the option name. Append `+`, `^`, or `-`, to
     append, prepend, or remove, values respectively.
  2. Option name is case-insensitive. You can improve readability a bit with
     camelCase/PascalCase. Since `:h {option}` is also case-insensitive,
     `(setlocal! :keywordPrg ":help")` for fennel still makes sense.

- `?val`: (boolean|number|string|table) New option value. If not provided, the
  value is supposed to be `true` (experimental).

```fennel
(set! :number true)
(set! :formatOptions [:1 :2 :c :B])
(set! :completeOpt [:menu :menuone :noselect])
(set! :listChars {:space :_ :tab: ">~"})

(set! :colorColumn+ :+1)
(set! :rtp^ [:/path/to/another/dir])

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
vim.go.completeopt = ["menu", "menuone", "noselect"]
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

Note: This macro has no support for either symbol or list with any flag at
option name; instead, use `set+`, `set^`, or `set-`, respectively for such
usage:

```fennel
;; Invalid usage!
(let [opt :formatoptions+]
  (set! opt [:1 :B]))
;; Use the corresponding macro instead.
(let [opt :formatoptions]
  (set+ opt [:1 :B]))
```

#### `set+`

Append a value to string-style options. Almost equivalent to
`:set {option}+={value}` in Vim script.

```fennel
(set+ name val)
```

#### `set-`

Remove a value from string-style options. Almost equivalent to
`:set {option}-={value}` in Vim script.

```fennel
(set- name val)
```

#### `set^`

Prepend a value to string-style options. Almost equivalent to
`:set {option}^={value}` in Vim script.

```fennel
(set^ name val)
```

#### `setglobal!`

Set global value to the option. Almost equivalent to `:setglobal` in Vim script.

```fennel
(setglobal! name-?flag ?val)
```

See [`set!`](#set) for the details.

#### `setglobal+`

Append a value to string-style global options. Almost equivalent to
`:setglobal {option}+={value}` in Vim script.

```fennel
(setglobal+ name val)
```

- name: (string) Option name.
- val: (string) Additional option value.

#### `setglobal-`

Remove a value from string-style global options. Almost equivalent to
`:setglobal {option}-={value}` in Vim script.

```fennel
(setglobal- name val)
```

#### `setglobal^`

Prepend a value from string-style global options. Almost equivalent to
`:setglobal {option}^={value}` in Vim script.

```fennel
(setglobal^ name val)
```

#### `setlocal!`

Set local value to the option. Almost equivalent to `:setlocal` in Vim script.

```fennel
(setlocal! name-?flag ?val)
```

See [`set!`](#set) for the details.

#### `setlocal+`

Append a value to string-style local options. Almost equivalent to
`:setlocal {option}+={value}` in Vim script.

```fennel
(setlocal+ name val)
```

#### `setlocal-`

Remove a value from string-style local options. Almost equivalent to
`:setlocal {option}-={value}` in Vim script.

```fennel
(setlocal- name val)
```

#### `setlocal^`

Prepend a value to string-style local options. Almost equivalent to
`:setlocal {option}^={value}` in Vim script.

```fennel
(setlocal^ name val)
```

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

Set buffer-scoped (`b:`) variable for the current buffer. Can be indexed with an
integer to access variables for specific buffer.

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

Set window-scoped (`w:`) variable for the current window. Can be indexed with an
integer to access variables for specific window.

```fennel
(w! ?id name val)
```

- `?id`: (integer) Window handle, or 0 for current window.
- `name`: (string) Variable name.
- `val`: (any) Variable value.

#### `t!`

Set tabpage-scoped (`t:`) variable for the current tabpage. Can be indexed with
an integer to access variables for specific tabpage.

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

### Keymap

- [`map!`](#map)
- [`noremap!`](#noremap)
- [`unmap!`](#unmap)
- [`<Cmd>`](#Cmd)
- [`<C-u>`](#C-u)
- [`map-all!`](#map-all)
- [`map-input!`](#map-input)
- [`map-motion!`](#map-motion)
- [`map-operator!`](#map-operator)
- [`map-textobj!`](#map-textobj)
- [`nmap!`](#nmap)
- [`vmap!`](#vmap)
- [`xmap!`](#xmap)
- [`smap!`](#smap)
- [`omap!`](#omap)
- [`imap!`](#imap)
- [`lmap!`](#lmap)
- [`cmap!`](#cmap)
- [`tmap!`](#tmap)
- [`noremap-all!`](#noremap-all)
- [`noremap-input!`](#noremap-input)
- [`noremap-motion!`](#noremap-motion)
- [`noremap-operator!`](#noremap-operator)
- [`noremap-textobj!`](#noremap-textobj)
- [`nnoremap!`](#nnoremap)
- [`vnoremap!`](#vnoremap)
- [`xnoremap!`](#xnoremap)
- [`snoremap!`](#snoremap)
- [`onoremap!`](#onoremap)
- [`inoremap!`](#inoremap)
- [`lnoremap!`](#lnoremap)
- [`cnoremap!`](#cnoremap)
- [`tnoremap!`](#tnoremap)

#### `map!`

Map `lhs` to `rhs` in `modes` recursively.

```fennel
(map! modes ?extra-opts lhs rhs ?api-opts)
(map! modes lhs ?extra-opts rhs ?api-opts)
```

- `modes`: (string|string[]) Mode short-name (map command prefix: "n", "i", "v",
  "x", …) or "!" for `:map!`, or empty string for `:map`.
- [`?extra-opts`](#extra-opts): (bare-sequence) Additional option:
  - `literal`: Disable `replace_keycodes`, which is automatically enabled when
    `expr` is set in `extra-opts`.
  - `<buffer>`: Map `lhs` in current buffer by itself.
  - `buffer`: Map `lhs` to a buffer of the next value.
  - `<command>`: It indicates that `rhs` must be Normal mode command execution
    by itself.
  - `ex`: An alias of `<command>` key.
  - `<callback>`: It indicates that `rhs` must be callback function by itself.
  - `cb`: An alias of `<callback>` key.
- `lhs`: (string) Left-hand-side of the mapping.
- `rhs`: (string|function) Right-hand-side of the mapping. Symbol, and anonymous
  function constructed by `fn`, `hashfn`, `lambda`, and `partial`, is regared as
  Lua function; otherwise, as Normal mode command execution.

  Note: Insert `<command>` key in `extra-opts` to set string via symbol.
- [`?api-opts`](#api-opts): (kv-table) `:h nvim_set_keymap`.

#### `noremap!`

Map `lhs` to `rhs` in `modes` non-recursively.

```fennel
(noremap! modes ?extra-opts lhs rhs ?api-opts)
(noremap! modes lhs ?extra-opts rhs ?api-opts)
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

#### `map-all!`

Map `lhs` to `rhs` in all modes recursively.

```fennel
(map-all! ?extra-opts rhs ?api-opts)
(map-all! lhs ?extra-opts rhs ?api-opts)
```

#### `map-input!`

Map `lhs` to `rhs` in Insert/Command-line mode recursively.

```fennel
(map-input! ?extra-opts lhs rhs ?api-opts)
(map-input! lhs ?extra-opts rhs ?api-opts)
```

#### `map-motion!`

Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode recursively. As long
as `lhs` is bare-string and doesn't include any invisible keys like `<Plug>`,
`<Esc>`, `<Left>`, `<C-f>`, and so on, it also map `lhs` to `rhs` in Select
mode.

```fennel
(map-motion! ?extra-opts lhs rhs ?api-opts)
(map-motion! lhs ?extra-opts rhs ?api-opts)
```

Note: This macro could delete mapping to `lhs` in Select mode for the
performance. To avoid this, use `(map! [:n :o :x] ...)` instead.

#### `map-operator!`

Map `lhs` to `rhs` in Normal/Visual mode recursively.

```fennel
(map-operator! ?extra-opts lhs rhs ?api-opts)
(map-operator! lhs ?extra-opts rhs ?api-opts)
```

#### `map-textobj!`

Map `lhs` to `rhs` in Visual/Operator-pending mode recursively.

```fennel
(map-textobj! ?extra-opts lhs rhs ?api-opts)
(map-textobj! lhs ?extra-opts rhs ?api-opts)
```

#### `nmap!`

Map `lhs` to `rhs` in Normal mode recursively.

```fennel
(nmap! ?extra-opts lhs rhs ?api-opts)
(nmap! lhs ?extra-opts rhs ?api-opts)
```

#### `vmap!`

Map `lhs` to `rhs` in Visual/Select mode recursively.

```fennel
(vmap! ?extra-opts lhs rhs ?api-opts)
(vmap! lhs ?extra-opts rhs ?api-opts)
```

#### `xmap!`

Map `lhs` to `rhs` in Visual mode recursively.

```fennel
(xmap! ?extra-opts lhs rhs ?api-opts)
(xmap! lhs ?extra-opts rhs ?api-opts)
```

#### `smap!`

Map `lhs` to `rhs` in Select mode recursively.

```fennel
(smap! ?extra-opts lhs rhs ?api-opts)
(smap! lhs ?extra-opts rhs ?api-opts)
```

#### `omap!`

Map `lhs` to `rhs` in Operator-pending mode recursively.

```fennel
(omap! ?extra-opts lhs rhs ?api-opts)
(omap! lhs ?extra-opts rhs ?api-opts)
```

#### `imap!`

Map `lhs` to `rhs` in Insert mode recursively.

```fennel
(imap! ?extra-opts lhs rhs ?api-opts)
(imap! lhs ?extra-opts rhs ?api-opts)
```

#### `lmap!`

Map `lhs` to `rhs` in Insert/Command-line mode, etc., recursively.
`:h language-mapping` for the details.

```fennel
(lmap! ?extra-opts lhs rhs ?api-opts)
(lmap! lhs ?extra-opts rhs ?api-opts)
```

#### `cmap!`

Map `lhs` to `rhs` in Command-line mode recursively.

```fennel
(cmap! ?extra-opts lhs rhs ?api-opts)
(cmap! lhs ?extra-opts rhs ?api-opts)
```

#### `tmap!`

Map `lhs` to `rhs` in Terminal mode recursively.

```fennel
(tmap! ?extra-opts lhs rhs ?api-opts)
(tmap! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-all!`

Same as [`map-all!`](#map-all), but non-recursively.

```fennel
(noremap-all! ?extra-opts lhs rhs ?api-opts)
(noremap-all! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-input!`

Same as [`map-input!`](#map-input), but non-recursively.

```fennel
(noremap-input! ?extra-opts lhs rhs ?api-opts)
(noremap-input! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-motion!`

Same as [`map-motion!`](#map-motion), but non-recursively.

```fennel
(noremap-motion! ?extra-opts lhs rhs ?api-opts)
(noremap-motion! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-operator!`

Same as [`map-operator!`](#map-operator), but non-recursively.

```fennel
(noremap-operator! ?extra-opts lhs rhs ?api-opts)
(noremap-operator! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-textobj!`

Same as [`map-textobj!`](#map-textobj), but non-recursively.

```fennel
(noremap-textobj! ?extra-opts lhs rhs ?api-opts)
(noremap-textobj! lhs ?extra-opts rhs ?api-opts)
```

#### `nnoremap!`

Same as [`nmap!`](#nmap!), but non-recursively.

```fennel
(nnoremap! ?extra-opts lhs rhs ?api-opts)
(nnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `vnoremap!`

Same as [`vmap!`](#vmap!), but non-recursively.

```fennel
(vnoremap! ?extra-opts lhs rhs ?api-opts)
(vnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `xnoremap!`

Same as [`xmap!`](#xmap), but non-recursively.

```fennel
(xnoremap! ?extra-opts lhs rhs ?api-opts)
(xnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `snoremap!`

Same as [`smap!`](#smap), but non-recursively.

```fennel
(snoremap! ?extra-opts lhs rhs ?api-opts)
(snoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `onoremap!`

Same as [`omap!`](#omap), but non-recursively.

```fennel
(onoremap! ?extra-opts lhs rhs ?api-opts)
(onoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `inoremap!`

Same as [`imap!`](#imap), but non-recursively.

```fennel
(inoremap! ?extra-opts lhs rhs ?api-opts)
(inoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `lnoremap!`

Same as [`lmap!`](#lmap), but non-recursively.

```fennel
(lnoremap! ?extra-opts lhs rhs ?api-opts)
(lnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `cnoremap!`

Same as [`cmap!`](#cmap), but non-recursively.

```fennel
(cnoremap! ?extra-opts lhs rhs ?api-opts)
(cnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `tnoremap!`

Same as [`tmap!`](#tmap), but non-recursively.

```fennel
(tnoremap! ?extra-opts lhs rhs ?api-opts)
(tnoremap! lhs ?extra-opts rhs ?api-opts)
```

### Others

- [`command!`](#command)
- [`feedkeys!`](#feedkeys)
- [`highlight!`](#highlight)
- [`hi!`](#hi)

#### `command!`

Create a user command.

```fennel
(command! ?extra-opts name command ?api-opts)
(command! name ?extra-opts command ?api-opts)
```

- [`?extra-opts`](#extra-opts): (bare-sequence) Optional command attributes.
  Additional attributes:
  - `<buffer>`: Create command in current buffer by itself.
  - `buffer`: Create command in the buffer of the next value.
- `name`: (string) Name of the new user command. It must begin with an uppercase
  letter.
- `command`: (string|function) Replacement command.
- [`?api-opts`](#api-opts): (kv-table) Optional command attributes. The same as
  `opts` for `nvim_create_user_command`.

```fennel
(command! :SayHello
          [:bang]
          "echo 'Hello world!'"
          {:desc "Say Hello!"})
(command! :Salute
          [:bar :<buffer> :desc "Salute!"]
          #(print "Hello world!"))
```

is equivalent to

```vim
command! -bang SayHello echo 'Hello world!'
command! -bar -buffer Salute echo 'Hello world!'
```

```lua
vim.api.nvim_create_user_command("SayHello", "echo 'Hello world!'", {
                                       bang = true,
                                       desc = "Say Hello!",
                                       })
vim.api.nvim_buf_create_user_command(0, "Salute", function()
                               print("Hello world!")
                             end, {
                             bar = true,
                             desc = "Salute!"
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

```fennel
(highlight! ?ns-id name val)
```

```fennel
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :ctermfg 103 :cterm {:bold true :italic}})
;; or
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :cterm {:fg 103 :bold true :italic}})
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

## Anti-Patterns

### [`autocmd!`](#autocmd)

#### `pcall` in the end of callback

It could be an unexpected behavior that `autocmd` whose callback ends with
`pcall` is executed only once because of the combination:

- Fennel `list` returns the last value.
- `pcall` returns `true` when the call succeeds without errors.
- `nvim_create_autocmd` deletes itself when its callback function returns
  `true`.

##### Anti-Pattern

```fennel
(autocmd! group events #(pcall foobar))
(autocmd! group events (fn []
                         ;; Do something else
                         (pcall foobar)))
```

##### Pattern

```fennel
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
`nvim_create_autocmd`; on the other hand, `$` in any hash functions included in
another anonymous function is meaningless in many cases.

##### Anti-Pattern

```fennel
(autocmd! group events #(vim.schedule #(nnoremap [:buffer $.buf] :lhs :rhs)))
(autocmd! group events (fn []
                         (vim.schedule #(nnoremap [:buffer $.buf] :lhs :rhs))))
```

##### Pattern

```fennel
(autocmd! group events #(vim.schedule (fn []
                                        (nnoremap [:buffer $.buf] :lhs :rhs))))
```
