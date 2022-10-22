(import-macros {: augroup! : augroup+ : au! : autocmd!} :nvim-laurel.macros)

(local default-augroup :default-test-augroup)
(local default-event [:BufRead :BufNewFile])
(local default-callback #:default-callback)
(local ex-default-command :default-command)

(lambda get-autocmds [?opts]
  (let [opts (or ?opts {:group default-augroup})]
    (vim.api.nvim_get_autocmds opts)))

(describe :autocmd ;
          (fn []
            (before_each (fn []
                           (augroup! default-augroup)
                           (let [aus (get-autocmds)]
                             (assert.is.same {} aus))))
            (describe :augroup!
                      (fn []
                        (it "returns augroup id without autocmds insides"
                            (let [id (augroup! :sample)]
                              (assert.has_no.errors #(vim.api.nvim_del_augroup_by_id id))))))
            (describe :au!/autocmd!
                      (fn []
                        (it "can add an autocmd to an existing augroup"
                            (fn []
                              (autocmd! default-augroup default-event
                                        [:pat1 :pat2] default-callback)
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.callback
                                                default-callback))))
                        (it "can add autocmd with no patterns for macro"
                            (fn []
                              (assert.has_no.errors #(autocmd! default-augroup
                                                               default-event
                                                               default-callback))))
                        (it "can add autocmds to an existing augroup within `augroup+`"
                            (fn []
                              (augroup+ default-augroup
                                        (au! default-event [:pat1 :pat2]
                                             default-callback))
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.callback
                                                default-callback))))
                        (it "can set Ex command in autocmds with prefix `ex-`"
                            (fn []
                              (augroup! default-augroup
                                        (au! default-event [:pat1 :pat2]
                                             ex-default-command))
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.command
                                                ex-default-command))))
                        (it "infers description from symbol name"
                            (fn []
                              (let [it-is-description #:sample-callback
                                    ex-prefix-is-dropped :sample-command
                                    event1 :BufRead
                                    event2 :BufNewFile]
                                (augroup! default-augroup
                                          (au! event1 :pat1 it-is-description)
                                          (au! event2 :pat2 ex-prefix-is-dropped))
                                (let [[au1] (get-autocmds {:event event1})
                                      [au2] (get-autocmds {:event event2})]
                                  (assert.is.same "It is description" au1.desc)
                                  (assert.is.same "Prefix is dropped" au2.desc)))))
                        (it "doesn't infer description if desc key has already value"
                            (fn []
                              (au! default-augroup default-event [:pat1 :pat2]
                                   [:desc "Prevent description inference"]
                                   default-callback)
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same "Prevent description inference"
                                                autocmd.desc))))))))
