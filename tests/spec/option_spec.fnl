(import-macros {: set!
                : set+
                : set^
                : set-
                : setglobal!
                : setlocal!
                : bo!
                : wo!} :nvim-laurel.macros)

(macro get-o [name]
  `(-> (. vim.opt ,name) (: :get)))

(macro get-go [name]
  `(-> (. vim.opt_global ,name) (: :get)))

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
       {;; buffer-local options
        ;; boolean (bo)
        :expandtab true
        ;; number (bo)
        :tabstop 1
        ;; string (bo) x
        :omnifunc :xyx
        ;; sequence (bo)
        :path "/tmp,/var,/usr"
        ;; kv-table (bo)
        :matchpairs "x:X,y:Y,z:Z"
        ;; window-local options
        ;; boolean (wo)
        :wrap true
        ;; number (wo)
        :foldlevel 1
        ;; string (wo)
        :signcolumn :yes
        ;; sequence (wo)
        :colorcolumn "+1,+2,+3"
        ;; kv-table (wo)
        :listchars "eol:x,tab:xy,space:x"})

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

(describe :options
  (fn []
    (before_each reset-context)
    (describe :set!
      (fn []
        (it "is case-insensitive at option name"
          (fn []
            (vim.cmd "set foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldLevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value with boolean"
          (fn []
            (vim.cmd "set nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (set! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value with number"
          (fn []
            (vim.cmd "set foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value with string"
          (fn []
            (vim.cmd "set signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (set! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value with sequence"
          (fn []
            (vim.cmd "set path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value with kv-table"
          (fn []
            (vim.cmd "set listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value with nil"
          (fn []
            (set vim.opt.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value with symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (set! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value with list"
          (fn []
            (let [return-val #2]
              (set vim.opt.foldlevel (return-val))
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (set! :foldlevel (return-val))
                (assert.is_same vals (get-o-lo-go :foldlevel))
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can append option value of sequence"
          (fn []
            (vim.cmd "set path+=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path+ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can prepend option value of sequence"
          (fn []
            (vim.cmd "set path^=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path^ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can remove option value of sequence"
          (fn []
            (vim.cmd "set path-=/tmp,/var")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path- [:/tmp :/var])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can append option value of kv-table"
          (fn []
            (: vim.opt.listchars :append {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars+ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can prepend option value of kv-table"
          (fn []
            (: vim.opt.listchars :prepend {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars^ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can remove option value of kv-table"
          (fn []
            (: vim.opt.listchars :remove [:eol :tab])
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars- [:eol :tab])
              (assert.is_same vals (get-o-lo-go :listchars))))))
      (describe "with no value"
        (fn []
          (it "updates option value to `true`"
            (fn []
              (vim.cmd "set nowrap")
              (assert.is_false (get-o :wrap))
              (set! :wrap)
              (assert.is_true (get-o :wrap))))
          (it "updates value to `true` even when option name is hidden in compile time"
            (fn []
              (vim.cmd "set nowrap")
              (assert.is_false (get-o :wrap))
              (let [name :wrap]
                (set! name)
                (assert.is_true (get-o name))))))))
    (describe :setlocal!
      (fn []
        (it "can update option value with boolean"
          (fn []
            (vim.cmd "setlocal nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (setlocal! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value with number"
          (fn []
            (vim.cmd "setlocal foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setlocal! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value with string"
          (fn []
            (vim.cmd "setlocal signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (setlocal! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value with sequence"
          (fn []
            (vim.cmd "setlocal path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setlocal! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value with kv-table"
          (fn []
            (vim.cmd "setlocal listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setlocal! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value with nil"
          (fn []
            (set vim.opt_local.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setlocal! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value with symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt_local.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setlocal! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value with list"
          (fn []
            (let [return-val #2]
              (set vim.opt_local.foldlevel (return-val))
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setlocal! :foldlevel (return-val))
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can append option value of sequence"
          (fn []
            (: vim.opt_local.path :append [:/foo :/bar :/baz])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setlocal! :path+ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can prepend option value of sequence"
          (fn []
            (: vim.opt_local.path :prepend [:/foo :/bar :/baz])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setlocal! :path^ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can remove option value of sequence"
          (fn []
            (: vim.opt_local.path :remove [:/tmp :/var])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setlocal! :path- [:/tmp :/var])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can append option value of kv-table"
          (fn []
            (: vim.opt_local.listchars :append {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setlocal! :listchars+ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can prepend option value of kv-table"
          (fn []
            (: vim.opt_local.listchars :prepend
               {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setlocal! :listchars^ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can remove option value of kv-table"
          (fn []
            (: vim.opt_local.listchars :remove [:eol :tab])
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setlocal! :listchars- [:eol :tab])
              (assert.is_same vals (get-o-lo-go :listchars))))))
      (describe "with no value"
        (fn []
          (it "updates option value to `true`"
            (fn []
              (vim.cmd "setlocal nowrap")
              (assert.is_false (get-lo :wrap))
              (setlocal! :wrap)
              (assert.is_true (get-lo :wrap))))
          (it "updates value to `true` even when option name is hidden in compile time"
            (fn []
              (vim.cmd "setlocal nowrap")
              (assert.is_false (get-lo :wrap))
              (let [name :wrap]
                (setlocal! name)
                (assert.is_true (get-lo name))))))))
    (describe :setglobal!
      (fn []
        (it "can update option value with boolean"
          (fn []
            (vim.cmd "setglobal nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (setglobal! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value with number"
          (fn []
            (vim.cmd "setglobal foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setglobal! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value with string"
          (fn []
            (vim.cmd "setglobal signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (setglobal! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value with sequence"
          (fn []
            (vim.cmd "setglobal path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setglobal! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value with kv-table"
          (fn []
            (vim.cmd "setglobal listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setglobal! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value with nil"
          (fn []
            (set vim.opt_global.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setglobal! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value with symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt_global.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setglobal! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value with list"
          (fn []
            (let [return-val #2]
              (set vim.opt_global.foldlevel (return-val))
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setglobal! :foldlevel (return-val))
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can append option value of sequence"
          (fn []
            (: vim.opt_global.path :append [:/foo :/bar :/baz])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setglobal! :path+ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can prepend option value of sequence"
          (fn []
            (: vim.opt_global.path :prepend [:/foo :/bar :/baz])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setglobal! :path^ [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can remove option value of sequence"
          (fn []
            (: vim.opt_global.path :remove [:/tmp :/var])
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setglobal! :path- [:/tmp :/var])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can append option value of kv-table"
          (fn []
            (: vim.opt_global.listchars :append
               {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setglobal! :listchars+ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can prepend option value of kv-table"
          (fn []
            (: vim.opt_global.listchars :prepend
               {:lead :a :trail :b :extends :c})
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setglobal! :listchars^ {:lead :a :trail :b :extends :c})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can remove option value of kv-table"
          (fn []
            (: vim.opt_global.listchars :remove [:eol :tab])
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setglobal! :listchars- [:eol :tab])
              (assert.is_same vals (get-o-lo-go :listchars))))))
      (describe "with no value"
        (fn []
          (it "updates option value to `true`"
            (fn []
              (vim.cmd "setglobal nowrap")
              (assert.is_false (get-go :wrap))
              (setglobal! :wrap)
              (assert.is_true (get-go :wrap))))
          (it "updates value to `true` even when option name is hidden in compile time"
            (fn []
              (vim.cmd "setglobal nowrap")
              (assert.is_false (get-go :wrap))
              (let [name :wrap]
                (setglobal! name)
                (assert.is_true (get-go name))))))))
    (describe :bo!
      (fn []
        (it "can update option value with boolean"
          (fn []
            (tset vim.bo :expandtab false)
            (let [vals (get-o-lo-go :expandtab)]
              (reset-context)
              (bo! :expandtab false)
              (assert.is_same vals (get-o-lo-go :expandtab)))))
        (it "can update option value with number"
          (fn []
            (tset vim.bo :tabstop 2)
            (let [vals (get-o-lo-go :tabstop)]
              (reset-context)
              (bo! :tabstop 2)
              (assert.is_same vals (get-o-lo-go :tabstop)))))
        (it "can update option value with string"
          (fn []
            (tset vim.bo :omnifunc :abc)
            (let [vals (get-o-lo-go :omnifunc)]
              (reset-context)
              (bo! :omnifunc :abc)
              (assert.is_same vals (get-o-lo-go :omnifunc)))))
        (it "can update option value with sequence"
          (fn []
            (tset vim.bo :path "/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (bo! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value with kv-table"
          (fn []
            (tset vim.bo :matchpairs "a:A,b:B,c:C")
            (let [vals (get-o-lo-go :matchpairs)]
              (reset-context)
              (bo! :matchPairs {:a :A :b :B :c :C})
              (assert.is_same vals (get-o-lo-go :matchpairs)))))
        (it "can update some option value with nil"
          (fn []
            (set vim.bo.tabstop nil)
            (let [vals (get-o-lo-go :tabstop)]
              (reset-context)
              (bo! :tabstop nil)
              (assert.is_same vals (get-o-lo-go :tabstop)))))
        (it "can update some option value with symbol"
          (fn []
            (let [new-val 2]
              (set vim.bo.tabstop new-val)
              (let [vals (get-o-lo-go :tabstop)]
                (reset-context)
                (bo! :tabstop new-val)
                (assert.is_same vals (get-o-lo-go :tabstop))))))
        (it "can update some option value with list"
          (fn []
            (let [return-val #2]
              (set vim.bo.tabstop (return-val))
              (let [vals (get-o-lo-go :tabstop)]
                (reset-context)
                (bo! :tabstop (return-val))
                (assert.is_same vals (get-o-lo-go :tabstop))))))))
    (describe :wo!
      (fn []
        (it "can update option value with boolean"
          (fn []
            (tset vim.wo :wrap false)
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (wo! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value with number"
          (fn []
            (tset vim.wo :foldlevel 2)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (wo! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value with string"
          (fn []
            (tset vim.wo :signcolumn :no)
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (wo! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value with sequence"
          (fn []
            (tset vim.wo :colorcolumn "80,81,82")
            (let [vals (get-o-lo-go :colorcolumn)]
              (reset-context)
              (wo! :colorcolumn [:80 :81 :82])
              (assert.is_same vals (get-o-lo-go :colorcolumn)))))
        (it "can update option value with kv-table"
          (fn []
            (tset vim.wo :listchars "eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (wo! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value with nil"
          (fn []
            (set vim.wo.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (wo! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value with symbol"
          (fn []
            (let [new-val 2]
              (set vim.wo.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (wo! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value with list"
          (fn []
            (let [return-val #2]
              (set vim.wo.foldlevel (return-val))
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (wo! :foldlevel (return-val))
                (assert.is_same vals (get-o-lo-go :foldlevel))))))))
    (describe :set+
      (fn []
        (it "appends option value of sequence"
          #(let [name :path
                 assigned-val [:/foo :/bar :/baz]]
             (-> (. vim.opt name) (: :append assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set+ name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))
        (it "appends option value of kv-table"
          #(let [name :listchars
                 assigned-val {:lead :a :trail :b :extends :c}]
             (-> (. vim.opt name) (: :append assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set+ name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))))
    (describe :set^
      (fn []
        (it "prepends option value of sequence"
          #(let [name :path
                 assigned-val [:/foo :/bar :/baz]]
             (-> (. vim.opt name) (: :prepend assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set^ name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))
        (it "prepends option value of kv-table"
          #(let [name :listchars
                 assigned-val {:lead :a :trail :b :extends :c}]
             (-> (. vim.opt name) (: :prepend assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set^ name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))))
    (describe :set-
      (fn []
        (it "removes option value of sequence"
          #(let [name :path
                 assigned-val [:/tmp :/var]]
             (-> (. vim.opt name) (: :remove assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set- name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))
        (it "removes option value of kv-table"
          #(let [name :listchars
                 assigned-val {:lead :a :trail :b :extends :c}]
             (-> (. vim.opt name) (: :remove assigned-val))
             (let [expected-vals (get-o-lo-go name)]
               (reset-context)
               (set- name assigned-val)
               (assert.is_same expected-vals (get-o-lo-go name)))))))))
