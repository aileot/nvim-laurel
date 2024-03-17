(import-macros {: setup*
                : teardown*
                : before-each
                : after-each
                : describe*
                : it*} :test._busted_macros)

(import-macros {: augroup! : au! : autocmd!} :nvim-laurel.macros)
(import-macros {: my-autocmd!
                : augroup+
                : bufnr-suffixed-augroup!
                : buf-autocmd!/with-buffer=0}
               :test._wrapper_macros)

(set _G.my-augroup-id (augroup! :MyAugroup))

(macro assert-spy [spy-instance method ...]
  `((. (assert.spy ,spy-instance) ,method) ,...))

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(local get-autocmds vim.api.nvim_get_autocmds)
(local del-autocmd vim.api.nvim_del_autocmd)
(local exec-autocmds vim.api.nvim_exec_autocmds)
(local del-augroup-by-id vim.api.nvim_del_augroup_by_id)
(local del-augroup-by-name vim.api.nvim_del_augroup_by_name)

(local default-augroup :default-test-augroup)
(local default-event :BufRead)
(local default-callback #:default-callback)
(local default-command :default-command)
(local default {:multi {:sym #:default.multi.sym}})

(local <default>-command :<default>-command)
(local <default>-str-callback #:<default>-str-callback)

(lambda get-first-autocmd [?opts]
  (. (get-autocmds ?opts) 1))

(var default-augroup-id nil)
(var another-augroup-name nil)

(var au-id1 nil)
(var au-id2 nil)
(var au-id3 nil)

;; Note: `(vim.cmd "normal! i")` does not trigger event `InsertEnter` in the
;; nvim nightly v0.10; use `vim.api.nvim_exec_autocmds` instead.
(describe* :autocmd
  (setup* (fn []
            (let [nvim-builtin-augroups [:nvim_cmdwin
                                         :nvim_terminal
                                         :nvim_swapfile]]
              (each [_ group (ipairs nvim-builtin-augroups)]
                (augroup! group)))
            (vim.cmd "function g:Test() abort\nendfunction")))
  (teardown* (fn []
               (vim.cmd "delfunction g:Test")))
  (before-each (fn []
                 (when another-augroup-name
                   (del-augroup-by-name another-augroup-name)
                   (set another-augroup-name nil))
                 (set default-augroup-id (augroup! default-augroup))
                 (let [aus (get-autocmds {})]
                   (assert.is_nil (next aus)))))
  (after-each (fn []
                (pcall del-autocmd au-id1)
                (pcall del-autocmd au-id2)
                (pcall del-autocmd au-id3)))
  (describe* :augroup!
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
                               (au! :FileType [:foo :bar] #:foobar)))))
  (describe* :au!/autocmd!
    (describe* "nested autocmds"
      (it* "callback arg value at `group` is `nil` when parent group is `nil`."
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
          (let [aus (get-autocmds {:event :InsertEnter})]
            (assert.is_same 1 (length aus)))
          (vim.api.nvim_exec_autocmds :InsertEnter {:buffer 0})
          (assert-spy s :was_called)
          (let [aus (get-autocmds {:event :InsertEnter})]
            (assert.is_same 1 (length aus)))
          (let [aus (get-autocmds {:event [:BufWritePre]})]
            (assert.is_same 1 (length aus)))))
      (it* "callback arg value at `group` is same as the parent group id."
        (let [s (spy.new)]
          (set au-id1
               (au! default-augroup [:InsertEnter]
                    [:buffer 0 :desc "spawned autocmd"]
                    (fn [a]
                      (assert.is_same default-augroup-id a.group)
                      (s)
                      (set au-id2
                           (autocmd! a.group [:BufWritePre] [:buffer 0]
                                     default-callback
                                     {:desc "spawned autocmd, nested"})))))
          (assert-spy s :was_not_called)
          (exec-autocmds :InsertEnter {:group default-augroup})
          (assert-spy s :was_called)
          (let [[au1 au2 &as aus] (get-autocmds {:group default-augroup})]
            (assert.is_same {:InsertEnter true :BufWritePre true}
                            {au1.event true au2.event true})
            (assert.is_same 2 (length aus)))))
      (it* "callback arg value at `group` is same as the parent group id even inside `augroup!` macro."
        (let [s (spy.new)]
          (set another-augroup-name :foobar)
          (augroup! another-augroup-name
            (au! [:VimEnter] (do
                               :dummy)))
          (augroup! default-augroup
            (au! [:BufReadPost] (do
                                  :dummy))
            (au! [:InsertEnter] [:desc "spawned autocmd"]
                 (fn [a]
                   (assert.is_same default-augroup-id a.group)
                   (s)
                   (let [[au1 au2 au3 au4 au5 &as aus] (get-autocmds {})]
                     (assert.is_same {:InsertEnter true
                                      :BufReadPost true
                                      :VimEnter true}
                                     {au1.event true
                                      au2.event true
                                      au3.event true}))
                   (autocmd! a.group [:BufWritePre] default-callback
                             {:desc "spawned autocmd, nested"})
                   (autocmd! a.group [:CmdlineEnter] default-callback
                             {:desc "spawned autocmd, nested"})
                   nil)))
          (let [[au1 au2 &as aus] (get-autocmds {:group default-augroup})]
            (assert.is_same {:InsertEnter true :BufReadPost true}
                            {au1.event true au2.event true})
            (assert.is_same 2 (length aus)))
          (assert-spy s :was_not_called)
          (exec-autocmds :InsertEnter {:group default-augroup})
          (assert-spy s :was_called)
          (let [[au1 au2 au3 au4 au5 &as aus] (get-autocmds {})]
            (assert.is_same {:InsertEnter true
                             :BufReadPost true
                             :VimEnter true
                             :BufWritePre true
                             :CmdlineEnter true}
                            {au1.event true
                             au2.event true
                             au3.event true
                             au4.event true
                             au5.event true})
            (assert.is_same 5 (length aus)))
          (let [[au1 au2 au3 au4 &as aus] (get-autocmds {:group default-augroup})]
            (assert.is_same {:InsertEnter true
                             :BufReadPost true
                             :BufWritePre true
                             :CmdlineEnter true}
                            {au1.event true
                             au2.event true
                             au3.event true
                             au4.event true})
            (assert.is_same 4 (length aus)))))
      (it* "callback arg value at `group` is same as the parent group id even inside `augroup!` macro with 'buffer' key assigned."
        (let [s (spy.new)]
          (augroup! default-augroup
            (au! [:InsertEnter] [:buffer 0 :desc "spawned autocmd"]
                 (fn [a]
                   (assert.is_same default-augroup-id a.group)
                   (s)
                   (autocmd! a.group [:BufWritePre] [:buffer 0]
                             default-callback {:desc "spawned autocmd, nested"})
                   nil)))
          (let [[au1 &as aus] (get-autocmds {:group default-augroup})]
            (assert.is_same {:InsertEnter true} {au1.event true})
            (assert.is_same 1 (length aus)))
          (assert-spy s :was_not_called)
          (exec-autocmds :InsertEnter {:group default-augroup})
          (assert-spy s :was_called)
          (let [[au1 au2 &as aus] (get-autocmds {:group default-augroup})]
            (assert.is_same {:InsertEnter true :BufWritePre true}
                            {au1.event true au2.event true})
            (assert.is_same 2 (length aus))))))
    (it* "should set callback via macro"
      (let [desc "macro callback"]
        (autocmd! default-augroup default-event [:pat] [:desc desc]
                  (macro-callback))
        (let [au (get-first-autocmd {:pattern :pat})]
          (assert.is_same desc au.desc))))
    (it* "should set callback function in symbol"
      (autocmd! default-augroup default-event [:pat] default-callback)
      (assert.is_same default-callback
                      (. (get-first-autocmd {:pattern :pat}) :callback)))
    (it* "should set callback function in multi-symbol"
      (let [desc :multi.sym]
        (autocmd! default-augroup default-event [:pat] default.multi.sym
                  {: desc})
        ;; FIXME: In vusted, callback is unexpectedly set to a string
        ;; "<vim function: default.multi.sym>"; it* must be the same as
        ;; `default.multi.sym`.
        (assert.is_same desc (. (get-first-autocmd {:pattern :pat}) :desc))))
    (it* "should set callback function in list"
      (let [desc :list]
        (autocmd! default-augroup default-event [:pat]
                  (default-callback :foo :bar) {: desc})
        (let [au (get-first-autocmd {:pattern :pat})]
          (assert.is_same desc au.desc))))
    (it* "should set vim.fn.Test in string \"Test\""
      (autocmd! default-augroup default-event [:pat] vim.fn.Test)
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_same "<vim function: Test>" au.callback)))
    (it* "set #(vim.fn.Test) to callback without modification"
      (autocmd! default-augroup default-event [:pat] #(vim.fn.Test))
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_not_same "<vim function: Test>" au.callback)))
    (it* "can add an autocmd to an existing augroup"
      (autocmd! default-augroup default-event [:pat1 :pat2] default-callback)
      (let [[au1] (get-autocmds {:group default-augroup})]
        (assert.is_same default-callback au1.callback)))
    (it* "can add autocmd with no patterns for macro"
      (assert.has_no.errors #(autocmd! default-augroup default-event
                                       default-callback)))
    (it* "sets vim.fn.Test to callback in string"
      (assert.has_no.errors #(autocmd! default-augroup default-event
                                       vim.fn.Test))
      (let [[autocmd] (get-autocmds {:group default-augroup})]
        (assert.is.same "<vim function: Test>" autocmd.callback)))
    (it* "creates buffer-local autocmd with `buffer` key"
      (let [buffer (vim.api.nvim_get_current_buf)
            au1 (au! default-augroup default-event [:buffer buffer]
                     default-callback)]
        (vim.cmd.new)
        (vim.cmd.only)
        (let [au2 (au! default-augroup default-event [:<buffer>]
                       default-callback)
              [autocmd1] (get-autocmds {: buffer})
              [autocmd2] ;
              (get-autocmds {:buffer (vim.api.nvim_get_current_buf)})]
          (assert.is.same au1 autocmd1.id)
          (assert.is.same au2 autocmd2.id))))
    (it* "can define autocmd without any augroup"
      (set au-id1 (au! nil default-event default-callback)))
    (it* "gives lowest priority to `pattern` as (< raw seq tbl)"
      (let [seq-pat :seq-pat
            tbl-pat :tbl-pat]
        (au! default-augroup default-event [:raw-seq-pat] default-callback)
        (au! default-augroup default-event [:pattern seq-pat] default-callback)
        (au! default-augroup default-event default-callback {:pattern tbl-pat})
        (let [au (get-first-autocmd {:pattern [:raw-seq-pat]})]
          (assert.is.same :raw-seq-pat au.pattern))
        (let [au (get-first-autocmd {:pattern seq-pat})]
          (assert.is.same seq-pat au.pattern))
        (let [au (get-first-autocmd {:pattern tbl-pat})]
          (assert.is.same tbl-pat au.pattern))))
    (describe* "detects 2 args:"
      (it* "sequence pattern and string callback"
        (autocmd! default-augroup default-event [:pat] :callback))
      (it* "sequence pattern and function callback"
        (autocmd! default-augroup default-event [:pat] #:callback))
      (it* "sequence pattern and symbol callback"
        (let [cb :callback]
          (autocmd! default-augroup default-event [:pat] cb)))
      (it* "extra-opts and string callback"
        (autocmd! default-augroup default-event [:pat] :callback))
      (it* "extra-opts and function callback"
        (autocmd! default-augroup default-event [:pat] #:callback))
      (it* "extra-opts and symbol callback"
        (let [cb :callback]
          (autocmd! default-augroup default-event [:pat] cb)))
      (it* "string callback and api-opts in table"
        (autocmd! default-augroup default-event :callback {:nested true}))
      (it* "string callback and api-opts in symbol"
        (let [opts {:nested true}]
          (autocmd! default-augroup default-event :callback opts)))
      (it* "function callback and api-opts in table"
        (autocmd! default-augroup default-event #:callback {:nested true}))
      (it* "function callback and api-opts in symbol"
        (let [opts {:nested true}]
          (autocmd! default-augroup default-event #:callback opts)))
      (it* "symbol callback and api-opts in table"
        (let [cb :callback]
          (autocmd! default-augroup default-event cb {:nested true})))
      (it* "symbol callback and api-opts in symbol"
        (let [cb :callback
              opts {:nested true}]
          (autocmd! default-augroup default-event cb opts))))
    (describe* :<Cmd>pattern
      (it* "symbol will be set to 'command'"
        (au! default-augroup default-event [:pat1] <default>-command)
        (let [au (get-first-autocmd {:pattern :pat1})]
          (assert.is_same <default>-command au.command)))
      (it* "list will be set to 'command'"
        (au! default-augroup default-event [:pat1] (<default>-str-callback))
        (let [au (get-first-autocmd {:pattern :pat1})]
          (assert.is_same (<default>-str-callback) au.command))))
    (describe* "with symbol &vim"
      (it* "should set symbol to `command`"
        (au! default-augroup default-event [:pat1] &vim default-command)
        (let [[autocmd1] (get-autocmds {:pattern :pat1})]
          (assert.is_same default-command autocmd1.command)))
      (it* "should set list to `command`"
        (autocmd! default-augroup default-event [:pat] &vim (macro-command))
        (let [au (get-first-autocmd {:pattern :pat})]
          (assert.is_same :macro-command au.command))))
    (describe* "(wrapper)"
      (describe* "with `&default-opts`,"
        (describe* "imported macro"
          (describe* :augroup+
            (it* "gets an existing augroup id"
              (let [id (augroup! default-augroup)]
                (assert.is_same id (augroup+ default-augroup))))
            (it* "can add autocmds to an existing augroup within `augroup+`"
              (augroup+ default-augroup
                (au! default-event [:pat1 :pat2] default-callback))
              (let [[autocmd] (get-autocmds {:group default-augroup})]
                (assert.is_same default-callback autocmd.callback))))
          (it* "can create autocmd in predefined augroup in global-scope"
            (set au-id1 (my-autocmd! [:FileType] [:foo] default-callback))
            (let [[au &as aus] (get-autocmds {:group _G.my-augroup-id})]
              (assert.is_same 1 (length aus))
              (assert.is_same :foo au.pattern))))
        (describe* "local macro"
          (describe* "carefully binding variables without gensym in order to get conflicted with existing variable"
            ;; Note: Another spec, carelessly bound to undefined variable,
            ;; throws error too earlier in nvim >= 0.10.
            (it* "can define buffer-local autocmd wrapper"
              (var foo false)
              (let [id (augroup! default-augroup)]
                (macro buf-au! [...]
                  `(autocmd! id &default-opts {:buffer a.buf} ,...))
                (assert.is_false foo)
                (autocmd! id [:FileType] [:foobar]
                          (fn [a]
                            (buf-au! [:InsertEnter] #(set foo true))))
                (assert.is_false foo)
                (let [buffer (vim.api.nvim_get_current_buf)]
                  (set vim.bo.filetype :foobar)
                  (assert.is_false foo)
                  (vim.api.nvim_exec_autocmds :InsertEnter {: buffer})
                  (assert.is_true foo)
                  (let [[au1 &as aus] (get-autocmds {:group id : buffer})]
                    (assert.is_same 1 (length aus))
                    (assert.is_same :InsertEnter au1.event)
                    (assert.is_same buffer au1.buffer)))))
            (it* "can spawn a buffer-local augroup"
              (let [local-group-prefix :local
                    bufnr (vim.api.nvim_get_current_buf)]
                (augroup! default-augroup
                  (au! [:FileType]
                       #(bufnr-suffixed-augroup! local-group-prefix
                                                 (au! [:InsertEnter]
                                                      [:<buffer>]
                                                      default-callback))))
                (let [[au &as aus] (get-autocmds {:group default-augroup})]
                  (assert.is_same 1 (length aus))
                  (assert.is_same :FileType au.event))
                (set vim.bo.filetype :foo)
                (set another-augroup-name (.. local-group-prefix bufnr))
                (let [[au1 &as aus] (get-autocmds {:group another-augroup-name})]
                  (assert.is_same 1 (length aus))
                  (assert.is_same :InsertEnter au1.event)))))
          (it* "can spawn buffer-local autocmd from a spawned buffer-local augroup"
            (let [local-group-prefix :local]
              (augroup! default-augroup
                (au! [:FileType]
                     #(bufnr-suffixed-augroup! local-group-prefix
                                               (au! [:InsertEnter]
                                                    [:buffer
                                                     0
                                                     :desc
                                                     "spawned autocmd"]
                                                    (fn [a]
                                                      (buf-autocmd!/with-buffer=0 a.group
                                                                                  [:BufWritePre]
                                                                                  default-callback
                                                                                  {:desc "spawned autocmd, nested"})
                                                      nil)))))
              (let [[au &as aus] (get-autocmds {:group default-augroup})]
                (assert.is_same 1 (length aus))
                (assert.is_same :FileType au.event))
              (set vim.bo.filetype :foo)
              (var ie nil)
              (let [buffer (vim.api.nvim_get_current_buf)]
                (set another-augroup-name (.. local-group-prefix buffer))
                (let [[au1 &as aus] (get-autocmds {:group another-augroup-name
                                                   : buffer})]
                  (assert.is_same 1 (length aus))
                  (assert.is_same :InsertEnter au1.event)
                  (set ie au1))
                (vim.api.nvim_exec_autocmds :InsertEnter {: buffer})
                (let [[au1 au2 &as aus] (get-autocmds {:group another-augroup-name
                                                       : buffer})]
                  (assert.is_same ie.group_name au1.group_name)
                  (assert.is_same ie.group au1.group)
                  (assert.is_not_same ie.event au1.event)
                  (assert.is_same {:InsertEnter true :BufWritePre true}
                                  {au1.event true au2.event true})
                  (assert.is_same 2 (length aus)))))))
        (describe* "wrapper function at runtime"
          (it* "usually causes errors because compiled into unexpected output."
            (autocmd! default-augroup [:FileType]
                      (fn [au]
                        (let [buf-local-augroup-name (: "buf-local-aug-%d"
                                                        :format au.buf)
                              buf-local-augroup-id (augroup! buf-local-augroup-name)]
                          (fn buf-au! [buffer ...]
                            (autocmd! buf-local-augroup-id ;
                                      &default-opts {: buffer} ...))

                          (assert.has.errors #(buf-au! [:InsertEnter]
                                                       default-callback)))
                        (let [buf-local-augroup-name (: "another-buf-local-aug-%d"
                                                        :format au.buf)
                              buf-local-augroup-id (augroup! buf-local-augroup-name)
                              buf-au! (fn [buffer ...]
                                        (autocmd! &default-opts {: buffer}
                                                  buf-local-augroup-id ...))]
                          (assert.has.errors #(buf-au! [:InsertEnter]
                                                       default-callback)))))))))))
