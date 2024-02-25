;; fennel-ls: macro-file
;; General Macros ///1

(macro ++ [num]
  "Increment `num` by 1
  @param num number
  @return number"
  `(do
     (set ,num (+ 1 ,num))
     ,num))

(macro when-not [cond ...]
  `(when (not ,cond)
     ,...))

(macro if-not [cond ...]
  `(if (not ,cond)
       ,...))

(macro nand [...]
  `(not (and ,...)))

(macro printf [str ...]
  `(string.format ,str ,...))

;; General Utils ///1
;; Predicates ///2

(lambda contains? [xs ?a]
  "Check if `?a` is in `xs`.
  @param xs sequence
  @param ?a any
  @return boolean"
  (accumulate [eq? false ;
               _ x (ipairs xs) ;
               &until eq?]
    (= ?a x)))

(fn nil? [x]
  "Check if `x` is `nil`.
  @param x any
  @return boolean"
  (= nil x))

(fn str? [x]
  "Check if `x` is `string`.
  @param x any
  @return boolean"
  (= :string (type x)))

(fn tbl? [x]
  "Check if `x` is `table`.
  @param x any
  @return boolean"
  (= :table (type x)))

(fn num? [x]
  "Check if `x` is `number`.
  @param x any
  @return boolean"
  (= :number (type x)))

(fn hidden-in-compile-time? [x]
  "Check if the value of `x` is hidden in compile time.
  @param x any
  @return boolean"
  (or (sym? x) (list? x) (varg? x)))

(fn seq? [x]
  "Check if `x` is sequence or list.
  @param x
  @return boolean"
  (or (sequence? x) ;; Note: sequence? does not consider [...] as sequence.
      (list? x) ;
      (and (table? x) (= 1 (next x)))))

(fn kv-table? [x]
  "Check if the value of `x` is kv-table.
  @param x any
  @return boolean"
  (and (table? x) (not (sequence? x))))

;; Misc ///2

(fn assert-seq [x]
  "Assert `x` is either sequence or list, or not.
  @param x any
  @return boolean"
  (assert (seq? x) (.. "expected sequence or list, got" (view x))))

(fn ->str [x]
  "Convert `x` to a string, or get the name if `x` is a symbol.
  @param x any
  @return string"
  (tostring x))

(fn inc [x]
  "Increment number `x`.
  @param x number
  @return number"
  (assert-compile (num? x) "Expected number" x)
  (+ x 1))

(fn dec [x]
  "Decrement number `x`.
  @param x number
  @return number"
  (assert-compile (num? x) "Expected number" x)
  (- x 1))

(lambda first [xs]
  "Return the first value in `xs`.
  @param xs sequence|list
  @return any"
  (assert-seq xs)
  (. xs 1))

(lambda second [xs]
  "Return the second value in `xs`.
  @param xs sequence|list
  @return any"
  (assert-seq xs)
  (. xs 2))

(fn last [xs]
  "Return the last value in `xs`.
  @param xs sequence|list
  @return any"
  (assert-seq xs)
  (. xs (length xs)))

(lambda slice [xs ?start ?end]
  "Return sequence from `?start` to `?end`.
  @param xs sequence
  @param ?start integer
  @param ?end integer
  @return sequence"
  (let [first (or ?start 1)
        last (or ?end (length xs))]
    (fcollect [i first last]
      (. xs i))))

(fn tbl/copy [from ?to]
  "Return a shallow copy of table `from`.
  @param from table
  @param ?to table
  @return table"
  (collect [k v (pairs (or from [])) &into (or ?to {})]
    (values k v)))

(fn tbl/merge [...]
  "Return a new merged tables. The rightmost map has priority. `nil` is
  ignored.
  @param ... table|nil
  @return table"
  (let [new-tbl {}]
    (each [_ t (ipairs [...])]
      (when t
        (assert-compile (tbl? t) "Expected table or nil" ...)
        (each [k v (pairs t)]
          (tset new-tbl k v))))
    new-tbl))

(fn tbl/merge! [tbl1 ...]
  "Merge tables into the first table `tbl1`. The rightmost map has
  priority. `nil` is ignored.
  @param ... table|nil
  @return table"
  (each [_ t (ipairs [...])]
    (when t
      (assert-compile (tbl? t) "Expected table or nil" ...)
      (each [k v (pairs t)]
        (tset tbl1 k v))))
  tbl1)

;; Additional predicates ///2

(fn quoted? [x]
  "Check if `x` is a list which begins with `quote`.
  @param x any
  @return boolean"
  (and (list? x) ;
       (= `quote (first x))))

(fn anonymous-function? [x]
  "(Compile time) Check if type of `x` is anonymous function.
  @param x any
  @return boolean"
  (and (list? x) ;
       (contains? [`fn `hashfn `lambda `partial] (first x))))

(fn vim-callback-format? [callback]
  "Tell if `callback` is to be interpreted in Vim script just by the
  `callback` format.
  @param callback any
  @return boolean"
  (or (and (sym? callback) ;
           (-> (->str callback) (: :match "^<.+>")))
      (and (list? callback) ;
           (-> (->str (first callback)) (: :match "^<.+>")))))

;; Specific Utils ///1

(lambda error* [msg]
  "Throw error with prefix."
  (error (.. "[nvim-laurel] " msg)))

(lambda msg-template/expected-actual [expected actual ...]
  "Assert `expr` but with error message in template.
  ```fennel
  (msg-template/expected-actual [expected actual] ?dump)
  ```
  @param expected string text to be inserted in \"expected %s\"
  @param actual string
  @param dump string"
  (let [msg (printf "expected %s, got %s" expected actual)]
    (match (select "#" ...)
      0 msg
      1 (.. msg "\ndump:\n" (select 1 ...))
      _ (error* (msg-template/expected-actual "2 or 3 args"
                                              (+ 2 (select "#" ...)))))))

(lambda merge-default-kv-table! [default another]
  "Fill key-value table with default values.
  @param default kv-table
  @param another kv-table"
  (each [k v (pairs default)]
    (when (nil? (. another k))
      (tset another k v))))

(lambda seq->kv-table [xs ?trues]
  "Convert `xs` into a kv-table as follows:
  - The values for `x` listed in `?trues` are set to `true`.
  - The values for the rest of `x`s are set to the next value in `xs`.
  @param xs sequence
  @param ?trues string[] The sequence of keys set to `true`.
  @return kv-table"
  (let [kv-table {}
        max (length xs)
        trues (or ?trues [])]
    (var i 1)
    (while (<= i max)
      (let [x (. xs i)]
        (if (contains? trues x)
            (tset kv-table x true)
            (tset kv-table x (. xs (++ i)))))
      (++ i))
    kv-table))

(lambda seq->trues [xs ?nexts]
  "Convert `xs` into a kv-table as follows:
  - The values for `x` listed in `?nexts` are set to the next value in `xs`.
  - The values for the rest of `x`s are set to `true`.
  @param xs sequence
  @param ?nexts string[]
  @return kv-table"
  (let [kv-table {}
        max (length xs)
        nexts (or ?nexts [])]
    (var i 1)
    (while (<= i max)
      (let [x (. xs i)]
        (if (contains? nexts x)
            (tset kv-table x (. xs (++ i)))
            (tset kv-table x true)))
      (++ i))
    kv-table))

(lambda merge-api-opts [?extra-opts ?api-opts]
  "Merge `?api-opts` into `?extra-opts` safely.
  @param ?extra-opts kv-table|nil
  @param ?api-opts table
  @return table"
  (if (hidden-in-compile-time? ?api-opts)
      (if (nil? ?extra-opts) `(or ,?api-opts {})
          `(vim.tbl_extend :force ,?extra-opts ,?api-opts))
      (nil? ?api-opts)
      (or ?extra-opts {})
      (collect [k v (pairs ?api-opts) &into ?extra-opts]
        (values k v))))

(fn ->unquoted [x]
  "If quoted, return unquoted `x`; otherwise, just return `x` itself.
  @param x any but nil
  @return any"
  (if (quoted? x)
      (second x)
      x))

(lambda extract-?vim-fn-name [x]
  "Extract \"foobar\" from multi-symbol `vim.fn.foobar`, or return `nil`.
  @param x any
  @return string|nil"
  (let [name (->str x)
        pat-vim-fn "^vim%.fn%.(%S+)$"]
    (name:match pat-vim-fn)))

(lambda extract-symbols [seq sym-names]
  "Extract symbols from `seq`, and return a copy of the rest and the 1-indexed
  positions of given `sym-names.`
  (extract-symbols ['&foo :bar '&foo '&foo :baz] ['&foo]) ;; => {:&foo [1 3 4]}
  @alias match-counts table[number]
  @param seq sequence
  @param sym-names quoted-symbol[]
  @return sequence, table<string,match-counts>"
  (let [new-seq [] ;
        symbol-positions {}]
    (each [i v (ipairs seq)]
      (if-not (contains? sym-names v)
        (table.insert new-seq v)
        (let [sym-name (->str v)]
          (if (. symbol-positions sym-name)
              (table.insert (. symbol-positions sym-name) i)
              (tset symbol-positions sym-name [i])))))
    (values new-seq symbol-positions)))

;;; Deprecation Utils ///1

(lambda deprecate [deprecated alternative version compatible]
  "Return a wrapper function, which returns `compatible`, about to notify
  deprecation when the file including it is `require`d at runtime.
  The message format of `vim.schedule`:
  \"{deprecated} is deprecated, use {alternative} instead. See :h deprecated
  This function will be removed in nvim-laurel version {version}\"
  @param deprecated string Deprecated target
  @param alternative string Suggestion to reproduce previous UX
  @param version string Version to drop the compatibility
  @param compatible any Anything to keep the compatibility
  @return list"
  (let [gcc-error-format "%s:%d: %s"
        deprecation `(vim.deprecate ,(printf "[nvim-laurel] %s" deprecated)
                                    ,alternative
                                    ,(printf "%s. `:cexpr g:laurel_deprecated` would help you update it. See `:h g:laurel_deprecated` for the details."
                                             version)
                                    :nvim-laurel false)
        msg (printf "nvim-laurel: %s is deprecated. Please update it with %s."
                    deprecated alternative)]
    `((fn []
        (when (= nil _G.__laurel_has_fnl_dir)
          (tset _G :__laurel_has_fnl_dir
                (= 1 (vim.fn.isdirectory (.. (vim.fn.stdpath :config) :/fnl)))))
        (tset vim.g :laurel_deprecated (or vim.g.laurel_deprecated {}))
        ;; Note: `table.insert` instead cannot handle `vim.g` interface.
        (let [qf-msg# ;
              (let [{:source source# :linedefined row#} ;
                    (debug.getinfo 1 :S)
                    lua-path# (source#:gsub "^@" "")
                    /fnl/-or-/lua/# (if _G.__laurel_has_fnl_dir :/fnl/ :/lua/)
                    fnl-path# (.. (vim.fn.stdpath :config)
                                  (-> lua-path#
                                      (: :gsub "%.lua$" :.fnl)
                                      (: :gsub :^.*/nvim/fnl/ :/fnl/)
                                      (: :gsub :^.*/nvim/lua/ /fnl/-or-/lua/#)))]
                (string.format ,gcc-error-format fnl-path# row# ,msg))]
          ;; Note: _G.__laurel_loaded_deprecated prevents duplicated item
          ;; in g:laurel_deprecated for QuickFix list.
          (when (= nil _G.__laurel_deprecated_loaded)
            (tset _G :__laurel_deprecated_loaded {}))
          (when (= nil (. _G.__laurel_deprecated_loaded qf-msg#))
            (tset _G.__laurel_deprecated_loaded qf-msg# true)
            (tset vim.g :laurel_deprecated
                  (vim.fn.add vim.g.laurel_deprecated qf-msg#))))
        ;; Note: It's safer to wrap it in `vim.schedule`.
        (vim.schedule #,deprecation)
        ,compatible))))

;;; Default API Options ///1

(local default/api-opts {})

(lambda default/extract-opts! [seq]
  "Extract symbols `&default-opts` and the following `kv-table`s from varg;
  no other type of args is supposed to precede them. The rightmost has priority.
  @param seq sequence
  @return sequence"
  (let [new-seq []
        removed-items []]
    (each [i v (ipairs seq)]
      (if (= `&default-opts v)
          (let [next-idx (inc i)
                ?next-tbl (. seq next-idx)]
            (assert-compile (kv-table? ?next-tbl) "expected kv-table" ?next-tbl)
            (tbl/merge! default/api-opts ?next-tbl)
            (tset removed-items i v)
            (tset removed-items next-idx ?next-tbl))
          (nil? (?. removed-items i))
          (table.insert new-seq v)))
    new-seq))

(lambda default/release-opts! []
  "Return saved default opts defined by user, and reset them.
  This operation can run without stack because macro expansion only runs sequentially.
  @return kv-table"
  ;; Note: This function is required to accept multiple &default-opts instead
  ;; of clearing default/api-opts on each default/extract-opts! call.
  (let [opts (tbl/copy default/api-opts)]
    (each [k _ (pairs default/api-opts)]
      (tset default/api-opts k nil))
    opts))

(lambda default/merge-opts! [api-opts]
  "Return the merge result of `api-opts` and `default/api-opts` saved by
  `default/extract-opts!`. The values of `api-opts` overrides those of
  `default/api-opts`. The `default/api-opts` gets cleared after the merge.
  @param api-opts kv-table The options to override `default/api-opts`.
  @return kv-table"
  (tbl/merge (default/release-opts!) api-opts))

;; Autocmd ///1

(local autocmd/extra-opt-keys [:group
                               :pattern
                               :buffer
                               :<buffer>
                               :desc
                               :callback
                               :command
                               :once
                               :nested])

(lambda autocmd/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.<buffer> nil)
  opts)

(lambda define-autocmd! [...]
  "Define an autocmd.
  ```fennel
  (define-autocmd! events api-opts)
  (define-autocmd! name|id events ?pattern ?extra-opts callback ?api-opts)
  ```
  @param name|id string|integer|nil The autocmd group name or id to match
      against. It is necessary unlike `vim.api.nvim_create_autocmd()` unless
      this `autocmd!` macro is within either `augroup!` or `augroup+` macro.
      Set it to `nil` to define `autocmd`s affiliated with no augroup.
  @param events string|string[] The event or events to register this autocmd.
  @param ?pattern bare-sequence
  @param ?extra-opts bare-sequence Addition to `api-opts` keys, `:<buffer>` is
      available to set `autocmd` to current buffer.
  @param callback string|function Set either vim Ex command, or function. Any
      bare string here is interpreted as vim Ex command; use `vim.fn` interface
      instead to set a Vimscript function.
  @param ?api-opts kv-table Optional autocmd attributes.
  @return undefined The return value of `nvim_create_autocmd`"
  (case (default/extract-opts! [...])
    ;; It works as an alias of `vim.api.nvim_create_autocmd()` if only two
    ;; args are provided.
    [events api-opts nil nil]
    (let [api-opts* (default/merge-opts! api-opts)]
      `(vim.api.nvim_create_autocmd ,events ,api-opts*))
    args
    (let [([?id events & rest] {:&vim ?vim-indice}) (extract-symbols args
                                                                     [`&vim])
          (?pattern ?extra-opts callback ?api-opts) ;
          (match rest
            [cb nil nil nil] (values nil nil cb nil)
            (where [a ex-opts c ?d] (sequence? ex-opts)) (values a ex-opts c ?d)
            [a b ?c nil] (if (or (str? a) (hidden-in-compile-time? a))
                             (values nil nil a b)
                             (contains? autocmd/extra-opt-keys (first a))
                             (values nil a b ?c)
                             (values a nil b ?c))
            _ (error* (printf "unexpected args:\n?id: %s\nevents: %s\nrest: %s"
                              (view args) (view ?id) (view events) (view rest))))
          extra-opts (if (nil? ?extra-opts) {}
                         (seq->kv-table ?extra-opts [:once :nested :<buffer>]))
          ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)
          ?pat (or extra-opts.pattern ?pattern)]
      (set extra-opts.group ?id)
      (set extra-opts.buffer ?bufnr)
      (let [pattern (if (and (sequence? ?pat) (= 1 (length ?pat)))
                        (first ?pat)
                        ?pat)]
        ;; Note: `*` is the default pattern and redundant.
        (when-not (and (str? pattern) (= "*" pattern))
          (set extra-opts.pattern pattern)))
      (if (or ?vim-indice (str? callback) (vim-callback-format? callback))
          (set extra-opts.command callback)
          ;; Note: Ignore the possibility to set Vimscript function to
          ;; callback in string; however, convert `vim.fn.foobar` into
          ;; "foobar" to set to "callback" key because functions written in
          ;; Vim script are rarely supposed to expect the table from
          ;; `nvim_create_autocmd` for its first arg.
          (let [cb (or (extract-?vim-fn-name callback) ;
                       callback)]
            (set extra-opts.callback cb)))
      (assert-compile (nand extra-opts.pattern extra-opts.buffer)
                      "cannot set both pattern and buffer for the same autocmd"
                      extra-opts)
      (let [api-opts (-> (default/merge-opts! extra-opts)
                         (autocmd/->compatible-opts!)
                         (merge-api-opts ?api-opts))]
        `(vim.api.nvim_create_autocmd ,events ,api-opts)))))

(fn autocmd? [args]
  (and (list? args) (contains? [`au! `autocmd!] (first args))))

(lambda define-augroup! [name api-opts autocmds]
  "Define an augroup.
  ```fennel
  (define-augroup! name api-opts [events ?pattern ?extra-opts callback ?api-opts])
  (define-augroup! name api-opts (au! events ?pattern ?extra-opts callback ?api-opts))
  (define-augroup! name api-opts (autocmd! events ?pattern ?extra-opts callback ?api-opts))
  ```
  @param name string Augroup name.
  @param opts kv-table Dictionary parameters for `nvim_create_augroup`.
  @param autocmds sequence|list Parameters for `define-autocmd!`.
  @return undefined Without `...`, the return value of `nvim_create_augroup`;
      otherwise, undefined (currently a sequence of `autocmd`s defined in the
      augroup.)"
  (if (= 0 (length autocmds))
      `(vim.api.nvim_create_augroup ,name ,api-opts)
      `(let [id# (vim.api.nvim_create_augroup ,name ,api-opts)]
         ,(icollect [_ args (ipairs autocmds)]
            (let [au-args (if (autocmd? args)
                              (slice args 2)
                              (sequence? args)
                              args
                              (error* (msg-template/expected-actual "sequence, or list which starts with `au!` or `autocmd!`"
                                                                    (type args)
                                                                    (view args))))]
              (define-autocmd! `id# (unpack au-args)))))))

;; Export ///2

(lambda augroup! [...]
  "Create, or override, an augroup, and add `autocmd` to the augroup.
  ```fennel
  (augroup! name ?api-opts
    ?[events ?pattern ?extra-opts callback ?api-opts]
    ?(au! events ?pattern ?extra-opts callback ?api-opts)
    ?(autocmd! events ?pattern ?extra-opts callback ?api-opts)
    ?...)
  ```
  @param name string Augroup name.
  @param ?api-opts|?autocmd table|nil Omittable.
  @param ... sequence|list
  @return undefined Without `...`, the return value of `nvim_create_augroup`;
      otherwise, undefined (currently a sequence of `autocmd`s defined in the)
      augroup."
  ;; Note: "clear" value in api-opts is true by default.
  (let [[name ?api-opts|?autocmd & rest] (default/extract-opts! [...])
        (api-opts autocmds) (if (nil? ?api-opts|?autocmd) (values {} [])
                                (or (sequence? ?api-opts|?autocmd)
                                    (autocmd? ?api-opts|?autocmd))
                                (values {} [?api-opts|?autocmd (unpack rest)])
                                (values ?api-opts|?autocmd rest))
        api-opts* (default/merge-opts! api-opts)]
    (define-augroup! name api-opts* autocmds)))

(fn autocmd! [...]
  "Define an autocmd. This macro also works as a syntax sugar in `augroup!`.
  ```fennel
  (autocmd! events api-opts)
  (autocmd! name|id events ?pattern ?extra-opts callback ?api-opts)
  ```
  @param name|id string|integer|nil The autocmd group name or id to match
      against. It is necessary unlike `vim.api.nvim_create_autocmd()` unless
      this `autocmd!` macro is within either `augroup!` or `augroup+` macro.
      Set it to `nil` to define `autocmd`s affiliated with no augroup.
  @param events string|string[] The event or events to register this autocmd.
  @param ?pattern bare-sequence
  @param ?extra-opts bare-sequence Addition to `api-opts` keys, `:<buffer>` is
      available to set `autocmd` to current buffer.
  @param callback string|function Set either vim Ex command, or function. Any
      bare string here is interpreted as vim Ex command; use `vim.fn` interface
      instead to set a Vimscript function.
  @param ?api-opts kv-table Optional autocmd attributes.
  @return undefined The return value of `nvim_create_autocmd`"
  ;; TODO: Detect if it were embedded in a runtime function with varg.
  ;;  (let [varg-size (select "#" ...)
  ;;        last-arg (select varg-size ...)]
  ;;    (assert (varg? last-arg) (.. "varg is incompatible. Please consider to embed it into macro instead of function:
  ;;" (view [...]))))
  (define-autocmd! ...))

;; Keymap ///1

(lambda keymap/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  (set opts.literal nil)
  opts)

(lambda keymap/parse-args [args]
  "Parse map! macro args in sequence.
  ```fennel
  (keymap/parse-args ?extra-opts lhs rhs ?api-opts)
  (keymap/parse-args lhs ?extra-opts rhs ?api-opts)
  ```
  @param ?extra-opts sequence|kv-table
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table
  @return extra-opts kv-table
  @return lhs string
  @return rhs string|function
  @return ?api-opts kv-table"
  (let [([modes a1 a2 ?a3 ?a4] {:&vim ?vim-indice}) ;
        (extract-symbols args [`&vim])]
    (if (kv-table? a1) (values a1 a2 ?a3 ?a4)
        (let [?seq-extra-opts (if (sequence? a1) a1
                                  (sequence? a2) a2)
              ?extra-opts (when ?seq-extra-opts
                            (seq->trues ?seq-extra-opts
                                        [:desc :buffer :callback]))
              [extra-opts lhs raw-rhs ?api-opts] (if-not ?extra-opts
                                                   [{} a1 a2 ?a3]
                                                   (sequence? a1)
                                                   [?extra-opts a2 ?a3 ?a4]
                                                   [?extra-opts a1 ?a3 ?a4])
              rhs (if (or ?vim-indice (str? raw-rhs)
                          (vim-callback-format? raw-rhs))
                      raw-rhs
                      (do
                        (set extra-opts.callback raw-rhs)
                        ""))
              ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)]
          (set extra-opts.buffer ?bufnr)
          (values modes extra-opts lhs rhs ?api-opts)))))

(lambda keymap/del-maps! [...]
  "Delete keymap.
  ```fennel
  (keymap/del-keymap! ?bufnr mode lhs)
  ```
  @param ?bufnr integer Buffer handle, or 0 for current buffer
  @param mode string
  @param lhs string"
  ;; TODO: Identify the cause to reach `_` just with three args.
  ;; (match (pick-values 4 ...)
  ;;   (mode lhs) `(vim.api.nvim_del_keymap ,mode ,lhs)
  ;;   (bufnr mode lhs) `(vim.api.nvim_buf_del_keymap ,bufnr ,mode ,lhs)
  ;;   _ (error* (msg-template/expected-actual "2 or 3 args" (select "#" ...))
  ;;             (view [...])))
  ;; Note: nvim_del_keymap itself cannot delete mappings in multi mode at once.
  (let [[?bufnr mode lhs] (if (select 3 ...) [...] [nil ...])]
    (if ?bufnr
        `(vim.api.nvim_buf_del_keymap ,?bufnr ,mode ,lhs)
        `(vim.api.nvim_del_keymap ,mode ,lhs))))

(lambda keymap/set-maps! [modes extra-opts lhs rhs ?api-opts]
  "Set keymap
  ```fennel
  (keymap/set-maps! modes extra-opts lhs rhs ?api-opts)
  ```
  @param modes string|string[]
  @param extra-opts kv-table
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (when (and extra-opts.expr (not= false extra-opts.replace_keycodes))
    (set extra-opts.replace_keycodes (if extra-opts.literal false true)))
  (when (or extra-opts.remap
            (and extra-opts.callback (not extra-opts.expr)
                 (or (nil? ?api-opts)
                     (and (not ?api-opts.expr)
                          (not (hidden-in-compile-time? ?api-opts))))))
    (set extra-opts.remap nil)
    (set extra-opts.noremap nil))
  (let [?bufnr extra-opts.buffer
        api-opts (merge-api-opts (keymap/->compatible-opts! extra-opts)
                                 ?api-opts)
        set-keymap (lambda [mode]
                     (if ?bufnr
                         `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode ,lhs ,rhs
                                                       ,api-opts)
                         `(vim.api.nvim_set_keymap ,mode ,lhs ,rhs ,api-opts)))
        modes (if (and (str? modes) (< 1 (length modes)))
                  (icollect [m (modes:gmatch ".")]
                    m)
                  modes)]
    (if (str? modes)
        (set-keymap modes)
        (hidden-in-compile-time? modes)
        ;; Note: With `vim.keymap.set` instead, it would be hard to deal
        ;; with `remap` key.
        `(if (= (type ,modes) :string)
             ,(set-keymap modes)
             (vim.tbl_map (fn [m#]
                            ,(set-keymap `m#)) ,modes))
        (icollect [_ m (ipairs modes)]
          (set-keymap m)))))

;; Export ///2

(lambda map! [...]
  "Map `lhs` to `rhs` in `modes` recursively.
  ```fennel
  (map! modes ?extra-opts lhs rhs ?api-opts)
  (map! modes lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (let [default-opts {:noremap true}
        args (default/extract-opts! [...])
        (modes extra-opts lhs rhs ?api-opts) (keymap/parse-args args)
        extra-opts* (tbl/merge default-opts ;
                               (default/release-opts!) ;
                               extra-opts)]
    (keymap/set-maps! modes extra-opts* lhs rhs ?api-opts)))

(lambda unmap! [...]
  "Delete keymap.
  ```fennel
  (unmap! ?bufnr mode lhs)
  ```
  @param ?bufnr integer Buffer handle, or 0 for current buffer
  @param mode string
  @param lhs string"
  (keymap/del-maps! ...))

(lambda <Cmd> [x]
  "Return \"<Cmd>`x`<CR>\"
  @param x string
  @return string"
  (if (str? x)
      (.. :<Cmd> x :<CR>)
      `(.. :<Cmd> ,x :<CR>)))

(lambda <C-u> [x]
  "Return \":<C-u>`x`<CR>\"
  @param x string
  @return string"
  (if (str? x)
      (.. ":<C-u>" x :<CR>)
      `(.. ":<C-u>" ,x :<CR>)))

;; Variable ///1

(lambda g! [name val]
  "Set global (`g:`) editor variable.
  ```fennel
  (g! name val)
  ```
  @param name string Variable name.
  @param val any Variable value."
  `(vim.api.nvim_set_var ,name ,val))

(lambda b! [id|name name|val ?val]
  "Set buffer-scoped (`b:`) variable for the current buffer. Can be indexed
  with an integer to access variables for specific buffer.
  ```fennel
  (b! ?id name val)
  ```
  @param ?id integer Buffer handle, or 0 for current buffer.
  @param name string Variable name.
  @param val any Variable value."
  (if ?val
      `(vim.api.nvim_buf_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_buf_set_var 0 ,id|name ,name|val)))

(lambda w! [id|name name|val ?val]
  "Set window-scoped (`w:`) variable for the current window. Can be indexed
  with an integer to access variables for specific window.
  ```fennel
  (w! ?id name val)
  ```
  @param ?id integer Window handle, or 0 for current window.
  @param name string Variable name.
  @param val any Variable value."
  (if ?val
      `(vim.api.nvim_win_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_win_set_var 0 ,id|name ,name|val)))

(lambda t! [id|name name|val ?val]
  "Set tabpage-scoped (`t:`) variable for the current tabpage. Can be indexed
  with an integer to access variables for specific tabpage.
  ```fennel
  (t! ?id name val)
  ```
  @param ?id integer Tabpage handle, or 0 for current tabpage.
  @param name string Variable name.
  @param val any Variable value."
  (if ?val
      `(vim.api.nvim_tabpage_set_var ,id|name ,name|val ,?val)
      `(vim.api.nvim_tabpage_set_var 0 ,id|name ,name|val)))

(lambda v! [name val]
  "Set `v:` variable if not readonly.
  ```fennel
  (v! name val)
  ```
  @param name string Variable name.
  @param val any Variable value."
  `(vim.api.nvim_set_vvar ,name ,val))

(lambda env! [name val]
  "Set environment variable in the editor session.
  ```fennel
  (env! name val)
  ```
  @param name string Variable name. A bare-string can starts with `$` (ignored
    internally), which helps `gf` jump to the path.
  @param val any Variable value."
  (let [new-name (if (str? name) (name:gsub "^%$" "") name)]
    `(vim.fn.setenv ,new-name ,val)))

;; Option ///1

(fn option/concatenatable? [x]
  "Check if `x` can be concatenated into string for Vim option value."
  (when (or (sequence? x) (table? x))
    (let [concatable-types [:string :number]]
      (accumulate [concatable? nil ;
                   k v (pairs x) ;
                   &until (= false concatable?)]
        (and (contains? concatable-types (type k))
             (contains? concatable-types (type v)))))))

(lambda option/concat-kv-table [kv-table]
  "Concat kv table into a string for `vim.api.nvim_set_option_value`.
  For example,
  `{:eob \" \" :fold \"-\"})` should be compiled to `\"eob: ,fold:-\"`"
  (assert-compile (table? kv-table)
                  (msg-template/expected-actual :table (type kv-table)
                                                (view kv-table))
                  kv-table)
  (let [key-val (icollect [k v (pairs kv-table)]
                  (.. k ":" v))]
    (table.concat key-val ",")))

(lambda option/->?vim-value [?val]
  "Return in vim value for such API as `nvim_set_option`.
  @param val any
  @return 'vim.NIL|boolean|number|string|nil"
  (match (type ?val)
    :nil `vim.NIL
    :boolean ?val
    :string ?val
    :number ?val
    _ (if-not (option/concatenatable? ?val)
        nil
        (sequence? ?val)
        (table.concat ?val ",")
        (table? ?val)
        (option/concat-kv-table ?val))))

(lambda option/modify [api-opts name ?val ?q-flag]
  (let [name (if (str? name) (name:lower) name)
        ?flag (when ?q-flag
                ;; Note: ->str rips quote off.
                (->str ?q-flag))
        interface (match api-opts
                    {:scope nil :buf nil :win nil} `vim.opt
                    {:scope :local} `vim.opt_local
                    {:scope :global} `vim.opt_global
                    {: buf :win nil} (if (= 0 buf) `vim.bo `(. vim.bo ,buf))
                    {: win :buf nil} (if (= 0 win) `vim.wo `(. vim.wo ,win))
                    _ (error* (.. "invalid api-opts: " (view api-opts))))
        ;; opt-obj `(. ,interface ,name)
        opt-obj (if (str? ?q-flag)
                    (deprecate "flag-in-name format like `(set! :foo+ :bar)`"
                               "infix flag like `(set! :foo + :bar)`" :v0.7.0
                               `(. ,interface ,name))
                    `(. ,interface ,name))
        ?val (if (and (contains? [:formatoptions :fo :shortmess :shm] name)
                      (sequence? ?val) (not= ?flag "-"))
                 (if (option/concatenatable? ?val)
                     (table.concat ?val)
                     `(table.concat ,?val))
                 ?val)]
    (match ?flag
      nil
      (match (option/->?vim-value ?val)
        vim-val `(vim.api.nvim_set_option_value ,name ,vim-val ,api-opts)
        _ `(tset ,interface ,name ,?val))
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
      (error* (.. "Invalid vim option modifier: " (view ?flag))))))

(lambda option/extract-flag [name-?flag]
  (let [?flag (name-?flag:match "[^a-zA-Z]")
        name (if ?flag (name-?flag:match "[a-zA-Z]+") name-?flag)]
    (values name ?flag)))

(fn option/set-with-scope [scope ...]
  (assert-compile (table? scope) "Expected kv-table" scope)
  (let [supported-flags [`+ `- `^ `! `& `<]
        [name ?flag val] ;
        (match ...
          (name nil)
          [name nil true]
          (where (name flag ?val)
                 (and (sym? flag) (contains? supported-flags flag)))
          [name flag ?val]
          ;; TODO: Remove flag-extraction on v0.7.0.
          (name-?flag val nil)
          (if (str? name-?flag)
              (let [(name ?flag) (option/extract-flag name-?flag)]
                [name ?flag val])
              [name-?flag nil val]))]
    (option/modify scope name val ?flag)))

;; Export ///2

(lambda set! [...]
  "Set value to the option.
  Almost equivalent to `:set` in Vim script.
  ```fennel
  (set! name ?flag ?val)
  ```
  @param name string Option name.
    As long as the option name is a bare string, i.e., neither symbol nor list,
    this macro has an advantage: option name is case-insensitive. You can
    improve readability a bit with camelCase/PascalCase. Since `:h {option}`
    is also case-insensitive, `(setlocal! :keywordPrg \":help\")` for fennel
    still makes sense.
  @param ?flag symbol One of `+`, `-`, or `^` is available.
  @param ?val boolean|number|string|table New option value.
    If not provided, the value is supposed to be `true` (experimental).
    This macro is expanding to `(vim.api.nvim_set_option_value name val)`;
    however, when the value is set in either symbol or list,
    this macro is expanding to `(tset vim.opt name val)` instead.
  Note: There is no plan to support option prefix either `no` or `inv`;
  instead, set `false` or `(not vim.go.foo)` respectively.
  ```fennel
  (let [opt :formatOptions]
    (set! opt + [:1 :B]))
  ```"
  (option/set-with-scope {} ...))

(lambda setlocal! [...]
  "Set local value to the option.
  Almost equivalent to `:setlocal` in Vim script.
  ```fennel
  (setlocal! name-?flag ?val)
  ```
  See `set!` for the details."
  (option/set-with-scope {:scope :local} ...))

(lambda setglobal! [...]
  "Set global value to the option.
  Almost equivalent to `:setglobal` in Vim script.
  ```fennel
  (setglobal! name-?flag ?val)
  ```
  See `set!` for the details."
  (option/set-with-scope {:scope :global} ...))

(lambda bo! [name|?id val|name ...]
  "Set a buffer option value.
  ```fennel
  (bo! ?id name value)
  ```
  @param ?id integer Buffer handle, or 0 for current buffer.
  @param name string Option name. Case-insensitive as long as in bare-string.
  @param value any Option value."
  (let [[id name val] (if (= 0 (select "#" ...)) [0 name|?id val|name]
                          [name|?id val|name ...])
        ?vim-val (option/->?vim-value val)]
    (option/modify {:buf id} name (or ?vim-val val))))

(lambda wo! [name|?id val|name ...]
  "Set a window option value.
  ```fennel
  (wo! ?id name value)
  ```
  @param ?id integer Window handle, or 0 for current window.
  @param name string Option name. Case-insensitive as long as in bare-string.
  @param value any Option value."
  (let [[id name val] (if (= 0 (select "#" ...)) [0 name|?id val|name]
                          [name|?id val|name ...])
        ?vim-val (option/->?vim-value val)]
    (option/modify {:win id} name (or ?vim-val val))))

;; Command ///1

(lambda command/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  opts)

(lambda command! [...]
  "Define a user command.
  ```fennel
  (command! ?extra-opts name command ?api-opts)
  (command! name ?extra-opts command ?api-opts)
  ```
  @param ?extra-opts bare-sequence Optional command attributes.
    Additional attributes:
    - <buffer>: with this alone, command is set in current buffer instead.
    - buffer: with the next value, command is set to the buffer instead.
  @param name string Name of the new user command.
    It must begin with an uppercase letter.
  @param command string|function Replacement command.
  @param ?api-opts kv-table Optional command attributes.
    The same as {opts} for `nvim_create_user_command`."
  (let [[a1 a2 ?a3 ?a4] (default/extract-opts! [...])
        ?seq-extra-opts (if (sequence? a1) a1
                            (sequence? a2) a2)
        (extra-opts name command ?api-opts) ;
        (case (when ?seq-extra-opts
                (seq->kv-table ?seq-extra-opts
                               [:bar :bang :<buffer> :register :keepscript]))
          nil (values {} a1 a2 ?a3)
          extra-opts (if (sequence? a1)
                         (values extra-opts a2 ?a3 ?a4)
                         (values extra-opts a1 ?a3 ?a4)))
        extra-opts* (default/merge-opts! extra-opts)
        ?bufnr (if extra-opts*.<buffer> 0 extra-opts*.buffer)
        api-opts (-> (command/->compatible-opts! extra-opts*)
                     (merge-api-opts ?api-opts))]
    (if ?bufnr
        `(vim.api.nvim_buf_create_user_command ,?bufnr ,name ,command ,api-opts)
        `(vim.api.nvim_create_user_command ,name ,command ,api-opts))))

;; Misc ///1

(lambda str->keycodes [str]
  "Replace terminal codes and keycodes in a string.
  ```fennel
  (str->keycodes str)
  ```
  @param str string
  @return string"
  `(vim.api.nvim_replace_termcodes ,str true true true))

(lambda feedkeys! [keys ?flags]
  "Equivalent to `vim.fn.feedkeys()`.
  ```fennel
  (feedkeys! keys ?flags)
  ```
  @param keys string
  @param ?flags string"
  (let [flags (if (str? ?flags)
                  (or ?flags "")
                  `(or ,?flags ""))]
    `(vim.api.nvim_feedkeys ,(str->keycodes keys) ,flags false)))

(lambda cterm-color? [?color]
  "`:h cterm-colors`
  @param ?color any
  @return boolean"
  (or (nil? ?color) (num? ?color) (and (str? ?color) (?color:match "[a-zA-Z]"))))

(lambda highlight! [...]
  "Set a highlight group.
  ```fennel
  (highlight! ?ns-id name api-opts)
 ```
 @param ?ns-id integer
 @param name string
 @param api-opts kv-table The same as {val} in `vim.api.nvim_set_hl()`."
  {:fnl/arglist [ns-id|name name|api-opts ?api-opts]}
  (let [(?ns-id name api-opts) (case (default/extract-opts! [...])
                                 [name api-opts nil] (values nil name api-opts)
                                 [ns-id name api-opts] (values ns-id name
                                                               api-opts))
        api-opts* (merge-api-opts (default/release-opts!)
                                  ;; Note: api-opts can be symbol or list, so
                                  ;; `default/merge-opts!` could not work
                                  ;; expectedly.
                                  api-opts)]
    (if (?. api-opts* :link)
        (each [k _ (pairs api-opts*)]
          (assert-compile (= k :link)
                          (.. "`link` key excludes any other options: " k)
                          api-opts*))
        (do
          (when (nil? api-opts*.ctermfg)
            (set api-opts*.ctermfg (?. api-opts* :cterm :fg))
            (when api-opts*.cterm
              (set api-opts*.cterm.fg nil)))
          (when (nil? api-opts*.ctermbg)
            (set api-opts*.ctermbg (?. api-opts* :cterm :bg))
            (when api-opts*.cterm
              (set api-opts*.cterm.bg nil)))
          (assert-compile (or (cterm-color? api-opts*.ctermfg)
                              (hidden-in-compile-time? api-opts*.ctermfg))
                          (.. "ctermfg expects 256 color, got "
                              (view api-opts*.ctermfg))
                          api-opts*)
          (assert-compile (or (cterm-color? api-opts*.ctermbg)
                              (hidden-in-compile-time? api-opts*.ctermbg))
                          (.. "ctermbg expects 256 color, got "
                              (view api-opts*.ctermbg))
                          api-opts*)))
    `(vim.api.nvim_set_hl ,(or ?ns-id 0) ,name ,api-opts*)))

;; Deprecated ///1

(lambda set+ [name val]
  "(Deprecated) Append a value to string-style options.
  Almost equivalent to `:set {option}+={value}` in Vim script.
  ```fennel
  (set+ name val)
  ```"
  (deprecate :set+ "set! with '+ flag" :v0.7.0 (set! name `+ val)))

(lambda set^ [name val]
  "(Deprecated) Prepend a value to string-style options.
  Almost equivalent to `:set {option}^={value}` in Vim script.
  ```fennel
  (set^ name val)
  ```"
  (deprecate :set^ "set! with '^ flag" :v0.7.0 (set! name `^ val)))

(lambda set- [name val]
  "(Deprecated) Remove a value from string-style options.
  Almost equivalent to `:set {option}-={value}` in Vim script.
  ```fennel
  (set- name val)
  ```"
  (deprecate :set- "set! with '- flag" :v0.7.0 (set! name `- val)))

(lambda setlocal+ [name val]
  "(Deprecated) Append a value to string-style local options.
  Almost equivalent to `:setlocal {option}+={value}` in Vim script.
  ```fennel
  (setlocal+ name val)
  ```"
  (deprecate :setlocal+ "setlocal! with '+ flag" :v0.7.0
             (setlocal! name `+ val)))

(lambda setlocal^ [name val]
  "(Deprecated) Prepend a value to string-style local options.
  Almost equivalent to `:setlocal {option}^={value}` in Vim script.
  ```fennel
  (setlocal^ name val)
  ```"
  (deprecate :setlocal+ "setlocal! with '^ flag" :v0.7.0
             (setlocal! name `^ val)))

(lambda setlocal- [name val]
  "(Deprecated) Remove a value from string-style local options.
  Almost equivalent to `:setlocal {option}-={value}` in Vim script.
  ```fennel
  (setlocal- name val)
  ```"
  (deprecate :setlocal- "setlocal! with '- flag" :v0.7.0
             (setlocal! name `- val)))

(lambda setglobal+ [name val]
  "(Deprecated) Append a value to string-style global options.
  Almost equivalent to `:setglobal {option}+={value}` in Vim script.
  ```fennel
  (setglobal+ name val)
  ```
  - name: (string) Option name.
  `- val: (string) Additional option value."
  (deprecate :setglobal+ "setglobal! with '+ flag" :v0.7.0
             (setglobal! name `+ val)))

(lambda setglobal^ [name val]
  "(Deprecated) Prepend a value from string-style global options.
  Almost equivalent to `:setglobal {option}^={value}` in Vim script.
  ```fennel
  (setglobal^ name val)
  ```"
  (deprecate :setglobal^ "setglobal! with '^ flag" :v0.7.0
             (setglobal! name `^ val)))

(lambda setglobal- [name val]
  "(Deprecated) Remove a value from string-style global options.
  Almost equivalent to `:setglobal {option}-={value}` in Vim script.
  ```fennel
  (setglobal- name val)
  ```"
  (deprecate :setglobal- "setglobal! with '- flag" :v0.7.0
             (setglobal! name `- val)))

;; Export ///1

{: map!
 : unmap!
 : <Cmd>
 : <C-u>
 : augroup!
 : autocmd!
 :au! autocmd!
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
 : command!
 : feedkeys!
 : highlight!
 :hi! highlight!
 : set+
 : set^
 : set-
 : setlocal+
 : setlocal^
 : setlocal-
 : setglobal+
 : setglobal^
 : setglobal-
 :go+ setglobal+
 :go^ setglobal^
 :go- setglobal-}

;; vim:fdm=marker:foldmarker=///,""""
