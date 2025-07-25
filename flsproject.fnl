{:lua-version "lua5.1"
 :extra-globals "describe it describe* it* setup teardown before_each after_each spy"
 ;; NOTE: For libraries, you should preinstall docsets like
 ;; `curl https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua -o $HOME/.local/share/fennel-ls/docsets/nvim.lua`
 :libraries {:nvim true}
 :macro-path "fnl/?.fnl;fnl/?/init.fnl;?.fnl;?/init.fnl"
 :fennel-path "fnl/?.fnl;fnl/?/init.fnl;?.fnl;?/init.fnl"}
