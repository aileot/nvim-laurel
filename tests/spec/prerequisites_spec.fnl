(import-macros {: describe* : it*} :_busted_macros)

(describe* :prerequisites
  (it* "vim.api is not nil"
    (assert.is_not_nil vim)
    (assert.is_not_nil vim.api)))
