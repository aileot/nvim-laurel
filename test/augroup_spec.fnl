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
  (describe* "should return the created augroup id"
    (it* "without any autocmd definitions inside"
      (let [id (augroup! default-augroup)]
        (assert.equals id
                       (vim.api.nvim_create_augroup default-augroup
                                                    {:clear false}))))
    (it* "with an autocmd definition inside"
      (let [id (augroup! default-augroup
                 (au! :InsertEnter * #:foobar))]
        (assert.equals id
                       (vim.api.nvim_create_augroup default-augroup
                                                    {:clear false}))))
    (it* "with some autocmd definitions inside"
      (let [id (augroup! default-augroup
                 (au! :InsertEnter * #:foo)
                 (au! :InsertLeave * #:bar))]
        (assert.equals id
                       (vim.api.nvim_create_augroup default-augroup
                                                    {:clear false}))))
    (describe* "with always-return-id"
      (describe* "set to false with an autocmd definition inside"
        (it* "as an api-opt returns augroup id"
          (let [id (augroup! default-augroup {:always-return-id false}
                     (au! :InsertEnter * #:foobar))]
            (assert.not_equals id
                               (vim.api.nvim_create_augroup default-augroup
                                                            {:clear false}))))
        (it* "as a default api-opt returns augroup id"
          (let [id (augroup! default-augroup &default-opts
                      {:always-return-id false}
                      (au! :InsertEnter * #:foobar))]
            (assert.not_equals id
                                (vim.api.nvim_create_augroup default-augroup
                                                            {:clear false}))))
        (it* "as a api-opt overriding preceding &default-opts returns augroup id"
          (let [id (augroup! default-augroup &default-opts
                      {:always-return-id true}
                      {:always-return-id false}
                      (au! :InsertEnter * #:foobar))]
              (assert.not_equals id
                                 (vim.api.nvim_create_augroup default-augroup
                                                              {:clear false}))))))
    (it* "which is assigned to all the autocmd(s) inside"
      (let [desc (tostring (math.random))
            id (augroup! :for-single-autocmd
                 (au! :InsertEnter * [:desc desc] #:foobar))]
        (assert.equals desc (-> (get-first-autocmd {:group id
                                                    :event :InsertEnter})
                                (. :desc))
                       "augroup id should assigned to the single autocmd inside")
        (del-augroup-by-id id))
      (let [desc1 (tostring (math.random))
            desc2 (tostring (math.random))
            desc3 (tostring (math.random))
            id (augroup! :for-multi-autocmds
                 (au! :InsertEnter * [:desc desc1] #:foobar)
                 (au! :InsertLeave * [:desc desc2] #:foobar)
                 [ :CmdlineEnter * [:desc desc3] #:foobar])]
        (assert.equals desc1 (-> (get-first-autocmd {:group id
                                                     :event :InsertEnter})
                                 (. :desc))
                       "augroup id should be assigned to the second autocmd inside")
        (assert.equals desc2 (-> (get-first-autocmd {:group id
                                                     :event :InsertLeave})
                                 (. :desc))
                       "augroup id should be assigned to the second autocmd inside")
        (assert.equals desc3 (-> (get-first-autocmd {:group id
                                                     :event :CmdlineEnter})
                                 (. :desc))
                       "augroup id should be assigned to the autocmd defined in sequence without `au!` macro inside")
        (del-augroup-by-id id))))
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
