;; fennel-ls: macro-file
(local {: augroup! : set! : map!} (require :nvim-laurel.macros))

(fn augroup+ [name ...]
  (augroup! name
    `&default-opts
    {:clear false}
    ...))

(fn set+ [name ...]
  (set! name `+ ...))

(fn set- [name ...]
  (set! name `- ...))

(fn set^ [name ...]
  (set! name `^ ...))

(fn nmap! [...]
  (map! :n ...))

(fn omni-map! [...]
  (map! ["" "!" :l :t] ...))

{: augroup+ : set+ : set- : set^ : nmap! : omni-map!}
