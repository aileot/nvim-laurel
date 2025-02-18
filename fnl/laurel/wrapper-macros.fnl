;; fennel-ls: macro-file

;; A set of wrapper macros.
;; The definitions also serve as practical examples to the end-users.

(local {: augroup! : let! : map!} (require :laurel.macros))

(λ augroup+ [...]
  "Define augroup without clearing it.
```fennel
(augroup+ name ...)
```
@param group string The augroup name.
@param ... list Parameters for `autocmd!`."
  (augroup! `&default-opts
    {:clear false}
    ...))

(λ set! [...]
  "Set Vim option value.
This changes the value of current buffer, and also the global one as
`vim.opt.foobar` does.
```fennel
(set! name ?flag val)
```
@param name string Vim option name.
@param ?flag `+`|`-`|`^`|nil (optional) flag to append, prepend, or remove, value to the option respectively.
@param val any New option value."
  (let! :opt ...))

(λ setlocal! [...]
  "Set Vim local option value as `vim.opt_local.foobar` does with fewer
overheads.
```fennel
(setlocal! name ?flag val)
```
@param name string Vim option name.
@param ?flag `+`|`-`|`^`|nil (optional) flag to append, prepend, or remove, value to the option respectively.
@param val any New option value."
  (let! :opt_local ...))

(λ setglobal! [...]
  "Set Vim global option value as `vim.opt_global.foobar` does with fewer
overheads.
```fennel
(setglobal! name ?flag val)
```
@param name string Vim option name.
@param ?flag `+`|`-`|`^`|nil (optional) flag to append, prepend, or remove, value to the option respectively.
@param val any New option value."
  (let! :opt_global ...))

(λ bo! [...]
  "Set Vim buffer-local option value as `vim.bo.foobar` does with fewer
overheads.
```fennel
(bo! ?id name ?flag val)
```
@param ?id number Buffer handle
@param name string Vim option name.
@param ?flag `+`|`-`|`^`|nil (optional) flag to append, prepend, or remove, value to the option respectively.
@param val any New option value."
  (let! :bo ...))

(λ wo! [...]
  "Set Vim window-local option value as `vim.wo.foobar` does with fewer
overheads.
```fennel
(wo! ?id name ?flag val)
```
@param ?id number Window handle
@param name string Vim option name.
@param ?flag`+`|`-`|`^`|nil (optional) flag to append, prepend, or remove, value to the option respectively.
@param val any New option value."
  (let! :wo ...))

(λ g! [name val]
  "Set global (`g:`) editor variable.
```fennel
(g! name val)
```
@param name string Variable name.
@param val any Variable value."
  (let! :g name val))

(λ b! [...]
  "Set buffer-scoped (`b:`) variable for the current buffer. Can be indexed
with an integer to access variables for specific buffer.
```fennel
(b! ?id name val)
```
@param ?id integer Buffer handle, or 0 for current buffer.
@param name string Variable name.
@param val any Variable value."
  (let! :b ...))

(λ w! [...]
  "Set window-scoped (`w:`) variable for the current window. Can be indexed
with an integer to access variables for specific window.
```fennel
(w! ?id name val)
```
@param ?id integer Window handle, or 0 for current window.
@param name string Variable name.
@param val any Variable value."
  (let! :w ...))

(λ t! [...]
  "Set tabpage-scoped (`t:`) variable for the current tabpage. Can be indexed
with an integer to access variables for specific tabpage.
```fennel
(t! ?id name val)
```
@param ?id integer Tabpage handle, or 0 for current tabpage.
@param name string Variable name.
@param val any Variable value."
  (let! :t ...))

(λ v! [name val]
  "Set `v:` variable if not readonly.
```fennel
(v! name val)
```
@param name string Variable name.
@param val any Variable value."
  (let! :v name val))

(λ env! [name val]
  "Set environment variable in the editor session.
```fennel
(env! name val)
```
@param name string Variable name. A bare-string can starts with `$` (ignored
internally), which helps `gf` jump to the path.
@param val any Variable value."
  (let! :env name val))

(λ set+ [name ...]
  "Append Vim option value.
This changes the value of current buffer, and also the global one as
`vim.opt.foobar:append` does.
```fennel
(set+ name val)
```
@param name string Vim option name.
@param val any New option value."
  (let! :opt name `+ ...))

(λ set- [name ...]
  "Remove value from the Vim option.
This changes the value of current buffer, and also the global one as
`vim.opt.foobar:remove` does.
```fennel
(set- name val)
```
@param name string Vim option name.
@param val any New option value."
  (let! :opt name `- ...))

(λ set^ [name ...]
  "Prepend Vim option value.
This changes the value of current buffer, and also the global one as
`vim.opt.foobar:prepend` does.
```fennel
(set^ name val)
```
@param name string Vim option name.
@param val any New option value."
  (let! :opt name `^ ...))

(λ remap! [...]
  "Map the key sequence `lhs` to `rhs` recursively, or map to Lua/Fennel
callback function.
```fennel
(remap! modes ?extra-opts lhs rhs ?api-opts)
(remap! modes lhs ?extra-opts rhs ?api-opts)
```
@param mode string|string[]
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! `&default-opts {:remap true} ...))

;; NOTE: Define keymap wrappers as the definition order as you can see in
;; vimdoc `:h :nmap`

(λ nmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Normal mode.
```fennel
(nmap! ?extra-opts lhs rhs ?api-opts)
(nmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :n ...))

(λ vmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel
callback function in Visual mode and Select mode.
```fennel
(vmap! ?extra-opts lhs rhs ?api-opts)
(vmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :v ...))

(λ xmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Visual mode.
```fennel
(xmap! ?extra-opts lhs rhs ?api-opts)
(xmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :x ...))

(λ smap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Select mode.
```fennel
(smap! ?extra-opts lhs rhs ?api-opts)
(smap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :s ...))

(λ imap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Normal mode.
```fennel
(imap! ?extra-opts lhs rhs ?api-opts)
(imap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :i ...))

(λ omap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Operator-pending mode.
```fennel
(omap! ?extra-opts lhs rhs ?api-opts)
(omap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :o ...))

(λ lmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  for language-mapping.
```fennel
(lmap! ?extra-opts lhs rhs ?api-opts)
(lmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :l ...))

(λ cmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Command-line mode.
```fennel
(cmap! ?extra-opts lhs rhs ?api-opts)
(cmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :c ...))

(λ tmap! [...]
  "Map the key sequence `lhs` to `rhs` or map to Lua/Fennel callback function
  in Terminal mode.
```fennel
(tmap! ?extra-opts lhs rhs ?api-opts)
(tmap! lhs ?extra-opts rhs ?api-opts)
```
@param ?extra-opts bare-sequence
@param lhs string
@param rhs string|function
@param ?api-opts kv-table"
  (map! :t ...))

{: augroup+
 : set!
 : setlocal!
 : setglobal!
 :go! setglobal!
 : bo!
 : wo!
 : g!
 : b!
 : w!
 : t!
 : v!
 : env!
 : set+
 : set-
 : set^
 : remap!
 : nmap!
 : vmap!
 : xmap!
 : smap!
 : omap!
 : imap!
 : lmap!
 : cmap!
 : tmap!}
