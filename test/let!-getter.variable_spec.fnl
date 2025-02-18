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
            (assert.equals "2" (let! :env :foo ?))))))))
