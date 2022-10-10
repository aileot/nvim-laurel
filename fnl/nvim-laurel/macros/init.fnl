(import-macros {: if-not
                : contains?
                : ->str
                : str?
                : num?
                : fn?
                : nil?
                : ++
                : slice} :nvim-laurel.macros.utils)

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
  (let [name (name:lower)
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

;; Export ///1
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

;; Variable ///1
(lambda b! [name val]
  `(tset vim.b ,name ,val))

(lambda w! [name val]
  `(tset vim.w ,name ,val))

(lambda t! [name val]
  `(tset vim.t ,name ,val))

(lambda g! [name val]
  `(tset vim.g ,name ,val))

(lambda v! [name val]
  `(tset vim.v ,name ,val))

(lambda env! [name val]
  `(tset vim.env ,name ,val))

;; (lambda $! [name val]
;;   `(tset vim.env ,name ,val))

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

(lambda keymap/extra-opts->api-opts [extra-opts]
  (let [complement {}
        api-opts (collect [_ map-arg (ipairs extra-opts)]
                   (match map-arg
                     ;; Note: Another macro will resolve the invalid "buffer" option.
                     :buffer
                     (values :buffer true)
                     :literal
                     (values :replace_keycodes false)
                     _
                     (if (contains? [:script :unique :expr] map-arg)
                         (values map-arg true)
                         (values :desc map-arg))))]
    (collect [k v (pairs complement) &into api-opts]
      (when (nil? (?. api-opts k))
        (values k v)))))

(lambda keymap/varargs->api-args [...]
  ;; [default-opts modes ?extra-opts lhs rhs ?api-opts]
  "Merge extra options with default ones.
   `(map modes ?extra-opts lhs rhs ?api-opts)` where
   - `?extra-opts` must be a sequence of literal strings.
   - `?api-opts` must be a dictionary which accepts the same arguments as
     `vim.api.nvim_set_keymap()` accepts.
  `desc` will be filled based on `rhs` which is a function."
  (let [v1 (select 1 ...)
        ?extra-opts (when (sequence? v1)
                      v1)
        [lhs raw-rhs ?api-opts] (if ?extra-opts
                                    (slice [...] 2)
                                    [...])
        extra-opts (if-not ?extra-opts {}
                           (keymap/extra-opts->api-opts ?extra-opts))
        api-opts (if-not ?api-opts extra-opts
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

(lambda keymap/del-maps! [modes lhs ?bufnr]
  "Delete keymap in such format as
  `(del-keymap :nx :f :buffer)`, or `(del-keymap :nx :f 8)`."
  ;; Note: nvim_del_keymap itself cannot delete mappings in multi mode at once.
  (let [del-maps! (fn [mode]
                    (match (type ?bufnr)
                      :nil `(vim.api.nvim_del_keymap ,mode ,lhs)
                      :number `(vim.api.nvim_buf_del_keymap ,?bufnr ,mode ,lhs)
                      _ (error (: "expected nil or number, got %s: %s" :format
                                  (type ?bufnr) (view ?bufnr)))))
        modes (if (str? modes) [modes] modes)]
    (icollect [_ m (ipairs modes)]
      (del-maps! m lhs))))

(lambda keymap/set-maps! [modes lhs rhs raw-api-opts]
  (if (or (sym? modes) (sym? rhs))
      ;; Note: We cannot tell whether or not `rhs` should be set to callback in
      ;; compile time. Keep the compiled results simple.
      `(vim.keymap.set ,modes ,lhs ,rhs ,raw-api-opts)
      (let [?bufnr (?. raw-api-opts :buffer)
            modes (if (str? modes) [modes] modes)
            set-keymap (if ?bufnr
                           (lambda [mode api-opts]
                             `(vim.api.nvim_buf_set_keymap ,?bufnr ,mode ,lhs
                                                           ,rhs ,api-opts))
                           (lambda [mode api-opts]
                             `(vim.api.nvim_set_keymap ,mode ,lhs ,rhs
                                                       ,api-opts)))
            maps (do
                   ;; Remove keys invalid to the api functions.
                   (tset raw-api-opts :buffer nil)
                   (when (and (?. raw-api-opts :expr) ;
                              (not= false (?. raw-api-opts :replace_keycodes)))
                     (tset raw-api-opts :replace_keycodes true))
                   (icollect [_ m (ipairs modes)]
                     (set-keymap m raw-api-opts)))]
        (if (< 1 (length maps))
            maps
            (unpack maps)))))

;; Export ///2
(lambda noremap! [modes ...]
  (let [default-opts {:noremap true}
        (lhs rhs api-opts) (keymap/varargs->api-args ...)]
    (merge-default-kv-table default-opts api-opts)
    (keymap/set-maps! modes lhs rhs api-opts)))

(lambda map! [modes ...]
  (let [default-opts {}
        (lhs rhs api-opts) (keymap/varargs->api-args ...)]
    (merge-default-kv-table default-opts api-opts)
    (keymap/set-maps! modes lhs rhs api-opts)))

(local unmap! keymap/del-maps!)

;; Wrapper ///3
(lambda noremap-all! [...]
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(noremap! "" lhs rhs api-opts)
     (noremap! "!" lhs rhs api-opts)
     (unpack (noremap! [:l :t] lhs rhs api-opts))]))

(lambda noremap-input! [...]
  (noremap! "!" ...))

(lambda noremap-motion! [...]
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(noremap! "" lhs rhs api-opts) (unmap! :s lhs)]))

(lambda noremap-operator! [...]
  (noremap! [:n :x] ...))

(lambda noremap-textobject! [...]
  (noremap! [:o :x] ...))

(lambda nnoremap! [...]
  (noremap! :n ...))

(lambda vnoremap! [...]
  (noremap! :v ...))

(lambda xnoremap! [...]
  (noremap! :x ...))

(lambda snoremap! [...]
  (noremap! :s ...))

(lambda onoremap! [...]
  (noremap! :o ...))

(lambda inoremap! [...]
  (noremap! :i ...))

(lambda lnoremap! [...]
  (noremap! :l ...))

(lambda cnoremap! [...]
  (noremap! :c ...))

(lambda tnoremap! [...]
  (noremap! :t ...))

(lambda map-all! [...]
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(map! "" lhs rhs api-opts)
     (map! "!" lhs rhs api-opts)
     (unpack (map! [:l :t] lhs rhs api-opts))]))

(lambda map-input! [...]
  (map! "!" ...))

(lambda map-motion! [...]
  (let [(lhs rhs api-opts) (keymap/varargs->api-args ...)]
    [(map! "" lhs rhs api-opts) (unmap! :s lhs)]))

(lambda map-operator! [...]
  (map! [:n :x] ...))

(lambda map-textobject! [...]
  (map! [:o :x] ...))

(lambda nmap! [...]
  (map! :n ...))

(lambda vmap! [...]
  (map! :v ...))

(lambda xmap! [...]
  (map! :x ...))

(lambda smap! [...]
  (map! :s ...))

(lambda omap! [...]
  (map! :o ...))

(lambda imap! [...]
  (map! :i ...))

(lambda lmap! [...]
  (map! :l ...))

(lambda cmap! [...]
  (map! :c ...))

(lambda tmap! [...]
  (map! :t ...))

;; Command ///1
(lambda command! [name command ?api-opts]
  "(command! name command ?api-opts)
  name: (string) Name of the new user command. Must begin with an uppercase letter.
  command: (string|function) Replacement command.
  ?api-opts: (table) Optional command attributes. Same opts for `nvim_create_user_command`.
      Additionally, `buffer` key is available, which is passed to {buffer} for `nvim_buf_create_user_command`.

  Equivalent to `vim.api.nvim_create_user_command`. When you set `buffer` key,
  it'll be equivalent to `vim.api.nvim_buf_create_user_command` instead.

  ```fennel
  (command! :SayHello \"echo 'Hello world!'\")
  (command! :Salute #(print \"Hello world!\")
            {:buffer 0 :bang true :desc \"Say Hello!\"})
  ```

  is equivalent to

  ```lua
  nvim_create_user_command(\"SayHello\", \"echo 'Hello world!'\", {})
  nvim_buf_create_user_command(0, \"Salute\",
                               function()
                                 print(\"'Hello world!'\")
                               end, {
                               bang = true,
                               desc = \"Say Hello!\"
                              })
  ```"
  (let [api-opts (or ?api-opts {})]
    (if api-opts.buffer
        (let [buffer-handle api-opts.buffer]
          (tset api-opts :buffer nil)
          `(vim.api.nvim_buf_create_user_command ,buffer-handle ,name ,command
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
            (assert-compile (or (sym? callback) (fn? callback))
                            (.. "callback must be a string or function, got "
                                (type callback))
                            callback))
          `(do
             (callback)
             (vim.schedule #(tset vim.g :eventignore save-ei#))))))

;; Autocmd/Augroup ///1
(lambda define-autocmd! [...]
  (if (= 2 (length [...]))
      ;; It works as an alias of `vim.api.nvim_create_autocmd()` if only two
      ;; args are provided.
      (let [(events api-opts) ...]
        `(vim.api.nvim_create_autocmd ,events ,api-opts))
      (let [[id events pattern & rest] [...]
            api-opts {:group id}]
        (when (and (str? pattern) (= pattern :<buffer>))
          (tset api-opts :buffer 0))
        (when (nil? api-opts.buffer)
          (tset api-opts :pattern
                (if (and (sym? pattern)
                         (-> (->str pattern)
                             (: :match "%*")))
                    (->str pattern)
                    pattern)))
        ;; TODO: More concise implementation.
        (let [es (if (str? events)
                     (icollect [p (events:gmatch "[a-zA-Z]+")]
                       p)
                     events)]
          (each [_ val (ipairs rest)]
            (if (sequence? val)
                (let [?extra-opts val
                      desc-pattern ;
                      "[^-a-zA-Z0-9_!#$%^&*=+\\|:/.?]"]
                  (each [_ v (ipairs ?extra-opts)]
                    (when (str? v)
                      (match v
                        :once (tset api-opts :once true)
                        :nested (tset api-opts :nested true)
                        _ (do
                            (assert-compile (v:match desc-pattern)
                                            (.. "Unexpected string: " v) v)
                            (tset api-opts :desc v))))))
                (match val
                  :once (tset api-opts :once true)
                  :nested (tset api-opts :nested true)
                  _ (if (excmd? val)
                        (tset api-opts :command val)
                        ;; Ignore the possibility to set VimL callback function in string.
                        (tset api-opts :callback val)))))
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

(lambda au! [...]
  "Define an autocmd:

  ```fennel
  (au! ?augroup-id events pattern ?extra-opts command-or-callback ?api-opts)
  ```

  ```fennel
  (augroup! :your-augroup
    (au! :FileType * [\"some description\"] #(fnl-expr))
    (au! :InsertEnter :<buffer> \"some Vimscript command\")
    (au! :BufNewFile.BufRead \"{some,any}.ext\"
         [:this-is-invalid-description]
         #(vim.fn.foo))
    (au! [:BufNewFile :BufRead] [:multi :patterns :for :events :in :sequence]
         [:once :nested \"You can also set :once or :nested here\"] ...))
  ```

  This macro also works as a syntax sugar in `(augroup!)`.
  - ?augroup-id (string|integer):
    Actually, `?augroup-id` is not an optional argument unlike
    `vim.api.nvim_create_autocmd()` unless you use this `au!` macro within
    either `augroup!` or `augroup+` macro.
  - events (string|string[]):
    You can set multiple events in a dot-separated literal string.
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
    lua or fennel. Any literal string here is interpreted as vim-command; use
    `vim.fn` table to set a Vimscript function.
  "
  (define-autocmd! ...))

(lambda autocmd! [...]
  "Same as `au!`"
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
  ;; FIXME: Compile error: Missing argument val
  ;; [?namespace hl-name val]
  "Set a highlight group.
  The first arg namespace is optional; without it, highlight is set globally.

  ```fennel
  (highlight! hl-name {:fg :Red :bold true})
  (highlight! hl-name {:link another-hl-name})
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
  "Same as highlight!"
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
 : b!
 : w!
 : t!
 : g!
 : v!
 : env!
 : noremap!
 : map!
 : unmap!
 : noremap-all!
 : noremap-input!
 : noremap-motion!
 : noremap-operator!
 : noremap-textobject!
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
 : map-textobject!
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
