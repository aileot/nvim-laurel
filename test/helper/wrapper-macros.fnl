;; fennel-ls: macro-file
(local {: augroup! : autocmd! : let! : map! : command! : highlight!}
       (require :laurel.macros))

(fn my-autocmd! [...]
  "Create an autocmd in predefined augroup, but the augroup MUST be defined
  outside of macro definition file. It requires the carefully conflicted
  variable assigned an augroup in global-scope."
  (autocmd! `_G.my-augroup-id ...))

(fn augroup+ [...]
  (augroup! `&default-opts
    {:clear false}
    ...))

(fn bufnr-suffixed-augroup! [name ...]
  "Create an buffer-local augroup. This macro is supposed to be expanded in
  another parent augroup or in ftplugin."
  (let [augroup-name `(: "%s%d" :format ,name (vim.api.nvim_get_current_buf))]
    (augroup! augroup-name
      ...)))

(fn buf-autocmd!/with-no-default-bufnr [buffer ...]
  (autocmd! `&default-opts {: buffer} ...))

(fn buf-autocmd!/with-buffer=0 [...]
  (autocmd! `&default-opts {:buffer 0} ...))

(fn set! [...]
  (let! :opt ...))

(fn setlocal! [...]
  (let! :opt_local ...))

(fn setglobal! [...]
  (let! :opt_global ...))

(fn bo! [...]
  (let! :bo ...))

(fn wo! [...]
  (let! :wo ...))

(fn v! [...]
  (let! :v ...))

(fn g! [...]
  (let! :g ...))

(fn b! [...]
  (let! :b ...))

(fn w! [...]
  (let! :w ...))

(fn t! [...]
  (let! :t ...))

(fn env! [...]
  (let! :env ...))

(fn set+ [name ...]
  (let! :opt name `+ ...))

(fn set- [name ...]
  (let! :opt name `- ...))

(fn set^ [name ...]
  (let! :opt name `^ ...))

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

(fn buf-command!/as-api-alias [bufnr ...]
  (command! `&default-opts {:buffer bufnr} ...))

(fn bold-highlight! [...]
  (highlight! `&default-opts {:bold true} ...))

(fn hi!-link-by-default [ref ...]
  ;; WIP: prop "key" should be omitted if any of the other props are set.
  (case (select "#" ...)
    1 (highlight! `&default-opts {:link ref} ...)
    _ (highlight! ...)))

{: my-autocmd!
 : augroup+
 : bufnr-suffixed-augroup!
 : buf-autocmd!/with-no-default-bufnr
 : buf-autocmd!/with-buffer=0
 : set!
 : setlocal!
 : setglobal!
 : bo!
 : wo!
 : v!
 : g!
 : b!
 : w!
 : t!
 : env!
 : set+
 : set-
 : set^
 : nmap!
 : omni-map!
 : remap!
 : buf-map!/with-buffer=0
 : buf-map!/with-<buffer>=true
 : buf-command!/as-api-alias
 : bold-highlight!
 : hi!-link-by-default}
