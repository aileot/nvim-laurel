(import-macros {: describe* : it*} :test._busted_macros)
(import-macros vim* :nvim-laurel.macros)

(lambda get-mapargs [mode lhs]
  (let [mappings (vim.api.nvim_get_keymap mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(lambda get-rhs [mode lhs]
  (?. (get-mapargs mode lhs) :rhs))

(describe* "On vim*,"
  (describe* :vim*.map!
    (it* "sets keymap as `map!` does"
      ;; (assert.is_nil (get-rhs :n :lhs))
      (vim*.map! :n :lhs :rhs)
      (assert.same :rhs (get-rhs :n :lhs))))
  (describe* :vim*.map
    (it* "sets keymap as `map!` does"
      ;; (assert.is_nil (get-rhs :n :lhs))
      (vim*.map :n :lhs :rhs)
      (assert.same :rhs (get-rhs :n :lhs))))
  (describe* :vim*.g
    (it* "sets Vim Variable as `(let! :g ...)` does"
      ;; (assert.is_nil (get-rhs :n :lhs))
      (vim*.g :foo :bar)
      (assert.same :bar vim.g.foo))))
