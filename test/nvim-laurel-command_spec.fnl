(import-macros {: describe* : it*} :test.helper.busted-macros)
(import-macros {: command!} :laurel.macros)
(import-macros {: buf-command!/as-api-alias} :test.helper.wrapper-macros)

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(macro buf-command!/current-buffer-by-default [...]
  `(command! &default-opts {:buffer 0} ,...))

(λ get-command [name]
  (-> (vim.api.nvim_get_commands {:builtin false})
      (. name)))

(λ get-command-definition [name]
  "Return command, or value for desc if callback is Lua function.
Read `Parameters.opts.desc` of `:h nvim_create_user_command()`"
  (. (get-command name) :definition))

(λ get-buf-command [bufnr name]
  (-> (vim.api.nvim_buf_get_commands bufnr {:builtin false})
      (. name)))

(describe* :command!
  (before_each (fn []
                 (pcall vim.api.nvim_del_user_command :Foo)
                 (pcall vim.api.nvim_buf_del_user_command 0 :Foo)
                 (assert.is_nil (get-command :Foo))))
  (it* "defines user command"
    (assert.is_nil (get-command :Foo))
    (command! :Foo :Bar)
    (assert.is_not_nil (get-command :Foo)))
  (it* "defines local user command for current buffer with `<buffer>` attr"
    (assert.is_nil (get-buf-command 0 :Foo))
    (command! [:<buffer>] :Foo :Bar)
    (assert.is_not_nil (get-buf-command 0 :Foo)))
  (it* "defines local user command with buffer number"
    (let [bufnr (vim.api.nvim_get_current_buf)]
      (assert.is_nil (get-buf-command bufnr :Foo))
      (vim.cmd.new)
      (vim.cmd.only)
      (command! :Foo [:buffer bufnr] :Bar)
      (assert.is_not_nil (get-buf-command bufnr :Foo))
      (assert.has_no_error #(vim.api.nvim_buf_del_user_command bufnr :Foo))))
  (it* "which sets callback vim.fn.Test will not be overridden by `desc` key"
    ;; Note: The reason is probably vim.fn.Test is not a Lua function but
    ;; a Vim one.
    (let [desc :Test]
      (command! :Foo vim.fn.Test)
      (assert.is_same "" (get-command-definition :Foo))
      (assert.is_not_same desc (get-command-definition :Foo))))
  (it* "set command in macro with no args"
    (command! :Foo (macro-command))
    (assert.is_same :macro-command (get-command-definition :Foo)))
  (it* "set command in macro with some args"
    (command! :Foo (macro-command :foo :bar))
    (assert.is_same :macro-command (get-command-definition :Foo)))
  (describe* :extra-opts
    (it* "can be either first arg or second arg"
      (assert.has_no_error #(command! [:bang] :Foo :Bar))
      (assert.has_no_error #(command! :Foo [:bang] :Bar)))
    (it* "can define command with `range` key with its value"
      (command! [:range "%"] :Foo :bar)
      (assert.is_same "%" (-> (get-command :Foo)
                              (. :range))))
    (it* "can define command with `range` key without its value"
      (command! [:range] :Foo :bar)
      (let [indicator-current-line "."]
        (assert.is_same indicator-current-line
                        (-> (get-command :Foo)
                            (. :range)))))
    (it* "can define command with `count` key with its value"
      (command! [:count 5] :Foo :bar)
      (assert.is_same :5 (-> (get-command :Foo)
                             (. :count))))
    (it* "can define command with `count` key without its value"
      (command! [:count] :Foo :bar)
      (let [default-count 0]
        (assert.is_same (tostring default-count)
                        (-> (get-command :Foo)
                            (. :count))))))
  (describe* :api-opts
    (it* "gives priority api-opts over extra-opts"
      (command! :Foo [:bar :bang] :FooBar)
      (assert.is_true (-> (get-command :Foo) (. :bang)))
      (assert.is_true (-> (get-command :Foo) (. :bar)))
      (command! :Bar [:bar :bang]
        :FooBar
        {:bar false})
      (assert.is_false (-> (get-command :Bar) (. :bar)))
      (let [tbl-opts {:bar false}
            fn-opts #{:bang false}]
        (command! :Baz [:bar :bang]
          :FooBar
          tbl-opts)
        (command! :Qux [:bar :bang]
          :FooBar
          (fn-opts))
        (let [cmd-baz (get-command :Baz)
              cmd-qux (get-command :Qux)]
          (assert.is_false cmd-baz.bar)
          (assert.is_true cmd-baz.bang)
          (assert.is_true cmd-qux.bar)
          (assert.is_false cmd-qux.bang)))))
  (describe* "(wrapper)"
    (describe* :buf-command!
      (describe* "as an alias of vim.api.nvim_buf_create_user_command()"
        (it* "can be defined as a macro"
          (vim.cmd.new)
          (vim.cmd.only)
          (let [bufnr (vim.api.nvim_get_current_buf)]
            (assert.is_nil (get-buf-command bufnr :Foo))
            (assert.has_no_error #(buf-command!/as-api-alias bufnr :Foo :Bar))
            (assert.is_not_nil (get-buf-command bufnr :Foo))
            (assert.has_no_error #(vim.api.nvim_buf_del_user_command bufnr :Foo)))))
      (describe* "which creates command for current buffer by default"
        (it* "can be defined as a macro"
          (vim.cmd.new)
          (vim.cmd.only)
          (let [bufnr (vim.api.nvim_get_current_buf)]
            (assert.is_nil (get-buf-command bufnr :Foo))
            (assert.has_no_error #(buf-command!/current-buffer-by-default :Foo
                                                                          :Bar))
            (assert.is_not_nil (get-buf-command bufnr :Foo))
            (assert.has_no_error #(vim.api.nvim_buf_del_user_command bufnr :Foo))))
        (it* "can overwrite target buffer"
          (let [buf1 (vim.api.nvim_get_current_buf)]
            (vim.cmd.new)
            (vim.cmd.only)
            (let [buf2 (vim.api.nvim_get_current_buf)]
              (assert.is_nil (get-buf-command buf1 :Foo))
              (assert.is_nil (get-buf-command buf2 :Foo))
              (assert.has_no_error #(buf-command!/current-buffer-by-default [:buffer
                                                                             buf1]
                                                                            :Foo
                                                                            :Bar))
              (assert.is_not_nil (get-buf-command buf1 :Foo))
              (assert.is_nil (get-buf-command buf2 :Foo))
              (assert.has_no_error #(vim.api.nvim_buf_del_user_command buf1
                                                                       :Foo))
              (assert.has_error #(vim.api.nvim_buf_del_user_command buf2 :Foo)))))))))
