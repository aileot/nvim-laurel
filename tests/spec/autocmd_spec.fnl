(import-macros {: describe : it} :_busted_macros)
(import-macros {: augroup! : au! : autocmd!} :nvim-laurel.macros)
(import-macros {: my-autocmd!
                : augroup+
                : buf-augroup!
                : buf-autocmd!/with-buffer=0} :_wrapper_macros)

(set _G.my-augroup-id (augroup! :MyAugroup))

(macro assert-spy [spy-instance method ...]
  `((. (assert.spy ,spy-instance) ,method) ,...))

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(local del-autocmd vim.api.nvim_del_autocmd)
(local exec-autocmds vim.api.nvim_exec_autocmds)

(local default-augroup :default-test-augroup)
(local default-event :BufRead)
(local default-callback #:default-callback)
(local default-command :default-command)
(local default {:multi {:sym #:default.multi.sym}})

(local <default>-command :<default>-command)
(local <default>-str-callback #:<default>-str-callback)

(lambda get-autocmds [?opts]
  (let [opts (collect [k v (pairs (or ?opts {})) ;
                       &into {:group default-augroup}]
               (values k v))]
    ;; Note: `vim.api.nvim_get_autocmds` would includes the autocmds defined
    ;; in running nvim when the tests are run in a local nvim instance.
    (when (= false opts.group)
      (set opts.group nil))
    ;; Note: The order of the result list is not always in the order of
    ;; definitions.
    (vim.api.nvim_get_autocmds opts)))

(lambda get-first-autocmd [?opts]
  (. (get-autocmds ?opts) 1))

(var au-id1 nil)
(var au-id2 nil)
(var au-id3 nil)

;; Note: `(vim.cmd "normal! i")` does not trigger event `InsertEnter` in the
;; nvim nightly v0.10; use `vim.api.nvim_exec_autocmds` instead.
(describe :autocmd
  (setup (fn []
           (let [nvim-builtin-augroups [:nvim_cmdwin :nvim_terminal]]
             (each [_ group (ipairs nvim-builtin-augroups)]
               (augroup! group)))
           (vim.cmd "function g:Test() abort\nendfunction")))
  (teardown (fn []
              (vim.cmd "delfunction g:Test")))
  (before_each (fn []
                 (augroup! default-augroup)
                 (let [aus (get-autocmds {})]
                   (assert.is_nil (next aus)))))
  (after_each (fn []
                (pcall del-autocmd au-id1)
                (pcall del-autocmd au-id2)
                (pcall del-autocmd au-id3)))
  (describe :augroup!
    (it "returns augroup id without autocmds insides"
      (let [id (augroup! default-augroup)]
        (assert.has_no.errors #(vim.api.nvim_del_augroup_by_id id))))
    (it "can create augroup with `au!` macro and sequence without `au!` macro mixed"
      (assert.has_no.errors #(augroup! default-augroup
                               [default-event default-callback]
                               (au! :FileType [:foo :bar] #:foobar)
                               [default-event default-callback]
                               (au! :FileType [:foo :bar] #:foobar)
                               [default-event default-callback]
                               (au! :FileType [:foo :bar] #:foobar)))))
  (describe :au!/autocmd!
    (describe "nested autocmds"
      (it "callback arg value at `group` is `nil` when parent group is `nil`."
        (let [desc "nil group to InsertEnter"
              s (spy.new)]
          (set au-id1
               (au! nil [:InsertEnter] [:buffer 0 :desc desc]
                    (fn [a]
                      (assert.is_nil a.group)
                      (s)
                      (set au-id2
                           (autocmd! a.group [:BufWritePre] [:buffer 0]
                                     default-callback)))))
          (assert-spy s :was_not_called)
          (let [aus (vim.api.nvim_get_autocmds {:event :InsertEnter})]
            (assert.is_same 1 (length aus)))
          (vim.api.nvim_exec_autocmds :InsertEnter {:buffer 0})
          (assert-spy s :was_called)
          (let [aus (vim.api.nvim_get_autocmds {:event :InsertEnter})]
            (assert.is_same 1 (length aus)))
          (let [aus (vim.api.nvim_get_autocmds {:event [:BufWritePre]})]
            (assert.is_same 1 (length aus)))))
      (it "callback arg value at `group` is same as the parent group id."
        (let [local-group "local group"
              group-id (augroup! local-group)
              s (spy.new)]
          (set au-id1
              (au! local-group [:InsertEnter]
                    [:buffer 0 :desc "spawned autocmd"]
                    (fn [a]
                      (assert.is_same group-id a.group)
                      (s)
                      (set au-id2
                          (autocmd! a.group [:BufWritePre] [:buffer 0]
                                    default-callback
                                    {:desc "spawned autocmd, nested"})))))
          (assert-spy s :was_not_called)
          (exec-autocmds :InsertEnter {:group local-group})
          (assert-spy s :was_called)
          (let [[au1 au2 &as aus] (get-autocmds {:group local-group})]
            (assert.is_same {:InsertEnter true :BufWritePre true}
                            {au1.event true au2.event true})
            (assert.is_same 2 (length aus)))))
      (it "callback arg value at `group` is same as the parent group id even inside `augroup!` macro."
        (let [local-group "local group"
              s (spy.new)]
          (augroup! local-group
            (au! [:InsertEnter] [:buffer 0 :desc "spawned autocmd"]
                 (fn [a]
                   (s)
                   (autocmd! a.group [:BufWritePre] [:buffer 0] default-callback
                             {:desc "spawned autocmd, nested"}))))
          (assert-spy s :was_not_called)
          (exec-autocmds :InsertEnter {:group local-group})
          (assert-spy s :was_called)
          (let [[au1 au2 &as aus] (vim.api.nvim_get_autocmds {:group local-group})]
            (assert.is_same {:InsertEnter true :BufWritePre true}
                            {au1.event true au2.event true})
            (assert.is_same 2 (length aus))))))
    (it "should set callback via macro"
      (let [desc "macro callback"]
        (set au-id1 (autocmd! default-augroup default-event [:pat] [:desc desc]
                              (macro-callback)))
        (let [au (get-first-autocmd {:pattern :pat})]
          (assert.is_same desc au.desc))))
    (it "should set callback function in symbol"
      (set au-id1 (autocmd! default-augroup default-event [:pat]
                            default-callback))
      (assert.is_same default-callback
                      (. (get-first-autocmd {:pattern :pat}) :callback)))))

                        (assert.has.errors #(buf-au! [:InsertEnter]
                                                     default-callback)))
                      (let [buf-local-augroup-name (: "another-buf-local-aug-%d"
                                                      :format au.buf)
                            buf-local-augroup-id (augroup! buf-local-augroup-name)
                            buf-au! (fn [buffer ...]
                                      (autocmd! &default-opts {: buffer}
                                                buf-local-augroup-id ...))]
                        (assert.has.errors #(buf-au! [:InsertEnter]
                                                     default-callback))))))))))
