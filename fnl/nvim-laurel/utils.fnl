(lambda keymap/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  (when (and opts.expr (not= false opts.replace_keycodes))
    (set opts.replace_keycodes true))
  (when opts.literal
    (set opts.literal nil)
    (set opts.replace_keycodes nil))
  opts)

(lambda command/->compatible-opts! [opts]
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  opts)

(lambda autocmd/->compatible-opts! [opts]
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  opts)

{: keymap/->compatible-opts!
 : command/->compatible-opts!
 : autocmd/->compatible-opts!}
