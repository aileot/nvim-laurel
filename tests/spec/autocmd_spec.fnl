(import-macros {: describe : it} :_busted_macros)
(import-macros {: augroup! : augroup+ : au! : autocmd!} :nvim-laurel.macros)

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(local default-augroup :default-test-augroup)
(local default-event :BufRead)
(local default-callback #:default-callback)
(local default-command :default-command)
(local default {:multi {:sym #:default.multi.sym}})

(lambda get-autocmds [?opts]
  (let [opts (collect [k v (pairs (or ?opts {})) ;
                       &into {:group default-augroup}]
               (values k v))]
    (vim.api.nvim_get_autocmds opts)))

(lambda get-first-autocmd [?opts]
  (. (get-autocmds ?opts) 1))

(describe :autocmd
  (setup (fn []
           (vim.cmd "function g:Test() abort\nendfunction")))
  (teardown (fn []
              (vim.cmd "delfunction g:Test")))
  (before_each (fn []
                 (augroup! default-augroup)
                 (let [aus (get-autocmds)]
                   (assert.is.same {} aus))))
  (describe :augroup!
    (it "returns augroup id without autocmds insides"
      (let [id (augroup! default-augroup)]
        (assert.has_no.errors #(vim.api.nvim_del_augroup_by_id id))))
    (it "can create augroup with sequence and `au!` macro mixed"
      (assert.has_no.errors #(augroup! default-augroup
                               [default-event `default-callback]
                               (au! :FileType [:foo :bar] #:foobar)))))
  (describe :au!/autocmd!
    (it "sets callback via macro with quote"
      (autocmd! default-augroup default-event [:pat] `(macro-callback))
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_not_nil au.callback)))
    (it "set command in macro with no args"
      (autocmd! default-augroup default-event [:pat] (macro-command))
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_same :macro-command au.command)))
    (it "set command in macro with some args"
      (autocmd! default-augroup default-event [:pat] (macro-command :foo :bar))
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_same :macro-command au.command)))
    (it "sets callback function with quoted symbol"
      (autocmd! default-augroup default-event [:pat] `default-callback)
      (assert.is_same default-callback
                      (. (get-first-autocmd {:pattern :pat}) :callback)))
    (it "sets callback function with quoted multi-symbol"
      (let [desc :multi.sym]
        (autocmd! default-augroup default-event [:pat] `default.multi.sym
                  {: desc})
        ;; FIXME: In vusted, callback is unexpectedly set to a string
        ;; "<vim function: default.multi.sym>"; it must be the same as
        ;; `default.multi.sym`.
        (assert.is_same desc (. (get-first-autocmd {:pattern :pat}) :desc))))
    (it "sets callback function with quoted list"
      (let [desc :list]
        (autocmd! default-augroup default-event [:pat]
                  `(default-callback :foo :bar) {: desc})
        (let [au (get-first-autocmd {:pattern :pat})]
          (assert.is_same desc au.desc))))
    (it "set `vim.fn.Test in string \"Test\""
      (autocmd! default-augroup default-event [:pat] `vim.fn.Test)
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_same "<vim function: Test>" au.callback)))
    (it "set #(vim.fn.Test) to callback without modification"
      (autocmd! default-augroup default-event [:pat] #(vim.fn.Test))
      (let [au (get-first-autocmd {:pattern :pat})]
        (assert.is_not_same "<vim function: Test>" au.callback)))
    (it "can add an autocmd to an existing augroup"
      (autocmd! default-augroup default-event [:pat1 :pat2] `default-callback)
      (let [[autocmd] (get-autocmds)]
        (assert.is.same default-callback autocmd.callback)))
    (it "can add autocmd with no patterns for macro"
      (assert.has_no.errors #(autocmd! default-augroup default-event
                                       `default-callback)))
    (it "can add autocmds to an existing augroup within `augroup+`"
      (augroup+ default-augroup
                (au! default-event [:pat1 :pat2] `default-callback))
      (let [[autocmd] (get-autocmds)]
        (assert.is.same default-callback autocmd.callback)))
    (it "can set Ex command in autocmds with `<command>` key"
      (augroup! default-augroup
        (au! default-event [:pat1] [:<command>] default-command)
        (au! default-event [:pat2] [:<command>] (.. :foo :bar)))
      (let [[autocmd1] (get-autocmds {:pattern :pat1})
            [autocmd2] (get-autocmds {:pattern :pat2})]
        (assert.is.same default-command autocmd1.command)
        (assert.is.same :foobar autocmd2.command)))
    (it "can set Ex command in autocmds with `ex` key"
      (augroup! default-augroup
        (au! default-event [:pat1] [:ex] default-command)
        (au! default-event [:pat2] [:ex] (.. :foo :bar)))
      (let [[autocmd1] (get-autocmds {:pattern :pat1})
            [autocmd2] (get-autocmds {:pattern :pat2})]
        (assert.is.same default-command autocmd1.command)
        (assert.is.same :foobar autocmd2.command)))
    (it "can set callback function in autocmds with `<callback>` key"
      (augroup! default-augroup
        (au! default-event [:pat1] [:<callback>] `default-callback)
        (au! default-event [:pat2] [:<callback>] (.. :foo :bar)))
      (let [[autocmd1] (get-autocmds {:pattern :pat1})
            [autocmd2] (get-autocmds {:pattern :pat2})]
        (assert.is.same default-callback autocmd1.callback)
        (assert.is.same "<vim function: foobar>" autocmd2.callback)))
    (it "can set callback function in autocmds with `cb` key"
      (augroup! default-augroup
        (au! default-event [:pat1] [:cb] `default-callback)
        (au! default-event [:pat2] [:cb] (.. :foo :bar)))
      (let [[autocmd1] (get-autocmds {:pattern :pat1})
            [autocmd2] (get-autocmds {:pattern :pat2})]
        (assert.is.same default-callback autocmd1.callback)
        (assert.is.same "<vim function: foobar>" autocmd2.callback)))
    (it "sets vim.fn.Test to callback in string"
      (assert.has_no.errors #(autocmd! default-augroup default-event
                                       vim.fn.Test))
      (let [[autocmd] (get-autocmds)]
        (assert.is.same "<vim function: Test>" autocmd.callback)))
    (it "creates buffer-local autocmd with `buffer` key"
      (let [bufnr (vim.api.nvim_get_current_buf)
            au1 (au! default-augroup default-event [:buffer bufnr]
                     `default-callback)]
        (vim.cmd.new)
        (vim.cmd.only)
        (let [au2 (au! default-augroup default-event [:<buffer>]
                       `default-callback)
              [autocmd1] (get-autocmds {:buffer bufnr})
              [autocmd2] ;
              (get-autocmds {:buffer (vim.api.nvim_get_current_buf)})]
          (assert.is.same au1 autocmd1.id)
          (assert.is.same au2 autocmd2.id))))
    (it "can define autocmd without any augroup"
      (assert.has_no.errors #(let [id (au! nil default-event `default-callback)]
                               (vim.api.nvim_del_autocmd id))))
    (it "gives lowest priority to `pattern` as (< raw seq tbl)"
      (let [seq-pat :seq-pat
            tbl-pat :tbl-pat]
        (au! default-augroup default-event [:raw-seq-pat] `default-callback)
        (au! default-augroup default-event [:pattern seq-pat] `default-callback)
        (au! default-augroup default-event `default-callback {:pattern tbl-pat})
        (let [au (get-first-autocmd {:pattern [:raw-seq-pat]})]
          (assert.is.same :raw-seq-pat au.pattern))
        (let [au (get-first-autocmd {:pattern seq-pat})]
          (assert.is.same seq-pat au.pattern))
        (let [au (get-first-autocmd {:pattern tbl-pat})]
          (assert.is.same tbl-pat au.pattern))))
    (describe "detects 2 args:"
      (it "sequence pattern and string callback"
        (autocmd! default-augroup default-event [:pat] :callback))
      (it "sequence pattern and function callback"
        (autocmd! default-augroup default-event [:pat] #:callback))
      (it "sequence pattern and symbol callback"
        (let [cb :callback]
          (autocmd! default-augroup default-event [:pat] cb)))
      (it "extra-opts and string callback"
        (autocmd! default-augroup default-event [:pat] :callback))
      (it "extra-opts and function callback"
        (autocmd! default-augroup default-event [:pat] #:callback))
      (it "extra-opts and symbol callback"
        (let [cb :callback]
          (autocmd! default-augroup default-event [:pat] cb)))
      (it "string callback and api-opts in table"
        (autocmd! default-augroup default-event :callback {:nested true}))
      (it "string callback and api-opts in symbol"
        (let [opts {:nested true}]
          (autocmd! default-augroup default-event :callback opts)))
      (it "function callback and api-opts in table"
        (autocmd! default-augroup default-event #:callback {:nested true}))
      (it "function callback and api-opts in symbol"
        (let [opts {:nested true}]
          (autocmd! default-augroup default-event #:callback opts)))
      (it "symbol callback and api-opts in table"
        (let [cb :callback]
          (autocmd! default-augroup default-event cb {:nested true})))
      (it "symbol callback and api-opts in symbol"
        (let [cb :callback
              opts {:nested true}]
          (autocmd! default-augroup default-event cb opts)))))
  (describe "(deprecated)"
    (describe :augroup+
      (it "gets an existing augroup id"
        (let [id (augroup! default-augroup)]
          (assert.is.same id (augroup+ default-augroup)))))))
