(import-macros {: map!
                : noremap!
                : nnoremap!
                : unmap!
                : smap!
                : map-range!
                : map-motion!
                : <C-u>
                : <Cmd>} :nvim-laurel.macros)

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(local default-rhs :default-rhs)
(local default-callback #:default-callback)
(local default {:multi {:sym #:default.multi.sym}})
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
    (setup (fn []
             (vim.cmd "function g:Test() abort
                       endfunction")))
    (teardown (fn []
                (vim.cmd "delfunction g:Test")))
    (before_each (fn []
                   (let [all-modes ["" "!" :l :t]]
                     (each [_ mode (ipairs all-modes)]
                       (pcall vim.api.nvim_del_keymap mode :lhs)
                       (assert.is_nil (get-rhs mode :lhs))))))
    (describe :map!
      (fn []
        (it "sets callback function with quoted symbol"
          #(do
             (map! :n :lhs `default-callback)
             (assert.is_same default-callback (get-callback :n :lhs))))
        (it "sets callback function with quoted multi-symbol"
          #(let [desc :multi.sym]
             (map! :n :lhs `default.multi.sym {: desc})
             (assert.is_same default.multi.sym (get-callback :n :lhs))))
        (it "sets callback function with quoted list"
          #(let [desc :list]
             (map! :n :lhs `(default-callback :foo :bar) {: desc})
             (assert.is_same desc (. (get-mapargs :n :lhs) :desc))))
        (it "set callback function in string for `vim.fn.Test"
          (fn []
            (map! :n :lhs `vim.fn.Test)
            (assert.is_same vim.fn.Test (get-callback :n :lhs))))
        (it "maps non-recursively by default"
          #(let [mode :n
                 modes [:n :o :t]]
             (map! mode :lhs :rhs)
             (map! modes :lhs :rhs)
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 1 noremap))
             (each [_ m (ipairs modes)]
               (let [{: noremap} (get-mapargs m :lhs)]
                 (assert.is.same 1 noremap)))))
        (it "is also available to recursive mappings"
          #(let [mode :n]
             (map! :o [:remap] :lhs :rhs)
             (map! mode [:remap] :lhs :rhs)
             (let [{: noremap} (get-mapargs :o :lhs)]
               (assert.is.same 0 noremap))
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 0 noremap))))
        (it "gives priority to `api-opts`"
          #(let [mode :n
                 modes [:i :c :t]
                 api-opts {:noremap true}]
             (map! :o :lhs :rhs api-opts)
             (map! mode :lhs :rhs api-opts)
             (map! modes :lhs :rhs api-opts)
             (let [{: noremap} (get-mapargs :o :lhs)]
               (assert.is.same 1 noremap))
             (let [{: noremap} (get-mapargs mode :lhs)]
               (assert.is.same 1 noremap))
             (each [_ m (ipairs modes)]
               (let [{: noremap} (get-mapargs m :lhs)]
                 (assert.is.same 1 noremap)))))
        (it "sets callback via macro with quote"
          (fn []
            (map! :n :lhs `(macro-callback))
            (assert.is_not_nil (get-callback :n :lhs))))
        (it "set command in macro with no args"
          (fn []
            (map! :n :lhs (macro-command))
            (assert.is_same :macro-command (get-rhs :n :lhs))))
        (it "set command in macro with some args"
          (fn []
            (map! :n :lhs (macro-command :foo :bar))
            (assert.is_same :macro-command (get-rhs :n :lhs))))
        (it "maps multiple mode mappings with a sequence at once"
          #(let [modes [:n :c :t]]
             (noremap! modes :lhs :rhs)
             (each [_ mode (ipairs modes)]
               (assert.is.same :rhs (get-rhs mode :lhs)))))
        (it "maps multiple mode mappings with a bare-string at once"
          #(do
             (noremap! :nct :lhs :rhs)
             (each [mode (-> :nct (: :gmatch "."))]
               (assert.is.same :rhs (get-rhs mode :lhs)))))
        (it "enables `replace_keycodes` with `expr` in `extra-opts`"
          #(let [modes [:n]]
             (map! modes [:expr] :lhs :rhs)
             (let [{: replace_keycodes} (get-mapargs :n :lhs)]
               (assert.is.same 1 replace_keycodes))))
        (it "disables `replace_keycodes` with `literal` in `extra-opts`"
          #(let [modes [:n]]
             (map! modes [:expr :literal] :lhs :rhs)
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
    (describe :<Cmd>/<C-u>
      (fn []
        (it "is set to rhs as a string"
          (fn []
            (assert.has_no.errors #(nnoremap! :lhs (<Cmd> "Do something")))
            (assert.is.same "<Cmd>Do something<CR>" (get-rhs :n :lhs))
            (assert.has_no.errors #(nnoremap! [:<buffer>] :lhs
                                              (<C-u> "Do something")))
            (assert.is.same ":<C-U>Do something<CR>" (buf-get-rhs 0 :n :lhs))))))
    (insulate "(deprecated)"
      (fn []
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
                   (assert.is.same :rhs (get-rhs mode :lhs)))))
            (it "maps recursively with `remap` key in `extra-opts`"
              #(let [modes [:n :o :x]]
                 (noremap! modes [:remap] :lhs :rhs)
                 (each [_ m (ipairs modes)]
                   (let [{: noremap} (get-mapargs m :lhs)]
                     (assert.is.same 0 noremap)))))))
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
        (describe :map-range!
          (fn []
            (it "maps lhs in Normal mode and Visual mode"
              (fn []
                (map-range! :lhs :rhs)
                (assert.is_same :rhs (get-rhs :n :lhs))
                (assert.is_same :rhs (get-rhs :x :lhs))
                (assert.is_same :rhs (get-rhs :v :lhs))
                (assert.is_nil (get-rhs :s :lhs))))))
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
                 (assert.is_nil (get-rhs :s :<S-f>))))))))))
