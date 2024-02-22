;; fennel-ls: macro-file
(local {: augroup! : autocmd! : set! : map!} (require :nvim-laurel.macros))

(fn augroup+ [...]
  (augroup! `&default-opts
    {:clear false}
    ...))

(fn buf-autocmd!/with-no-default-bufnr [buffer ...]
  (augroup! :buf-local-augroup
    (autocmd! `&default-opts {: buffer} ...)))

(fn buf-autocmd!/with-buffer=0 [...]
  (autocmd! `&default-opts {:buffer 0} ...))

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

{: augroup+
 : buf-autocmd!/with-no-default-bufnr
 : buf-autocmd!/with-buffer=0
 : set+
 : set-
 : set^
 : nmap!
 : omni-map!
 : remap!
 : buf-map!/with-buffer=0}
