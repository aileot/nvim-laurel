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
                  (assert.is_not_nil (get-buf-command 0 :Foo))))
            (it "defines local user command with buffer number"
                (fn []
                  (let [bufnr (vim.api.nvim_get_current_buf)]
                    (assert.is_nil (get-buf-command bufnr :Foo))
                    (vim.cmd.new)
                    (vim.cmd.only)
                    (command! :Foo [:buffer= bufnr] :Bar)
                    (assert.is_not_nil (get-buf-command bufnr :Foo))
                    (assert.has_no_error #(vim.api.nvim_buf_del_user_command bufnr
                                                                             :Foo)))))))
