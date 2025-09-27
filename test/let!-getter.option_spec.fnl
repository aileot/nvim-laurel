(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: let!} :laurel.macros)

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

(fn reset-context! []
  "Reset test context."
  (each [name val (pairs default-opt-map)]
    (tset vim.opt name val)
    (assert.is_same val (. vim.go name))
    (assert.is_same val (. vim.o name)))
  (vim.cmd.new)
  (vim.cmd.only)
  (each [name val (pairs default-opt-map)]
    (assert.is_same val (. vim.o name))))

(describe* "`let!` with a symbol `?`"
  (before_each (fn []
                 (reset-context!)))
  (describe* "can return value"
    (describe* "in the format that `vim.api` function returns"
      (describe* "of option"
        (it* "`:opt_local`"
          (set vim.opt_local.expandtab false)
          (assert.is_false (let! :opt_local :expandtab ?))
          (set vim.opt_local.expandtab true)
          (assert.is_true (let! :opt_local :expandtab ?)))
        (describe* "`:bo`"
          (it* "in boolean"
            (set vim.bo.expandtab false)
            (assert.is_false (let! :bo :expandtab ?))
            (set vim.bo.expandtab true)
            (assert.is_true (let! :bo :expandtab ?)))
          (describe* "with index"
            (it* "in boolean"
              (let [buf (vim.api.nvim_get_current_buf)]
                (vim.cmd.new)
                (tset vim.bo buf :expandtab false)
                (assert.is_false (let! :bo buf :expandtab ?))
                (tset vim.bo buf :expandtab true)
                (assert.is_true (let! :bo buf :expandtab ?))))))
        (describe* "`:wo`"
          (it* "in boolean"
            (set vim.wo.wrap false)
            (assert.is_false (let! :wo :wrap ?))
            (set vim.wo.wrap true)
            (assert.is_true (let! :wo :wrap ?)))
          (describe* "with index"
            (it* "in boolean"
              (let [win (vim.api.nvim_get_current_win)]
                (vim.cmd.new)
                (tset vim.wo win :wrap false)
                (assert.is_false (let! :wo win :wrap ?))
                (tset vim.wo win :wrap true)
                (assert.is_true (let! :wo win :wrap ?))))))))))
