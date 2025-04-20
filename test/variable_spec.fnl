(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: b! : w! : t! : env!} :test.helper.wrapper-macros)

(import-macros {: let! :b! b* :env! env*} :laurel.macros)

(fn reset-context! []
  (vim.cmd.new)
  (vim.cmd.only))

;; TODO: Also test `:v`. What variable is not readonly?
(local scope-list [:g :b :w :t :env])

(describe* "`let!` macro for Vim script `variable` (g, b, w, t, env)"
  (before_each (fn []
                 (reset-context!)))
  (describe* "with scope in symbol"
    (it* "can set vim option value in any scope."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo :bar)
        (assert.is_same :bar (. vim scope :foo))))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (each [_ scope (ipairs scope-list)]
          (let! scope :foo)
          ;; Note: (. vim scope :foo) does not return `true`, but `v:true`.
          ;; However, attempt to compare with `"v:true"` only fails
          ;; because it surprisingly returns `true` then. So, it compares
          ;; both at a time as a workaround. At least, the compiled result
          ;; is the intended one.
          (assert.is_true (or (= true (. vim scope :foo))
                              (= "v:true" (. vim scope :foo)))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo)))))
  (describe* :g
    (it* "can set vim option value in any scope."
      (let! :g :foo :bar)
      (assert.is_same :bar (. vim :g :foo)))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (let! :g :foo)
        ;; Note: (. vim :g :foo) does not return `true`, but `v:true`.
        ;; However, attempt to compare with `"v:true"` only fails
        ;; because it surprisingly returns `true` then. So, it compares
        ;; both at a time as a workaround. At least, the compiled result
        ;; is the intended one.
        (assert.is_true (or (= true (. vim :g :foo))
                            (= "v:true" (. vim :g :foo))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo)))))
  (describe* :b
    (it* "can set vim option value in any scope."
      (let! :b :foo :bar)
      (assert.is_same :bar (. vim :b :foo)))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (let! :b :foo)
        (assert.is_true (or (= true (. vim :b :foo))
                            (= "v:true" (. vim :b :foo))))))
    (it* "also accepts buffer id after scope."
      (let [buf (vim.api.nvim_get_current_buf)]
        (vim.cmd.new)
        (let! :b buf :foo "bar")
        (assert.is_true (or (= "bar" (. vim :b buf :foo))
                            (= "bar" (. vim :b buf :foo))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo)))))
  (describe* :w
    (it* "can set vim option value in any scope."
      (let! :w :foo :bar)
      (assert.is_same :bar (. vim :w :foo)))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (let! :w :foo)
        (assert.is_true (or (= true (. vim :w :foo))
                            (= "v:true" (. vim :w :foo))))))
    (it* "also accepts window id after scope."
      (let [win (vim.api.nvim_get_current_win)]
        (vim.cmd.new)
        (let! :w win :foo "bar")
        (assert.is_true (or (= "bar" (. vim :w win :foo))
                            (= "bar" (. vim :w win :foo))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo)))))
  (describe* :t
    (it* "can set vim option value in any scope."
      (let! :t :foo :bar)
      (assert.is_same :bar (. vim :t :foo)))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (let! :t :foo)
        (assert.is_true (or (= true (. vim :t :foo))
                            (= "v:true" (. vim :t :foo))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo)))))
  (describe* :env
    (it* "can set vim option value in any scope."
      (let! :env :foo :bar)
      (assert.is_same :bar (. vim :env :foo)))
    (describe* "without either id or value"
      (it* "sets vim option value to `true`."
        (let! :env :foo)
        (assert.is_true (or (= true (. vim :env :foo))
                            (= "v:true" (. vim :env :foo))))))
    (it* "can set to `nil`."
      (each [_ scope (ipairs scope-list)]
        (let! scope :foo nil)
        (assert.is_nil (. vim scope :foo))))))

(describe* "(wrapper of `let!` macro)"
  (describe* "`env!`"
    (before_each (fn []
                   (set vim.env.FOO nil)
                   (set vim.env.BAR nil)))
    (it* "sets environment variable in the editor session"
      (env! :FOO "foo")
      (env! :$BAR "bar")
      (assert.is_same "foo" vim.env.FOO)
      (assert.is_same "bar" vim.env.BAR)))
  (describe* "`b!`"
    (before_each (fn []
                   (set vim.b.foo nil)
                   (set vim.b.bar nil)))
    (it* "sets buffer-local variable in the current buffer"
      (b! :foo :foo1)
      (assert.is_nil vim.b.bar)
      (assert.is_same :foo1 vim.b.foo))
    (it* "sets buffer-local variable with specific buffer id"
      (let [buf (vim.api.nvim_get_current_buf)]
        (vim.cmd.new)
        (b! buf :bar :bar1)
        (assert.is_nil (. vim.b buf :foo))
        (assert.is_same :bar1 (. vim.b buf :bar)))))
  (describe* "`w!`"
    (before_each (fn []
                   (set vim.w.foo nil)
                   (set vim.w.bar nil)))
    (it* "sets window-local variable in the current window"
      (w! :foo :foo1)
      (assert.is_nil vim.w.bar)
      (assert.is_same :foo1 vim.w.foo))
    (it* "sets window-local variable with specific window id"
      (let [win (vim.api.nvim_get_current_win)]
        ;; Create a new split window, making it the current one
        (vim.cmd.new)
        ;; Set variable in the *original* window `win`
        (w! win :bar :bar1)
        ;; Assertions
        (assert.is_nil vim.w.bar
                       "Variable should not be set in the current window")
        (assert.is_same :bar1 (. vim.w win :bar)
                        "Variable should be set in the specified window"))))
  (describe* "`t!`"
    (before_each (fn []
                   (set vim.t.foo nil)
                   (set vim.t.bar nil)))
    (it* "sets tab-local variable in the current tab"
      (t! :foo :foo1)
      (assert.is_nil vim.t.bar)
      (assert.is_same :foo1 vim.t.foo))
    (it* "sets tab-local variable with specific tabpage id"
      (let [tab (vim.api.nvim_get_current_tabpage)]
        ;; Create a new tab, making it the current one
        (vim.cmd.tabnew)
        ;; Set variable in the *original* tabpage `tab`
        (t! tab :bar :bar1)
        ;; Assertions
        (assert.is_nil vim.t.bar
                       "Variable should not be set in the current tabpage")
        (assert.is_same :bar1 (. vim.t tab :bar)
                        "Variable should be set in the specified tabpage")))))

(describe* "(deprecated in favor of `let!` wrapper)"
  (describe* "`env!`"
    (before_each (fn []
                   (set vim.env.FOO nil)
                   (set vim.env.BAR nil)))
    (it* "sets environment variable in the editor session"
      (env* :FOO :foo)
      (env* :$BAR :bar)
      (assert.is_same :foo vim.env.FOO)
      (assert.is_same :bar vim.env.BAR)))
  (describe* "`b!`"
    (before_each (fn []
                   (set vim.b.foo nil)
                   (set vim.b.bar nil)))
    (it* "sets buffer-local variable in the current buffer"
      (b* :foo :foo1)
      (assert.is_nil vim.b.bar)
      (assert.is_same :foo1 vim.b.foo))
    (it* "sets buffer-local variable with specific buffer id"
      (let [buf (vim.api.nvim_get_current_buf)]
        (vim.cmd.new)
        (b* buf :bar :bar1)
        (assert.is_nil (. vim.b buf :foo))
        (assert.is_same :bar1 (. vim.b buf :bar))))))
