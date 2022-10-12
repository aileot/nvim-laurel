(import-macros {: command!} :nvim-laurel.macros)

(lambda get-command [name]
  (-> (vim.api.nvim_get_commands {:builtin false})
      (. name)))

(lambda get-buf-command [bufnr name]
  (-> (vim.api.nvim_buf_get_commands bufnr {:builtin false})
      (. name)))

(describe :command! ;
          (fn []
            (it "defines user command"
                (fn []
                  (assert.is_nil (get-command :Foo))
                  (command! :Foo :Bar)
                  (assert.is_not_nil (get-command :Foo))))
            (it "defines buffer-local user command"
                (fn []
                  (assert.is_nil (get-buf-command :Foo))
                  (command! :Foo :Bar {:buffer 0})
                  (assert.is_not_nil (get-buf-command :Foo))))))
