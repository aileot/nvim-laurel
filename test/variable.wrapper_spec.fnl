(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: v! : g! : b! : w! : t! : env!} :laurel.wrapper-macros)

(describe* "(supported wrapper of `let!` macro)"
  (describe* "`env!`"
    (before_each (fn []
                   (set vim.env.FOO nil)
                   (set vim.env.BAR nil)))
    (it* "sets environment variable in the editor session"
      (env! :FOO "foo")
      (env! :$BAR "bar")
      (assert.is_same "foo" vim.env.FOO)
      (assert.is_same "bar" vim.env.BAR)))
  (describe* "`v!`"
    (before_each (fn []
                   (set vim.b.foo nil)
                   (set vim.b.bar nil)))
    (it* "sets `v:` variable"
      (v! :errmsg "bar")
      (assert.is_same "bar" vim.v.errmsg)))
  (describe* "`g!`"
    (before_each (fn []
                   (set vim.b.foo nil)
                   (set vim.b.bar nil)))
    (it* "sets global variable"
      (g! :foo "bar")
      (assert.is_same "bar" vim.g.foo)))
  (describe* "`b!`"
    (before_each (fn []
                   (set vim.b.foo nil)
                   (set vim.b.bar nil)))
    (it* "sets buffer-local variable in the current buffer"
      (b! :foo "bar")
      (assert.is_nil vim.b.bar)
      (assert.is_same "bar" vim.b.foo))
    (it* "sets buffer-local variable with specific buffer id"
      (let [buf (vim.api.nvim_get_current_buf)]
        (vim.cmd.new)
        (b! buf :bar "bar")
        (assert.is_nil (. vim.b buf :foo))
        (assert.is_same "bar" (. vim.b buf :bar)))))
  (describe* "`w!`"
    (before_each (fn []
                   (set vim.w.foo nil)
                   (set vim.w.bar nil)))
    (it* "sets window-local variable in the current window"
      (w! :foo "bar")
      (assert.is_nil vim.w.bar)
      (assert.is_same "bar" vim.w.foo))
    (it* "sets window-local variable with specific window id"
      (let [win (vim.api.nvim_get_current_win)]
        ;; Create a new split window, making it the current one
        (vim.cmd.new)
        ;; Set variable in the *original* window `win`
        (w! win :bar "bar")
        ;; Assertions
        (assert.is_nil vim.w.bar
                       "Variable should not be set in the current window")
        (assert.is_same "bar" (. vim.w win :bar)
                        "Variable should be set in the specified window"))))
  (describe* "`t!`"
    (before_each (fn []
                   (set vim.t.foo nil)
                   (set vim.t.bar nil)))
    (it* "sets tab-local variable in the current tab"
      (t! :foo "bar")
      (assert.is_nil vim.t.bar)
      (assert.is_same "bar" vim.t.foo))
    (it* "sets tab-local variable with specific tabpage id"
      (let [tab (vim.api.nvim_get_current_tabpage)]
        ;; Create a new tab, making it the current one
        (vim.cmd.tabnew)
        ;; Set variable in the *original* tabpage `tab`
        (t! tab :bar "bar")
        ;; Assertions
        (assert.is_nil vim.t.bar
                       "Variable should not be set in the current tabpage")
        (assert.is_same "bar" (. vim.t tab :bar)
                        "Variable should be set in the specified tabpage")))))
