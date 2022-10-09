(import-macros {: command!} :nvim-laurel.macros)

(describe :command! ;
          (fn []
            (it "defines user command"
                (fn []
                  (assert.is_nil (-> (vim.api.nvim_get_commands {:builtin false})
                                     (. :Foo)))
                  (command! :Foo :Bar)
                  (assert.is_not_nil (-> (vim.api.nvim_get_commands {:builtin false})
                                         (. :Foo)))))
            (it "defines buffer-local user command"
                (fn []
                  (assert.is_nil (-> (vim.api.nvim_buf_get_commands 0
                                                                    {:builtin false})
                                     (. :Foo)))
                  (command! :Foo :Bar {:buffer 0})
                  (assert.is_not_nil (-> (vim.api.nvim_buf_get_commands 0
                                                                        {:builtin false})
                                         (. :Foo)))))))
