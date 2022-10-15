;; General Macros ///1
(macro ++ [x]
  "Increment `x` by 1"
  `(do
     (set ,x (+ 1 ,x))
     ,x))

;; General Utils ///1
(fn ->str [x]
  "Convert `x` to a string, or get the name if `x` is a symbol."
  (tostring x))

(lambda slice [xs ?first ?last ?step]
  (let [first (or ?first 1)
        last (or ?last (length xs))
        step (or ?step 1)]
    (fcollect [i first last step] ;
              (. xs i))))

;; Predicates ///2
(lambda contains? [xs ?a]
  "Check if `?a` is in `xs`."
  (accumulate [eq? false ;
               _ x (ipairs xs) ;
               &until eq?]
    (= ?a x)))

(fn nil? [x]
  "Check if value of 'x' is nil."
  (= nil x))

(fn str? [x]
  "Check if `x` is of string type."
  (= :string (type x)))

(fn num? [x]
  "Check if 'x' is of number type."
  (= :number (type x)))

(fn function? [x]
  "(Compile time) Check if type of `x` is function.
  Note: It cannot detect a function set in a symbol."
  (let [ref (?. x 1 1)]
    (contains? [:fn :hashfn :lambda :partial] ref)))

;; Specific Utils ///1
(lambda merge-default-kv-table [default another]
  (each [k v (pairs default)]
    (when (nil? (?. another :k))
      (tset another k v))))

;; cspell:word excmd
(lambda excmd? [cmd]
  "Check if is Ex command. A symbol prefixed by `ex-` must be Ex command."
  (or (str? cmd) ;
      (and (sym? cmd) ;
           (string.match (->str cmd) :^ex-))))

(lambda seq->kv-table [xs ?trues]
  "Convert `xs` into a kv-table.
  The value for `x` listed in `?trues` is set to `true`.
  The value for the rest of `x`s is set to the next value in `xs`."
  (let [kv-table {}
        max (length xs)]
    (var i 1)
    (while (<= i max)
      (let [x (. xs i)]
        (if (contains? ?trues x)
            (tset kv-table x true)
            (tset kv-table x (. xs (++ i)))))
      (++ i))
    kv-table))

;; Option ///1
(lambda option/concat-kv-table [kv-table]
  "Concat kv table into a string for `vim.api.nvim_set_option_value`.
  For example,
  `{:eob \" \" :fold \"-\"})` should be compiled to `\"eob: ,fold:-\"`"
  (assert-compile (table? kv-table)
                  (.. "Expected table, got " (type kv-table) "\ndump:\n"
                      (view kv-table)) ;
                  kv-table)
  (let [key-val (icollect [k v (pairs kv-table)]
                  (.. k ":" v))]
    (table.concat key-val ",")))

(lambda option/modify [scope name ?val ?flag]
  (let [name (if (str? name) (name:lower) name)
        interface (match scope
                    :local `vim.opt_local
                    :global `vim.opt_global
                    :general `vim.opt
                    _ (error (.. "Expected `local`, `global`, or `general`, got: "
                                 (view scope))))
        opt-obj `(. ,interface ,name)
        ?val (if (and (contains? [:formatoptions :shortmess] name)
                      ;; Convert sequence of table values into a sequence of
                      ;; letters; let us set them in sequential table.
                      (sequence? ?val))
                 (accumulate [str "" _ v (ipairs ?val)]
                   (do
                     (assert-compile (not (sym? v))
                                     (.. name " cannot include " (type v)
                                         " value")
                                     v)
                     (.. str v)))
                 ?val)]
    (if (nil? ?flag)
        (let [opts {:scope (if (= scope :general) nil scope)}]
          (if (sym? ?val)
              ;; Note: `set` is unavailable in compiler environment
              `(tset ,interface ,name ,?val)
              (sequence? ?val)
              `(vim.api.nvim_set_option_value ,name ,(table.concat ?val ",")
                                              ,opts)
              (table? ?val)
              `(vim.api.nvim_set_option_value ,name
                                              ,(option/concat-kv-table ?val)
                                              ,opts)
              `(vim.api.nvim_set_option_value ,name ,?val ,opts)))
        (match ?flag
          "+"
          `(: ,opt-obj :append ,?val)
          "^"
          `(: ,opt-obj :prepend ,?val)
          "-"
          `(: ,opt-obj :remove ,?val)
          "!"
          `(tset ,opt-obj (not (: ,opt-obj :get)))
          "<" ; Sync local option to global one.
          `(vim.api.nvim_set_option_value ,name ;
                                          (vim.api.nvim_get_option ,name)
                                          {:scope :local})
          ;; "&" `(vim.cmd.set (.. ,name "&"))
          _
          (error (.. "Invalid vim option modifier: " (view ?flag)))))))

(lambda option/extract-flag [name-?flag]
  (let [?flag (: name-?flag :match "[^a-zA-Z]")
        name (if ?flag (: name-?flag :match "[a-zA-Z]+") name-?flag)]
    [name ?flag]))

(lambda option/set [scope name-?flag ?val]
  (let [[name ?flag] (if (str? name-?flag)
                         (option/extract-flag name-?flag)
                         [name-?flag nil])
        ?val (if (nil? ?val) true ?val)]
    (option/modify scope name ?val ?flag)))

;; Export ///2
(lambda set! [name-?flag ?val]
  "Set value to the option.
  Almost equivalent to `:set` in Vim script.

  ```fennel
  (set! name-?flag ?val)
  ```

  - name-?flag: (string) Option name.
    As long as the option name is literal string, i.e., neither symbol nor list,
    this macro has two advantages:

    1. A flag can be appended to the option name. Append `+`, `^`, or `-`,
       to append, prepend, or remove values, respectively.
    2. Option name is case-insensitive. You can improve readability a bit with
       camelCase/PascalCase. Since `:h {option}` is also case-insensitive,
       `(setlocal! :keywordPrg \":help\")` for fennel still makes sense.

  - ?val: (boolean|number|string|table) New option value.
    If not provided, the value is supposed to be `true` (experimental).
    This macro is expanding to `(vim.api.nvim_set_option_value name val)`;
    however, when the value is set in either symbol or list,
    this macro is expanding to `(tset vim.opt name val)` instead.

  ```fennel
  (set! :number true)
  (set! :formatOptions [:1 :2 :c :B])
  (set! :listchars {:space :_ :tab: :>~})
  (set! :colorColumn+ :+1)
  (set! :rtp^ [:/path/to/another/vimrc])

  (local val :yes)
  (set! :signColumn val)
  (local opt :wrap)
  (set! opt false)
  ```

  is equivalent to

  ```lua
  vim.api.nvim_set_option_value(\"number\", true)
  vim.api.nvim_set_option_value(\"signcolumn\", \"yes\")
  vim.api.nvim_set_option_value(\".formatoptions\", \"12cB\")
  vim.api.nvim_set_option_value(\"listchars\", \"space:_,tab:>~\")
  vim.opt_global.colorcolumn:append(\"+1\")
  vim.opt_global.rtp:prepend(\"/path/to/another/vimrc\")

  local val = \"yes\"
  vim.opt.signcolumn = val
  local opt = \"wrap\"
  vim.opt[opt] = false
  ```

  Note: There is no plan to support option prefix either `no` or `inv`; instead,
  set `false` or `(not vim.go.foo)` respectively.

  Note: This macro has no support for either symbol or list with any flag
  at option name; instead, use `set+`, `set^`, or `set-`, respectively for such
  usage:

  ```fennel
  ;; Invalid usage!
  (let [opt :formatOptions+]
    (set! opt [:1 :B]))
  ;; Use the corresponding macro instead.
  (let [opt :formatOptions]
    (set+ opt [:1 :B]))
  ```"
  (option/set :general name-?flag ?val))

(lambda setlocal! [name-?flag ?val]
  "Set local value to the option.
  Almost equivalent to `:setlocal` in Vim script.

  ```fennel
  (setlocal! name-?flag ?val)
  ```

  See `set!` for the details."
  (option/set :local name-?flag ?val))

(lambda setglobal! [name-?flag ?val]
  "Set global value to the option.
  Almost equivalent to `:setglobal` in Vim script.

  ```fennel
  (setglobal! name-?flag ?val)
  ```
  See `set!` for the details."
  (option/set :global name-?flag ?val))

(lambda set+ [name val]
  "Append a value to string-style options.
  Almost equivalent to `:set {option}+={value}` in Vim script.

  ```fennel
  (set+ name val)
  ```"
  (option/modify :general name val "+"))

(lambda set^ [name val]
  "Prepend a value to string-style options.
  Almost equivalent to `:set {option}^={value}` in Vim script.

  ```fennel
  (set^ name val)
  ```"
  (option/modify :general name val "^"))

(lambda set- [name val]
  "Remove a value from string-style options.
  Almost equivalent to `:set {option}-={value}` in Vim script.

  ```fennel
  (set- name val)
  ```"
  (option/modify :general name val "-"))

(lambda setlocal+ [name val]
  "Append a value to string-style local options.
  Almost equivalent to `:setlocal {option}+={value}` in Vim script.

  ```fennel
  (setlocal+ name val)
  ```"
  (option/modify :local name val "+"))

(lambda setlocal^ [name val]
  "Prepend a value to string-style local options.
  Almost equivalent to `:setlocal {option}^={value}` in Vim script.

  ```fennel
  (setlocal^ name val)
  ```"
  (option/modify :local name val "^"))

(lambda setlocal- [name val]
  "Remove a value from string-style local options.
  Almost equivalent to `:setlocal {option}-={value}` in Vim script.

  ```fennel
  (setlocal- name val)
  ```"
  (option/modify :local name val "-"))

(lambda setglobal+ [name val]
  "Append a value to string-style global options.
  Almost equivalent to `:setglobal {option}+={value}` in Vim script.

  ```fennel
  (setglobal+ name val)
  ```

  - name: (string) Option name.
  - val: (string) Additional option value."
  (option/modify :global name val "+"))

(lambda setglobal^ [name val]
  "Prepend a value from string-style global options.
  Almost equivalent to `:setglobal {option}^={value}` in Vim script.

  ```fennel
  (setglobal^ name val)
  ```"
  (option/modify :global name val "^"))

(lambda setglobal- [name val]
  "Remove a value from string-style global options.
  Almost equivalent to `:setglobal {option}-={value}` in Vim script.

  ```fennel
  (setglobal- name val)
  ```"
  (option/modify :global name val "-"))

;; Keymap ///1
(lambda keymap/infer-description [raw-rhs]
  (let [raw-rhs (->str raw-rhs)
        ?description (when (< 2 (length raw-rhs))
                       (.. (-> raw-rhs
                               (: :sub 1 1)
                               (: :gsub "[-_]+" " ")
                               (: :upper))
                           (raw-rhs:sub 2)))]
    ?description))

(lambda keymap/varargs->api-args [...]
  ;; [default-opts modes ?extra-opts lhs rhs ?api-opts]
  "Merge extra options with default ones.
   `(map modes ?extra-opts lhs rhs ?api-opts)` where
   - `?extra-opts` must be a sequence of raw strings.
   - `?api-opts` must be a dictionary which accepts the same arguments as
     `vim.api.nvim_set_keymap()` accepts.
  `desc` will be filled based on `rhs` which is a function."
  (let [v1 (select 1 ...)
        ?extra-opts (when (sequence? v1)
                      v1)
        [lhs raw-rhs ?api-opts] (if ?extra-opts
                                    (slice [...] 2)
                                    [...])
        extra-opts (if (nil? ?extra-opts) {}
                       (seq->kv-table ?extra-opts
                                      [:<buffer>
                                       :expr
                                       :literal
                                       :script
                                       :unique]))
        api-opts (if (nil? ?api-opts) extra-opts
                     (collect [k v (pairs ?api-opts) &into extra-opts]
                       (values k v)))
        rhs (if (excmd? raw-rhs)
                raw-rhs
                (do
                  (tset api-opts :callback raw-rhs)
                  ""))]
    (assert-compile lhs "lhs cannot be nil" lhs)
    (assert-compile rhs "rhs cannot be nil" rhs)
    (when (and (sym? raw-rhs) (nil? (?. api-opts :desc)))
      (let [?description (keymap/infer-description raw-rhs)]
        (when ?description
          (tset api-opts :desc ?description))))
    (values lhs rhs api-opts)))

(lambda keymap/resolve-opts-compatibilities [api-opts]
  "Remove invalid keys in the api functions."
  (set api-opts.buffer nil)
  (set api-opts.<buffer> nil)
  (when (and api-opts.expr (not= false api-opts.replace_keycodes))
    (set api-opts.replace_keycodes true))
  (when api-opts.literal
    (set api-opts.literal nil)
    (set api-opts.replace_keycodes nil))
  api-opts)

(lambda keymap/del-maps! [...]
  "Delete keymap in such format as
  `(del-keymap :n :lhs)`, or `(del-keymap bufnr :n :lhs)`."
  ;; Note: nvim_del_keymap itself cannot delete mappings in multi mode at once.
  (let [[?bufnr mode lhs] (if (= 3 (select "#" ...)) [...] [nil ...])]
    (if ?bufnr
        `(vim.api.nvim_buf_del_keymap ,?bufnr ,mode ,lhs)
        `(vim.api.nvim_del_keymap ,mode ,lhs))))

(lambda keymap/set-maps! [modes lhs rhs raw-api-opts]
  (if (or (sym? modes) (sym? rhs))
      ;; Note: We cannot tell whether or not `rhs` should be set to callback in
      ;; compile time. Keep the compiled results simple.
      `(vim.keymap.set ,modes ,lhs ,rhs ,raw-api-opts)
      (let [?bufnr (if raw-api-opts.<buffer> 0 raw-api-opts.buffer)
            api-opts (keymap/resolve-opts-compatibilities raw-api-opts)
            set-keymap (if ?bufnr
                           (lambda [mode]
                             `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode ,lhs
                                                           ,rhs ,api-opts))
                           (lambda [mode]
                             `(vim.api.nvim_set_keymap ,mode ,lhs ,rhs
                                                       ,api-opts)))]
        (if (str? modes)
            (set-keymap modes)
            (icollect [_ m (ipairs modes)]
              (set-keymap m))))))

;; Export ///2
(lambda noremap! [modes ...]
  "Map `lhs` to `rhs` in `modes` non-recursively.

  ```fennel
  (noremap! modes ?extra-opts lhs rhs ?api-opts)
  (noremap! modes lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [default-opts {:noremap true}
        (lhs rhs api-opts) (keymap/varargs->api-args ...)]
    (merge-default-kv-table default-opts api-opts)
    (keymap/set-maps! modes lhs rhs api-opts)))

(lambda map! [modes ...]
  "Map `lhs` to `rhs` in `modes` recursively.

  ```fennel
  (noremap! modes ?extra-opts lhs rhs ?api-opts)
  (noremap! modes lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [default-opts {}
        (lhs rhs api-opts) (keymap/varargs->api-args ...)]
    (merge-default-kv-table default-opts api-opts)
    (keymap/set-maps! modes lhs rhs api-opts)))

;; Wrapper ///3
(lambda noremap-all! [...]
  "Map `lhs` to `rhs` in all modes non-recursively.

  ```fennel
  (noremap-all! ?extra-opts lhs rhs ?api-opts)
  (noremap-all! lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(noremap! "" lhs rhs api-opts)
     (noremap! "!" lhs rhs api-opts)
     (unpack (noremap! [:l :t] lhs rhs api-opts))]))

(lambda noremap-input! [...]
  "Map `lhs` to `rhs` in Insert/Command-line mode non-recursively.

  ```fennel
  (noremap-input! ?extra-opts lhs rhs ?api-opts)
  (noremap-input! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! "!" ...))

(lambda noremap-motion! [...]
  "Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode
  non-recursively.

  ```fennel
  (noremap-motion! ?extra-opts lhs rhs ?api-opts)
  (noremap-motion! lhs ?extra-opts rhs ?api-opts)
  ```

  Note: This macro `unmap`s `lhs` in Select mode for the performance.
  To avoid this, use `(noremap! [:n :o :x] ...)` instead."
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(noremap! "" lhs rhs api-opts) (keymap/del-maps! :s lhs)]))

(lambda noremap-operator! [...]
  "Map `lhs` to `rhs` in Normal/Visual mode non-recursively.

  ```fennel
  (noremap-operator! ?extra-opts lhs rhs ?api-opts)
  (noremap-operator! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! [:n :x] ...))

(lambda noremap-textobj! [...]
  "Map `lhs` to `rhs` in Visual/Operator-pending mode non-recursively.

  ```fennel
  (noremap-textobj! ?extra-opts lhs rhs ?api-opts)
  (noremap-textobj! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! [:o :x] ...))

(lambda nnoremap! [...]
  "Map `lhs` to `rhs` in Normal mode non-recursively.

  ```fennel
  (nnoremap! ?extra-opts lhs rhs ?api-opts)
  (nnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :n ...))

(lambda vnoremap! [...]
  "Map `lhs` to `rhs` in Visual/Select mode non-recursively.

  ```fennel
  (vnoremap! ?extra-opts lhs rhs ?api-opts)
  (vnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :v ...))

(lambda xnoremap! [...]
  "Map `lhs` to `rhs` in Visual mode non-recursively.

  ```fennel
  (xnoremap! ?extra-opts lhs rhs ?api-opts)
  (xnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :x ...))

(lambda snoremap! [...]
  "Map `lhs` to `rhs` in Select mode non-recursively.

  ```fennel
  (snoremap! ?extra-opts lhs rhs ?api-opts)
  (snoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :s ...))

(lambda onoremap! [...]
  "Map `lhs` to `rhs` in Operator-pending mode non-recursively.

  ```fennel
  (onoremap! ?extra-opts lhs rhs ?api-opts)
  (onoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :o ...))

(lambda inoremap! [...]
  "Map `lhs` to `rhs` in Insert mode non-recursively.

  ```fennel
  (inoremap! ?extra-opts lhs rhs ?api-opts)
  (inoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :i ...))

(lambda lnoremap! [...]
  "Map `lhs` to `rhs` in Insert/Command-line mode, etc., non-recursively.
  `:h language-mapping` for the details.

  ```fennel
  (lnoremap! ?extra-opts lhs rhs ?api-opts)
  (lnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :l ...))

(lambda cnoremap! [...]
  "Map `lhs` to `rhs` in Command-line mode non-recursively.

  ```fennel
  (cnoremap! ?extra-opts lhs rhs ?api-opts)
  (cnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :c ...))

(lambda tnoremap! [...]
  "Map `lhs` to `rhs` in Terminal mode non-recursively.

  ```fennel
  (tnoremap! ?extra-opts lhs rhs ?api-opts)
  (tnoremap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (noremap! :t ...))

(lambda map-all! [...]
  "Map `lhs` to `rhs` in all modes recursively.

  ```fennel
  (map-all! ?extra-opts lhs rhs ?api-opts)
  (map-all! lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(map! "" lhs rhs api-opts)
     (map! "!" lhs rhs api-opts)
     (unpack (map! [:l :t] lhs rhs api-opts))]))

(lambda map-input! [...]
  "Map `lhs` to `rhs` in Insert/Command-line mode recursively.

  ```fennel
  (map-input! ?extra-opts lhs rhs ?api-opts)
  (map-input! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! "!" ...))

(lambda map-motion! [...]
  "Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode
  recursively.

  ```fennel
  (map-motion! ?extra-opts lhs rhs ?api-opts)
  (map-motion! lhs ?extra-opts rhs ?api-opts)
  ```

  Note: This macro `unmap`s `lhs` in Select mode for the performance.
  To avoid this, use `(map! [:n :o :x] ...)` instead."
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(map! "" lhs rhs api-opts) (keymap/del-maps! :s lhs)]))

(lambda map-operator! [...]
  "Map `lhs` to `rhs` in Normal/Visual mode recursively.

  ```fennel
  (map-operator! ?extra-opts lhs rhs ?api-opts)
  (map-operator! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! [:n :x] ...))

(lambda map-textobj! [...]
  "Map `lhs` to `rhs` in Visual/Operator-pending mode recursively.

  ```fennel
  (map-textobj! ?extra-opts lhs rhs ?api-opts)
  (map-textobj! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! [:o :x] ...))

(lambda nmap! [...]
  "Map `lhs` to `rhs` in Normal mode recursively.

  ```fennel
  (nmap! ?extra-opts lhs rhs ?api-opts)
  (nmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :n ...))

(lambda vmap! [...]
  "Map `lhs` to `rhs` in Visual/Select mode recursively.

  ```fennel
  (vmap! ?extra-opts lhs rhs ?api-opts)
  (vmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :v ...))

(lambda xmap! [...]
  "Map `lhs` to `rhs` in Visual mode recursively.

  ```fennel
  (xmap! ?extra-opts lhs rhs ?api-opts)
  (xmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :x ...))

(lambda smap! [...]
  "Map `lhs` to `rhs` in Select mode recursively.

  ```fennel
  (smap! ?extra-opts lhs rhs ?api-opts)
  (smap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :s ...))

(lambda omap! [...]
  "Map `lhs` to `rhs` in Operator-pending mode recursively.

  ```fennel
  (omap! ?extra-opts lhs rhs ?api-opts)
  (omap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :o ...))

(lambda imap! [...]
  "Map `lhs` to `rhs` in Insert mode recursively.

  ```fennel
  (imap! ?extra-opts lhs rhs ?api-opts)
  (imap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :i ...))

(lambda lmap! [...]
  "Map `lhs` to `rhs` in Insert/Command-line mode, etc., recursively.
  `:h language-mapping` for the details.

  ```fennel
  (lmap! ?extra-opts lhs rhs ?api-opts)
  (lmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :l ...))

(lambda cmap! [...]
  "Map `lhs` to `rhs` in Command-line mode recursively.

  ```fennel
  (cmap! ?extra-opts lhs rhs ?api-opts)
  (cmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :c ...))

(lambda tmap! [...]
  "Map `lhs` to `rhs` in Terminal mode recursively.

  ```fennel
  (tmap! ?extra-opts lhs rhs ?api-opts)
  (tmap! lhs ?extra-opts rhs ?api-opts)
  ```"
  (map! :t ...))

;; Command ///1
(lambda command! [...]
  "Define a user command.

  ```fennel
  (command! ?extra-opts name command ?api-opts)
  (command! name ?extra-opts command ?api-opts)
  ```

  - name: (string) Name of the new user command.
    It must begin with an uppercase letter.
  - ?extra-opts: (sequence) Optional command attributes.
    Neither symbol nor list can be placed here.
    This sequential table is treated as if a key/value table, except the
    boolean attributes.
    The boolean attributes are set to `true` just being there alone.
    To set some attributes to `false`, set them instead in `?api-opts` below.
    All the keys must be raw string there.
    Additional attributes:
    - `<buffer>`: with this alone, command is set in current buffer instead.
    - `buffer`: with the next value, command is set to the buffer instead.
  - command: (string|function) Replacement command.
  - ?api-opts: (table) Optional command attributes.
    The same as {opts} for `nvim_create_user_command`.

  ```fennel
  (command! :SayHello
            \"echo 'Hello world!'\"
            {:bang true :desc \"Hello world!\"})
  (command! :Salute
            [:bar :buffer 10 :desc \"Say Hello!\"]
            #(print \"Salute!\")
  ```

  is equivalent to

  ```lua
  nvim_create_user_command(\"SayHello\", \"echo 'Hello world!'\", {
                                         bang = true,
                                         desc = \"Say Hello!\",
                                         })
  nvim_buf_create_user_command(10, \"Salute\",
                               function()
                                 print(\"'Hello world!'\")
                               end, {
                               bar = true,
                               desc = \"Salute!\"
                              })
  ```"
  (let [api-opts {}
        [name command ?api-opts] ;
        (accumulate [args [] _ varg (ipairs [...])]
          (do
            (if (sequence? varg)
                (let [extra-opts (seq->kv-table varg
                                                [:bar
                                                 :bang
                                                 :<buffer>
                                                 :register
                                                 :keepscript])]
                  (each [k v (pairs extra-opts)]
                    (tset api-opts k v)))
                (table.insert args varg))
            args))
        ?bufnr (if api-opts.<buffer> 0 api-opts.buffer)]
    (when ?api-opts
      (collect [k v (pairs ?api-opts) &into api-opts]
        (values k v)))
    (if ?bufnr
        (do
          (tset api-opts :buffer nil)
          (tset api-opts :<buffer> nil)
          `(vim.api.nvim_buf_create_user_command ,?bufnr ,name ,command
                                                 ,api-opts))
        `(vim.api.nvim_create_user_command ,name ,command ,api-opts))))

(lambda noautocmd! [callback]
  "(experimental) Imitation of `:noautocmd`. It sets `&eventignore` to \"all\"
  for the duration of callback.
  callback: (string|function) If string or symbol prefixed by `ex-` is regarded
      as vim Ex command; otherwise, it must be lua/fennel function."
  `(let [save-ei# vim.g.eventignore]
     (tset vim.g :eventignore :all)
     ,(if (excmd? callback) `(vim.cmd ,callback)
          (do
            (assert-compile (or (sym? callback) (function? callback))
                            (.. "callback must be a string or function, got "
                                (type callback))
                            callback)
            `(,callback)))
     (vim.schedule #(tset vim.g :eventignore save-ei#))))

;; Autocmd/Augroup ///1
(lambda define-autocmd! [...]
  (if (= 2 (length [...]))
      ;; It works as an alias of `vim.api.nvim_create_autocmd()` if only two
      ;; args are provided.
      (let [(events api-opts) ...]
        `(vim.api.nvim_create_autocmd ,events ,api-opts))
      (let [[id events pattern & rest] [...]
            api-opts {:group id}]
        (each [_ val (ipairs rest)]
          (if (sequence? val)
              (let [extra-opts (seq->kv-table val [:once :nested])]
                (each [k v (pairs extra-opts)]
                  (tset api-opts k v)))
              (if (excmd? val)
                  (tset api-opts :command val)
                  ;; Ignore the possibility to set VimL callback function in string.
                  (tset api-opts :callback val))))
        (when (and (str? pattern) (= pattern :<buffer>))
          (tset api-opts :buffer 0))
        (when (nil? api-opts.buffer)
          (tset api-opts :pattern
                (if (and (sym? pattern)
                         (-> (->str pattern)
                             (: :match "%*")))
                    (->str pattern)
                    pattern)))
        (when (= "*" api-opts.pattern)
          ;; Note: `*` is the default and redundant.
          (tset api-opts :pattern nil))
        (let [es (if (str? events)
                     ;; Expect dot-separated format: `:BufNewFile.BufReadPost`.
                     (icollect [p (events:gmatch "[a-zA-Z]+")]
                       p)
                     events)]
          `(vim.api.nvim_create_autocmd ,es ,api-opts)))))

(lambda define-augroup! [name opts ...]
  (if (= 0 (length [...]))
      `(vim.api.nvim_create_augroup ,name ,opts)
      `(let [id# (vim.api.nvim_create_augroup ,name ,opts)]
         ,(icollect [_ args (ipairs [...])]
            (let [au-args (if (contains? [:au! :autocmd!] (?. args 1 1))
                              (slice args 2)
                              args)]
              (define-autocmd! `id# (unpack au-args)))))))

;; Export ///2
(lambda augroup! [name ...]
  "Define/Override an augroup."
  ;; "clear" value is true by default.
  (define-augroup! name {} ...))

(lambda augroup+ [name ...]
  "Append `autocmd`s to an existing `augroup`."
  (define-augroup! name {:clear false} ...))

(lambda autocmd! [...]
  "Define an autocmd:

  ```fennel
  (autocmd! ?augroup-id events pattern ?extra-opts command-or-callback ?api-opts)
  ```

  ```fennel
  (augroup! :your-augroup
    (autocmd! :FileType * [\"some description\"] #(fnl-expr))
    (autocmd! :InsertEnter :<buffer> \"some Vimscript command\")
    (autocmd! :BufNewFile.BufRead \"{some,any}.ext\"
         [:this-is-invalid-description]
         #(vim.fn.foo))
    (autocmd! [:BufNewFile :BufRead] [:multi :patterns :for :events :in :sequence]
         [:once :nested \"You can also set :once or :nested here\"] ...))
  ```

  This macro also works as a syntax sugar in `(augroup!)`.
  - ?augroup-id (string|integer):
    Actually, `?augroup-id` is not an optional argument unlike
    `vim.api.nvim_create_autocmd()` unless you use this `autocmd!` macro within
    either `augroup!` or `augroup+` macro.
  - events (string|string[]):
    You can set multiple events in a dot-separated raw string.
  - pattern ('*'|string|string[]):
    You can set `:<buffer>` here to set `autocmd` to current buffer.
    Symbol `*` can be passed as if a string.
  - ?extra-opts (string[]?):
    No symbol is available here.
    You can set `:once` and/or `:nested` here to make them `true`.
    You can also set a string value for `:desc` with a bit of restriction. The
    string for description must be a `\"double-quoted string\"` which contains
    at least one of any characters, on qwerty keyboard, which can compose
    `\"double-quoted string\"`, but cannot `:string-with-colon-ahead`.
  - command-or-callback:
    A value for api options. Set either vim-command or callback function of vim,
    lua or fennel. Any raw string here is interpreted as vim-command; use
    `vim.fn` table to set a Vimscript function.
  "
  (define-autocmd! ...))

(lambda au! [...]
  "An alias of `autocmd!`"
  (define-autocmd! ...))

;; Misc ///1
(lambda str->keycodes [str]
  "Replace terminal codes and keycodes in a string.

  ```fennel
  (str->keycodes :foo)
  ```

  is compiled to

  ```lua
  vim.api.nvim_replace_termcodes(\"foo\", true, false, true)
  ```"
  `(vim.api.nvim_replace_termcodes ,str true false true))

(lambda feedkeys! [keys ?flags]
  "Equivalent to `vim.fn.feedkeys()`.

  ```fennel
  (feedkeys! :foo :ni)
  ```

  is compiled to

  ```lua
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(\"foo\", true, false, true) \"ni\", false)
  ```"
  `(vim.api.nvim_feedkeys ,(str->keycodes keys) ,?flags false))

(lambda cterm-color? [?color]
  "`:h cterm-colors`"
  (or (nil? ?color) (num? ?color) (and (str? ?color) (?color:match "[a-zA-Z]"))))

(lambda highlight! [...]
  "Set a highlight group.

  ```fennel
  (highlight! ?ns-id name val)
 ```"
  (local [?namespace hl-name val] (match (length [...])
                                    2 [nil (select 1 ...) (select 2 ...)]
                                    3 [...]))
  (if (?. val :link)
      (each [k _ (pairs val)]
        (assert-compile (= k :link) ;
                        (.. "With `link` key, no other options are invalid: " k)
                        val))
      (do
        (when (nil? val.ctermfg)
          (set val.ctermfg (?. val :cterm :fg)))
        (when (nil? val.ctermbg)
          (set val.ctermbg (?. val :cterm :bg)))
        (assert-compile (cterm-color? val.ctermfg)
                        (.. "ctermfg expects 256 color, got "
                            (view val.ctermfg)) val)
        (assert-compile (cterm-color? val.ctermbg)
                        (.. "ctermbg expects 256 color, got "
                            (view val.ctermbg)) val)
        `(vim.api.nvim_set_hl ,(or ?namespace 0) ,hl-name ,val))))

(lambda hi! [...]
  "An alias of `highlight!`"
  (highlight! ...))

;; Export ///1

{: set!
 : setlocal!
 : setglobal!
 : set+
 : set^
 : set-
 : setlocal+
 : setlocal^
 : setlocal-
 : setglobal+
 : setglobal^
 : setglobal-
 : noremap!
 : map!
 :unmap! keymap/del-maps!
 : noremap-all!
 : noremap-input!
 : noremap-motion!
 : noremap-operator!
 : noremap-textobj!
 : nnoremap!
 : vnoremap!
 : xnoremap!
 : snoremap!
 : onoremap!
 : inoremap!
 : lnoremap!
 : cnoremap!
 : tnoremap!
 : map-all!
 : map-input!
 : map-motion!
 : map-operator!
 : map-textobj!
 : nmap!
 : vmap!
 : xmap!
 : smap!
 : omap!
 : imap!
 : lmap!
 : cmap!
 : tmap!
 : command!
 : noautocmd!
 : augroup!
 : augroup+
 : au!
 : autocmd!
 : str->keycodes
 : feedkeys!
 : highlight!
 : hi!}

;; vim:fdm=marker:foldmarker=///,"""
