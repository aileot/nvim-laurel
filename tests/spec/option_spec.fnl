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
        (it "updates option values in any type"
          (fn []))))))
