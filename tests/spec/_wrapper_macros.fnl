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

(fn remap! [...]
  (map! `&default-opts {:noremap false} ...))

(fn buf-map!/with-buffer=0 [...]
  (map! `&default-opts {:buffer 0} ...))

(fn buf-map!/with-<buffer>=true [...]
  (map! `&default-opts {:<buffer> true} ...))

{: augroup+
 : set+
 : set-
 : set^
 : nmap!
 : omni-map!
 : remap!
 : buf-map!/with-buffer=0
 : buf-map!/with-<buffer>=true}
