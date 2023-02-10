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

(fn num? [x]
  "Check if `x` is `number`.
  @param x any
  @return boolean"
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
  "Convert `x` to a string, or get the name if `x` is a symbol.
  @param x any
  @return string"
  (tostring x))

(lambda first [xs]
  "Return the first value in `xs`
  @param xs sequence
  @return undefined"
  (. xs 1))

(lambda second [xs]
  "Return the second value in `xs`
  @param xs sequence
  @return undefined"
  (. xs 2))

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
  @param ?extra-opts table Not a sequence.
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

(lambda amp->str [amp]
  "Convert `'&foo` into `:foo`.
  @param amp quoted-symbol
  @return string"
  (-> (->str (->unquoted amp))
      (: :sub 2)))

(lambda extract-amps [seq amps]
  "Extract `'&foo`s from `seq` and return the rest.
  @param seq sequence
  @param amps quoted-symbol[]
  @return sequence"
  (let [new-seq [] ;
        ;; e.g., [(quote &foo)] -> {:foo nil}
        extracted (collect [_ v (ipairs amps)]
                    (amp->str v))]
    (each [_ v (ipairs seq)]
      (if (contains? amps v)
          (tset extracted (amp->str v) true)
          (table.insert new-seq v)))
    (values new-seq extracted)))

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

(lambda autocmd/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  (set opts.<callback> nil)
  (set opts.cb nil)
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
  (if (< (select "#" ...) 3)
      ;; It works as an alias of `vim.api.nvim_create_autocmd()` if only two
      ;; args are provided.
      (let [[events api-opts] [...]]
        `(vim.api.nvim_create_autocmd ,events ,api-opts))
      (let [([?id events & rest] {:vim vim?}) (extract-amps [...] [`&vim])
            [?pattern ?extra-opts callback ?api-opts] ;
            (match rest
              [cb nil nil nil] [nil nil cb nil]
              (where [a ex-opts c ?d] (sequence? ex-opts)) [a ex-opts c ?d]
              [a b ?c nil] (if (or (str? a) (hidden-in-compile-time? a))
                               [nil nil a b]
                               (contains? autocmd/extra-opt-keys (first a))
                               [nil a b ?c] ;
                               [a nil b ?c])
              _ (error* (printf "unexpected args:\n%s" (view [...]))))
            extra-opts (if (nil? ?extra-opts) {}
                           (seq->kv-table ?extra-opts
                                          [:once
                                           :nested
                                           :<buffer>
                                           :ex
                                           :<command>
                                           :cb
                                           :<callback>]))
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
        (when (and (or extra-opts.<command> extra-opts.ex)
                   (or extra-opts.<callback> extra-opts.cb))
          (error* "cannot set both <command>/ex and <callback>/cb."))
        (var vim-cb? false)
        (if ;; TODO: Deprecate `<command>` option.
            (or extra-opts.<command> extra-opts.ex)
            (set extra-opts.command callback)
            vim?
            (set extra-opts.command callback)
            (vim-callback-format? callback)
            ;; TODO: Remove vim-cb? check on v0.6.0.
            ;; (set extra-opts.command callback)
            (set vim-cb? true)
            (or extra-opts.<callback> extra-opts.cb ;
                (sym? callback) ;
                (anonymous-function? callback) ;
                (quoted? callback))
            ;; Note: Ignore the possibility to set Vimscript function to callback
            ;; in string; however, convert `vim.fn.foobar` into "foobar" to set
            ;; to "callback" key because functions written in Vim script are
            ;; rarely supposed to expect the table from `nvim_create_autocmd` for
            ;; its first arg.
            (let [cb (->unquoted callback)
                  cb* (or (extract-?vim-fn-name cb) ;
                          cb)]
              (set extra-opts.callback
                   ;; Note: Either vim.fn.foobar or `vim.fn.foobar should be
                   ;; "foobar" set to "callback" key.
                   (if (quoted? callback)
                       (deprecate "quoted callback" "it without quote" :v0.6.0
                                  cb*)
                       cb*)))
            (set extra-opts.command callback))
        (assert-compile (nand extra-opts.pattern extra-opts.buffer)
                        "cannot set both pattern and buffer for the same autocmd"
                        extra-opts)
        (local deprecated-opts-command? (or extra-opts.<command> extra-opts.ex))
        (local deprecated-opts-callback?
               (or extra-opts.<callback> extra-opts.cb))
        (let [api-opts ;
              (merge-api-opts (autocmd/->compatible-opts! extra-opts)
                              ;; TODO: Remove all the if-expr except `?api-opts` here to set `callback` to `command`.
                              (if vim-cb?
                                  `(vim.tbl_extend :keep (or ,?api-opts {})
                                                   (let [cb# ,callback
                                                         str?# (= :string
                                                                  (type cb#))]
                                                     {:command (when str?#
                                                                 cb#)
                                                      :callback (when (not str?#)
                                                                  ,(deprecate "symbol which, or list whose first symbol, matches \"^<.+>\" to set Lua callback"
                                                                              "another name"
                                                                              :v0.6.0
                                                                              `cb#))}))
                                  (and (list? extra-opts.command)
                                       (and (not vim?)
                                            (not (vim-callback-format? extra-opts.command))))
                                  `(vim.tbl_extend :keep (or ,?api-opts {})
                                                   (let [cb# ,extra-opts.command
                                                         str?# (= :string
                                                                  (type cb#))]
                                                     {:command (when str?#
                                                                 ,(deprecate "bare-list to set Ex command"
                                                                             "&vim, or rename symbol to match `^<.+>`,"
                                                                             :v0.6.0
                                                                             `cb#))
                                                      :callback (when (not str?#)
                                                                  cb#)}))
                                  ?api-opts))]
          `(vim.api.nvim_create_autocmd ,events
                                        ,(if deprecated-opts-command?
                                             (deprecate "special opts <command> and ex"
                                                        "&vim, or rename symbol to match `^<.+>`,"
                                                        :v0.6.0 api-opts)
                                             deprecated-opts-callback?
                                             (deprecate "special opts <callback> and cb"
                                                        "callback with no decorations"
                                                        :v0.6.0 api-opts)
                                             api-opts))))))

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

(lambda augroup! [name ?api-opts|?autocmd ...]
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
  (let [[api-opts autocmds] (if (nil? ?api-opts|?autocmd) [{} []]
                                (or (sequence? ?api-opts|?autocmd)
                                    (autocmd? ?api-opts|?autocmd)) ;
                                [{} [?api-opts|?autocmd ...]]
                                [?api-opts|?autocmd [...]])]
    (define-augroup! name api-opts autocmds)))

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
  (define-autocmd! ...))

;; Keymap ///1

(lambda keymap/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  (set opts.<callback> nil)
  (set opts.cb nil)
  (set opts.literal nil)
  opts)

(lambda keymap/parse-varargs [...]
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
  (let [([a1 a2 ?a3 ?a4] {:vim vim?}) (extract-amps [...] [`&vim])]
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
              rhs (do
                    (when (and (or extra-opts.<command> extra-opts.ex)
                               (or extra-opts.<callback> extra-opts.cb))
                      (error* "cannot set both <command>/ex and <callback>/cb."))
                    (if vim?
                        (do
                          ;; TODO: Remove the dirty hack on v0.6.0.
                          (set extra-opts.vim? true)
                          raw-rhs)
                        (or extra-opts.<command> extra-opts.ex)
                        raw-rhs
                        (vim-callback-format? raw-rhs)
                        raw-rhs
                        (or extra-opts.<callback> extra-opts.cb ;
                            (sym? raw-rhs) ;
                            (anonymous-function? raw-rhs) ;
                            (quoted? raw-rhs))
                        (do
                          (set extra-opts.callback
                               (if (quoted? raw-rhs)
                                   (deprecate "quoted callback"
                                              "it without quote" :v0.6.0
                                              (->unquoted raw-rhs))
                                   (->unquoted raw-rhs)))
                          "")
                        (str? raw-rhs)
                        raw-rhs
                        ;; TODO: Remove list detection on v0.6.0.
                        (list? raw-rhs)
                        raw-rhs
                        (do
                          (set extra-opts.callback raw-rhs)
                          "")))
              ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)]
          (set extra-opts.buffer ?bufnr)
          (values extra-opts lhs rhs ?api-opts)))))

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
  ;; TODO: Remove the dirty workarounds for the compatibility before v0.6.0.
  (local vim? extra-opts.vim?)
  (set extra-opts.vim? nil)
  (local deprecated-opts-command? (or extra-opts.<command> extra-opts.ex))
  (local deprecated-opts-callback? (or extra-opts.<callback> extra-opts.cb))
  (let [?bufnr extra-opts.buffer
        api-opts* (merge-api-opts (keymap/->compatible-opts! extra-opts)
                                  ?api-opts)
        api-opts (if deprecated-opts-command?
                     (deprecate "special opts <command> and ex"
                                "&vim, or rename symbol to match `^<.+>`,"
                                :v0.6.0 api-opts*)
                     deprecated-opts-callback?
                     (deprecate "special opts <callback> and cb"
                                "callback with no decorations" :v0.6.0 api-opts*)
                     api-opts*)
        set-keymap (lambda [mode]
                     ;; TODO: Drop the compatibility on v0.6.0.
                     (if (vim-callback-format? rhs)
                         `(let [cb# ,rhs
                                str?# (= :string (type cb#))
                                rhs# (if str?# cb# "")
                                api-opts# ;
                                (if str?#
                                    ,api-opts
                                    (vim.tbl_extend :force
                                                    ,(keymap/->compatible-opts! extra-opts)
                                                    {:callback ,(deprecate "symbol which, or list whose first symbol, matches \"^<.+>\" to set Lua callback"
                                                                           "another name"
                                                                           :v0.6.0
                                                                           `cb#)}
                                                    (or ,?api-opts {})))]
                            ,(if ?bufnr
                                 `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode
                                                               ,lhs rhs#
                                                               api-opts#)
                                 `(vim.api.nvim_set_keymap ,mode ,lhs rhs#
                                                           api-opts#)))
                         (and (list? rhs)
                              (and (not vim?) ;
                                   (not (vim-callback-format? rhs))))
                         `(let [cb# ,rhs
                                fn?# (= :function (type cb#))
                                rhs# (if fn?# ""
                                         ,(deprecate "list for key sequence"
                                                     "&vim, or rename symbol to match `^<.+>`,"
                                                     :v0.6.0 `cb#))
                                api-opts# ;
                                (if fn?#
                                    (vim.tbl_extend :force
                                                    ,(keymap/->compatible-opts! extra-opts)
                                                    {:callback cb#}
                                                    (or ,?api-opts {}))
                                    ,api-opts)]
                            ,(if ?bufnr
                                 `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode
                                                               ,lhs rhs#
                                                               api-opts#)
                                 `(vim.api.nvim_set_keymap ,mode ,lhs rhs#
                                                           api-opts#)))
                         (if ?bufnr
                             `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode ,lhs
                                                           ,rhs ,api-opts)
                             `(vim.api.nvim_set_keymap ,mode ,lhs ,rhs
                                                       ,api-opts))))
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

(lambda keymap/invisible-key? [lhs]
  "Check if `lhs` is invisible key like `<Plug>`, `<CR>`, `<C-f>`, `<F5>`, etc.
  @param lhs string
  @return boolean"
  (or ;; cspell:ignore acdms
      ;; <C-f>, <M-b>, ...
      (and (lhs:match "<[acdmsACDMS]%-[a-zA-Z0-9]+>")
           (not (lhs:match "<[sS]%-[a-zA-Z]>"))) ;
      ;; <CR>, <Left>, ...
      (lhs:match "<[a-zA-Z][a-zA-Z]+>") ;
      ;; <k0>, <F5>, ...
      (lhs:match "<[fkFK][0-9]>")))

;; Export ///2

(lambda map! [modes ...]
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
        (extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
    (merge-default-kv-table! default-opts extra-opts)
    (keymap/set-maps! modes extra-opts lhs rhs ?api-opts)))

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

(lambda option/modify [api-opts name ?val ?flag]
  (let [name (if (str? name) (name:lower) name)
        interface (match api-opts
                    {:scope nil :buf nil :win nil} `vim.opt
                    {:scope :local} `vim.opt_local
                    {:scope :global} `vim.opt_global
                    {: buf :win nil} (if (= 0 buf) `vim.bo `(. vim.bo ,buf))
                    {: win :buf nil} (if (= 0 win) `vim.wo `(. vim.wo ,win))
                    _ (error* (.. "invalid api-opts: " (view api-opts))))
        opt-obj `(. ,interface ,name)
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
  (let [?flag (: name-?flag :match "[^a-zA-Z]")
        name (if ?flag (: name-?flag :match "[a-zA-Z]+") name-?flag)]
    [name ?flag]))

(lambda option/set [scope name-?flag ?val]
  (let [[name ?flag] (if (str? name-?flag)
                         (option/extract-flag name-?flag)
                         [name-?flag nil])
        val (if (nil? ?val) true ?val)]
    (option/modify scope name val ?flag)))

;; Export ///2

(lambda set! [name-?flag ?val]
  "Set value to the option.
  Almost equivalent to `:set` in Vim script.
  ```fennel
  (set! name-?flag ?val)
  ```
  @param name-?flag string Option name.
    As long as the option name is a bare string, i.e., neither symbol nor list,
    this macro has two advantages:
    1. A flag can be appended to the option name. Append `+`, `^`, or `-`,
       to append, prepend, or remove values, respectively.
    2. Option name is case-insensitive. You can improve readability a bit with
       camelCase/PascalCase. Since `:h {option}` is also case-insensitive,
       `(setlocal! :keywordPrg \":help\")` for fennel still makes sense.
  @param ?val boolean|number|string|table New option value.
    If not provided, the value is supposed to be `true` (experimental).
    This macro is expanding to `(vim.api.nvim_set_option_value name val)`;
    however, when the value is set in either symbol or list,
    this macro is expanding to `(tset vim.opt name val)` instead.
  Note: There is no plan to support option prefix either `no` or `inv`;
  instead, set `false` or `(not vim.go.foo)` respectively.
  Note: This macro has no support for either symbol or list with any flag at
  option name; instead, use `set+`, `set^`, or `set-`, respectively for such
  usage:
  ```fennel
  ;; Invalid usage!
  (let [opt :formatOptions+]
    (set! opt [:1 :B]))
  ;; Use the corresponding macro instead.
  (let [opt :formatOptions]
    (set+ opt [:1 :B]))
  ```"
  (option/set {} name-?flag ?val))

(lambda set+ [name val]
  "Append a value to string-style options.
  Almost equivalent to `:set {option}+={value}` in Vim script.
  ```fennel
  (set+ name val)
  ```"
  (option/modify {} name val "+"))

(lambda set^ [name val]
  "Prepend a value to string-style options.
  Almost equivalent to `:set {option}^={value}` in Vim script.
  ```fennel
  (set^ name val)
  ```"
  (option/modify {} name val "^"))

(lambda set- [name val]
  "Remove a value from string-style options.
  Almost equivalent to `:set {option}-={value}` in Vim script.
  ```fennel
  (set- name val)
  ```"
  (option/modify {} name val "-"))

(lambda setlocal! [name-?flag ?val]
  "Set local value to the option.
  Almost equivalent to `:setlocal` in Vim script.
  ```fennel
  (setlocal! name-?flag ?val)
  ```
  See `set!` for the details."
  (option/set {:scope :local} name-?flag ?val))

(lambda setlocal+ [name val]
  "Append a value to string-style local options.
  Almost equivalent to `:setlocal {option}+={value}` in Vim script.
  ```fennel
  (setlocal+ name val)
  ```"
  (option/modify {:scope :local} name val "+"))

(lambda setlocal^ [name val]
  "Prepend a value to string-style local options.
  Almost equivalent to `:setlocal {option}^={value}` in Vim script.
  ```fennel
  (setlocal^ name val)
  ```"
  (option/modify {:scope :local} name val "^"))

(lambda setlocal- [name val]
  "Remove a value from string-style local options.
  Almost equivalent to `:setlocal {option}-={value}` in Vim script.
  ```fennel
  (setlocal- name val)
  ```"
  (option/modify {:scope :local} name val "-"))

(lambda setglobal! [name-?flag ?val]
  "Set global value to the option.
  Almost equivalent to `:setglobal` in Vim script.
  ```fennel
  (setglobal! name-?flag ?val)
  ```
  See `set!` for the details."
  (option/set {:scope :global} name-?flag ?val))

(lambda setglobal+ [name val]
  "Append a value to string-style global options.
  Almost equivalent to `:setglobal {option}+={value}` in Vim script.
  ```fennel
  (setglobal+ name val)
  ```
  - name: (string) Option name.
  - val: (string) Additional option value."
  (option/modify {:scope :global} name val "+"))

(lambda setglobal^ [name val]
  "Prepend a value from string-style global options.
  Almost equivalent to `:setglobal {option}^={value}` in Vim script.
  ```fennel
  (setglobal^ name val)
  ```"
  (option/modify {:scope :global} name val "^"))

(lambda setglobal- [name val]
  "Remove a value from string-style global options.
  Almost equivalent to `:setglobal {option}-={value}` in Vim script.
  ```fennel
  (setglobal- name val)
  ```"
  (option/modify {:scope :global} name val "-"))

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

(lambda command! [a1 a2 ?a3 ?a4]
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
  (let [?seq-extra-opts (if (sequence? a1) a1
                            (sequence? a2) a2)
        ?extra-opts (when ?seq-extra-opts
                      (seq->kv-table ?seq-extra-opts
                                     [:bar
                                      :bang
                                      :<buffer>
                                      :register
                                      :keepscript]))
        [extra-opts name raw-command ?api-opts] (if-not ?extra-opts
                                                  [{} a1 a2 ?a3]
                                                  (sequence? a1)
                                                  [?extra-opts a2 ?a3 ?a4]
                                                  [?extra-opts a1 ?a3 ?a4])
        command (if (quoted? raw-command)
                    (deprecate "quoted callback" "it without quote" :v0.6.0
                               (->unquoted raw-command))
                    raw-command)
        ?bufnr (if extra-opts.<buffer> 0 extra-opts.buffer)
        api-opts (merge-api-opts (command/->compatible-opts! extra-opts)
                                 ?api-opts)]
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

(lambda highlight! [ns-id|name name|val ?val]
  "Set a highlight group.
  ```fennel
  (highlight! ?ns-id name val)
 ```
 @param ?ns-id integer
 @param name string
 @param val kv-table"
  (let [[?ns-id name val] (if ?val [ns-id|name name|val ?val]
                              [nil ns-id|name name|val])]
    (if (?. val :link)
        (each [k _ (pairs val)]
          (assert-compile (= k :link)
                          (.. "`link` key excludes any other options: " k) val))
        (do
          (when (nil? val.ctermfg)
            (set val.ctermfg (?. val :cterm :fg))
            (when val.cterm
              (set val.cterm.fg nil)))
          (when (nil? val.ctermbg)
            (set val.ctermbg (?. val :cterm :bg))
            (when val.cterm
              (set val.cterm.bg nil)))
          (assert-compile (or (cterm-color? val.ctermfg)
                              (hidden-in-compile-time? val.ctermfg))
                          (.. "ctermfg expects 256 color, got "
                              (view val.ctermfg)) val)
          (assert-compile (or (cterm-color? val.ctermbg)
                              (hidden-in-compile-time? val.ctermbg))
                          (.. "ctermbg expects 256 color, got "
                              (view val.ctermbg)) val)))
    `(vim.api.nvim_set_hl ,(or ?ns-id 0) ,name ,val)))

;; Deprecated ///1

(lambda map-all! [...]
  "(Deprecated) Map `lhs` to `rhs` in all modes recursively.
  ```fennel
  (map-all! ?extra-opts lhs rhs ?api-opts)
  (map-all! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :map-all! "`map!` or your own wrapper" :v0.6.0 ;
             (map! ["" "!" :l :t] ...)))

(lambda map-input! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert/Command-line mode recursively.
  ```fennel
  (map-input! ?extra-opts lhs rhs ?api-opts)
  (map-input! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :map-motion! "`map!` or your own wrapper" :v0.6.0 ;
             (map! "!" ...)))

(lambda map-motion! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode
  recursively.
  ```fennel
  (map-motion! ?extra-opts lhs rhs ?api-opts)
  (map-motion! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table
    Note: This macro could `unmap` `lhs` in Select mode for the performance.
  To avoid this, use `(map! [:n :o :x] ...)` instead."
  (deprecate :map-motion! "`map!` or your own wrapper" :v0.6.0 ;
             (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)
                   ?bufnr extra-opts.buffer]
               (if (str? lhs)
                   (if (keymap/invisible-key? lhs)
                       (map! "" extra-opts lhs rhs ?api-opts)
                       [(map! "" extra-opts lhs rhs ?api-opts)
                        (keymap/del-maps! ?bufnr :s lhs)])
                   (map! [:n :o :x] extra-opts lhs rhs ?api-opts)))))

(lambda map-range! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal/Visual mode recursively.
  ```fennel
  (map-range! ?extra-opts lhs rhs ?api-opts)
  (map-range! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :map-range! "`map!` or your own wrapper" :v0.6.0 ;
             (map! [:n :x] ...)))

(lambda map-operator! [...]
  "(Deprecated) Alias of `map-range!."
  (deprecate :map-operator! "`map!` or your own wrapper" :v0.6.0 ;
             (map-range! ...)))

(lambda map-textobj! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual/Operator-pending mode
  recursively.
  ```fennel
  (map-textobj! ?extra-opts lhs rhs ?api-opts)
  (map-textobj! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :map-textobj! "`map!` or your own wrapper" :v0.6.0 ;
             (map! [:o :x] ...)))

(lambda nmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal mode recursively.
  ```fennel
  (nmap! ?extra-opts lhs rhs ?api-opts)
  (nmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :nmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :n ...)))

(lambda vmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual/Select mode recursively.
  ```fennel
  (vmap! ?extra-opts lhs rhs ?api-opts)
  (vmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :vmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :v ...)))

(lambda xmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual mode recursively.
  ```fennel
  (xmap! ?extra-opts lhs rhs ?api-opts)
  (xmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :xmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :x ...)))

(lambda smap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Select mode recursively.
  ```fennel
  (smap! ?extra-opts lhs rhs ?api-opts)
  (smap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :smap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :s ...)))

(lambda omap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Operator-pending mode recursively.
  ```fennel
  (omap! ?extra-opts lhs rhs ?api-opts)
  (omap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :omap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :o ...)))

(lambda imap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert mode recursively.
  ```fennel
  (imap! ?extra-opts lhs rhs ?api-opts)
  (imap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :imap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :i ...)))

(lambda lmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert/Command-line mode, etc.,
  recursively. `:h language-mapping` for the details.
  ```fennel
  (lmap! ?extra-opts lhs rhs ?api-opts)
  (lmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :lmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :l ...)))

(lambda cmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Command-line mode recursively.
  ```fennel
  (cmap! ?extra-opts lhs rhs ?api-opts)
  (cmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :cmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :c ...)))

(lambda tmap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Terminal mode recursively.
  ```fennel
  (tmap! ?extra-opts lhs rhs ?api-opts)
  (tmap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :tmap! "`map!` or your own wrapper" :v0.6.0 ;
             (map! :t ...)))

(lambda noremap! [modes ...]
  "(Deprecated) Map `lhs` to `rhs` in `modes` non-recursively.
  ```fennel
  (noremap! modes ?extra-opts lhs rhs ?api-opts)
  (noremap! modes lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :noremap! "`map!` or your own wrapper" :v0.6.0 ;
             (let [default-opts {:noremap true}
                   (extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)]
               (merge-default-kv-table! default-opts extra-opts)
               (keymap/set-maps! modes extra-opts lhs rhs ?api-opts))))

(lambda noremap-all! [...]
  "(Deprecated) Map `lhs` to `rhs` in all modes non-recursively.
  ```fennel
  (noremap-all! ?extra-opts lhs rhs ?api-opts)
  (noremap-all! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :noremap-all! "`map!` or your own wrapper" :v0.6.0 ;
             (noremap! ["" "!" :l :t] ...)))

(lambda noremap-input! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert/Command-line mode
  non-recursively.
  ```fennel
  (noremap-input! ?extra-opts lhs rhs ?api-opts)
  (noremap-input! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :noremap-input! "`map!` or your own wrapper" :v0.6.0 ;
             (noremap! "!" ...)))

(lambda noremap-motion! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal/Visual/Operator-pending mode
  non-recursively.
  ```fennel
  (noremap-motion! ?extra-opts lhs rhs ?api-opts)
  (noremap-motion! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table
  Note: This macro could `unmap` `lhs` in Select mode for the performance.
  To avoid this, use `(noremap! [:n :o :x] ...)` instead."
  (deprecate :noremap-motion! "`map!` or your own wrapper" :v0.6.0 ;
             (let [(extra-opts lhs rhs ?api-opts) (keymap/parse-varargs ...)
                   ;; Note: With unknown reason, keymap/del-maps! fails to get
                   ;; `extra-opts.buffer` only to find it `nil` unless it's set to `?bufnr`.
                   ?bufnr extra-opts.buffer]
               (if (str? lhs)
                   (if (keymap/invisible-key? lhs)
                       (noremap! "" extra-opts lhs rhs ?api-opts)
                       [(noremap! "" extra-opts lhs rhs ?api-opts)
                        (keymap/del-maps! ?bufnr :s lhs)])
                   (noremap! [:n :o :x] extra-opts lhs rhs ?api-opts)))))

(lambda noremap-range! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal/Visual mode non-recursively.
  ```fennel
  (noremap-range! ?extra-opts lhs rhs ?api-opts)
  (noremap-range! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :noremap-range! "`map!` or your own wrapper" :v0.6.0 ;
             (noremap! [:n :x] ...)))

(lambda noremap-operator! [...]
  "(Deprecated) Alias of `noremap-range!`."
  (deprecate :noremap-operator! "`map!` or your own wrapper" :v0.6.0 ;
             (noremap-range! ...)))

(lambda noremap-textobj! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual/Operator-pending mode
  non-recursively.
  ```fennel
  (noremap-textobj! ?extra-opts lhs rhs ?api-opts)
  (noremap-textobj! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (noremap! [:o :x] ...))

(lambda nnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Normal mode non-recursively.
  ```fennel
  (nnoremap! ?extra-opts lhs rhs ?api-opts)
  (nnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :nnoremap! :map! :v0.6.0 ;
             (noremap! :n ...)))

(lambda vnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual/Select mode non-recursively.
  ```fennel
  (vnoremap! ?extra-opts lhs rhs ?api-opts)
  (vnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :vnoremap! :map! :v0.6.0 ;
             (noremap! :v ...)))

(lambda xnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Visual mode non-recursively.
  ```fennel
  (xnoremap! ?extra-opts lhs rhs ?api-opts)
  (xnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :xnoremap! :map! :v0.6.0 ;
             (noremap! :x ...)))

(lambda snoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Select mode non-recursively.
  ```fennel
  (snoremap! ?extra-opts lhs rhs ?api-opts)
  (snoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :snoremap! :map! :v0.6.0 ;
             (noremap! :s ...)))

(lambda onoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Operator-pending mode non-recursively.
  ```fennel
  (onoremap! ?extra-opts lhs rhs ?api-opts)
  (onoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :onoremap! :map! :v0.6.0 ;
             (noremap! :o ...)))

(lambda inoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert mode non-recursively.
  ```fennel
  (inoremap! ?extra-opts lhs rhs ?api-opts)
  (inoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :inoremap! :map! :v0.6.0 ;
             (noremap! :i ...)))

(lambda lnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Insert/Command-line mode, etc.,
  non-recursively. `:h language-mapping` for the details.
  ```fennel
  (lnoremap! ?extra-opts lhs rhs ?api-opts)
  (lnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :lnoremap! :map! :v0.6.0 ;
             (noremap! :l ...)))

(lambda cnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Command-line mode non-recursively.
  ```fennel
  (cnoremap! ?extra-opts lhs rhs ?api-opts)
  (cnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :cnoremap! :map! :v0.6.0 ;
             (noremap! :c ...)))

(lambda tnoremap! [...]
  "(Deprecated) Map `lhs` to `rhs` in Terminal mode non-recursively.
  ```fennel
  (tnoremap! ?extra-opts lhs rhs ?api-opts)
  (tnoremap! lhs ?extra-opts rhs ?api-opts)
  ```
  @param modes string|string[]
  @param ?extra-opts bare-sequence
  @param lhs string
  @param rhs string|function
  @param ?api-opts kv-table"
  (deprecate :tnoremap! :map! :v0.6.0 ;
             (noremap! :t ...)))

(lambda augroup+ [name ...]
  "(Deprecated) Create, or get, an augroup, or add `autocmd`s to an existing
  augroup.
  ```fennel
  (augroup+ name
    ?[events ?pattern ?extra-opts callback ?api-opts]
    ?(au! events ?pattern ?extra-opts callback ?api-opts)
    ?(autocmd! events ?pattern ?extra-opts callback ?api-opts)
    ?...)
  ```
  @param name string Augroup name.
  @return undefined Without `...`, the return value of `nvim_create_augroup`;
      otherwise, undefined (currently a sequence of `autocmd`s defined in the)
      augroup."
  (deprecate :augroup+ :augroup! :v0.6.0
             (augroup! name
               {:clear false}
               ...)))

;; Export ///1

{: map!
 : unmap!
 : <Cmd>
 : <C-u>
 : augroup!
 : autocmd!
 :au! autocmd!
 : set!
 : set+
 : set^
 : set-
 : setlocal!
 : setlocal+
 : setlocal^
 : setlocal-
 : setglobal!
 : setglobal+
 : setglobal^
 : setglobal-
 :go! setglobal!
 :go+ setglobal+
 :go^ setglobal^
 :go- setglobal-
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
 : map-all!
 : map-input!
 : map-motion!
 : map-range!
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
 : noremap!
 : noremap-all!
 : noremap-input!
 : noremap-motion!
 : noremap-range!
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
 : augroup+}

;; vim:fdm=marker:foldmarker=///,""""
