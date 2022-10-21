(import-macros {: map! : noremap! : nnoremap! : unmap! : cmap! : map-all!}
               :nvim-laurel.macros)

(fn refresh-buffer []
  (vim.cmd.new)
  (vim.cmd.only))

(lambda get-mapargs [mode lhs]
  (let [mappings (vim.api.nvim_get_keymap mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(lambda get-rhs [mode lhs]
  (?. (get-mapargs mode lhs) :rhs))

(lambda get-callback [mode lhs]
  (?. (get-mapargs mode lhs) :callback))

(lambda get-desc [mode lhs]
  (?. (get-mapargs mode lhs) :desc))

(lambda buf-get-mapargs [bufnr mode lhs]
  (let [mappings (vim.api.nvim_buf_get_keymap bufnr mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(lambda buf-get-rhs [bufnr mode lhs]
  (?. (buf-get-mapargs bufnr mode lhs) :rhs))

(lambda buf-get-callback [bufnr mode lhs]
  (?. (buf-get-mapargs bufnr mode lhs) :callback))

(insulate :macros.keymap
          (fn []
            (before_each (fn []
                           (let [all-modes ["" "!" :l :t]]
                             (each [_ mode (ipairs all-modes)]
                               (pcall vim.api.nvim_del_keymap mode :lhs)
                               (assert.is_nil (get-rhs mode :lhs))))))
            (describe :noremap!
                      (fn []
                        (it "maps lhs to rhs with `noremap` set to `true` represented by `1`"
                            #(let [mode :n]
                               (noremap! mode :lhs :rhs)
                               (let [{: noremap} (get-mapargs mode :lhs)]
                                 (assert.is.same 1 noremap))))
                        (it "maps multiple mode mappings with sequence at once"
                            #(let [modes [:n :t :o]]
                               (noremap! modes :lhs :rhs)
                               (each [_ mode (ipairs modes)]
                                 (assert.is.same :rhs (get-rhs mode :lhs)))))))
            (describe :map!
                      (fn []
                        ;; (it "maps lhs to rhs with `noremap` set to `false` represented by `1`"
                        ;;     #(let [mode :n]
                        ;;        (map! mode :lhs :rhs)
                        ;;        (let [{: noremap} (get-mapargs mode :lhs)]
                        ;;          (assert.is.same 0 noremap))))
                        (it "maps symbol prefixed by `ex-` to rhs"
                            #(let [mode :n
                                   ex-rhs :rhs]
                               (map! mode :lhs ex-rhs)
                               (assert.is.same ex-rhs (get-rhs mode :lhs))))
                        (it "maps symbol without prefix `ex-` to callback instead"
                            #(let [mode :n
                                   rhs #:rhs]
                               (map! mode :lhs rhs)
                               ;; Note: rhs is nil when callback is set in the dictionary.
                               (assert.is.same rhs (get-callback mode :lhs))))
                        (it "maps multiple mode mappings with a string at once"
                            #(let [modes [:n :c :t]]
                               (noremap! modes :lhs :rhs)
                               (each [_ mode (ipairs modes)]
                                 (assert.is.same :rhs (get-rhs mode :lhs)))))))
            (describe :nnoremap!
                      (fn []
                        (it "maps to current buffer with `<buffer>`"
                            (fn []
                              (nnoremap! [:<buffer>] :lhs :rhs)
                              (assert.is.same :rhs (buf-get-rhs 0 :n :lhs))))
                        (it "maps to specific buffer with `buffer`"
                            (fn []
                              (let [bufnr (vim.api.nvim_get_current_buf)]
                                (refresh-buffer)
                                (nnoremap! [:buffer bufnr] :lhs :rhs)
                                (assert.is_nil (buf-get-rhs 0 :n :lhs))
                                (assert.is.same :rhs
                                                (buf-get-rhs bufnr :n :lhs)))))
                        (it "infers description from rhs symbol"
                            #(let [it-is-description :rhs
                                   ex-prefix-is-dropped :ex-cmd]
                               (nnoremap! :lhs1 it-is-description)
                               (nnoremap! :lhs2 ex-prefix-is-dropped)
                               (assert.is.same "It is description"
                                               (get-desc :n :lhs1))
                               (assert.is.same "Prefix is dropped"
                                               (get-desc :n :lhs2))))
                        (it "doesn't infer description if desc key has already value"
                            (fn []
                              (nnoremap! [:desc
                                          "Prevent description inference"]
                                         :lhs :rhs)
                              (assert.is.same "Prevent description inference"
                                              (get-desc :n :lhs)))))))
          (describe :unmap!
                    (fn []
                      (it "`unmap`s key"
                          (fn []
                            (nnoremap! :lhs :rhs)
                            (assert.is.same :rhs (get-rhs :n :lhs))
                            (unmap! :n :lhs)
                            (assert.is_nil (get-rhs :n :lhs))))
                      (it "can unmap buffer local key"
                          (fn []
                            (let [bufnr (vim.api.nvim_get_current_buf)]
                              (nnoremap! [:<buffer>] :lhs :rhs)
                              (assert.is.same :rhs (buf-get-rhs 0 :n :lhs))
                              (unmap! 0 :n :lhs)
                              (assert.is_nil (buf-get-rhs 0 :n :lhs))
                              (nnoremap! [:buffer bufnr] :lhs :rhs)
                              (assert.is.same :rhs (buf-get-rhs bufnr :n :lhs))
                              (unmap! bufnr :n :lhs)
                              (assert.is_nil (buf-get-rhs bufnr :n :lhs))))))))
