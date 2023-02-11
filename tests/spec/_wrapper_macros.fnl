(local {: augroup! : map!} (require :nvim-laurel.macros))

(fn augroup+ [name ...]
  (augroup! name
    {:clear false}
    ...))

(fn nmap! [...]
  (map! :n ...))

(fn omni-map! [...]
  (map! ["" "!" :l :t] ...))

{: augroup+ : nmap! : omni-map!}
