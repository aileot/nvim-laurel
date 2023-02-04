(local {: map! } (require :nvim-laurel.macros))

(fn nmap! [...]
  (map! :n ...))

(fn omni-map! [...]
  (map! ["" "!" :l :t] ...))

{: nmap!
 : omni-map!}
