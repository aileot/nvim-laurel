(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: let!} :laurel.macros)

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
