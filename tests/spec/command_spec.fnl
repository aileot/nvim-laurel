(import-macros {: command!} :nvim-laurel.macros)

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(local default-callback #:default-callback)
(local default {:multi {:sym #:default.multi.sym}})

(lambda get-command [name]
  (-> (vim.api.nvim_get_commands {:builtin false})
      (. name)))

(lambda get-command-definition [name]
  "Return command, or value for desc if callback is Lua function.
  Read `Parameters.opts.desc` of `:h nvim_create_user_command()`"
  (. (get-command name) :definition))

(lambda get-buf-command [bufnr name]
  (-> (vim.api.nvim_buf_get_commands bufnr {:builtin false})
      (. name)))

(describe :command!
  (fn []
    (before_each (fn []
                   (pcall vim.api.nvim_del_user_command :Foo)
                   (pcall vim.api.nvim_buf_del_user_command 0 :Foo)
                   (assert.is_nil (get-command :Foo))))
    (it "defines user command"
      (fn []
        (assert.is_nil (get-command :Foo))
        (command! :Foo :Bar)
        (assert.is_not_nil (get-command :Foo))))
    (it "defines local user command for current buffer with `<buffer>` attr"
      (fn []
        (assert.is_nil (get-buf-command 0 :Foo))
        (command! [:<buffer>] :Foo :Bar)
        (assert.is_not_nil (get-buf-command 0 :Foo))))
    (it "defines local user command with buffer number"
      (fn []
        (let [bufnr (vim.api.nvim_get_current_buf)]
          (assert.is_nil (get-buf-command bufnr :Foo))
          (vim.cmd.new)
          (vim.cmd.only)
          (command! :Foo [:buffer bufnr] :Bar)
          (assert.is_not_nil (get-buf-command bufnr :Foo))
          (assert.has_no_error #(vim.api.nvim_buf_del_user_command bufnr :Foo)))))
    (it "can set callback function with quoted symbol"
      (fn []
        (command! :Foo `default-callback)
        ;; Note: command.definition should be empty string if callback is
        ;; function without `desc` key.
        (assert.is_same "" (get-command-definition :Foo))))
    (it "can set callback function with quoted multi-symbol"
      (fn []
        (let [desc :multi.sym]
          (command! :Foo `default.multi.sym {: desc})
          (assert.is_same desc (get-command-definition :Foo)))))
    (it "can set quoted list result to callback"
      (fn []
        (let [desc :list]
          (command! :Foo `(default-callback :foo :bar) {: desc})
          (assert.is_same (default-callback) (get-command-definition :Foo)))))
    (it "which sets callback `vim.fn.Test will not be overridden by `desc` key"
      ;; Note: The reason is probably vim.fn.Test is not a Lua function but
      ;; a Vim one.
      (fn []
        (let [desc :Test]
          (command! :Foo `vim.fn.Test)
          (assert.is_same "" (get-command-definition :Foo))
          (assert.is_not_same desc (get-command-definition :Foo)))))
    (it "must be wrapped in hashfn, fn, ..., to set callback in macro"
      (fn []
        (command! :Foo #(macro-callback))
        ;; TODO: Check if callback is set.
        (assert.is_not_nil (get-command :Foo))))
    (it "set command in macro with no args"
      (fn []
        (command! :Foo (macro-command))
        (assert.is_same :macro-command (get-command-definition :Foo))))
    (it "set command in macro with some args"
      (fn []
        (command! :Foo (macro-command :foo :bar))
        (assert.is_same :macro-command (get-command-definition :Foo))))
    (describe :extra-opts
      (fn []
        (it "can be either first arg or second arg"
          (fn []
            (assert.has_no_error #(command! [:bang] :Foo :Bar))
            (assert.has_no_error #(command! :Foo [:bang] :Bar))))))
    (describe :api-opts
      (fn []
        (it "gives priority api-opts over extra-opts"
          (fn []
            (command! :Foo [:bar :bang] :FooBar)
            (assert.is_true (-> (get-command :Foo) (. :bang)))
            (assert.is_true (-> (get-command :Foo) (. :bar)))
            (command! :Bar [:bar :bang] :FooBar {:bar false})
            (assert.is_false (-> (get-command :Bar) (. :bar)))
            (let [tbl-opts {:bar false}
                  fn-opts #{:bang false}]
              (command! :Baz [:bar :bang] :FooBar tbl-opts)
              (command! :Qux [:bar :bang] :FooBar (fn-opts))
              (let [cmd-baz (get-command :Baz)
                    cmd-qux (get-command :Qux)]
                (assert.is_false cmd-baz.bar)
                (assert.is_true cmd-baz.bang)
                (assert.is_true cmd-qux.bar)
                (assert.is_false cmd-qux.bang)))))))))
