(import-macros {: before-each : describe* : it*} :test._busted_macros)
(import-macros {: set+ : set- : set^} :test._wrapper_macros)
(import-macros {: let!
                : set!
                : setglobal!
                : setlocal!
                : bo!
                : wo!
                :set+ deprecated/set+
                :set- deprecated/set-
                :set^ deprecated/set^} :nvim-laurel.macros)

(macro get-o [name]
  `(-> (. vim.opt ,name) (: :get)))

(macro get-go [name]
  `(. vim.go ,name))

(macro get-lo [name]
  `(-> (. vim.opt_local ,name) (: :get)))

(macro get-o-lo-go [name]
  "Get option values.
  @param name string
  @return any[]"
  `[(get-o ,name) (get-lo ,name) (get-go ,name)])

(local default-opt-map
       ;; Note: The default option values are supposed to be different from
       ;; Neovim default value.
       {;;; buffer-local options
        ;; boolean (bo)
        :expandtab true
        ;; number (bo)
        :tabstop 1
        ;; string (bo) x
        :omnifunc :xyx
        ;; sequence (bo)
        :path "/tmp,/var,/usr"
        ;; kv-table (bo)
        ;; Note: None of buf-local option can be set in kv-table probably.
        ;;:matchpairs "x:X,y:Y,z:Z"
        ;;; window-local options
        ;; boolean (wo)
        :wrap true
        ;; number (wo)
        :foldlevel 1
        ;; string (wo)
        :signcolumn :yes
        ;; sequence (wo)
        :colorcolumn "+1,+2,+3"
        ;; kv-table (wo)
        :listchars "eol:x,tab:xy,space:x"
        ;; shortmess (should be set both in string or bare-sequence)
        :shortmess :fiw
        ;; formatoptions (should be set both in string or bare-sequence)
        :formatoptions :12b})

(fn reset-context []
  "Reset test context."
  (each [name val (pairs default-opt-map)]
    (tset vim.opt name val)
    (assert.is_same val (. vim.go name))
    (assert.is_same val (. vim.o name)))
  (vim.cmd.new)
  (vim.cmd.only)
  (each [name val (pairs default-opt-map)]
    (assert.is_same val (. vim.o name))))

;; TODO: Also test `:v`. What variable is not readonly?
(local scope-list [:g :b :w :t :env])
(local buf-local-scope-list [:o :bo :opt :opt_local])
(local win-local-scope-list [:o :wo :opt :opt_local])

(describe* :options
  (before-each (do
                 (reset-context)))
  (describe* :let!
    (describe* "for Vim script `variable` (g, b, w, t, env)"
      (describe* "with scope in symbol"
        (it* "can set vim option value in any scope."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo :bar)
            (assert.is_same :bar (. vim scope :foo))))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (each [_ scope (ipairs scope-list)]
              (let! scope :foo)
              ;; Note: (. vim scope :foo) does not return `true`, but `v:true`.
              ;; However, attempt to compare with `"v:true"` only fails
              ;; because it surprisingly returns `true` then. So, it compares
              ;; both at a time as a workaround. At least, the compiled result
              ;; is the intended one.
              (assert.is_true (or (= true (. vim scope :foo))
                                  (= "v:true" (. vim scope :foo)))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo)))))
      (describe* :g
        (it* "can set vim option value in any scope."
          (let! :g :foo :bar)
          (assert.is_same :bar (. vim :g :foo)))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (let! :g :foo)
            ;; Note: (. vim :g :foo) does not return `true`, but `v:true`.
            ;; However, attempt to compare with `"v:true"` only fails
            ;; because it surprisingly returns `true` then. So, it compares
            ;; both at a time as a workaround. At least, the compiled result
            ;; is the intended one.
            (assert.is_true (or (= true (. vim :g :foo))
                                (= "v:true" (. vim :g :foo))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo)))))
      (describe* :b
        (it* "can set vim option value in any scope."
          (let! :b :foo :bar)
          (assert.is_same :bar (. vim :b :foo)))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (let! :b :foo)
            (assert.is_true (or (= true (. vim :b :foo))
                                (= "v:true" (. vim :b :foo))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo)))))
      (describe* :w
        (it* "can set vim option value in any scope."
          (let! :w :foo :bar)
          (assert.is_same :bar (. vim :w :foo)))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (let! :w :foo)
            (assert.is_true (or (= true (. vim :w :foo))
                                (= "v:true" (. vim :w :foo))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo)))))
      (describe* :t
        (it* "can set vim option value in any scope."
          (let! :t :foo :bar)
          (assert.is_same :bar (. vim :t :foo)))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (let! :t :foo)
            (assert.is_true (or (= true (. vim :t :foo))
                                (= "v:true" (. vim :t :foo))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo)))))
      (describe* :env
        (it* "can set vim option value in any scope."
          (let! :env :foo :bar)
          (assert.is_same :bar (. vim :env :foo)))
        (describe* "without either id or value"
          (it* "sets vim option value to `true`."
            (let! :env :foo)
            (assert.is_true (or (= true (. vim :env :foo))
                                (= "v:true" (. vim :env :foo))))))
        (it* "can set to `nil`."
          (each [_ scope (ipairs scope-list)]
            (let! scope :foo nil)
            (assert.is_nil (. vim scope :foo))))))
    (describe* "for Vim script `option` scope (o, go, bo, wo, opt, opt_global, opt_local)"
      (describe* "with scope in symbol"
        (it* "cannot set any options when option name is capitalized"
          (each [_ scope (ipairs win-local-scope-list)]
            (assert.has_error #(let! scope :foldLevel 2))))
        (describe* "can set vim buf-local option"
          (it* "in boolean"
            (each [_ scope (ipairs buf-local-scope-list)]
              (let! scope :expandtab false)
              (assert.is_false (get-lo :expandtab))))
          (it* "in number"
            (each [_ scope (ipairs buf-local-scope-list)]
              (let! scope :tabstop 2)
              (assert.is_same 2 (get-lo :tabstop))))
          (it* "in string"
            (each [_ scope (ipairs buf-local-scope-list)]
              (let! scope :omnifunc :abc)
              (assert.is_same :abc (get-lo :omnifunc))))
          (it* "in sequence (except :bo)"
            (each [_ scope (ipairs [:opt :opt_local])]
              (let! scope :path [:/foo :/bar :/baz])
              (assert.is_same [:/foo :/bar :/baz] (get-lo :path)))))
        (describe* "can set vim win-local option"
          (it* "in boolean"
            (each [_ scope (ipairs win-local-scope-list)]
              (let! scope :wrap false)
              (assert.is_false (get-lo :wrap))))
          (it* "in number"
            (each [_ scope (ipairs win-local-scope-list)]
              (let! scope :foldlevel 2)
              (assert.is_same 2 (get-lo :foldlevel))))
          (it* "in string"
            (each [_ scope (ipairs win-local-scope-list)]
              (let! scope :signcolumn :no)
              (assert.is_same :no (get-lo :signcolumn))))
          (it* "in sequence (except :wo)"
            (each [_ scope (ipairs [:opt :opt_local])]
              (let! scope :colorcolumn [:80 :81 :+1])
              (assert.is_same [:80 :81 :+1] (get-lo :colorcolumn))))
          (it* "in kv-table (except :wo)"
            (each [_ scope (ipairs [:opt :opt_local])]
              (let! scope :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same {:eol :a :tab :abc :space :a} (get-lo :listchars))))))
      (describe* "in `:opt` scope"
        (it* "is case-insensitive at option name"
          (vim.cmd "set foldlevel=2")
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt :foldLevel 2)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update option value with boolean"
          (vim.cmd "set nowrap")
          (let [vals (get-o-lo-go :wrap)]
            (reset-context)
            (let! :opt :wrap false)
            (assert.is_same vals (get-o-lo-go :wrap))))
        (it* "can update option value with number"
          (vim.cmd "set foldlevel=2")
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt :foldLevel 2)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update option value with string"
          (vim.cmd "set signcolumn=no")
          (let [vals (get-o-lo-go :signcolumn)]
            (reset-context)
            (let! :opt :signColumn :no)
            (assert.is_same vals (get-o-lo-go :signcolumn))))
        (it* "can update option value with sequence"
          (vim.cmd "set path=/foo,/bar,/baz")
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt :path [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can update option value with kv-table"
          (vim.cmd "set listchars=eol:a,tab:abc,space:a")
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt :listChars {:eol :a :tab :abc :space :a})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can update some option value with nil"
          (set vim.opt.foldlevel nil)
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt :foldlevel nil)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update some option value with symbol"
          (let [new-val 2]
            (set vim.opt.foldlevel new-val)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt :foldLevel new-val)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can update some option value with list"
          (let [return-val #2]
            (set vim.opt.foldlevel (return-val))
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt :foldLevel (return-val))
              (assert.is_same vals (get-o-lo-go :foldlevel))
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (describe* "with infix-flag"
          (it* "can append option value of sequence"
            (vim.cmd "set path+=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (let! :opt :path + [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path))))
          (it* "can prepend option value of sequence"
            (vim.cmd "set path^=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (let! :opt :path ^ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path))))
          (it* "can remove option value of sequence"
            (vim.cmd "set path-=/tmp,/var")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (let! :opt :path - [:/tmp :/var])
              (assert.is_same vals (get-o-lo-go :path))))
          (it* "can append option value of kv-table"
            (vim.opt.listchars:append {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (let! :opt :listchars + {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars))))
          (it* "can prepend option value of kv-table"
            (vim.opt.listchars:prepend {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (let! :opt :listchars ^ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars))))
          (it* "can remove option value of kv-table"
            (vim.opt.listchars:remove [:eol :tab])
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (let! :opt :listchars - [:eol :tab])
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (describe* "with no value"
          (it* "updates option value to `true`"
            (vim.cmd "set nowrap")
            (assert.is_false (get-o :wrap))
            (let! :opt :wrap)
            (assert.is_true (get-o :wrap)))
          (it* "updates value to `true` even when option name is hidden in compile time"
            (vim.cmd "set nowrap")
            (assert.is_false (get-o :wrap))
            (let [name :wrap]
              (let! :opt name)
              (assert.is_true (get-o name))))))
      (describe* "in `:opt_local` scope`"
        (it* "can update option value with boolean"
          (vim.cmd "setlocal nowrap")
          (let [vals (get-o-lo-go :wrap)]
            (reset-context)
            (let! :opt_local :wrap false)
            (assert.is_same vals (get-o-lo-go :wrap))))
        (it* "can update option value with number"
          (vim.cmd "setlocal foldlevel=2")
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt_local :foldlevel 2)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update option value with string"
          (vim.cmd "setlocal signcolumn=no")
          (let [vals (get-o-lo-go :signcolumn)]
            (reset-context)
            (let! :opt_local :signcolumn :no)
            (assert.is_same vals (get-o-lo-go :signcolumn))))
        (it* "can update option value with sequence"
          (vim.cmd "setlocal path=/foo,/bar,/baz")
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_local :path [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can update option value with kv-table"
          (vim.cmd "setlocal listchars=eol:a,tab:abc,space:a")
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_local :listchars {:eol :a :tab :abc :space :a})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can update some option value with nil"
          (set vim.opt_local.foldlevel nil)
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt_local :foldlevel nil)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update some option value with symbol"
          (let [new-val 2]
            (set vim.opt_local.foldlevel new-val)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt_local :foldlevel new-val)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can update some option value with list"
          (let [return-val #2]
            (set vim.opt_local.foldlevel (return-val))
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt_local :foldlevel (return-val))
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can append option value of sequence"
          (vim.opt_local.path:append [:/foo :/bar :/baz])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_local :path + [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can prepend option value of sequence"
          (vim.opt_local.path:prepend [:/foo :/bar :/baz])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_local :path ^ [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can remove option value of sequence"
          (vim.opt_local.path:remove [:/tmp :/var])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_local :path - [:/tmp :/var])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can append option value of kv-table"
          (vim.opt_local.listchars:append {:lead :a :trail :b :extends :c})
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_local :listchars + {:lead :a :trail :b :extends :c})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can prepend option value of kv-table"
          (vim.opt_local.listchars:prepend {:lead :a :trail :b :extends :c})
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_local :listchars ^ {:lead :a :trail :b :extends :c})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can remove option value of kv-table"
          (vim.opt_local.listchars:remove [:eol :tab])
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_local :listchars - [:eol :tab])
            (assert.is_same vals (get-o-lo-go :listchars))))
        (describe* "with no value"
          (it* "updates option value to `true`"
            (vim.cmd "setlocal nowrap")
            (assert.is_false (get-lo :wrap))
            (let! :opt_local :wrap)
            (assert.is_true (get-lo :wrap)))
          (it* "updates value to `true` even when option name is hidden in compile time"
            (vim.cmd "setlocal nowrap")
            (assert.is_false (get-lo :wrap))
            (let [name :wrap]
              (let! :opt_local name)
              (assert.is_true (get-lo name)))))
        (describe* "for &l:formatoptions"
          (it* "can append flags in sequence"
            ;; Note: In truth, the formatoptions flag order doesn't matter.
            (let! :opt_local :formatOptions + [:a :r :B])
            (assert.is_same {:1 true :2 true :b true :a true :r true :B true}
                            (get-lo :formatoptions)))
          (it* "can prepend flags in sequence"
            ;; Note: In truth, the formatoptions flag order doesn't matter.
            (let! :opt_local :formatOptions ^ [:a :r :B])
            (assert.is_same {:1 true :2 true :b true :a true :r true :B true}
                            (get-lo :formatoptions)))
          (it* "can remove flags in sequence"
            (let! :opt_local :formatOptions - [:b :2])
            (assert.is_same {:1 true} (get-lo :formatoptions)))
          (it* "can set symbol in sequence"
            (let [val :r]
              (let! :opt_local :formatOptions [val])
              (assert.is_same {val true} (get-lo :formatoptions))))))
      (describe* "in `:opt_global` scope"
        (it* "can update option value with boolean"
          (vim.cmd "setglobal nowrap")
          (let [vals (get-o-lo-go :wrap)]
            (reset-context)
            (let! :opt_global :wrap false)
            (assert.is_same vals (get-o-lo-go :wrap))))
        (it* "can update option value with number"
          (vim.cmd "setglobal foldlevel=2")
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (let! :opt_global :foldlevel 2)
            (assert.is_same vals (get-o-lo-go :foldlevel))))
        (it* "can update option value with string"
          (vim.cmd "setglobal signcolumn=no")
          (let [vals (get-o-lo-go :signcolumn)]
            (reset-context)
            (let! :opt_global :signcolumn :no)
            (assert.is_same vals (get-o-lo-go :signcolumn))))
        (it* "can update option value with sequence"
          (vim.cmd "setglobal path=/foo,/bar,/baz")
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_global :path [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can update option value with kv-table"
          (vim.cmd "setglobal listchars=eol:a,tab:abc,space:a")
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_global :listchars {:eol :a :tab :abc :space :a})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (if (= 1 (vim.fn.has :nvim-0.10.0-dev))
            (it* "throws an error with nil assigned"
              (assert.error #(set vim.opt_global.foldlevel nil)))
            (it* "can update some option value with nil"
              (set vim.opt_global.foldlevel nil)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (let! :opt_global :foldlevel nil)
                (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can update some option value with symbol"
          (let [new-val 2]
            (set vim.opt_global.foldlevel new-val)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt_global :foldlevel new-val)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can update some option value with list"
          (let [return-val #2]
            (set vim.opt_global.foldlevel (return-val))
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (let! :opt_global :foldlevel (return-val))
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it* "can append option value of sequence"
          (vim.opt_global.path:append [:/foo :/bar :/baz])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_global :path + [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can prepend option value of sequence"
          (vim.opt_global.path:prepend [:/foo :/bar :/baz])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_global :path ^ [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can remove option value of sequence"
          (vim.opt_global.path:remove [:/tmp :/var])
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :opt_global :path - [:/tmp :/var])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can append option value of kv-table"
          (vim.opt_global.listchars:append {:lead :a :trail :b :extends :c})
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_global :listchars + {:lead :a :trail :b :extends :c})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can prepend option value of kv-table"
          (vim.opt_global.listchars:prepend {:lead :a :trail :b :extends :c})
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_global :listchars ^ {:lead :a :trail :b :extends :c})
            (assert.is_same vals (get-o-lo-go :listchars))))
        (it* "can remove option value of kv-table"
          (vim.opt_global.listchars:remove [:eol :tab])
          (let [vals (get-o-lo-go :listchars)]
            (reset-context)
            (let! :opt_global :listchars - [:eol :tab])
            (assert.is_same vals (get-o-lo-go :listchars))))
        (describe* "for &l:shortmess"
          (it* "can append flags in sequence"
            ;; Note: In truth, the shortmess flag order doesn't matter.
            (let! :opt_global :shortMess + [:m :n :r])
            (assert.is_same {:f true :i true :w true :m true :n true :r true}
                            (get-lo :shortmess)))
          (it* "can prepend flags in sequence"
            ;; Note: In truth, the shortmess flag order doesn't matter.
            (let! :opt_global :shortMess ^ [:m :n :r])
            (assert.is_same {:f true :i true :w true :m true :n true :r true}
                            (get-lo :shortmess)))
          (it* "can remove flags in sequence"
            (let! :opt_global :shortMess - [:i :f])
            (assert.is_same {:w true} (get-lo :shortmess))))
        (describe* "with no value"
          (it* "updates option value to `true`"
            (vim.cmd "setglobal nowrap")
            (assert.is_false (get-go :wrap))
            (let! :opt_global :wrap)
            (assert.is_true (get-go :wrap)))
          (it* "updates value to `true` even when option name is hidden in compile time"
            (vim.cmd "setglobal nowrap")
            (assert.is_false (get-go :wrap))
            (let [name :wrap]
              (let! :opt_global name)
              (assert.is_true (get-go name))))))
      (describe* "in `:bo` scope"
        (it* "can update option value with boolean"
          (tset vim.bo :expandtab false)
          (let [vals (get-o-lo-go :expandtab)]
            (reset-context)
            (let! :bo :expandtab false)
            (assert.is_same vals (get-o-lo-go :expandtab))))
        (it* "can update option value with number"
          (tset vim.bo :tabstop 2)
          (let [vals (get-o-lo-go :tabstop)]
            (reset-context)
            (let! :bo :tabstop 2)
            (assert.is_same vals (get-o-lo-go :tabstop))))
        (it* "can update option value with string"
          (tset vim.bo :omnifunc :abc)
          (let [vals (get-o-lo-go :omnifunc)]
            (reset-context)
            (let! :bo :omnifunc :abc)
            (assert.is_same vals (get-o-lo-go :omnifunc))))
        (it* "can update option value with sequence"
          (tset vim.bo :path "/foo,/bar,/baz")
          (let [vals (get-o-lo-go :path)]
            (reset-context)
            (let! :bo :path [:/foo :/bar :/baz])
            (assert.is_same vals (get-o-lo-go :path))))
        (it* "can update option value with kv-table"
          (tset vim.bo :matchpairs "a:A,b:B,c:C")
          (let [vals (get-o-lo-go :matchpairs)]
            (reset-context)
            (let! :bo :matchPairs {:a :A :b :B :c :C})
            (assert.is_same vals (get-o-lo-go :matchpairs))))
        (it* "can update some option value with nil"
          (set vim.bo.tabstop nil)
          (let [vals (get-o-lo-go :tabstop)]
            (reset-context)
            (let! :bo :tabstop nil)
            (assert.is_same vals (get-o-lo-go :tabstop))))
        (it* "can update some option value with symbol"
          (let [new-val 2]
            (set vim.bo.tabstop new-val)
            (let [vals (get-o-lo-go :tabstop)]
              (reset-context)
              (let! :bo :tabstop new-val)
              (assert.is_same vals (get-o-lo-go :tabstop)))))
        (it* "can update some option value with list"
          (let [return-val #2]
            (set vim.bo.tabstop (return-val))
            (let [vals (get-o-lo-go :tabstop)]
              (reset-context)
              (let! :bo :tabstop (return-val))
              (assert.is_same vals (get-o-lo-go :tabstop)))))
        (describe* "with bufnr"
          (it* "can update option value with boolean"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :expandtab false)
              (assert.is_false (. vim.bo buf :expandtab))))
          (it* "can update option value with number"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :tabstop 2)
              (assert.is_same 2 (. vim.bo buf :tabstop))))
          (it* "can update option value with string"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :omnifunc :abc)
              (assert.is_same :abc (. vim.bo buf :omnifunc))))
          (it* "can update option value with sequence"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :path [:/foo :/bar :/baz])
              (assert.is_same "/foo,/bar,/baz" (. vim.bo buf :path))))
          (it* "can update option value with kv-table"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :matchPairs {:a :A :b :B :c :C})
              (assert.is_same "a:A,b:B,c:C" (. vim.bo buf :matchpairs))))
          (it* "can update some option value with nil"
            (let [buf (vim.api.nvim_get_current_buf)]
              (reset-context)
              (let! :bo buf :tabstop nil)
              (assert.is_same vim.go.tabstop (. vim.bo buf :tabstop))))
          (it* "can update some option value with symbol"
            (let [buf (vim.api.nvim_get_current_buf)
                  new-val 2]
              (reset-context)
              (let! :bo buf :tabstop new-val)
              (assert.is_same new-val (. vim.bo buf :tabstop))))
          (it* "can update some option value with list"
            (let [buf (vim.api.nvim_get_current_buf)
                  new-val 2
                  return-val #new-val]
              (reset-context)
              (let! :bo buf :tabstop (return-val))
              (assert.is_same new-val (. vim.bo buf :tabstop))))))))
  (describe* :set!
    (it* "is case-insensitive at option name"
      (vim.cmd "set foldlevel=2")
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (set! :foldLevel 2)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update option value with boolean"
      (vim.cmd "set nowrap")
      (let [vals (get-o-lo-go :wrap)]
        (reset-context)
        (set! :wrap false)
        (assert.is_same vals (get-o-lo-go :wrap))))
    (it* "can update option value with number"
      (vim.cmd "set foldlevel=2")
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (set! :foldlevel 2)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update option value with string"
      (vim.cmd "set signcolumn=no")
      (let [vals (get-o-lo-go :signcolumn)]
        (reset-context)
        (set! :signcolumn :no)
        (assert.is_same vals (get-o-lo-go :signcolumn))))
    (it* "can update option value with sequence"
      (vim.cmd "set path=/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (set! :path [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can update option value with kv-table"
      (vim.cmd "set listchars=eol:a,tab:abc,space:a")
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (set! :listchars {:eol :a :tab :abc :space :a})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can update some option value with nil"
      (set vim.opt.foldlevel nil)
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (set! :foldlevel nil)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update some option value with symbol"
      (let [new-val 2]
        (set vim.opt.foldlevel new-val)
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (set! :foldlevel new-val)
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can update some option value with list"
      (let [return-val #2]
        (set vim.opt.foldlevel (return-val))
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (set! :foldlevel (return-val))
          (assert.is_same vals (get-o-lo-go :foldlevel))
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can append option value of sequence"
      (vim.cmd "set path+=/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (set! :path + [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can prepend option value of sequence"
      (vim.cmd "set path^=/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (set! :path ^ [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can remove option value of sequence"
      (vim.cmd "set path-=/tmp,/var")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (set! :path - [:/tmp :/var])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can append option value of kv-table"
      (vim.opt.listchars:append {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (set! :listchars + {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can prepend option value of kv-table"
      (vim.opt.listchars:prepend {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (set! :listchars ^ {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can remove option value of kv-table"
      (vim.opt.listchars:remove [:eol :tab])
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (set! :listchars - [:eol :tab])
        (assert.is_same vals (get-o-lo-go :listchars))))
    (describe* "with no value"
      (it* "updates option value to `true`"
        (vim.cmd "set nowrap")
        (assert.is_false (get-o :wrap))
        (set! :wrap)
        (assert.is_true (get-o :wrap)))
      (it* "updates value to `true` even when option name is hidden in compile time"
        (vim.cmd "set nowrap")
        (assert.is_false (get-o :wrap))
        (let [name :wrap]
          (set! name)
          (assert.is_true (get-o name))))))
  (describe* :setlocal!
    (it* "can update option value with boolean"
      (vim.cmd "setlocal nowrap")
      (let [vals (get-o-lo-go :wrap)]
        (reset-context)
        (setlocal! :wrap false)
        (assert.is_same vals (get-o-lo-go :wrap))))
    (it* "can update option value with number"
      (vim.cmd "setlocal foldlevel=2")
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (setlocal! :foldlevel 2)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update option value with string"
      (vim.cmd "setlocal signcolumn=no")
      (let [vals (get-o-lo-go :signcolumn)]
        (reset-context)
        (setlocal! :signcolumn :no)
        (assert.is_same vals (get-o-lo-go :signcolumn))))
    (it* "can update option value with sequence"
      (vim.cmd "setlocal path=/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setlocal! :path [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can update option value with kv-table"
      (vim.cmd "setlocal listchars=eol:a,tab:abc,space:a")
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setlocal! :listchars {:eol :a :tab :abc :space :a})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can update some option value with nil"
      (set vim.opt_local.foldlevel nil)
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (setlocal! :foldlevel nil)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update some option value with symbol"
      (let [new-val 2]
        (set vim.opt_local.foldlevel new-val)
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (setlocal! :foldlevel new-val)
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can update some option value with list"
      (let [return-val #2]
        (set vim.opt_local.foldlevel (return-val))
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (setlocal! :foldlevel (return-val))
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can append option value of sequence"
      (vim.opt_local.path:append [:/foo :/bar :/baz])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setlocal! :path + [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can prepend option value of sequence"
      (vim.opt_local.path:prepend [:/foo :/bar :/baz])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setlocal! :path ^ [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can remove option value of sequence"
      (vim.opt_local.path:remove [:/tmp :/var])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setlocal! :path - [:/tmp :/var])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can append option value of kv-table"
      (vim.opt_local.listchars:append {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setlocal! :listchars + {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can prepend option value of kv-table"
      (vim.opt_local.listchars:prepend {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setlocal! :listchars ^ {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can remove option value of kv-table"
      (vim.opt_local.listchars:remove [:eol :tab])
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setlocal! :listchars - [:eol :tab])
        (assert.is_same vals (get-o-lo-go :listchars))))
    (describe* "with no value"
      (it* "updates option value to `true`"
        (vim.cmd "setlocal nowrap")
        (assert.is_false (get-lo :wrap))
        (setlocal! :wrap)
        (assert.is_true (get-lo :wrap)))
      (it* "updates value to `true` even when option name is hidden in compile time"
        (vim.cmd "setlocal nowrap")
        (assert.is_false (get-lo :wrap))
        (let [name :wrap]
          (setlocal! name)
          (assert.is_true (get-lo name)))))
    (describe* "for &l:formatoptions"
      (it* "can append flags in sequence"
        ;; Note: In truth, the formatoptions flag order doesn't matter.
        (setlocal! :formatOptions + [:a :r :B])
        (assert.is_same {:1 true :2 true :b true :a true :r true :B true}
                        (get-lo :formatoptions)))
      (it* "can prepend flags in sequence"
        ;; Note: In truth, the formatoptions flag order doesn't matter.
        (setlocal! :formatOptions ^ [:a :r :B])
        (assert.is_same {:1 true :2 true :b true :a true :r true :B true}
                        (get-lo :formatoptions)))
      (it* "can remove flags in sequence"
        (setlocal! :formatOptions - [:b :2])
        (assert.is_same {:1 true} (get-lo :formatoptions)))
      (it* "can set symbol in sequence"
        (let [val :r]
          (setlocal! :formatOptions [val])
          (assert.is_same {val true} (get-lo :formatoptions))))))
  (describe* :setglobal!
    (it* "can update option value with boolean"
      (vim.cmd "setglobal nowrap")
      (let [vals (get-o-lo-go :wrap)]
        (reset-context)
        (setglobal! :wrap false)
        (assert.is_same vals (get-o-lo-go :wrap))))
    (it* "can update option value with number"
      (vim.cmd "setglobal foldlevel=2")
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (setglobal! :foldlevel 2)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update option value with string"
      (vim.cmd "setglobal signcolumn=no")
      (let [vals (get-o-lo-go :signcolumn)]
        (reset-context)
        (setglobal! :signcolumn :no)
        (assert.is_same vals (get-o-lo-go :signcolumn))))
    (it* "can update option value with sequence"
      (vim.cmd "setglobal path=/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setglobal! :path [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can update option value with kv-table"
      (vim.cmd "setglobal listchars=eol:a,tab:abc,space:a")
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setglobal! :listchars {:eol :a :tab :abc :space :a})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (if (= 1 (vim.fn.has :nvim-0.10.0-dev))
        (it* "throws an error with nil assigned"
          (assert.error #(set vim.opt_global.foldlevel nil)))
        (it* "can update some option value with nil"
          (set vim.opt_global.foldlevel nil)
          (let [vals (get-o-lo-go :foldlevel)]
            (reset-context)
            (setglobal! :foldlevel nil)
            (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can update some option value with symbol"
      (let [new-val 2]
        (set vim.opt_global.foldlevel new-val)
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (setglobal! :foldlevel new-val)
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can update some option value with list"
      (let [return-val #2]
        (set vim.opt_global.foldlevel (return-val))
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (setglobal! :foldlevel (return-val))
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can append option value of sequence"
      (vim.opt_global.path:append [:/foo :/bar :/baz])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setglobal! :path + [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can prepend option value of sequence"
      (vim.opt_global.path:prepend [:/foo :/bar :/baz])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setglobal! :path ^ [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can remove option value of sequence"
      (vim.opt_global.path:remove [:/tmp :/var])
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (setglobal! :path - [:/tmp :/var])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can append option value of kv-table"
      (vim.opt_global.listchars:append {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setglobal! :listchars + {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can prepend option value of kv-table"
      (vim.opt_global.listchars:prepend {:lead :a :trail :b :extends :c})
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setglobal! :listchars ^ {:lead :a :trail :b :extends :c})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can remove option value of kv-table"
      (vim.opt_global.listchars:remove [:eol :tab])
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (setglobal! :listchars - [:eol :tab])
        (assert.is_same vals (get-o-lo-go :listchars))))
    (describe* "for &l:shortmess"
      (it* "can append flags in sequence"
        ;; Note: In truth, the shortmess flag order doesn't matter.
        (setglobal! :shortMess + [:m :n :r])
        (assert.is_same {:f true :i true :w true :m true :n true :r true}
                        (get-lo :shortmess)))
      (it* "can prepend flags in sequence"
        ;; Note: In truth, the shortmess flag order doesn't matter.
        (setglobal! :shortMess ^ [:m :n :r])
        (assert.is_same {:f true :i true :w true :m true :n true :r true}
                        (get-lo :shortmess)))
      (it* "can remove flags in sequence"
        (setglobal! :shortMess - [:i :f])
        (assert.is_same {:w true} (get-lo :shortmess))))
    (describe* "with no value"
      (it* "updates option value to `true`"
        (vim.cmd "setglobal nowrap")
        (assert.is_false (get-go :wrap))
        (setglobal! :wrap)
        (assert.is_true (get-go :wrap)))
      (it* "updates value to `true` even when option name is hidden in compile time"
        (vim.cmd "setglobal nowrap")
        (assert.is_false (get-go :wrap))
        (let [name :wrap]
          (setglobal! name)
          (assert.is_true (get-go name))))))
  (describe* :bo!
    (it* "can update option value with boolean"
      (tset vim.bo :expandtab false)
      (let [vals (get-o-lo-go :expandtab)]
        (reset-context)
        (bo! :expandtab false)
        (assert.is_same vals (get-o-lo-go :expandtab))))
    (it* "can update option value with number"
      (tset vim.bo :tabstop 2)
      (let [vals (get-o-lo-go :tabstop)]
        (reset-context)
        (bo! :tabstop 2)
        (assert.is_same vals (get-o-lo-go :tabstop))))
    (it* "can update option value with string"
      (tset vim.bo :omnifunc :abc)
      (let [vals (get-o-lo-go :omnifunc)]
        (reset-context)
        (bo! :omnifunc :abc)
        (assert.is_same vals (get-o-lo-go :omnifunc))))
    (it* "can update option value with sequence"
      (tset vim.bo :path "/foo,/bar,/baz")
      (let [vals (get-o-lo-go :path)]
        (reset-context)
        (bo! :path [:/foo :/bar :/baz])
        (assert.is_same vals (get-o-lo-go :path))))
    (it* "can update option value with kv-table"
      (tset vim.bo :matchpairs "a:A,b:B,c:C")
      (let [vals (get-o-lo-go :matchpairs)]
        (reset-context)
        (bo! :matchPairs {:a :A :b :B :c :C})
        (assert.is_same vals (get-o-lo-go :matchpairs))))
    (it* "can update some option value with nil"
      (set vim.bo.tabstop nil)
      (let [vals (get-o-lo-go :tabstop)]
        (reset-context)
        (bo! :tabstop nil)
        (assert.is_same vals (get-o-lo-go :tabstop))))
    (it* "can update some option value with symbol"
      (let [new-val 2]
        (set vim.bo.tabstop new-val)
        (let [vals (get-o-lo-go :tabstop)]
          (reset-context)
          (bo! :tabstop new-val)
          (assert.is_same vals (get-o-lo-go :tabstop)))))
    (it* "can update some option value with list"
      (let [return-val #2]
        (set vim.bo.tabstop (return-val))
        (let [vals (get-o-lo-go :tabstop)]
          (reset-context)
          (bo! :tabstop (return-val))
          (assert.is_same vals (get-o-lo-go :tabstop)))))
    (describe* "with bufnr"
      (it* "can update option value with boolean"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :expandtab false)
          (assert.is_false (. vim.bo buf :expandtab))))
      (it* "can update option value with number"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :tabstop 2)
          (assert.is_same 2 (. vim.bo buf :tabstop))))
      (it* "can update option value with string"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :omnifunc :abc)
          (assert.is_same :abc (. vim.bo buf :omnifunc))))
      (it* "can update option value with sequence"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :path [:/foo :/bar :/baz])
          (assert.is_same "/foo,/bar,/baz" (. vim.bo buf :path))))
      (it* "can update option value with kv-table"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :matchPairs {:a :A :b :B :c :C})
          (assert.is_same "a:A,b:B,c:C" (. vim.bo buf :matchpairs))))
      (it* "can update some option value with nil"
        (let [buf (vim.api.nvim_get_current_buf)]
          (reset-context)
          (bo! buf :tabstop nil)
          (assert.is_same vim.go.tabstop (. vim.bo buf :tabstop))))
      (it* "can update some option value with symbol"
        (let [buf (vim.api.nvim_get_current_buf)
              new-val 2]
          (reset-context)
          (bo! buf :tabstop new-val)
          (assert.is_same new-val (. vim.bo buf :tabstop))))
      (it* "can update some option value with list"
        (let [buf (vim.api.nvim_get_current_buf)
              new-val 2
              return-val #new-val]
          (reset-context)
          (bo! buf :tabstop (return-val))
          (assert.is_same new-val (. vim.bo buf :tabstop))))))
  (describe* :wo!
    (it* "can update option value with boolean"
      (tset vim.wo :wrap false)
      (let [vals (get-o-lo-go :wrap)]
        (reset-context)
        (wo! :wrap false)
        (assert.is_same vals (get-o-lo-go :wrap))))
    (it* "can update option value with number"
      (tset vim.wo :foldlevel 2)
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (wo! :foldlevel 2)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update option value with string"
      (tset vim.wo :signcolumn :no)
      (let [vals (get-o-lo-go :signcolumn)]
        (reset-context)
        (wo! :signcolumn :no)
        (assert.is_same vals (get-o-lo-go :signcolumn))))
    (it* "can update option value with sequence"
      (tset vim.wo :colorcolumn "80,81,82")
      (let [vals (get-o-lo-go :colorcolumn)]
        (reset-context)
        (wo! :colorcolumn [:80 :81 :82])
        (assert.is_same vals (get-o-lo-go :colorcolumn))))
    (it* "can update option value with kv-table"
      (tset vim.wo :listchars "eol:a,tab:abc,space:a")
      (let [vals (get-o-lo-go :listchars)]
        (reset-context)
        (wo! :listchars {:eol :a :tab :abc :space :a})
        (assert.is_same vals (get-o-lo-go :listchars))))
    (it* "can update some option value with nil"
      (set vim.wo.foldlevel nil)
      (let [vals (get-o-lo-go :foldlevel)]
        (reset-context)
        (wo! :foldlevel nil)
        (assert.is_same vals (get-o-lo-go :foldlevel))))
    (it* "can update some option value with symbol"
      (let [new-val 2]
        (set vim.wo.foldlevel new-val)
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (wo! :foldlevel new-val)
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (it* "can update some option value with list"
      (let [return-val #2]
        (set vim.wo.foldlevel (return-val))
        (let [vals (get-o-lo-go :foldlevel)]
          (reset-context)
          (wo! :foldlevel (return-val))
          (assert.is_same vals (get-o-lo-go :foldlevel)))))
    (describe* "with win-id"
      (it* "can update option value with woolean"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :wrap false)
          (assert.is_false (. vim.wo win :wrap))))
      (it* "can update option value with number"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :foldlevel 2)
          (assert.is_same 2 (. vim.wo win :foldlevel))))
      (it* "can update option value with string"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :signcolumn :no)
          (assert.is_same :no (. vim.wo win :signcolumn))))
      (it* "can update option value with sequence"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :colorcolumn [:80 :81 :82])
          (assert.is_same "80,81,82" (. vim.wo win :colorcolumn))))
      (it* "can update option value with kv-table"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :listchars {:eol :a :tab :abc :space :a})
          (assert.is_same "eol:a,tab:abc,space:a" (. vim.wo win :listchars))))
      (it* "can update some option value with nil"
        (let [win (vim.api.nvim_get_current_win)]
          (vim.cmd.new)
          (wo! win :foldlevel nil)
          (assert.is_same vim.go.foldlevel (. vim.wo win :foldlevel))))
      (it* "can update some option value with symbol"
        (let [win (vim.api.nvim_get_current_win)
              new-val 2]
          (vim.cmd.new)
          (wo! win :foldlevel new-val)
          (assert.is_same new-val (. vim.wo win :foldlevel))))
      (it* "can update some option value with list"
        (let [win (vim.api.nvim_get_current_win)
              new-val 2
              return-val #new-val]
          (vim.cmd.new)
          (wo! win :foldlevel (return-val))
          (assert.is_same new-val (. vim.wo win :foldlevel))))))
  (describe* "(wrapper)"
    (describe* :set+
      (it* "appends option value of sequence"
        (let [name :path
              assigned-val [:/foo :/bar :/baz]]
          (-> (. vim.opt name) (: :append assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set+ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "appends option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :append assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set+ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name))))))
    (describe* :set^
      (it* "prepends option value of sequence"
        (let [name :path
              assigned-val [:/foo :/bar :/baz]]
          (-> (. vim.opt name) (: :prepend assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set^ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "prepends option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :prepend assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set^ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name))))))
    (describe* :set-
      (it* "removes option value of sequence"
        (let [name :path
              assigned-val [:/tmp :/var]]
          (-> (. vim.opt name) (: :remove assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set- name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "removes option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :remove assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (set- name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))))
  (describe* "(deprecated, v0.7.0 will not support this spec.)"
    (describe* :set+
      (it* "appends option value of sequence"
        (let [name :path
              assigned-val [:/foo :/bar :/baz]]
          (-> (. vim.opt name) (: :append assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set+ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "appends option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :append assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set+ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name))))))
    (describe* :set^
      (it* "prepends option value of sequence"
        (let [name :path
              assigned-val [:/foo :/bar :/baz]]
          (-> (. vim.opt name) (: :prepend assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set^ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "prepends option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :prepend assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set^ name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name))))))
    (describe* :set-
      (it* "removes option value of sequence"
        (let [name :path
              assigned-val [:/tmp :/var]]
          (-> (. vim.opt name) (: :remove assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set- name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name)))))
      (it* "removes option value of kv-table"
        (let [name :listchars
              assigned-val {:lead :a :trail :b :extends :c}]
          (-> (. vim.opt name) (: :remove assigned-val))
          (let [expected-vals (get-o-lo-go name)]
            (reset-context)
            (deprecated/set- name assigned-val)
            (assert.is_same expected-vals (get-o-lo-go name))))))))
