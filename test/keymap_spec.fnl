(import-macros {: setup* : teardown* : describe* : it*}
               :test.helper.busted-macros)

(import-macros {: omni-map!
                : remap!
                : buf-map!/with-buffer=0
                : buf-map!/with-<buffer>=true}
               :test.helper.wrapper-macros)

(import-macros {: map! : unmap! : <C-u> : <Cmd>} :laurel.macros)

(macro macro-callback []
  `#:macro-callback)

(macro macro-command []
  :macro-command)

(macro buf-map! [...]
  `(map! &default-opts {:buffer 0 :nowait true} ,...))

(local default-rhs :default-rhs)
(local default-callback #:default-callback)
(local default
       {:multi {:sym {:callback #:default.multi.sym.callback
                      :command :default.multi.sym.command}}})

;; Note: Avoid using `<` in string for rhs, which is interpreted as `<lt>`,
;; lest checks become a bit complicated.
(local <default>-command :ltgt-command)
(local <default>-str-callback #:ltgt-str-callback)

(local new-callback #(fn []
                       $))

(fn refresh-buffer []
  (vim.cmd.new)
  (vim.cmd.only))

(λ get-mapargs [mode lhs]
  (let [mappings (vim.api.nvim_get_keymap mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(λ get-rhs [mode lhs]
  (?. (get-mapargs mode lhs) :rhs))

(λ get-callback [mode lhs]
  (?. (get-mapargs mode lhs) :callback))

(λ get-map-desc [mode lhs]
  (?. (get-mapargs mode lhs) :desc))

(λ buf-get-mapargs [bufnr mode lhs]
  (let [mappings (vim.api.nvim_buf_get_keymap bufnr mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(λ buf-get-rhs [bufnr mode lhs]
  (?. (buf-get-mapargs bufnr mode lhs) :rhs))

(λ buf-get-callback [bufnr mode lhs]
  (?. (buf-get-mapargs bufnr mode lhs) :callback))

(describe* :macros.keymap
  (setup* (fn []
            (vim.cmd "function g:Test()\nendfunction")))
  (teardown* (fn []
               (vim.cmd "delfunction g:Test")))
  (before_each (fn []
                 (let [all-modes ["" "!" :l :t]]
                   (each [_ mode (ipairs all-modes)]
                     (pcall vim.api.nvim_del_keymap mode :lhs)
                     (assert.is_nil (get-rhs mode :lhs))))))
  (describe* :map!
    (it* "should set callback function in symbol"
      (map! :n :lhs default-callback)
      (assert.is_same default-callback (get-callback :n :lhs)))
    (it* "should set callback function in multi-symbol"
      (let [desc :multi.sym]
        (map! :n :lhs default.multi.sym.callback {: desc})
        (assert.is_same default.multi.sym.callback (get-callback :n :lhs))))
    (it* "should set callback function in list"
      (let [desc :list]
        (map! :n :lhs (default-callback :foo :bar) {: desc})
        (assert.is_same desc (. (get-mapargs :n :lhs) :desc))))
    (it* "should set callback function in string for vim.fn.Test"
      (map! :n :lhs vim.fn.Test)
      (assert.is_same vim.fn.Test (get-callback :n :lhs)))
    (it* "maps non-recursively by default"
      (let [mode :n
            modes [:n :o :t]]
        (map! mode :lhs :rhs)
        (map! modes :lhs :rhs)
        (let [{: noremap} (get-mapargs mode :lhs)]
          (assert.is_same 1 noremap))
        (each [_ m (ipairs modes)]
          (let [{: noremap} (get-mapargs m :lhs)]
            (assert.is_same 1 noremap)))))
    (it* "is also available to recursive mappings"
      (let [mode :n]
        (map! :o [:remap] :lhs :rhs)
        (map! mode [:remap] :lhs :rhs)
        (let [{: noremap} (get-mapargs :o :lhs)]
          (assert.is_same 0 noremap))
        (let [{: noremap} (get-mapargs mode :lhs)]
          (assert.is_same 0 noremap))))
    (it* "gives priority to `api-opts`"
      (let [mode :n
            modes [:i :c :t]
            api-opts {:noremap true}]
        (map! :o :lhs :rhs api-opts)
        (map! mode :lhs :rhs api-opts)
        (map! modes :lhs :rhs api-opts)
        (let [{: noremap} (get-mapargs :o :lhs)]
          (assert.is_same 1 noremap))
        (let [{: noremap} (get-mapargs mode :lhs)]
          (assert.is_same 1 noremap))
        (each [_ m (ipairs modes)]
          (let [{: noremap} (get-mapargs m :lhs)]
            (assert.is_same 1 noremap)))))
    (it* "should set callback via macro"
      (map! :n :lhs (macro-callback))
      (assert.is_not_nil (get-callback :n :lhs)))
    (it* "set command in macro with no args"
      (map! :n :lhs &vim (macro-command))
      (assert.is_same :macro-command (get-rhs :n :lhs)))
    (it* "set command in macro with some args"
      (map! :n :lhs &vim (macro-command :foo :bar))
      (assert.is_same :macro-command (get-rhs :n :lhs)))
    (it* "maps multiple mode mappings with a sequence at once"
      (let [modes [:n :c :t]]
        (map! modes :lhs :rhs)
        (each [_ mode (ipairs modes)]
          (assert.is_same :rhs (get-rhs mode :lhs)))))
    (it* "maps multiple mode mappings with a bare-string at once"
      (map! :nct :lhs :rhs)
      (each [mode (-> :nct (: :gmatch "."))]
        (assert.is_same :rhs (get-rhs mode :lhs))))
    (it* "enables `replace_keycodes` with `expr` in `extra-opts`"
      (let [modes [:n]]
        (map! modes [:expr] :lhs :rhs)
        (let [{: replace_keycodes} (get-mapargs :n :lhs)]
          (assert.is_same 1 replace_keycodes))))
    (it* "disables `replace_keycodes` with `literal` in `extra-opts`"
      (let [modes [:n]]
        (map! modes [:expr :literal] :lhs :rhs)
        (let [{: replace_keycodes} (get-mapargs :n :lhs)]
          (assert.is_nil replace_keycodes))))
    (describe* :extra-opt
      (describe* "`buffer`"
        (it* "with the next value sets buffer-local keymap to the buffer"
          (let [buf (vim.api.nvim_get_current_buf)]
            (map! :n [:buffer buf] :lhs :rhs)
            (assert.is_same :rhs (buf-get-rhs buf :n :lhs))))
        (it* "with no next value sets buffer-local keymap to current buffer"
          (let [buf (vim.api.nvim_get_current_buf)]
            (map! :n [:buffer] :lhs :rhs)
            (assert.is_same :rhs (buf-get-rhs buf :n :lhs))))
        (it* "with no next value, followed by another extra-opts, sets buffer-local keymap to current buffer"
          (let [buf (vim.api.nvim_get_current_buf)]
            (map! :n [:buffer :nowait] :lhs :rhs)
            (assert.is_same :rhs (buf-get-rhs buf :n :lhs)))))
      (describe* "`wait`"
        (it* "disables `nowait` in extra-opts regardless of the order"
          (map! :n [:nowait] :lhs :rhs)
          (let [{: nowait} (get-mapargs :n :lhs)]
            (assert.is_same 1 nowait))
          (map! :n [:nowait :wait] :lhs :rhs)
          (let [{: nowait} (get-mapargs :n :lhs)]
            (assert.is_same 0 nowait))
          (map! :n [:nowait] :lhs :rhs)
          (let [{: nowait} (get-mapargs :n :lhs)]
            (assert.is_same 1 nowait))
          (map! :n [:wait :nowait] :lhs :rhs)
          (let [{: nowait} (get-mapargs :n :lhs)]
            (assert.is_same 0 nowait)))
        (it* "will NOT disable `nowait` _in api-opts_"
          (map! :n [:wait] :lhs :rhs {:nowait true})
          (let [{: nowait} (get-mapargs :n :lhs)]
            (assert.is_same 1 nowait)))))
    (describe* "`:desc` key as the first `extra-opts` value can be omittable"
      (it* "if `extra-opts` precedes `lhs`."
        (map! :n :lhs ["foo"] :rhs)
        (assert.is_same :foo (get-map-desc :n :lhs))
        (map! :n :lhs ["bar" :nowait] :rhs)
        (assert.is_same :bar (get-map-desc :n :lhs))
        (map! :n :lhs ["baz"] :rhs {:nowait true})
        (assert.is_same :baz (get-map-desc :n :lhs)))
      (it* "if `lhs` precedes `extra-opts`."
        (map! :n ["foo"] :lhs :rhs)
        (assert.is_same :foo (get-map-desc :n :lhs))
        (map! :n ["bar" :nowait] :lhs :rhs)
        (assert.is_same :bar (get-map-desc :n :lhs))
        (map! :n :lhs ["baz"] :rhs {:nowait true})
        (assert.is_same :baz (get-map-desc :n :lhs))))
    (describe* :<Cmd>pattern
      (it* "symbol will be set to 'command'"
        (map! :n :lhs <default>-command)
        (let [rhs (get-rhs :n :lhs)]
          (assert.is_same <default>-command rhs)))
      (it* "list will be set to 'command'"
        (map! :n :lhs (<default>-str-callback))
        (let [rhs (get-rhs :n :lhs)]
          (assert.is_same (<default>-str-callback) rhs))))
    (describe* "with `&vim` indicator"
      (it* "sets `callback` in symbol as key sequence"
        (map! :n :lhs &vim default-rhs)
        (assert.is_same default-rhs (get-rhs :n :lhs)))
      (it* "sets `callback` in multi symbol as key sequence"
        (map! :n :lhs &vim default.multi.sym.command)
        (assert.is_same default.multi.sym.command (get-rhs :n :lhs)))
      (it* "sets `callback` in list as key sequence"
        (map! :n :lhs &vim (macro-command))
        (assert.is_same (macro-command) (get-rhs :n :lhs)))))
  (describe* :unmap!
    (it* "`unmap`s key"
      (map! :n :lhs :rhs)
      (assert.is_same :rhs (get-rhs :n :lhs))
      (unmap! :n :lhs)
      (assert.is_nil (get-rhs :n :lhs)))
    (it* "can unmap buffer local key"
      (let [bufnr (vim.api.nvim_get_current_buf)]
        (map! :n [:<buffer>] :lhs :rhs)
        (assert.is_same :rhs (buf-get-rhs 0 :n :lhs))
        (unmap! 0 :n :lhs)
        (assert.is_nil (buf-get-rhs 0 :n :lhs))
        (map! :n [:buffer bufnr] :lhs :rhs)
        (assert.is_same :rhs (buf-get-rhs bufnr :n :lhs))
        (unmap! bufnr :n :lhs)
        (assert.is_nil (buf-get-rhs bufnr :n :lhs))))
    (it* "can unmap a key in multi modes at once"
      (map! :n :lhs :rhs1)
      (map! :x :lhs :rhs2)
      (map! :o :lhs :rhs3)
      (assert.is_same :rhs1 (get-rhs :n :lhs))
      (assert.is_same :rhs2 (get-rhs :x :lhs))
      (assert.is_same :rhs3 (get-rhs :o :lhs))
      (unmap! [:n :x :o] :lhs)
      (assert.is_nil (get-rhs :n :lhs))
      (assert.is_nil (get-rhs :x :lhs))
      (assert.is_nil (get-rhs :o :lhs)))
    (it* "can unmap buffer-locally a key in multi modes at once"
      (let [bufnr (vim.api.nvim_get_current_buf)]
        (map! :n [:buffer bufnr] :lhs :rhs1)
        (map! :x [:buffer bufnr] :lhs :rhs2)
        (map! :o [:buffer bufnr] :lhs :rhs3)
        (assert.is_same :rhs1 (buf-get-rhs bufnr :n :lhs))
        (assert.is_same :rhs2 (buf-get-rhs bufnr :x :lhs))
        (assert.is_same :rhs3 (buf-get-rhs bufnr :o :lhs))
        (unmap! bufnr [:n :x :o] :lhs)
        (assert.is_nil (buf-get-rhs bufnr :n :lhs))
        (assert.is_nil (buf-get-rhs bufnr :x :lhs))
        (assert.is_nil (buf-get-rhs bufnr :o :lhs)))))
  (describe* :<Cmd>/<C-u>
    (it* "is set to rhs as a string"
      (assert.has_no.errors #(map! :n :lhs (<Cmd> "Do something")))
      (assert.is_same "<Cmd>Do something<CR>" (get-rhs :n :lhs))
      (assert.has_no.errors #(map! :n [:<buffer>] :lhs (<C-u> "Do something")))
      (assert.is_same ":<C-U>Do something<CR>" (buf-get-rhs 0 :n :lhs))))
  (describe* "(wrapper)"
    (describe* :omni-map!
      (it* "should map to lhs in any mode"
        (each [_ mode (ipairs [:n :v :x :s :o :i :l :c :t])]
          (assert.is_nil (get-rhs mode :lhs)))
        (omni-map! :lhs :rhs)
        (each [_ mode (ipairs [:n :v :x :s :o :i :l :c :t])]
          (assert.is_same :rhs (get-rhs mode :lhs)))))
    (describe* "with `&default-opts`,"
      (describe* "local macro"
        (describe* :buf-map!
          (before_each (fn []
                         (refresh-buffer)))
          (after_each (fn []
                        (refresh-buffer)))
          (it* "creates current buffer-local mapping by default"
            (let [mode :n
                  bufnr (vim.api.nvim_get_current_buf)]
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (buf-map! mode :lhs :rhs)
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_same :rhs (buf-get-rhs 0 mode :lhs))
              (refresh-buffer)
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (assert.is_same :rhs (buf-get-rhs bufnr mode :lhs))))
          (it* "creates mapping with `nowait` set to true by default"
            (buf-map! :n :lhs :rhs)
            (let [{: nowait} (buf-get-mapargs 0 :n :lhs)]
              (assert.is_same 1 nowait)))))
      (describe* "imported macro"
        (describe* :remap!
          (it* "creates recursive mapping by default"
            (let [mode :x
                  modes [:n :o :t]]
              (remap! mode :lhs :rhs)
              (remap! modes :lhs :rhs)
              (let [{: noremap} (get-mapargs mode :lhs)]
                (assert.is_same 0 noremap))
              (each [_ m (ipairs modes)]
                (let [{: noremap} (get-mapargs m :lhs)]
                  (assert.is_same 0 noremap)))))
          (it* "can create non-recursive mappings by overriding option"
            (let [mode :x
                  modes [:n :o :t]]
              (map! mode [:noremap] :lhs :rhs)
              (map! modes [:noremap] :lhs :rhs)
              (let [{: noremap} (get-mapargs mode :lhs)]
                (assert.is_same 1 noremap))
              (each [_ m (ipairs modes)]
                (let [{: noremap} (get-mapargs m :lhs)]
                  (assert.is_same 1 noremap))))))
        (describe* "buf-map! with {:buffer 0} in its default-opts"
          (before_each (fn []
                         (refresh-buffer)))
          (after_each (fn []
                        (refresh-buffer)))
          (it* "creates current buffer-local mapping by default"
            (let [mode :x
                  bufnr (vim.api.nvim_get_current_buf)]
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (buf-map!/with-buffer=0 mode :lhs :rhs)
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_same :rhs (buf-get-rhs 0 mode :lhs))
              (refresh-buffer)
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (assert.is_same :rhs (buf-get-rhs bufnr mode :lhs))))
          (it* "can create another buffer-local mapping by overriding option"
            (let [mode :x
                  bufnr (vim.api.nvim_get_current_buf)]
              (refresh-buffer)
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (buf-map!/with-buffer=0 mode [:buffer bufnr] :lhs :rhs)
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (refresh-buffer)
              (assert.is_same :rhs (buf-get-rhs bufnr mode :lhs)))))
        (describe* "buf-map! with {:<buffer> true} in its default-opts"
          (before_each (fn []
                         (refresh-buffer)))
          (after_each (fn []
                        (refresh-buffer)))
          (it* "creates current buffer-local mapping by default"
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (assert.is_nil (get-rhs :x :lhs))
              (assert.is_nil (buf-get-rhs 0 :x :lhs))
              (buf-map!/with-<buffer>=true :x :lhs :rhs)
              (assert.is_nil (get-rhs :x :lhs))
              (assert.is_same :rhs (buf-get-rhs 0 :x :lhs))
              (refresh-buffer)
              (assert.is_nil (buf-get-rhs 0 :x :lhs))
              (assert.is_same :rhs (buf-get-rhs bufnr :x :lhs))))
          (it* "can create another buffer-local mapping by overriding option"
            (let [mode :x
                  bufnr (vim.api.nvim_get_current_buf)]
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_nil (buf-get-rhs 0 mode :lhs))
              (buf-map!/with-<buffer>=true mode [:buffer bufnr] :lhs :rhs)
              (assert.is_nil (get-rhs mode :lhs))
              (assert.is_same :rhs (buf-get-rhs 0 mode :lhs))
              (refresh-buffer)
              (assert.is_nil (buf-get-rhs 0 :x :lhs))
              (assert.is_same :rhs (buf-get-rhs bufnr mode :lhs)))))))))
