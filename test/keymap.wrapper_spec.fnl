(import-macros {: describe* : it*} :test.helper.busted-macros)

(import-macros {: <C-u> : <Cmd>} :laurel.macros)
(import-macros {: nmap!} :laurel.wrapper-macros)

(fn refresh-buffer! []
  (vim.cmd.new)
  (vim.cmd.only))

(λ get-mapargs [mode lhs]
  (let [mappings (vim.api.nvim_get_keymap mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(λ get-rhs [mode lhs]
  (?. (get-mapargs mode lhs) :rhs))

(λ buf-get-mapargs [bufnr mode lhs]
  (let [mappings (vim.api.nvim_buf_get_keymap bufnr mode)]
    (accumulate [rhs nil _ m (ipairs mappings) &until rhs]
      (when (= lhs m.lhs)
        m))))

(λ buf-get-rhs [bufnr mode lhs]
  (?. (buf-get-mapargs bufnr mode lhs) :rhs))

(describe* "(supported wrapper macro)"
  (describe* :nmap!
    (it* "can include extra-opts in either first or second arg"
      (assert.has_no.errors #(nmap! [:nowait] :lhs :rhs))
      (assert.has_no.errors #(nmap! :lhs [:nowait] :rhs)))
    (it* "maps to current buffer with `<buffer>`"
      (nmap! [:<buffer>] :lhs :rhs)
      (assert.is_same :rhs (buf-get-rhs 0 :n :lhs)))
    (it* "maps to specific buffer with `buffer`"
      (let [bufnr (vim.api.nvim_get_current_buf)]
        (refresh-buffer!)
        (nmap! [:buffer bufnr] :lhs :rhs)
        (assert.is_nil (buf-get-rhs 0 :n :lhs))
        (assert.is_same :rhs (buf-get-rhs bufnr :n :lhs))))
    (it* "set a list which will result in string without callback"
      (nmap! :lhs &vim (.. :r :h :s))
      (nmap! :lhs1 &vim (.. (<Cmd> :foobar) :<Esc>))
      (assert.is_same :rhs (get-rhs :n :lhs))
      (assert.is_same :<Cmd>foobar<CR><Esc> (get-rhs :n :lhs1)))
    (it* "enables `replace_keycodes` when `expr` is set in `extra-opts`"
      (nmap! :lhs [:expr] :rhs)
      (nmap! :lhs1 :rhs {:expr true})
      (let [opt {:expr true}]
        (nmap! :lhs2 :rhs opt))
      (let [{: replace_keycodes} (get-mapargs :n :lhs)]
        (assert.is_same 1 replace_keycodes))
      (let [{: replace_keycodes} (get-mapargs :n :lhs1)]
        (assert.is_nil replace_keycodes))
      (let [{: replace_keycodes} (get-mapargs :n :lhs2)]
        (assert.is_nil replace_keycodes)))
    (it* "disables `replace_keycodes` when `literal` is set in `extra-opts`"
      (nmap! :lhs [:expr :literal] :rhs)
      (let [{: replace_keycodes} (get-mapargs :n :lhs)]
        (assert.is_nil replace_keycodes)))))
