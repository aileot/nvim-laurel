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

;; General Utils ///1
;; Predicates ///2

(λ contains? [xs ?a]
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

(fn error-fmt [str ...]
  (error (str:format ...)))

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

;; (fn dec [x]
;;   "Decrement number `x`.
;;   @param x number
;;   @return number"
;;   (assert-compile (num? x) "Expected number" x)
;;   (- x 1))

(λ first [xs]
  "Return the first value in `xs`.
@param xs sequence|list
@return any"
  (assert-seq xs)
  (. xs 1))

(λ second [xs]
  "Return the second value in `xs`.
@param xs sequence|list
@return any"
  (assert-seq xs)
  (. xs 2))

;; (fn last [xs]
;;   "Return the last value in `xs`.
;;   @param xs sequence|list
;;   @return any"
;;   (assert-seq xs)
;;   (. xs (length xs)))

(λ slice [xs ?start ?end]
  "Return sequence from `?start` to `?end`.
@param xs sequence
@param ?start integer
@param ?end integer
@return sequence"
  (let [first (or ?start 1)
        last (or ?end (length xs))]
    (fcollect [i first last]
      (. xs i))))

;; (fn prefer-sequence [seq]
;;   "Return `seq` as it is if `seq` is a bare-sequence; otherwise, wrap the item
;; `seq` into sequence initializer.
;; @param seq any
;; @return any"
;;   (if (seq? seq) seq [seq]))

(fn dislike-sequence [seq]
  "Strip off sequence initializer and return as the item if `seq` is
a bare-sequence which only contains one item; otherwise, return `seq` as it
is.
@param seq any
@return any"
  (if (and (seq? seq) (< (length seq) 2))
      (first seq)
      seq))

(fn tbl->keys [tbl]
  "Return keys of `tbl`.
@param tbl table
@return sequence"
  (icollect [k _ (pairs tbl)]
    k))

;; (fn tbl->values [tbl]
;;   "Return values of `tbl`.
;;   @param tbl table
;;   @return sequence"
;;   (icollect [_ v (pairs tbl)]
;;     v))

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
@param ... kv-table|nil symbol or list are unexpected.
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
@param ... kv-table|nil symbol or list are unexpected.
@return table"
  (each [_ t (ipairs [...])]
    (when t
      (assert-compile (tbl? t) "Expected table or nil" ...)
      (each [k v (pairs t)]
        (tset tbl1 k v))))
  tbl1)

;; Additional predicates ///2

;; (fn quoted? [x]
;;   "Check if `x` is a list which begins with `quote`.
;;   @param x any
;;   @return boolean"
;;   (and (list? x) ;
;;        (= `quote (first x))))

;; (fn anonymous-function? [x]
;;   "(Compile time) Check if type of `x` is anonymous function.
;;   @param x any
;;   @return boolean"
;;   (and (list? x) ;
;;        (contains? [`fn `hashfn `lambda `partial] (first x))))

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

(λ error* [msg]
  "Throw error with prefix."
  (error (.. "[nvim-laurel] " msg)))

(λ msg-template/expected-actual [expected actual ...]
  "Assert `expr` but with error message in template.
  ```fennel
  (msg-template/expected-actual [expected actual] ?dump)
  ```
  @param expected string text to be inserted in \"expected %s\"
  @param actual string
  @param dump string"
  (let [msg (: "expected %s, got %s" :format expected actual)]
    (case (select "#" ...)
      0 msg
      1 (.. msg "\ndump:\n" (select 1 ...))
      _ (error* (msg-template/expected-actual "2 or 3 args"
                                              (+ 2 (select "#" ...)))))))

(λ validate-type [val valid-type-list]
  "Validate the type of `val` is one of valid-types. When `val` is symbol or
list, it's ignored.
@param val any
@param valid-type-list string|string[]
@return any `val` as is"
  (when-not (hidden-in-compile-time? val)
    (let [val-type (type val)
          valid-types (case valid-type-list
                        [:default _ & rest] rest
                        _ valid-type-list)]
      (assert (contains? valid-types val-type)
              (: "expected %s, got %s" ;
                 :format (table.concat valid-types "/") val-type))))
  val)

(λ extra-opts/supplement-desc-key! [extra-opts extra-opt-valid-keys]
  "Insert missing `desc` key in `extra-opts` sequence.
@param extra-opts sequence
@param extra-opt-valid-keys string[]
@return sequence"
  (if (. extra-opt-valid-keys (first extra-opts)) extra-opts
      (do
        (table.insert extra-opts 1 :desc)
        extra-opts)))

(λ extra-opts/seq->kv-table [xs valid-option-types]
  "Convert `xs` into a kv-table as follows:

- The keys in `valid-option-types` cannot be a value of `x`. So, when the
  next value of `x` is a key `valid-option-types`, the value next to `:default`
  in `valid-option-types` at `x` is set to `x`.
- When the valid type of `valid-option-types` of `x` is boolean, set to `true`.
- The values for the rest of `x`s are set to the next value in `xs`.
  @param xs sequence
  @param valid-option-types 'boolean'|table<string,string[]> Type-validation table for each available option. Set :boolean instead to set to `true`.
  @return kv-table"
  (assert (sequence? xs) (.. "expected sequence, got " (type xs)))
  (let [kv-table {}
        new-xs (extra-opts/supplement-desc-key! xs valid-option-types)
        max (length new-xs)]
    (var i 1)
    (while (<= i max)
      (let [key (. new-xs i)
            val (case (. valid-option-types key)
                  :boolean true
                  valid-types (let [next-val (. new-xs (inc i))]
                                (if (or (. valid-option-types next-val)
                                        (<= max i))
                                    (case valid-types
                                      :boolean true
                                      [:default default-val] default-val
                                      _ (error-fmt "`%s` key requires a value"
                                                   key))
                                    (do
                                      (++ i)
                                      (validate-type next-val valid-types))))
                  _ (error (.. "Invalid option in extra-opts: " key)))]
        (assert (not= nil val) (: "nil at `%s` key is unexpected" :format key))
        (tset kv-table key val))
      (++ i))
    kv-table))

(λ merge-api-opts [?extra-opts ?api-opts]
  "Merge `?api-opts` into `?extra-opts` safely.
@param ?extra-opts kv-table|nil
@param ?api-opts kv-table|symbol|list
@return table"
  (if (hidden-in-compile-time? ?api-opts)
      (if (nil? ?extra-opts) `(or ,?api-opts {})
          `(vim.tbl_extend :force ,?extra-opts ,?api-opts))
      (nil? ?api-opts)
      (or ?extra-opts {})
      (collect [k v (pairs ?api-opts) &into ?extra-opts]
        (values k v))))

;; (fn ->unquoted [x]
;;   "If quoted, return unquoted `x`; otherwise, just return `x` itself.
;;   @param x any but nil
;;   @return any"
;;   (if (quoted? x)
;;       (second x)
;;       x))

(λ extract-?vim-fn-name [x]
  "Extract \"foobar\" from multi-symbol `vim.fn.foobar`, or return `nil`.
  @param x any
  @return string|nil"
  (let [name (->str x)
        pat-vim-fn "^vim%.fn%.(%S+)$"]
    (name:match pat-vim-fn)))

(λ extract-symbols [seq sym-names]
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

(var args nil)
(fn pin-args [callback]
  "Pin arguments to specify deprecated code location later."
  (fn [...]
    (set args [...])
    (callback ...)))

(λ deprecate [deprecated alternative version compatible]
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
        deprecation `(vim.deprecate ,(: "[nvim-laurel] %s" :format deprecated)
                                    ,alternative
                                    ,(: "%s. `:cexpr g:laurel_deprecated` would help you update it. See `:h g:laurel_deprecated` for the details."
                                        :format version)
                                    :nvim-laurel false)
        msg (: "nvim-laurel: %s is deprecated. Please update it with %s."
               :format deprecated alternative)]
    (case (accumulate [(?filename _line) nil _ a (ipairs args) &until ?filename]
            (let [ast (ast-source a)]
              (values ast.filename ast.line)))
      (fnl-path row) (let [qf-msg (string.format gcc-error-format fnl-path row
                                                 msg)]
                       `(do
                          (tset vim.g :laurel_deprecated
                                (or vim.g.laurel_deprecated {}))
                          ;; Note: `table.insert` instead cannot handle `vim.g` interface.
                          (tset vim.g :laurel_deprecated
                                (vim.fn.add vim.g.laurel_deprecated ,qf-msg))
                          ;; Note: It's safer to wrap it in `vim.schedule`.
                          (vim.schedule #,deprecation)
                          ,compatible))
      _ `(do
           (when (= nil _G.__laurel_has_fnl_dir)
             (tset _G :__laurel_has_fnl_dir
                   (= 1
                      (vim.fn.isdirectory (.. (vim.fn.stdpath :config) :/fnl)))))
           (tset vim.g :laurel_deprecated (or vim.g.laurel_deprecated {}))
           ;; Note: `table.insert` instead cannot handle `vim.g` interface.
           (let [qf-msg# ;
                 (let [{:source source# :linedefined row#} (debug.getinfo 1 :S)
                       lua-path# (source#:gsub "^@" "")
                       /fnl/-or-/lua/# (if _G.__laurel_has_fnl_dir :/fnl/
                                           :/lua/)
                       fnl-path# (.. (vim.fn.stdpath :config)
                                     (-> lua-path#
                                         (: :gsub "%.lua$" :.fnl)
                                         (: :gsub :^.-/lua/ /fnl/-or-/lua/#)))]
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

(λ default/extract-opts! [seq]
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

(λ default/release-opts! []
  "Return saved default opts defined by user, and reset them.
  This operation can run without stack because macro expansion only runs sequentially.
  @return kv-table"
  ;; Note: This function is required to accept multiple &default-opts instead
  ;; of clearing default/api-opts on each default/extract-opts! call.
  (let [opts (tbl/copy default/api-opts)]
    (each [k _ (pairs default/api-opts)]
      (tset default/api-opts k nil))
    opts))

(λ default/merge-opts! [api-opts]
  "Return the merge result of `api-opts` and `default/api-opts` saved by
`default/extract-opts!`. The values of `api-opts` overrides those of
`default/api-opts`. The `default/api-opts` gets cleared after the merge.
@param api-opts kv-table The options to override `default/api-opts`.
@return kv-table"
  (tbl/merge (default/release-opts!) api-opts))

;; Autocmd ///1

(local autocmd/extra-opt-keys
       {:<buffer> :boolean
        :buffer [:default 0 :number]
        :callback [:function]
        :command [:string]
        :desc [:string]
        :nested :boolean
        :once :boolean
        :pattern [:string :table]
        :group [:string :number]})

(λ autocmd/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.<buffer> nil)
  opts)

(λ define-autocmd! [...]
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
@param ?pattern bare-sequence|`*` pattern(s) to match literally `autocmd-pattern`.
@param ?extra-opts bare-sequence
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
            [a b ?c nil] (if (= `* a)
                             (if (sequence? b)
                                 (values "*" b ?c)
                                 (values "*" nil b ?c))
                             (or (str? a) (hidden-in-compile-time? a))
                             (values nil nil a b)
                             (or (. autocmd/extra-opt-keys (first a))
                                 (. autocmd/extra-opt-keys (second a)))
                             (values nil a b ?c)
                             (values a nil b ?c))
            _ (error* (: "unexpected args:\n?id: %s\nevents: %s\nrest: %s"
                         :format (view args) (view ?id) (view events)
                         (view rest))))
          extra-opts (if (nil? ?extra-opts) {}
                         (-> ?extra-opts
                             (extra-opts/seq->kv-table autocmd/extra-opt-keys)))
          ?bufnr (if extra-opts.<buffer>
                     (deprecate ":<buffer> key" ":buffer key alone, or with 0,"
                                :v0.9.0 0)
                     extra-opts.buffer)
          ?pat (or extra-opts.pattern ?pattern)]
      (set extra-opts.group ?id)
      (set extra-opts.buffer ?bufnr)
      (let [pat (if (and (sequence? ?pat) (= 1 (length ?pat)))
                    (first ?pat)
                    ?pat)
            pattern (if (= `* pat) "*" pat)]
        ;; Note: `*` is the default pattern and redundant in compiled result.
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

(λ define-augroup! [name api-opts autocmds]
  "Define an augroup.

```fennel
(define-augroup! name api-opts [events ?pattern ?extra-opts callback ?api-opts])
(define-augroup! name api-opts
  (au! events ?pattern ?extra-opts callback ?api-opts))

(define-augroup! name api-opts
  (autocmd! events ?pattern ?extra-opts callback ?api-opts))
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
         ,(-> (icollect [_ args (ipairs autocmds)]
                (let [au-args (if (autocmd? args)
                                  (slice args 2)
                                  (sequence? args)
                                  args
                                  (error* (msg-template/expected-actual "sequence, or list which starts with `au!` or `autocmd!`"
                                                                        (type args)
                                                                        (view args))))]
                  (define-autocmd! `id# (unpack au-args))))
              (unpack)))))

;; Export ///2

(λ augroup! [...]
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
@param ?pattern bare-sequence|`*` pattern(s) to match literally `autocmd-pattern`.
@param ?extra-opts bare-sequence
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

(local keymap/extra-opt-keys {:<buffer> :boolean
                              :buffer [:default 0 :number]
                              :callback [:function]
                              :desc [:string]
                              :expr :boolean
                              :literal :boolean
                              :noremap :boolean
                              :nowait :boolean
                              :remap :boolean
                              :replace_keycodes :boolean
                              :script :boolean
                              :silent :boolean
                              :unique :boolean
                              :wait :boolean})

(λ keymap/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  (set opts.literal nil)
  (set opts.wait nil)
  opts)

(λ keymap/parse-args [...]
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
  (let [args (default/extract-opts! [...])
        ([modes a1 a2 ?a3 ?a4] {:&vim ?vim-indice}) ;
        (extract-symbols args [`&vim])]
    (if (kv-table? a1) (values a1 a2 ?a3 ?a4)
        (let [?seq-extra-opts (if (sequence? a1) a1
                                  (sequence? a2) a2)
              ?extra-opts (when ?seq-extra-opts
                            (-> ?seq-extra-opts
                                (extra-opts/seq->kv-table keymap/extra-opt-keys)))
              [extra-opts lhs raw-rhs ?api-opts] (if-not ?extra-opts
                                                   [{} a1 a2 ?a3]
                                                   (sequence? a1)
                                                   [?extra-opts a2 ?a3 ?a4]
                                                   [?extra-opts a1 ?a3 ?a4])
              extra-opts* (default/merge-opts! extra-opts)
              rhs (if (or ?vim-indice (str? raw-rhs)
                          (vim-callback-format? raw-rhs))
                      raw-rhs
                      (do
                        (set extra-opts*.callback raw-rhs)
                        ""))
              ?bufnr (if extra-opts*.<buffer>
                         (deprecate ":<buffer> key"
                                    ":buffer key alone, or with 0," :v0.9.0 0)
                         extra-opts*.buffer)]
          (set extra-opts*.buffer ?bufnr)
          (values modes extra-opts* lhs rhs ?api-opts)))))

(λ keymap/del-maps! [...]
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
    (if (str? mode)
        (if ?bufnr
            `(vim.api.nvim_buf_del_keymap ,?bufnr ,mode ,lhs)
            `(vim.api.nvim_del_keymap ,mode ,lhs))
        (if ?bufnr
            ;; Note: Prefer the simplicity of the wrapper to extra
            ;; optimizations; `unmap` is unlikely to be used here and there.
            `(vim.keymap.del ,mode ,lhs {:buffer ,?bufnr})
            `(vim.keymap.del ,mode ,lhs)))))

(λ keymap/set-maps! [modes extra-opts lhs rhs ?api-opts]
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
    (set extra-opts.replace_keycodes
         (if extra-opts.literal
             false
             true)))
  (when extra-opts.wait
    (set extra-opts.nowait nil))
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
        set-keymap (λ [mode]
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
        `(do
           ,(-> (icollect [_ m (ipairs modes)]
                  (set-keymap m))
                (unpack))))))

;; Export ///2

(λ map! [...]
  "Map `lhs` to `rhs` in `modes`, non-recursively by default.

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
        (modes extra-opts lhs rhs ?api-opts) (keymap/parse-args ...)
        extra-opts* (tbl/merge default-opts extra-opts)]
    (keymap/set-maps! modes extra-opts* lhs rhs ?api-opts)))

(λ unmap! [...]
  "Delete keymap.

```fennel
(unmap! ?bufnr mode lhs)
```

@param ?bufnr integer Buffer handle, or 0 for current buffer
@param mode string
@param lhs string"
  (keymap/del-maps! ...))

(λ <Cmd> [x]
  "Return\"<Cmd>`x`<CR>\"
  @param x string
  @return string"
  (if (str? x)
      (.. :<Cmd> x :<CR>)
      `(.. :<Cmd> ,x :<CR>)))

(λ <C-u> [x]
  "Return\":<C-u>`x`<CR>\"
  @param x string
  @return string"
  (if (str? x)
      (.. ":<C-u>" x :<CR>)
      `(.. ":<C-u>" ,x :<CR>)))

;; Variable ///1

(λ g! [name val]
  "(Subject to be deprecated in favor of `let!`)
Set global (`g:`) editor variable.

```fennel
(g! name val)
```

@param name string Variable name.
@param val any Variable value."
  `(vim.api.nvim_set_var ,name ,val))

(λ b! [id|name name|val ?val]
  "(Subject to be deprecated in favor of `let!`)
Set buffer-scoped (`b:`) variable for the current buffer. Can be indexed
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

(λ w! [id|name name|val ?val]
  "(Subject to be deprecated in favor of `let!`)
Set window-scoped (`w:`) variable for the current window. Can be indexed
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

(λ t! [id|name name|val ?val]
  "(Subject to be deprecated in favor of `let!`)
Set tabpage-scoped (`t:`) variable for the current tabpage. Can be indexed
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

(λ v! [name val]
  "(Subject to be deprecated in favor of `let!`)
Set `v:` variable if not readonly.

```fennel
(v! name val)
```

@param name string Variable name.
@param val any Variable value."
  `(vim.api.nvim_set_vvar ,name ,val))

(λ env! [name val]
  "(Subject to be deprecated in favor of `let!`)
Set environment variable in the editor session.

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

(λ option/concat-kv-table [kv-table]
  "Concat kv table into a string for `vim.api.nvim_set_option_value`.
For example,
`{:eob\"
 \" :fold\"-\"})` should be compiled to `\"eob: ,fold:-\"`"
  (assert-compile (table? kv-table)
                  (msg-template/expected-actual :table (type kv-table)
                                                (view kv-table))
                  kv-table)
  (let [key-val (icollect [k v (pairs kv-table)]
                  (.. k ":" v))]
    (table.concat key-val ",")))

(λ option/->?vim-value [?val]
  "Return in vim value for such API as `nvim_set_option`.
@param val any
@return 'vim.NIL|boolean|number|string|nil"
  (case (type ?val)
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

(λ option/modify [api-opts raw-name ?val ?q-flag]
  (let [(name ?infix-flag) (if (str? raw-name)
                               (case (raw-name:match "^(%a+)(%A?)$")
                                 (name flag) (values (name:lower)
                                                     (if (= "" flag) nil flag))
                                 _ (error (.. "invalid option name format: "
                                              raw-name)))
                               raw-name)
        interface (case api-opts
                    {:scope nil :buf nil :win nil} `vim.opt
                    {:scope "local"} `vim.opt_local
                    {:scope "global"} `vim.opt_global
                    {: buf :win nil} (if (= 0 buf) `vim.bo `(. vim.bo ,buf))
                    {: win :buf nil} (if (= 0 win) `vim.wo `(. vim.wo ,win))
                    _ (error* (.. "invalid api-opts: " (view api-opts))))
        ;; opt-obj `(. ,interface ,name)
        opt-obj (if ?infix-flag
                    (deprecate "flag-in-name format like `(set! :foo+ :bar)`"
                               "infix flag like `(set! :foo + :bar)`" :v0.8.0
                               `(. ,interface ,name))
                    `(. ,interface ,name))
        ?flag (when ?q-flag
                (->str ?q-flag))
        ?val (if (and (contains? [:formatoptions :fo :shortmess :shm] name)
                      (sequence? ?val) (not= ?flag "-"))
                 (if (option/concatenatable? ?val)
                     (table.concat ?val)
                     `(table.concat ,?val))
                 ?val)]
    (case (or ?flag ?infix-flag)
      "?"
      `(vim.api.nvim_get_option_value ,name ,api-opts)
      nil
      (case (option/->?vim-value ?val)
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
                                      (vim.api.nvim_get_option_value ,name
                                                                     {:scope "global"})
                                      {:scope "local"})
      ;; "&" `(vim.cmd.set (.. ,name "&"))
      _
      (error* (.. "Invalid vim option modifier: " (view ?flag))))))

;; Export ///2

(λ let! [scope ...]
  "(Experimental) Set editor variable in `scope`.
  This macro is expanded to a list of `vim.api` in most cases; otherwise,
  this macro is expanded to `(tset vim.opt name val)` instead.
  The Exceptions:
    - `scope` is set in either symbol or list.
    - `?val` is set in either symbol or list.
  ```fennel
  (let! scope name val)
  (let! scope name ?flag val) ; only in the scope: `opt`, `opt_local`, or `opt_global`
  (let! scope ?id name val) ; only in the scope: `b`, `w`, or `t`
  ```
  @param scope \"g\"
  |\"b\"
  |\"w\"
  |\"t\"
  |\"v\"
  |\"env\"
  |\"o\"
  |\"go\"
  |\"bo\"
  |\"wo\"
  |\"opt\"
  |\"opt_local\"
  |\"opt_global\"
  One of the scopes
  @param ?id integer Optional location handle, or 0 for current location:
    buffer, window, or tabpage. Only available in the scopes `b`, `w`, or `t`.
  @param name string Variable name.
  @param ?flag symbol Omittable flag. Set one of `+`, `^`, or `-` to append,
    prepend, or remove, value to the option. Only available in the `scope`s:
    `opt`, `opt_local`, `opt_global`.
  @param val boolean|number|string|table New option value."
  (if (hidden-in-compile-time? scope)
      (if (= 1 (select "#" ...))
          (deprecate "(Partial) The format `let!` without value"
                     "Set `true` to set it to `true` explicitly" :v0.8.0
                     `(tset vim ,scope ,... true))
          `(tset vim ,scope ,...))
      (let [supported-flags [`+ `- `^ `? `! `& `<]
            (args-without-flags symbols) (extract-symbols [...] supported-flags)
            ?flag (next symbols)]
        (assert (< (length (tbl->keys symbols)) 2)
                "only one symbol is supported at most")
        (case (case scope
                :g (values 2 `vim.api.nvim_set_var `vim.api.nvim_get_var)
                :b (values 3 `vim.api.nvim_buf_set_var
                           `vim.api.nvim_buf_get_var)
                :w (values 3 `vim.api.nvim_win_set_var
                           `vim.api.nvim_win_get_var)
                :t (values 3 `vim.api.nvim_tabpage_set_var
                           `vim.api.nvim_tabpage_get_var)
                :v (values 2 `vim.api.nvim_set_vvar `vim.api.nvim_get_vvar)
                :env (values 2 `vim.fn.setenv `vim.fn.getenv)
                _ (values 3 `vim.api.nvim_set_option_value
                          `vim.api.nvim_get_option_value))
          (max-args setter getter)
          ;; Vim Variables
          (let [actual-arg-count (length args-without-flags)
                (?id name val) (case max-args
                                 3
                                 (case actual-arg-count
                                   3 (unpack args-without-flags)
                                   2 (if (= "?" ?flag)
                                         (unpack args-without-flags)
                                         (values 0 (unpack args-without-flags)))
                                   1 (values 0 (unpack args-without-flags)
                                             (deprecate "(Partial) The format `let!` without value"
                                                        "Set `true` to set it to `true` explicitly"
                                                        :v0.8.0 true))
                                   _ (error* (.. "expected 1, 2, or 3 args, got "
                                                 actual-arg-count)))
                                 ;; For 2, `?id` should be `nil`.
                                 2
                                 (case actual-arg-count
                                   2 (values nil (unpack args-without-flags))
                                   1 (values nil (unpack args-without-flags)
                                             (deprecate "(Partial) The format `let!` without value"
                                                        "Set `true` to set it to `true` explicitly"
                                                        :v0.8.0 true))
                                   _ (error* (.. "expected 1 or 2 args, got "
                                                 actual-arg-count)))
                                 _
                                 (error* (.. "expected 2 or 3, got " max-args)))
                name* (if (and (= scope :env) (str? name))
                          (name:gsub "^%$" "")
                          name)]
            (if (= setter `vim.api.nvim_set_option_value)
                ;; Vim Options
                (let [opts (case (values scope args-without-flags)
                             (where (or :o :opt)) {}
                             :opt_local {:scope "local"}
                             (where (or :go :opt_global)) {:scope "global"}
                             :bo {:buf ?id}
                             :wo {:win ?id}
                             _ (error* (-> "Invalid scope %s in type %s with args %s to be `unpack`ed"
                                           (: :format (view scope) (type scope)
                                              (view args-without-flags)))))]
                  (option/modify opts name val ?flag))
                ;; Vim Variables
                (let [should-use-getter? (= "?" ?flag)]
                  (case max-args
                    2 (if should-use-getter?
                          `(,getter ,name*)
                          `(,setter ,name* ,val))
                    3 (do
                        (assert (or (= :number (type ?id))
                                    (hidden-in-compile-time? ?id))
                                (-> "for %s, expected number, got %s: %s"
                                    (: :format name* (type ?id) (view ?id))))
                        (if should-use-getter?
                            `(,getter ,?id ,name*)
                            `(,setter ,?id ,name* ,val)))))))))))

(λ set! [...]
  "(Deprecated in favor of `let!`)
  Set value to the option.
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
  (let! :opt ...))

(λ setlocal! [...]
  "(Deprecated in favor of `let!`)
Set local value to the option.
Almost equivalent to `:setlocal` in Vim script.

```fennel
(setlocal! name-?flag ?val)
```

See `set!` for the details."
  (let! :opt_local ...))

(λ setglobal! [...]
  "(Deprecated in favor of `let!`)
Set global value to the option.
Almost equivalent to `:setglobal` in Vim script.

```fennel
(setglobal! name-?flag ?val)
```

See `set!` for the details."
  (let! :opt_global ...))

(λ bo! [...]
  "(Deprecated in favor of `let!`)
Set a buffer option value.

```fennel
(bo! ?id name value)
```

@param ?id integer Buffer handle, or 0 for current buffer.
@param name string Option name. Case-insensitive as long as in bare-string.
@param value any Option value."
  (let! :bo ...))

(λ wo! [...]
  "(Deprecated in favor of `let!`)
Set a window option value.

```fennel
(wo! ?id name value)
```

@param ?id integer Window handle, or 0 for current window.
@param name string Option name. Case-insensitive as long as in bare-string.
@param value any Option value."
  (let! :wo ...))

;; Command ///1

(local command/extra-opt-keys
       {:<buffer> :boolean
        :addr [:string]
        :bang :boolean
        :bar :boolean
        :buffer [:default 0 :number]
        :complete [:function :string]
        :count [:default 0 :number]
        :desc [:string]
        :keepscript :boolean
        :nargs [:string]
        :preview [:function]
        :range [:default true :number :string]
        :register :boolean})

(λ command/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  opts)

(λ command! [...]
  "Define a user command.

```fennel
(command! ?extra-opts name command ?api-opts)
(command! name ?extra-opts command ?api-opts)
```

@param ?extra-opts bare-sequence Optional command attributes.
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
                (extra-opts/seq->kv-table ?seq-extra-opts
                                          command/extra-opt-keys))
          nil (values {} a1 a2 ?a3)
          extra-opts (if (sequence? a1)
                         (values extra-opts a2 ?a3 ?a4)
                         (values extra-opts a1 ?a3 ?a4)))
        extra-opts* (default/merge-opts! extra-opts)
        ?bufnr (if extra-opts*.<buffer>
                   (deprecate ":<buffer> key" ":buffer key alone, or with 0,"
                              :v0.9.0 0)
                   extra-opts*.buffer)
        api-opts (-> (command/->compatible-opts! extra-opts*)
                     (merge-api-opts ?api-opts))]
    (if ?bufnr
        `(vim.api.nvim_buf_create_user_command ,?bufnr ,name ,command ,api-opts)
        `(vim.api.nvim_create_user_command ,name ,command ,api-opts))))

;; Misc ///1

(λ str->keycodes [str]
  "Replace terminal codes and keycodes in a string.

```fennel
(str->keycodes str)
```

@param str string
@return string"
  `(vim.api.nvim_replace_termcodes ,str true true true))

(λ feedkeys! [keys ?flags]
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

(λ cterm-color? [?color]
  "`:h cterm-colors`
@param ?color any
@return boolean"
  (or (nil? ?color) (num? ?color) (and (str? ?color) (?color:match "[a-zA-Z]"))))

(λ highlight! [...]
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
                        (view api-opts*.ctermfg)) api-opts*)
    (assert-compile (or (cterm-color? api-opts*.ctermbg)
                        (hidden-in-compile-time? api-opts*.ctermbg))
                    (.. "ctermbg expects 256 color, got "
                        (view api-opts*.ctermbg)) api-opts*)
    `(vim.api.nvim_set_hl ,(or ?ns-id 0) ,name ,api-opts*)))

;; Deprecated ///1

;; Export ///1

(collect [k v (pairs {: map!
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
                      : let!})]
  (values k (pin-args v)))

;; vim:fdm=marker:foldmarker=///,""""
