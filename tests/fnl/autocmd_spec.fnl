(import-macros {: augroup! : augroup+ : au! : autocmd!} :nvim-laurel.macros)

(local default-augroup :default-test-augroup)
(local default-event [:BufRead :BufNewFile])
(local default-pattern [:sample1 :sample2])
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
                                        default-pattern default-callback)
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.callback
                                                default-callback))))
                        (it "can add autocmds to an existing augroup within `augroup+`"
                            (fn []
                              (augroup+ default-augroup
                                        (au! default-event default-pattern
                                             default-callback))
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.callback
                                                default-callback))))
                        (it "can set Ex command in autocmds with prefix `ex-`"
                            (fn []
                              (augroup! default-augroup
                                        (au! default-event default-pattern
                                             ex-default-command))
                              (let [[autocmd] (get-autocmds)]
                                (assert.is.same autocmd.command
                                                ex-default-command))))))))
