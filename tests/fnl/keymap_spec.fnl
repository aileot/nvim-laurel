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

(insulate :macros.keymap
          (describe :map!
                    (fn []
                      (it "maps lhs to rhs with `noremap` set to false"
                          #(let [mode :n
                                 lhs :foo
                                 rhs :bar]
                             (assert.is.same "" (vim.fn.maparg mode lhs))
                             (map! mode lhs rhs)
                             (vim.schedule #(let [{: noremap} (vim.fn.maparg mode
                                                                             lhs)]
                                              (assert.is.same 0 noremap)))))))
          (describe :noremap!
                    (fn []
                      (it "maps lhs to rhs with `noremap` set to true"
                          #(let [mode :n
                                 lhs :foo
                                 rhs :bar]
                             (assert.is.same "" (vim.fn.maparg mode lhs))
                             (noremap! mode lhs rhs)
                             (vim.schedule #(let [{: noremap} (vim.fn.maparg mode
                                                                             lhs)]
                                              (assert.is.same 1 noremap)))))
                      (it "maps multiple mode mappings with sequence at once"
                          #(let [modes [:n :t :o]
                                 lhs :foo
                                 rhs :bar]
                             (each [_ mode (ipairs modes)]
                               (assert.is.same "" (vim.fn.maparg mode lhs)))
                             (noremap! modes lhs rhs)
                             (vim.schedule #(each [_ mode (ipairs modes)]
                                              (assert.is.same rhs
                                                              (vim.fn.maparg mode
                                                                             lhs))))))
                      (it "maps multiple mode mappings with a string at once"
                          #(let [modes [:n :c :t]
                                 lhs :foo
                                 rhs :bar]
                             (each [_ mode (ipairs modes)]
                               (assert.is.same "" (vim.fn.maparg mode lhs)))
                             (noremap! modes lhs rhs)
                             (vim.schedule #(each [_ mode (ipairs modes)]
                                              (assert.is.same rhs
                                                              (vim.fn.maparg mode
                                                                             lhs))))))))
          (describe :cmap!
                    (fn []
                      (it "maps key without `silent` by default"
                          (fn []
                            (let [lhs :<CR>
                                  rhs :foo]
                              (assert.is.same "" (vim.fn.maparg :c lhs))
                              (cmap! lhs rhs)
                              (vim.schedule #(let [{: silent?} (vim.fn.maparg :c
                                                                              lhs
                                                                              false
                                                                              true)]
                                               (assert.is.same 0 silent?))))))))
          (describe :map-all!
                    (fn []
                      (setup (fn []
                               (map-all! :foo :bar)))
                      (it "maps without silent key by default for i, l, c, t."
                          #(vim.schedule #(let [modes [:i :l :c :t]]
                                            (each [_ mode (ipairs modes)]
                                              (let [dict (vim.fn.maparg :foo
                                                                        mode
                                                                        false
                                                                        true)]
                                                (assert.is.not_nil dict)
                                                (assert.is.same 0 dict.silent))))))
                      (it "maps with silent set to true by default for n, x, s, v, o."
                          #(vim.schedule #(let [modes [:n :x :s :v :o]]
                                            (each [_ mode (ipairs modes)]
                                              (let [dict (vim.fn.maparg :foo
                                                                        mode
                                                                        false
                                                                        true)]
                                                (assert.is.not_nil dict)
                                                (assert.is.same 1 dict.silent)))))))))
