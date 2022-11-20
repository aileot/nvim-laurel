(import-macros {: set! : setglobal! : setlocal!} :nvim-laurel.macros)

(macro get-o [name]
  `(-> (. vim.opt ,name) (: :get)))

(macro get-go [name]
  `(-> (. vim.opt_global ,name) (: :get)))

(macro get-lo [name]
  `(-> (. vim.opt_local ,name) (: :get)))

(fn get-o-lo-go [name]
  "Get option values.
  @param name string
  @return any[]"
  [(get-o name) (get-lo name) (get-go name)])

(local default-opt-map
       ;; Note: The default option values are supposed to be different from
       ;; Neovim default value.
       {;; boolean
        :wrap true
        ;; number
        :foldlevel 1
        ;; string
        :signcolumn :yes
        ;; sequence
        :path "/tmp,/var,/usr"
        ;; kv-table
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
        (it "can update option value by boolean"
          (fn []
            (vim.cmd "set nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (set! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value by number"
          (fn []
            (vim.cmd "set foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value by string"
          (fn []
            (vim.cmd "set signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (set! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value by sequence"
          (fn []
            (vim.cmd "set path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value by kv-table"
          (fn []
            (vim.cmd "set listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value by nil"
          (fn []
            (set vim.opt.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value by symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (set! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value by list"
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
              (assert.is_same vals (get-o-lo-go :path)))))))
    (describe :setlocal!
      (fn []
        (it "can update option value by boolean"
          (fn []
            (vim.cmd "setlocal nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (setlocal! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value by number"
          (fn []
            (vim.cmd "setlocal foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setlocal! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value by string"
          (fn []
            (vim.cmd "setlocal signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (setlocal! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value by sequence"
          (fn []
            (vim.cmd "setlocal path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setlocal! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value by kv-table"
          (fn []
            (vim.cmd "setlocal listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setlocal! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value by nil"
          (fn []
            (set vim.opt_local.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value by symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt_local.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setlocal! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value by list"
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
              (assert.is_same vals (get-o-lo-go :path)))))))
    (describe :setglobal!
      (fn []
        (it "can update option value by boolean"
          (fn []
            (vim.cmd "setglobal nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (setglobal! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value by number"
          (fn []
            (vim.cmd "setglobal foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (setglobal! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value by string"
          (fn []
            (vim.cmd "setglobal signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (setglobal! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value by sequence"
          (fn []
            (vim.cmd "setglobal path=/foo,/bar,/baz")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (setglobal! :path [:/foo :/bar :/baz])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value by kv-table"
          (fn []
            (vim.cmd "setglobal listchars=eol:a,tab:abc,space:a")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (setglobal! :listchars {:eol :a :tab :abc :space :a})
              (assert.is_same vals (get-o-lo-go :listchars)))))
        (it "can update some option value by nil"
          (fn []
            (set vim.opt_global.foldlevel nil)
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel nil)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update some option value by symbol"
          (fn []
            (let [new-val 2]
              (set vim.opt_global.foldlevel new-val)
              (let [vals (get-o-lo-go :foldlevel)]
                (reset-context)
                (setglobal! :foldlevel new-val)
                (assert.is_same vals (get-o-lo-go :foldlevel))))))
        (it "can update some option value by list"
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
              (assert.is_same vals (get-o-lo-go :path)))))))))
