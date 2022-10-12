(import-macros {: command!} :nvim-laurel.macros)

(lambda get-command [name]
  (-> (vim.api.nvim_get_commands {:builtin false})
      (. name)))

(lambda get-buf-command [bufnr name]
  (-> (vim.api.nvim_buf_get_commands bufnr {:builtin false})
      (. name)))

(describe :command! ;
          (fn []
            (before_each (fn []
                           (pcall vim.api.nvim_del_user_command :Foo)
                           (pcall vim.api.nvim_buf_del_user_command 0 :Foo)))
            (it "defines user command"
                (fn []
                  (assert.is_nil (get-command :Foo))
                  (command! :Foo :Bar)
                  (assert.is_not_nil (get-command :Foo))))
            (it "defines local user command for current buffer with `buffer` attr"
                (fn []
                  (assert.is_nil (get-buf-command 0 :Foo))
                  (command! [:buffer] :Foo :Bar)
                  (assert.is_not_nil (get-buf-command 0 :Foo))))))
