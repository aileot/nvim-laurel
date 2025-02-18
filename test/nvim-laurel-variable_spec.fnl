(import-macros {: describe* : it*} :test.helper.busted-macros)
(import-macros {: b! : env!} :laurel.macros)

(describe* :b!
  (before_each (fn []
                 (set vim.b.foo nil)
                 (set vim.b.bar nil)
                 (set vim.env.FOO nil)
                 (set vim.env.BAR nil)))
  (it* "sets environment variable in the editor session"
    (env! :FOO :foo)
    (env! :$BAR :bar)
    (assert.is.same :foo vim.env.FOO)
    (assert.is.same :bar vim.env.BAR))
  (it* "sets buffer-local variable"
    (let [buf (vim.api.nvim_get_current_buf)]
      (vim.cmd.new)
      (vim.cmd.only)
      (b! :foo :foo1)
      (b! buf :bar :bar1)
      (assert.is_nil (. vim.b buf :foo))
      (assert.is_nil vim.b.bar)
      (assert.is.same :foo1 vim.b.foo)
      (assert.is.same :bar1 (. vim.b buf :bar)))))
