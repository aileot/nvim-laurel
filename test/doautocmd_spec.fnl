(import-macros {: describe* : it*} :test.helper.busted-macros)
(import-macros {: evaluate} :test.helper.util-macros)

(import-macros {: augroup! : au! : autocmd! : doautocmd!} :laurel.macros)

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

(describe* :doautocmd!
  (before_each (fn []
                 (clear-any-autocmds!)))
  (describe* "with 1 arg"
    (it* "just with an `events` arg"
      (let [s (spy.new (fn []))]
        (au! nil [:InsertEnter] * #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! [:InsertEnter])
        (-> (assert.spy s)
            (. :was_called)
            (evaluate))))
    (it* "should execute autocommand for multiple events"
      (let [s (spy.new (fn []))]
        (au! nil [:BufRead :BufNewFile] * #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! [:BufRead])
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 1))
        (doautocmd! [:BufNewFile])
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 2)))))
  (describe* "with 2 args"
    (it* "should execute autocommand for a single event"
      (let [s (spy.new (fn []))]
        (au! nil [:BufRead] * #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! [:BufRead] *)
        (-> (assert.spy s)
            (. :was_called)
            (evaluate))))
    (it* "should execute autocommand for a specific buffer"
      (let [s (spy.new (fn []))
            buf1 (vim.api.nvim_create_buf false true)
            buf2 (vim.api.nvim_create_buf false true)]
        (au! nil [:BufRead] [:buffer buf1] #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! [:BufRead] {:buffer buf1})
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 1))
        (doautocmd! [:BufRead] {:buffer buf2})
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 1))))
    (it* "should execute autocommand for a specific pattern"
      (let [s (spy.new (fn []))
            test-file-txt "test.txt"
            test-file-md "test.md"]
        (au! nil [:BufRead] [test-file-txt] #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! [:BufRead] [test-file-txt])
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 1))
        (doautocmd! [:BufRead] [test-file-md])
        (-> (assert.spy s)
            (. :was_called)
            (evaluate 1)))))
  (describe* "with 3 args"
    (describe* "should execute callback to be matched against existing autocmd event"
      (it* "with augroup, pattern in a sequence, and an api-opts, with neither pattern nor buffer handle"
        (let [s (spy.new (fn []))
              augroup (augroup! :foobar)]
          (au! augroup [:OptionSet] [:tabstop] #(s))
          (-> (assert.spy s)
              (. :was_not_called)
              (evaluate))
          (doautocmd! augroup [:OptionSet] {:pattern "tabstop"})
          (-> (assert.spy s)
              (. :was_called)
              (evaluate))))
      (it* "with multi events in multiple times"
        (let [s (spy.new (fn []))
              augroup (augroup! :foobar)
              multi-events (fn [] [:InsertEnter :InsertLeave])]
          (au! augroup [(multi-events)] #(s))
          (doautocmd! augroup [:InsertLeave :InsertEnter] {})
          (doautocmd! augroup [(multi-events)] {})
          (-> (assert.spy s)
              (. :was_called)
              (evaluate 4)))))
    (it* "with full set of parameters against buffer in a symbol"
      (let [s (spy.new (fn []))
            augroup (augroup! :foobar)]
        (au! augroup [:InsertEnter] * #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (let [buffer (vim.api.nvim_get_current_buf)]
          (doautocmd! augroup [:InsertEnter] {: buffer}))
        (-> (assert.spy s)
            (. :was_called)
            (evaluate)))))
  (describe* "with 4 args"
    (it* "with full set of parameters against pattern in a sequence"
      (let [s (spy.new (fn []))
            augroup (augroup! :foobar)]
        (au! augroup [:OptionSet] [:tabstop] #(s))
        (-> (assert.spy s)
            (. :was_not_called)
            (evaluate))
        (doautocmd! augroup [:OptionSet] [:tabstop] {})
        (-> (assert.spy s)
            (. :was_called)
            (evaluate))))))
