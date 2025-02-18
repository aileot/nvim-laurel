(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: let!} :laurel.macros)

;; (describe* "`let!` with a symbol `?`"
;;   (describe* "can return value"
;;     (describe* "in the format that `vim.api` function returns"
;;       (describe* "of option"
;;         (it* "`o`"
;;           (set vim.o.tabstop 1)
;;           (assert.equals 1 (let! :o :tabstop ?)))))))

(describe* "`let!` with a symbol `?`"
  (describe* "can return value"
    (describe* "in the format that `vim.api` function returns"
      (describe* "of variable"
        (describe* "with no scope option available"
          (it* "`:v`"
            (assert.equals vim.v.version (let! :v :version ?)))
          (it* "`:g`"
            (set vim.g.foo 1)
            (assert.equals 1 (let! :g :foo ?))
            (set vim.g.foo 2)
            (assert.equals 2 (let! :g :foo ?)))
          (it* "`:env`"
            ;; NOTE: vim.env, or os.getenv, returns value in string.
            (set vim.env.foo 1)
            (assert.equals "1" (let! :env :foo ?))
            (set vim.env.foo 2)
            (assert.equals "2" (let! :env :foo ?))))
        (describe* "without scope index"
          (it* "`:b`"
            (set vim.b.foo 1)
            (assert.equals 1 (let! :b :foo ?))
            (set vim.b.foo 2)
            (assert.equals 2 (let! :b :foo ?)))
          (it* "`:w`"
            (set vim.w.foo 1)
            (assert.equals 1 (let! :w :foo ?))
            (set vim.w.foo 2)
            (assert.equals 2 (let! :w :foo ?)))
          (it* "`:t`"
            (set vim.t.foo 1)
            (assert.equals 1 (let! :t :foo ?))
            (set vim.t.foo 2)
            (assert.equals 2 (let! :t :foo ?))))
        (describe* "with scope index"
          (it* "`:b`"
            (let [idx (vim.api.nvim_get_current_buf)]
              (tset vim.b idx :foo 1)
              (assert.equals 1 (let! :b idx :foo ?))
              (tset vim.b idx :foo 2)
              (assert.equals 2 (let! :b idx :foo ?))))
          (it* "`:w`"
            (let [idx (vim.api.nvim_get_current_win)]
              (tset vim.w idx :foo 1)
              (assert.equals 1 (let! :w idx :foo ?))
              (tset vim.w idx :foo 2)
              (assert.equals 2 (let! :w idx :foo ?)))))))))
