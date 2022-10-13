(import-macros {: map! : noremap! : unmap! : cmap! : map-all!}
               :nvim-laurel.macros)

(lambda get-mapargs [mode lhs]
  (let [mappings (vim.api.nvim_get_keymap mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(lambda get-rhs [mode lhs]
  (?. (get-mapargs mode lhs) :rhs))

(lambda get-callback [mode lhs]
  (?. (get-mapargs mode lhs) :callback))

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
                               (pcall vim.api.nvim_del_keymap mode :foo)
                               (assert.is_nil (get-rhs mode :foo))))))
            (describe :noremap!
                      (fn []
                        (it "maps lhs to rhs with `noremap` set to `true` represented by `1`"
                            #(let [mode :n
                                   lhs :foo
                                   rhs :bar]
                               (noremap! mode lhs rhs)
                               (let [{: noremap} (get-mapargs mode lhs)]
                                 (assert.is.same 1 noremap))))
                        (it "maps multiple mode mappings with sequence at once"
                            #(let [modes [:n :t :o]
                                   lhs :foo
                                   rhs :bar]
                               (noremap! modes lhs :bar)
                               (each [_ mode (ipairs modes)]
                                 (assert.is.same rhs (get-rhs mode lhs)))))))
            (describe :map!
                      (fn []
                        (it "maps lhs to rhs with `noremap` set to `false` represented by `1`"
                            #(let [mode :n
                                   lhs :foo
                                   rhs :bar]
                               (map! mode lhs rhs)
                               (vim.schedule #(let [{: noremap} (get-rhs mode
                                                                         lhs)]
                                                (assert.is.same 0 noremap)))))
                        (it "maps symbol prefixed by `ex-` to rhs"
                            #(let [mode :n
                                   lhs :foo
                                   ex-rhs :bar]
                               (map! mode lhs ex-rhs)
                               (assert.is.same ex-rhs (get-rhs mode lhs))))
                        (it "maps symbol without prefix `ex-` to callback instead"
                            #(let [mode :n
                                   lhs :foo
                                   rhs #:bar]
                               (map! mode lhs rhs)
                               ;; Note: rhs is nil when callback is set in the dictionary.
                               (assert.is.same rhs (get-callback mode lhs))))
                        (it "maps multiple mode mappings with a string at once"
                            #(let [modes [:n :c :t]
                                   lhs :foo
                                   rhs :bar]
                               (noremap! modes lhs :bar)
                               (each [_ mode (ipairs modes)]
                                 (assert.is.same rhs (get-rhs mode lhs)))))))))
