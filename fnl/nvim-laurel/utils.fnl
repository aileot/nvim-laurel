(lambda keymap/->compatible-opts! [opts]
  "Remove invalid keys of `opts` for the api functions."
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  (set opts.<callback> nil)
  (set opts.cb nil)
  (set opts.literal nil)
  opts)

(lambda command/->compatible-opts! [opts]
  (set opts.buffer nil)
  (set opts.<buffer> nil)
  opts)

(lambda autocmd/->compatible-opts! [opts]
  (set opts.<buffer> nil)
  (set opts.<command> nil)
  (set opts.ex nil)
  (set opts.<callback> nil)
  (set opts.cb nil)
  opts)

{: keymap/->compatible-opts!
 : command/->compatible-opts!
 : autocmd/->compatible-opts!}
