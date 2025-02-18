(import-macros {: before-each : describe* : it*} :test.helper.busted-macros)
(import-macros {: let! : b! : env!} :laurel.macros)

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

(describe* :b!
  (before-each (fn []
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
