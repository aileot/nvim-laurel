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
        :path "/tmp,/var"
        ;; kv-table
        :listchars "eol:x,tab:xy"})

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
        (it "can update option value by boolean."
          (fn []
            (vim.cmd "set nowrap")
            (let [vals (get-o-lo-go :wrap)]
              (reset-context)
              (set! :wrap false)
              (assert.is_same vals (get-o-lo-go :wrap)))))
        (it "can update option value by number."
          (fn []
            (vim.cmd "set foldlevel=2")
            (let [vals (get-o-lo-go :foldlevel)]
              (reset-context)
              (set! :foldlevel 2)
              (assert.is_same vals (get-o-lo-go :foldlevel)))))
        (it "can update option value by string."
          (fn []
            (vim.cmd "set signcolumn=no")
            (let [vals (get-o-lo-go :signcolumn)]
              (reset-context)
              (set! :signcolumn :no)
              (assert.is_same vals (get-o-lo-go :signcolumn)))))
        (it "can update option value by sequence."
          (fn []
            (vim.cmd "set path=/foo,/bar")
            (let [vals (get-o-lo-go :path)]
              (reset-context)
              (set! :path [:/foo :/bar])
              (assert.is_same vals (get-o-lo-go :path)))))
        (it "can update option value by kv-table."
          (fn []
            (vim.cmd "set listchars=eol:a,tab:abc")
            (let [vals (get-o-lo-go :listchars)]
              (reset-context)
              (set! :listchars {:eol :a :tab :abc})
              (assert.is_same vals (get-o-lo-go :listchars)))))))))
