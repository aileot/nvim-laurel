;; fennel-ls: macro-file
(local {: augroup! : autocmd! : set! : map! : command! : highlight!}
       (require :nvim-laurel.macros))

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

(fn buf-command!/as-api-alias [bufnr ...]
  (command! `&default-opts {:buffer bufnr} ...))

(fn bold-highlight! [...]
  (highlight! `&default-opts {:bold true} ...))

(fn hi!-link-by-default [ref ...]
  ;; WIP: prop "key" should be omitted if any of the other props are set.
  (case (select "#" ...)
    1 (highlight! `&default-opts {:link ref} ...)
    _ (highlight! ...)))

{: augroup+
 : buf-autocmd!/with-no-default-bufnr
 : buf-autocmd!/with-buffer=0
 : set+
 : set-
 : set^
 : nmap!
 : omni-map!
 : remap!
 : buf-map!/with-buffer=0
 : buf-command!/as-api-alias
 : bold-highlight!
 : hi!-link-by-default}
