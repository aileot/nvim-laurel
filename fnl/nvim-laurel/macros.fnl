(local {: keymap/->compatible-opts!
        : command/->compatible-opts!
        : autocmd/->compatible-opts!} (require :nvim-laurel.utils))

;; General Macros ///1

(macro ++ [x]
  "Increment `x` by 1"
  `(do
     (set ,x (+ 1 ,x))
     ,x))

(macro when-not [cond ...]
  `(when (not ,cond)
     ,...))

(macro if-not [cond ...]
  `(if (not ,cond)
       ,...))

;; General Utils ///1
;; Predicates ///2

(lambda contains? [xs ?a]
  "Check if `?a` is in `xs`."
  (accumulate [eq? false ;
               _ x (ipairs xs) ;
               &until eq?]
    (= ?a x)))

(fn nil? [x]
  "Check if value of `x` is nil."
  (= nil x))

(fn str? [x]
  "Check if `x` is of string type."
  (= :string (type x)))

(fn num? [x]
  "Check if `x` is of number type."
  (= :number (type x)))

(fn hidden-in-compile-time? [x]
  "Check if the value of `x` is hidden in compile time.

  @param x any
  @return boolean"
  (or (sym? x) (list? x)))

(fn kv-table? [x]
  "Check if the value of `x` is kv-table.
  @param x any
  @return boolean"
  (and (table? x) (not (sequence? x))))

;; Misc ///2

(fn ->str [x]
  "Convert `x` to a string, or get the name if `x` is a symbol."
  (tostring x))

(lambda first [xs]
  "Return the first value in `xs`"
  (. xs 1))

(lambda slice [xs ?first ?last ?step]
  (let [first (or ?first 1)
        last (or ?last (length xs))
        step (or ?step 1)]
    (fcollect [i first last step]
      ;
      (. xs i))))

(lambda first-symbol [x]
  "Return the first symbol in list `x`"
  ;; TODO: Check if `x` is list.
  ;; (assert-compile (or (list? x) (table? x))
  ;;                 (.. "expected list or table, got " (type x)) x)
  (let [first-item (first x)]
    (if (str? first-item) first-item ;
        (first-symbol first-item))))

;; Additional predicates ///2

(fn anonymous-function? [x]
  "(Compile time) Check if type of `x` is anonymous function."
  (and (list? x) ;
       (contains? [:fn :hashfn :lambda :partial] (first-symbol x))))

;; Specific Utils ///1

(lambda wrapper [key ...]
  `(. (require :nvim-laurel.wrapper) ,key ,...))

(lambda merge-default-kv-table [default another]
  (each [k v (pairs default)]
    (when (nil? (. another k))
      (tset another k v))))

(fn ->str? [x]
  "Check if `x` will result in string at runtime."
  (when (list? x)
    (let [general-str-constructors [".."
                                    :table.concat
                                    :string.format
                                    :tostring
                                    :->str
                                    :->string]]
      (contains? general-str-constructors (first-symbol x)))))

;; cspell:word excmd

(fn excmd? [x]
  "Check if `x` is Ex command."
  (or (str? x) (->str? x)))

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

(lambda merge-api-opts [?api-opts ?extra-opts]
  "Merge `?api-opts` into `?extra-opts` safely.

  @param ?api-opts table
  @param ?extra-opts table Not a sequence.
  @return table"
  (if (hidden-in-compile-time? ?api-opts)
      (if (nil? ?extra-opts) `(or ,?api-opts {})
          `(,(wrapper :merge-api-opts) ,?api-opts ,?extra-opts))
      (nil? ?api-opts)
      (or ?extra-opts {})
      (collect [k v (pairs ?api-opts) &into ?extra-opts]
        (values k v))))

(lambda infer-description [raw-base]
  "Infer description from the name of hyphenated symbol, which is likely to be
  named by end user. It doesn't infer from any multi-symbol.
  Return nil if `raw-base` is not a symbol."
  (when (and (sym? raw-base) (not (multi-sym? raw-base)))
    (let [base (->str raw-base)
          ?description (when (and (< 2 (length base)) (base:match "%-"))
                         (.. (-> (base:sub 1 1)
                                 (: :upper))
                             (-> (base:sub 2)
                                 (: :gsub "%-+" " "))))]
      ?description)))

(lambda extract-?vim-fn-name [x]
  "Extract \"foobar\" from multi-symbol `vim.fn.foobar`, or return `nil`."
  (when (multi-sym? x)
    (let [(fn-name pos) (-> (->str x) (: :gsub "^vim%.fn%." ""))]
      (when (< 0 pos)
        fn-name))))

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
    As long as the option name is a bare string, i.e., neither symbol nor list,
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

;; Variable ///1

(lambda g! [name val]
  `(vim.api.nvim_set_var ,name ,val))

(lambda b! [id|name name|val ?val]
  (if ?val
      `(vim.api.nvim_buf_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_buf_set_var 0 ,id|name ,name|val)))

(lambda w! [id|name name|val ?val]
  (if ?val
      `(vim.api.nvim_win_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_win_set_var 0 ,id|name ,name|val)))

(lambda t! [id|name name|val ?val]
  (if ?val
      `(vim.api.nvim_tabpage_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_tabpage_set_var 0 ,id|name ,name|val)))

(lambda v! [name val]
  `(vim.api.nvim_set_vvar ,name ,val))

(lambda env! [name val]
  (let [new-name (if (str? name) (name:gsub "^%$" "") name)]
    `(vim.fn.setenv ,new-name ,val)))

;; Keymap ///1

(lambda keymap/parse-varargs [a1 a2 ?a3 ?a4]
  "Parse varargs.
  ```fennel
  (keymap/parse-varargs ?extra-opts lhs rhs ?api-opts)
  (keymap/parse-varargs lhs ?extra-opts rhs ?api-opts)
  ```
  @param ?extra-opts sequence|kv-table
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table
  @return extra-opts kv-table
  @return lhs string
  @return rhs string|function
  @return ?api-opts kv-table"
  (if (kv-table? a1) (values a1 a2 ?a3 ?a4)
      (let [?seq-extra-opts (if (sequence? a1) a1
                                (sequence? a2) a2)
            ?extra-opts (when ?seq-extra-opts
                          (seq->kv-table ?seq-extra-opts
                                         [:<buffer>
                                          :ex
                                          :<command>
                                          :cb
                                          :<callback>
                                          :nowait
                                          :silent
                                          :script
                                          :unique
                                          :expr
                                          :replace_keycodes
                                          :literal]))
            [extra-opts lhs raw-rhs ?api-opts] (if-not ?extra-opts
                                                 [{} a1 a2]
                                                 (sequence? a1)
                                                 [?extra-opts a2 ?a3 ?a4]
                                                 [?extra-opts a1 ?a3 ?a4])
            rhs (do
                  (when (and (or extra-opts.<command> extra-opts.ex)
                             (or extra-opts.<callback> extra-opts.cb))
                    (error "[nvim-laurel] cannot set both <command>/ex and <callback>/cb."))
                  (if (or extra-opts.<command> extra-opts.ex) raw-rhs
                      (or extra-opts.<callback> extra-opts.cb ;
                          (sym? raw-rhs) ;
                          (anonymous-function? raw-rhs)) ;
                      (do
                        ;; Hack: `->compatible-opts` must remove
                        ;; `cb`/`<callback>` key instead, but it doesn't at
                        ;; present. It should be reported to Fennel repository,
                        ;; but no idea how to reproduce it in minimal codes.
                        (set extra-opts.cb nil)
                        (set extra-opts.<callback> nil)
                        (set extra-opts.callback raw-rhs)
                        "") ;
                      raw-rhs))
            ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)]
        (set extra-opts.buffer ?bufnr)
        (when (nil? extra-opts.desc)
          (set extra-opts.desc (infer-description raw-rhs)))
        (values extra-opts lhs rhs ?api-opts))))

(lambda keymap/del-maps! [...]
  "Delete keymap in such format as
  `(del-keymap :n :lhs)`, or `(del-keymap bufnr :n :lhs)`."
  ;; Note: nvim_del_keymap itself cannot delete mappings in multi mode at once.
  (let [[?bufnr mode lhs] (if (select 3 ...) [...] [nil ...])]
    (if ?bufnr
        `(vim.api.nvim_buf_del_keymap ,?bufnr ,mode ,lhs)
        `(vim.api.nvim_del_keymap ,mode ,lhs))))

(lambda keymap/set-maps! [modes extra-opts lhs rhs ?api-opts]
  (if (or (sym? modes) (list? modes))
      `(,(wrapper :keymap/set-maps!) ,modes ,extra-opts ,lhs ,rhs ,?api-opts)
      (let [?bufnr extra-opts.buffer
            api-opts (merge-api-opts ?api-opts
                                     (keymap/->compatible-opts! extra-opts))
            set-keymap (lambda [mode]
                         (if ?bufnr
                             `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode ,lhs
                                                           ,rhs ,api-opts)
                             `(vim.api.nvim_set_keymap ,mode ,lhs ,rhs
                                                       ,api-opts)))]
        (if (str? modes)
            (set-keymap modes)
            (icollect [_ m (ipairs modes)]
              (set-keymap m))))))

(lambda keymap/invisible-key? [lhs]
  "Check if lhs is invisible key."
  (or ;; cspell:ignore acdms
      ;; <C-f>, <M-b>, ...
      (and (lhs:match "<[acdmsACDMS]%-[a-zA-Z0-9]+>")
           (not (lhs:match "<[sS]%-[a-zA-Z]>"))) ;
      ;; <CR>, <Left>, ...
      (lhs:match "<[a-zA-Z][a-zA-Z]+>") ;
      ;; <k0>, <F5>, ...
      (lhs:match "<[fkFK][0-9]>")))

;; Export ///2

(lambda <C-u> [x]
  "Return \":<C-u>`x`<CR>\""
  (if (str? x)
      (.. ":<C-u>" x :<CR>)
      `(.. ":<C-u>" ,x :<CR>)))

(lambda <Cmd> [x]
  "Return \"<Cmd>`x`<CR>\""
  (if (str? x)
      (.. :<Cmd> x :<CR>)
      `(.. :<Cmd> ,x :<CR>)))

(lambda noremap! [modes ...]
  "Map `lhs` to `rhs` in `modes` non-recursively.

  ```fennel
  (noremap! modes ?extra-opts lhs rhs ?api-opts)
  (noremap! modes lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [default-opts {:noremap true}
        (extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
    (merge-default-kv-table default-opts extra-opts)
    (keymap/set-maps! modes extra-opts lhs rhs ?api-opts)))

(lambda map! [modes ...]
  "Map `lhs` to `rhs` in `modes` recursively.

  ```fennel
  (noremap! modes ?extra-opts lhs rhs ?api-opts)
  (noremap! modes lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [default-opts {}
        (extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
    (merge-default-kv-table default-opts extra-opts)
    (keymap/set-maps! modes extra-opts lhs rhs ?api-opts)))

;; Wrapper ///3

(lambda noremap-all! [...]
  "Map `lhs` to `rhs` in all modes non-recursively.

  ```fennel
  (noremap-all! ?extra-opts lhs rhs ?api-opts)
  (noremap-all! lhs ?extra-opts rhs ?api-opts)
  ```"
  (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
    [(noremap! "" extra-opts lhs rhs ?api-opts)
     (noremap! "!" extra-opts lhs rhs ?api-opts)
     (unpack (noremap! [:l :t] extra-opts lhs rhs ?api-opts))]))

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
  (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)
        ;; Note: With unknown reason, keymap/del-maps! fails to get
        ;; `extra-opts.buffer` only to find it `nil` unless it's set to `?bufnr`.
        ?bufnr extra-opts.buffer]
    (if (str? lhs)
        (if (keymap/invisible-key? lhs)
            (noremap! "" extra-opts lhs rhs ?api-opts)
            [(noremap! "" extra-opts lhs rhs ?api-opts)
             (keymap/del-maps! ?bufnr :s lhs)])
        (noremap! [:n :o :x] extra-opts lhs rhs ?api-opts))))

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
  (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
    [(map! "" extra-opts lhs rhs ?api-opts)
     (map! "!" extra-opts lhs rhs ?api-opts)
     (unpack (map! [:l :t] extra-opts lhs rhs ?api-opts))]))

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
  (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)
        ?bufnr extra-opts.buffer]
    (if (str? lhs)
        (if (keymap/invisible-key? lhs)
            (map! "" extra-opts lhs rhs ?api-opts)
            [(map! "" extra-opts lhs rhs ?api-opts)
             (keymap/del-maps! ?bufnr :s lhs)])
        (map! [:n :o :x] extra-opts lhs rhs ?api-opts))))

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

(lambda command! [a1 a2 ?a3 ?a4]
  "Define a user command.

  ```fennel
  (command! ?extra-opts name command ?api-opts)
  (command! name ?extra-opts command ?api-opts)
  ```

  - `?extra-opts`: (sequence) Optional command attributes.
    Additional attributes:
    - `<buffer>`: with this alone, command is set in current buffer instead.
    - `buffer`: with the next value, command is set to the buffer instead.
  - `name`: (string) Name of the new user command.
    It must begin with an uppercase letter.
  - `command`: (string|function) Replacement command.
  - `?api-opts`: (table) Optional command attributes.
    The same as {opts} for `nvim_create_user_command`."
  (let [?seq-extra-opts (if (sequence? a1) a1
                            (sequence? a2) a2)
        ?extra-opts (when ?seq-extra-opts
                      (seq->kv-table ?seq-extra-opts
                                     [:bar
                                      :bang
                                      :<buffer>
                                      :register
                                      :keepscript]))
        [extra-opts name command ?api-opts] (if-not ?extra-opts
                                              [{} a1 a2 ?a3]
                                              (sequence? a1)
                                              [?extra-opts a2 ?a3 ?a4]
                                              [?extra-opts a1 ?a3 ?a4])
        ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)
        api-opts (merge-api-opts ?api-opts
                                 (command/->compatible-opts! extra-opts))]
    (if ?bufnr
        `(vim.api.nvim_buf_create_user_command ,?bufnr ,name ,command ,api-opts)
        `(vim.api.nvim_create_user_command ,name ,command ,api-opts))))

;; Autocmd ///1

(local autocmd/extra-opt-keys [:group
                               :pattern
                               :buffer
                               :<buffer>
                               :ex
                               :<command>
                               :desc
                               :callback
                               :command
                               :once
                               :nested])

(lambda define-autocmd! [?a1 a2 ?a3 ?x ?y ?z]
  "Define an autocmd.
  This macro also works as a syntax sugar in `augroup!`.

  @param name-or-id string|integer|nil:
    The autocmd group name or id to match against. It is necessary unlike
    `vim.api.nvim_create_autocmd()` unless this `autocmd!` macro is within
    either `augroup!` or `augroup+` macro. Set it to `nil` to define `autocmd`s
    affiliated with no augroup.
  @param events string|string[]:
    The event or events to register this autocmd.
  @param ?pattern bare-sequence
  @param ?extra-opts bare-sequence:
    Addition to `api-opts` keys, `:<buffer>` is available to set `autocmd` to
    current buffer.
  @param callback string|function:
    Set either vim Ex command, or function. Any bare string here is interpreted
    as vim Ex command; use `vim.fn` interface instead to set a Vimscript
    function.
  @param ?api-opts kv-table:
    Optional autocmd attributes."
  (if (nil? ?a3)
      ;; It works as an alias of `vim.api.nvim_create_autocmd()` if only two
      ;; args are provided.
      (let [[events api-opts] [?a1 a2]]
        `(vim.api.nvim_create_autocmd ,events ,api-opts))
      (let [[?id events] [?a1 a2]
            [?pattern ?extra-opts callback ?api-opts] ;
            (match [?a3 ?x ?y ?z]
              [cb nil nil nil] [nil nil cb nil]
              (where [a ex-opts c ?d] (sequence? ex-opts)) [a ex-opts c ?d]
              [a b ?c nil] (if (or (str? a) (hidden-in-compile-time? a))
                               [nil nil a b]
                               (contains? autocmd/extra-opt-keys (first a))
                               [nil a b ?c] ;
                               [a nil b ?c])
              _ (error (string.format "unexpected args:\n%s\n%s\n%s\n%s"
                                      (view ?a3) (view ?x) (view ?y) (view ?z))))
            extra-opts (if (nil? ?extra-opts) {}
                           (seq->kv-table ?extra-opts
                                          [:once
                                           :nested
                                           :<buffer>
                                           :ex
                                           :<command>
                                           :cb
                                           :<callback>]))
            ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)]
        (set extra-opts.group ?id)
        (set extra-opts.buffer ?bufnr)
        (when (and ?pattern (nil? extra-opts.pattern))
          (when-not (and (str? ?pattern) (= "*" ?pattern))
            ;; Note: `*` is the default pattern and redundant.
            (set extra-opts.pattern ?pattern)))
        (when (and (or extra-opts.<command> extra-opts.ex)
                   (or extra-opts.<callback> extra-opts.cb))
          (error "[nvim-laurel] cannot set both <command>/ex and <callback>/cb."))
        (if (or extra-opts.<command> extra-opts.ex)
            (set extra-opts.command callback)
            (or extra-opts.<callback> extra-opts.cb ;
                (sym? callback) ;
                (anonymous-function? callback))
            ;; Note: Ignore the possibility to set Vimscript function to callback
            ;; in string; however, convert `vim.fn.foobar` into "foobar" to set
            ;; to "callback" key because functions written in Vim script are
            ;; rarely supposed to expect the table from `nvim_create_autocmd` for
            ;; its first arg.
            (set extra-opts.callback
                 (or (extract-?vim-fn-name callback) ;
                     callback))
            (set extra-opts.command callback))
        (when (nil? extra-opts.desc)
          (set extra-opts.desc (infer-description callback)))
        (let [api-opts (merge-api-opts ?api-opts
                                       (autocmd/->compatible-opts! extra-opts))]
          `(vim.api.nvim_create_autocmd ,events ,api-opts)))))

(lambda define-augroup! [name opts ...]
  (if (= 0 (length [...]))
      `(vim.api.nvim_create_augroup ,name ,opts)
      `(let [id# (vim.api.nvim_create_augroup ,name ,opts)]
         ,(icollect [_ args (ipairs [...])]
            (let [au-args (if (and (list? args)
                                   (contains? [:au! :autocmd!]
                                              (first-symbol args)))
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

;; Misc ///1

(lambda str->keycodes [str]
  "Replace terminal codes and keycodes in a string.

  ```fennel
  (str->keycodes str)
  ```"
  `(vim.api.nvim_replace_termcodes ,str true true true))

(lambda feedkeys! [keys ?flags]
  "Equivalent to `vim.fn.feedkeys()`.

  ```fennel
  (feedkeys! keys ?flags)
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
 : g!
 : b!
 : w!
 : t!
 : v!
 : env!
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
 : <C-u>
 : <Cmd>
 : command!
 : augroup!
 : augroup+
 :au! define-autocmd!
 :autocmd! define-autocmd!
 : str->keycodes
 : feedkeys!
 : highlight!
 :hi! highlight!}

;; vim:fdm=marker:foldmarker=///,"""
