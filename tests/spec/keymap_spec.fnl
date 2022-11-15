(import-macros {: map!
                : noremap!
                : nnoremap!
                : unmap!
                : smap!
                : map-motion!
                : <C-u>
                : <Cmd>} :nvim-laurel.macros)

(local default-rhs :default-rhs)
(local default-callback #:default-callback)
(local new-callback #(fn []
                       $))

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
        (it "maps lhs to rhs with `noremap` set to `false` represented by `1`"
          #(let [mode :n
                 modes [:n :o :t]]
             (map! mode :lhs :rhs)
             (map! modes :lhs :rhs)
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 0 noremap))
             (each [_ m (ipairs modes)]
               (let [{: noremap} (get-mapargs m :lhs)]
                 (assert.is.same 0 noremap)))))
        (it "is also available to non-recursive mappings"
          #(let [mode :n]
             (map! :o [:noremap] :lhs :rhs)
             (map! mode [:noremap] :lhs :rhs)
             (let [{: noremap} (get-mapargs :o :lhs)]
               (assert.is.same 1 noremap))
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 1 noremap))))
        (it "gives priority to `api-opts`"
          #(let [mode :n
                 api-opts {:noremap true}]
             (map! :o :lhs :rhs api-opts)
             (map! mode :lhs :rhs api-opts)
             (let [{: noremap} (get-mapargs :o :lhs)]
               (assert.is.same 1 noremap))
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 1 noremap))))
        (it "maps symbol prefixed by `ex-` to rhs"
          #(let [mode :n
                 rhs :rhs]
             (map! mode [:<command>] :lhs rhs)
             (assert.is.same rhs (get-rhs mode :lhs))))
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
        (it "can include extra-opts in either first or second arg"
          (fn []
            (assert.has_no.errors #(nnoremap! [:nowait] :lhs :rhs))
            (assert.has_no.errors #(nnoremap! :lhs [:nowait] :rhs))))
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
              (assert.is.same :rhs (buf-get-rhs bufnr :n :lhs)))))
        (it "set a list which will result in string without callback"
          (fn []
            (nnoremap! :lhs (.. :r :h :s))
            (nnoremap! :lhs1 (.. (<Cmd> :foobar) :<Esc>))
            (assert.is.same :rhs (get-rhs :n :lhs))
            (assert.is.same :<Cmd>foobar<CR><Esc> (get-rhs :n :lhs1))))
        (it "can set Ex command in autocmds with `<command>` key"
          (fn []
            (nnoremap! :lhs1 [:<command>] default-rhs)
            (nnoremap! :lhs2 [:<command>] (.. :foo :bar))
            (assert.is.same default-rhs (get-rhs :n :lhs1))
            (assert.is.same :foobar (get-rhs :n :lhs2))))
        (it "can set Ex command in autocmds with `ex` key"
          (fn []
            (nnoremap! :lhs1 [:ex] default-rhs)
            (nnoremap! :lhs2 [:ex] (.. :foo :bar))
            (assert.is.same default-rhs (get-rhs :n :lhs1))
            (assert.is.same :foobar (get-rhs :n :lhs2))))
        (it "can set callback function in autocmds with `<callback>` key"
          (fn []
            (nnoremap! :lhs1 [:<callback>] default-callback)
            ;; Note: vim.api.nvim_get_keymap cannot get vim function.
            (nnoremap! :lhs2 [:<callback>] (new-callback (.. :foo :bar)))
            (assert.is.same default-callback (get-callback :n :lhs1))
            (assert.is_true (= :function (type (get-callback :n :lhs2))))))
        (it "can set callback function in autocmds with `cb` key"
          (fn []
            (nnoremap! :lhs1 [:cb] default-callback)
            (nnoremap! :lhs2 [:cb] (new-callback (.. :foo :bar)))
            (assert.is.same default-callback (get-callback :n :lhs1))
            (assert.is_true (= :function (type (get-callback :n :lhs2))))))
        (it "enables `replace_keycodes` when `expr` is set in `extra-opts`"
          (fn []
            (nnoremap! :lhs [:expr] :rhs)
            (nnoremap! :lhs1 :rhs {:expr true})
            (let [opt {:expr true}]
              (nnoremap! :lhs2 :rhs opt))
            (let [{: replace_keycodes} (get-mapargs :n :lhs)]
              (assert.is.same 1 replace_keycodes))
            (let [{: replace_keycodes} (get-mapargs :n :lhs1)]
              (assert.is_nil replace_keycodes))
            (let [{: replace_keycodes} (get-mapargs :n :lhs2)]
              (assert.is_nil replace_keycodes))))
        (it "disables `replace_keycodes` when `literal` is set in `extra-opts`"
          (fn []
            (nnoremap! :lhs [:expr :literal] :rhs)
            (let [{: replace_keycodes} (get-mapargs :n :lhs)]
              (assert.is_nil replace_keycodes))))))
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
              (assert.is_nil (buf-get-rhs bufnr :n :lhs)))))))
    (describe :map-motion!
      (fn []
        (it "`unmap`s `smap` internally without errors"
          (fn []
            (assert.has_no.errors #(map-motion! :lhs :rhs))
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (assert.has_no.errors #(map-motion! [:<buffer>] :lhs :rhs))
              (refresh-buffer)
              (assert.has_no.errors #(map-motion! [:buffer bufnr] :lhs :rhs)))))
        (it "`sunmap`s when lhs is visible key in compile time."
          #(let [lhs :sym]
             (smap! :lhs :old)
             (smap! lhs :old)
             (smap! :<Esc> :old)
             (smap! :<C-f> :old)
             (smap! :<k9> :old)
             (smap! :<S-f> :old)
             (assert.has_no.errors #(map-motion! :lhs :new))
             (assert.has_no.errors #(map-motion! lhs :new))
             (assert.has_no.errors #(map-motion! :<Esc> :new))
             (assert.has_no.errors #(map-motion! :<C-f> :new))
             (assert.has_no.errors #(map-motion! :<k9> :new))
             (assert.has_no.errors #(map-motion! :<S-f> :new))
             (assert.is_nil (get-rhs :s :lhs))
             (assert.is.same :old (get-rhs :s lhs))
             (assert.is.same :new (get-rhs :s :<Esc>))
             (assert.is.same :new (get-rhs :s :<C-F>))
             (assert.is.same :new (get-rhs :s :<k9>))
             (assert.is_nil (get-rhs :s :<S-f>)))))
      (describe :<Cmd>/<C-u>
        (fn []
          (it "is set to rhs as a string"
            (fn []
              (assert.has_no.errors #(nnoremap! :lhs (<Cmd> "Do something")))
              (assert.is.same "<Cmd>Do something<CR>" (get-rhs :n :lhs))
              (assert.has_no.errors #(nnoremap! [:<buffer>] :lhs
                                                (<C-u> "Do something")))
              (assert.is.same ":<C-U>Do something<CR>" (buf-get-rhs 0 :n :lhs)))))))))
