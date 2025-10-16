(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: augroup! : au! : autocmd!} :laurel.macros)

(local default-augroup :default-test-augroup)
(local default-event :BufRead)
(local default-callback #:default-callback)

(local get-autocmds vim.api.nvim_get_autocmds)
(local del-augroup-by-id vim.api.nvim_del_augroup_by_id)

(fn clear-any-autocmds! []
  ;; Clear all the badly defined autocmds apart from any group.
  (vim.api.nvim_clear_autocmds {})
  (let [builtin-autocmds (vim.api.nvim_get_autocmds {})]
    (each [_ {: group} (ipairs builtin-autocmds)]
      ;; NOTE: autocmd id could be nil.
      (vim.api.nvim_clear_autocmds {: group}))))

(λ get-first-autocmd [?opts]
  (. (get-autocmds ?opts) 1))

(describe* :augroup!
  (before_each (fn []
                 (clear-any-autocmds!)))
  (describe* "should not return in table"
    (it* "without any autocmd definitions inside"
      (assert.not_equals :table (type (augroup! default-augroup))))
    (it* "with an autocmd definition inside"
      (assert.not_equals :table
                         (type (augroup! default-augroup
                                 (au! :InsertEnter * #:foobar)))))
    (it* "with some autocmd definitions inside"
      (assert.not_equals :table
                         (type (augroup! default-augroup
                                 (au! :InsertEnter * #:foo)
                                 (au! :InsertLeave * #:bar))))))
  (it* "returns augroup id without autocmds insides"
    (let [id (augroup! default-augroup)]
      (assert.has_no_errors #(del-augroup-by-id id))))
  (it* "can create augroup with `au!` macro and sequence without `au!` macro mixed"
    (assert.has_no_errors #(augroup! default-augroup
                             [default-event default-callback]
                             (au! :FileType [:foo :bar] #:foobar)
                             [default-event default-callback]
                             (au! :FileType [:foo :bar] #:foobar)
                             [default-event default-callback]
                             (au! :FileType [:foo :bar] #:foobar))))
  (describe* "including bare-sequences with the symbol `*` at `pattern` position"
    (describe* "without `extra-opts`"
      (it* "can create autocmd with pattern `*`."
        (augroup! default-augroup
          [default-event * default-callback])
        (assert.is_same "*" (-> (get-first-autocmd {:group default-augroup})
                                (. :pattern))))
      (describe* "but with `api-opts`"
        (it* "can create autocmd with pattern `*`."
          (augroup! default-augroup
            [default-event * default-callback {:desc :foo}])
          (assert.is_same "*" (-> (get-first-autocmd {:group default-augroup})
                                  (. :pattern))))))
    (describe* "preceding `extra-opts`"
      (it* "can create autocmd with pattern `*`."
        (augroup! default-augroup
          [default-event * [:desc :foo] default-callback])
        (assert.is_same "*" (-> (get-first-autocmd {:group default-augroup})
                                (. :pattern)))))
    (describe* "preceding both `extra-opts` and `api-opts`"
      (it* "can create autocmd with pattern `*`."
        (augroup! default-augroup
          [default-event * [:nested] default-callback {:desc :foo}])
        (let [au (get-first-autocmd {:group default-augroup})]
          (assert.is_same "*" au.pattern))))))
