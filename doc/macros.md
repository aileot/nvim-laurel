# nvim-laurel macros

- [CAUTION](#CAUTION)
- [Terminology](#Terminology)
- [Macros](#Macros)

## CAUTION

Each macro might be more flexible than documented, but of course, undocumented
usages are subject to change without notifications.

## Terminology

### lhs

Abbreviation of left-hand-side.

### rhs

Abbreviation of right-hand-side.

### sequence

It is an alias of sequential table `[]`.

### kv-table

It is an alias of key/value table `{}`.

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

### ex-{name}

A special symbol name. With prefix `ex-`, some of nvim-laurel macros in compile
time can tell that the named symbol will result in a string of vim Ex command in
runtime.

## Macros

- [Autocmd](#Autocmd)
- [Option](#Option)
- [Keymap](#Keymap)
- [Others](#Others)

### Autocmd

- [`au!`](#au)
- [`augroup!`](#augroup)
- [`augroup+`](#augroup-1)
- [`autocmd!`](#autocmd)

#### `augroup!`

Define/Override an augroup.

```fennel
(augroup! name)
(augroup! name
  (autocmd! ...))
```

#### `augroup+`

Add `autocmd`s to an existing `augroup`.

```fennel
(augroup+ name
  (autocmd! ...))
```

#### `autocmd!`

Define an autocmd:

```fennel
(autocmd! events api-opts) ; Just as an alias of `nvim_create_autocmd`.
(autocmd! name-or-id events ?pattern ?extra-opts callback ?api-opts)
(augroup! name-or-id
  (autocmd! events ?pattern ?extra-opts callback ?api-opts))
```

- `name-or-id`: (string|integer|nil) The autocmd group name or id to match
  against. It is necessary unlike `vim.api.nvim_create_autocmd` unless this
  `autocmd!` macro is within either `augroup!` or `augroup+`. Set it to `nil` to
  define `autocmd`s affiliated with no augroup.
- `events`: (string|string[]) The event or events to register this autocmd.
- `?pattern`: (bare-string|bare-sequence) To set `pattern` in symbol or list,
  set it in either `extra-opts` or `api-opts` instead.
- [`?extra-opts`](#extra-opts): (bare-sequence) Additional option:
  - `<buffer>`: with this alone, create autocmd to current buffer.
- `callback`: (string|function) Set either vim Ex command or callback function.
  Any bare-string here is interpreted as vim Ex command; use `vim.fn` interface
  to set a Vim script function.
- [`?api-opts`](#api-opts): (kv-table) `:h nvim_create_autocmd`

```fennel
(augroup! :your-augroup
  (autocmd! :FileType [:fennel :lua :vim] #(simple-expr))
  (autocmd! [:InsertEnter :InsertLeave] [:<buffer>] "echo 'foo'")
  (autocmd! :BufRead [:pattern (.. dir "/" fname)] "Do something"))
  ;; Note: Within `augroup!`, `autocmd!` is just a syntax sugar macro for a sequence.
  [:VimEnter [:once :nested :desc "call vim autoload function"] #(vim.fn.foo#bar)])
```

is equivalent to

```vim
augroup your-augroup
  autocmd!
  autocmd FileType fennel,lua,vim " Anonymous function is unavailable in Vim script.
  autocmd InsertEnter,InsertLeave <buffer> echo 'foo'
  execute 'autocmd BufRead' dir . '/' . fname 'Do something'
  autocmd VimEnter * ++once ++nested call foo#bar()
augroup END
```

```lua
local id = vim.api.nvim_create_augroup('your-augroup')
vim.api.nvim_create_autocmd("FileType", {
  group = id,
  pattern = {"fennel", "lua", "vim"},
  callback = function()
      -- simple expr
  end,
})
vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave"}, {
  group = id,
  buffer = 0,
  command = "echo 'foo'",
})
vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave"}, {
  group = id,
  pattern = dir .. "/" .. fname,
  command = "Do something",
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = id,
  once = true,
  nested = true,
  desc = "call vim autoload function",
  callback = "foo#bar",
})
```

#### `au!`

An alias of `autocmd!`

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

- `name-?flag`: (string) Option name. As long as the option name is literal
  string, i.e., neither symbol nor list, this macro has two advantages:

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
(set! :listchars {:space :_ :tab: :>~})
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
set listchars=space:_,tab:>~
set colorcolumn+=+1
set rtp^=/path/to/another/dir

let val = 'yes'
let &signcolumn = val
let opt = 'wrap'
execute 'set no' opt
```

```lua
vim.api.nvim_set_option_value("number", true)
vim.api.nvim_set_option_value("signcolumn", "yes")
vim.api.nvim_set_option_value("formatoptions", "12cB")
vim.api.nvim_set_option_value("listchars", "space:_,tab:>~")
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
(map! modes lhs ?extra-opts rhs ?api-opts)
```

- `modes`: (string|string[]) Mode short-name (map command prefix: "n", "i", "v",
  "x", …) or "!" for `:map!`, or empty string for `:map`.
- [`?extra-opts`](#extra-opts): (bare-sequence) Additional option:
  - `<buffer>`: map `lhs` in current buffer.
  - `buffer`: map `lhs` to a buffer of the next value.
- `lhs`: (string) Left-hand-side of the mapping.
- `rhs`: (string|function) Right-hand-side of the mapping. Set a string, or
  prefix `ex-` to a symbol name, to set Ex command for `rhs`; otherwise, it is
  regarded as a function.
- [`?api-opts`](#api-opts): (kv-table) `:h nvim_set_keymap`.

#### `noremap!`

Map `lhs` to `rhs` in `modes` non-recursively.

```fennel
(noremap! modes lhs ?extra-opts rhs ?api-opts)
```

#### `unmap!`

Delete keymap.

```fennel
(unmap! ?bufnr mode lhs).
```

- `?bufnr`: (number) Optional buffer handle, or 0 for current buffer.
- `mode`: (string) mode to unmap.
- `lhs`: (string) left-hand-side key to unmap.

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
(map-all! lhs ?extra-opts rhs ?api-opts)
```

#### `map-input!`

Map `lhs` to `rhs` in Insert/Command-line mode recursively.

```fennel
(map-input! lhs ?extra-opts rhs ?api-opts)
```

#### `map-motion!`

Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode recursively.

```fennel
(map-motion! lhs ?extra-opts rhs ?api-opts)
```

Note: This macro deletes mapping to `lhs` in Select mode for the performance. To
avoid this, use `(map! [:n :o :x] ...)` instead.

#### `map-operator!`

Map `lhs` to `rhs` in Normal/Visual mode recursively.

```fennel
(map-operator! lhs ?extra-opts rhs ?api-opts)
```

#### `map-textobj!`

Map `lhs` to `rhs` in Visual/Operator-pending mode recursively.

```fennel
(map-textobj! lhs ?extra-opts rhs ?api-opts)
```

#### `nmap!`

Map `lhs` to `rhs` in Normal mode recursively.

```fennel
(nmap! lhs ?extra-opts rhs ?api-opts)
```

#### `vmap!`

Map `lhs` to `rhs` in Visual/Select mode recursively.

```fennel
(vmap! lhs ?extra-opts rhs ?api-opts)
```

#### `xmap!`

Map `lhs` to `rhs` in Visual mode recursively.

```fennel
(xmap! lhs ?extra-opts rhs ?api-opts)
```

#### `smap!`

Map `lhs` to `rhs` in Select mode recursively.

```fennel
(smap! lhs ?extra-opts rhs ?api-opts)
```

#### `omap!`

Map `lhs` to `rhs` in Operator-pending mode recursively.

```fennel
(omap! lhs ?extra-opts rhs ?api-opts)
```

#### `imap!`

Map `lhs` to `rhs` in Insert mode recursively.

```fennel
(imap! lhs ?extra-opts rhs ?api-opts)
```

#### `lmap!`

Map `lhs` to `rhs` in Insert/Command-line mode, etc., recursively.
`:h language-mapping` for the details.

```fennel
(lmap! lhs ?extra-opts rhs ?api-opts)
```

#### `cmap!`

Map `lhs` to `rhs` in Command-line mode recursively.

```fennel
(cmap! lhs ?extra-opts rhs ?api-opts)
```

#### `tmap!`

Map `lhs` to `rhs` in Terminal mode recursively.

```fennel
(tmap! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-all!`

Map `lhs` to `rhs` in all modes non-recursively.

```fennel
(noremap-all! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-input!`

Map `lhs` to `rhs` in Insert/Command-line mode non-recursively.

```fennel
(noremap-input! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-motion!`

Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode non-recursively.

```fennel
(noremap-motion! lhs ?extra-opts rhs ?api-opts)
```

Note: This macro deletes mapping to `lhs` in Select mode for the performance. To
avoid this, use `(noremap! [:n :o :x] ...)` instead.

#### `noremap-operator!`

Map `lhs` to `rhs` in Normal/Visual mode non-recursively.

```fennel
(noremap-operator! lhs ?extra-opts rhs ?api-opts)
```

#### `noremap-textobj!`

Map `lhs` to `rhs` in Visual/Operator-pending mode non-recursively.

```fennel
(noremap-textobj! lhs ?extra-opts rhs ?api-opts)
```

#### `nnoremap!`

Map `lhs` to `rhs` in Normal mode non-recursively.

```fennel
(nnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `vnoremap!`

Map `lhs` to `rhs` in Visual/Select mode non-recursively.

```fennel
(vnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `xnoremap!`

Map `lhs` to `rhs` in Visual mode non-recursively.

```fennel
(xnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `snoremap!`

Map `lhs` to `rhs` in Select mode non-recursively.

```fennel
(snoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `onoremap!`

Map `lhs` to `rhs` in Operator-pending mode non-recursively.

```fennel
(onoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `inoremap!`

Map `lhs` to `rhs` in Insert mode non-recursively.

```fennel
(inoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `lnoremap!`

Map `lhs` to `rhs` in Insert/Command-line mode, etc., non-recursively.
`:h language-mapping` for the details.

```fennel
(lnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `cnoremap!`

Map `lhs` to `rhs` in Command-line mode non-recursively.

```fennel
(cnoremap! lhs ?extra-opts rhs ?api-opts)
```

#### `tnoremap!`

Map `lhs` to `rhs` in Terminal mode non-recursively.

```fennel
(tnoremap! lhs ?extra-opts rhs ?api-opts)
```

### Others

- [`command!`](#command)
- [`feedkeys!`](#feedkeys)
- [`highlight!`](#highlight)
- [`hi!`](#hi)

#### `command!`

Define a user command.

```fennel
(command! name ?extra-opts command ?api-opts)
```

- `name`: (string) Name of the new user command. It must begin with an uppercase
  letter.
- [`?extra-opts`](#extra-opts): (bare-sequence) Optional command attributes.
  Additional attributes:
  - `<buffer>`: with this alone, command is set in current buffer.
  - `buffer`: with the next value, command is set to the buffer.
- `command`: (string|function) Replacement command.
- [`?api-opts`](#api-opts): (kv-table) Optional command attributes. The same as
  `opts` for `nvim_create_user_command`.

```fennel
(command! :SayHello
          "echo 'Hello world!'"
          {:bang true :desc "Hello world!"})
(command! :Salute
          [:bar :<buffer> :desc "Say Hello!"]
          #(print "Salute!")
```

is equivalent to

```vim
command! -bang SayHello echo 'Hello world!'
command! -bar -buffer Salute " Anonymous function is unavailable.
```

```lua
nvim_create_user_command("SayHello", "echo 'Hello world!'", {
                                       bang = true,
                                       desc = "Hello world!",
                                       })
nvim_buf_create_user_command(0, "Salute", function()
                               print("Hello world!")
                             end, {
                             bar = true,
                             desc = "Say Hello!"
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
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :ctermfg 103 :cterm {:bold true :italic})
;; or
(highlight! :Foo {:fg "#8d9eb2" :bold true :italic true :cterm {:fg 103 :bold true :italic})
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

An alias of `highlight!`
