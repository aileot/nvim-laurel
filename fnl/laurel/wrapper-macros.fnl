;; fennel-ls: macro-file

;; A set of wrapper macros.
;; The definitions also serve as practical examples to the end-users.

(local {: augroup! : let! : map!} (require :laurel.macros))

(λ augroup+ [...]
  (augroup! `&default-opts
    {:clear false}
    ...))

(λ set! [...]
  (let! :opt ...))

(λ setlocal! [...]
  (let! :opt_local ...))

(λ setglobal! [...]
  (let! :opt_global ...))

(λ bo! [...]
  (let! :bo ...))

(λ wo! [...]
  (let! :wo ...))

(λ set+ [name ...]
  (let! :opt name `+ ...))

(λ set- [name ...]
  (let! :opt name `- ...))

(λ set^ [name ...]
  (let! :opt name `^ ...))

(λ remap! [...]
  (map! `&default-opts {:remap true} ...))

;; NOTE: Define keymap wrappers as the definition order as you can see in
;; vimdoc `:h :nmap`

(λ nmap! [...]
  (map! :n ...))

(λ vmap! [...]
  (map! :v ...))

(λ xmap! [...]
  (map! :x ...))

(λ smap! [...]
  (map! :s ...))

(λ imap! [...]
  (map! :i ...))

(λ omap! [...]
  (map! :o ...))

(λ lmap! [...]
  (map! :l ...))

(λ cmap! [...]
  (map! :c ...))

(λ tmap! [...]
  (map! :t ...))

{: augroup+
 : set!
 : setlocal!
 : setglobal!
 : bo!
 : wo!
 : set+
 : set-
 : set^
 : remap!
 : nmap!
 : vmap!
 : xmap!
 : smap!
 : omap!
 : imap!
 : lmap!
 : cmap!
 : tmap!}
