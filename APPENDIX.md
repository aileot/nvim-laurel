# Appendix of nvim-laurel

## LSP: Get fennel-ls support

This is an example to get a support from
[fennel-ls](https://git.sr.ht/~xerool/fennel-ls)
with
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
The code lets `fennel-ls` aware of all the Fennel files under `fnl/` in
`&runtimepath`.

```fennel
(let [globals [:vim]
      extra-globals (table.concat globals " ")
      runtime-fnl-roots (vim.api.nvim_get_runtime_file :fnl true)
      pat-project-root "."
      _ (table.insert runtime-fnl-roots pat-project-root)
      ;; Note: It shares the suffix patterns with fennel-path and macro-path.
      ;; Another step is required if you need `?/init-macros.fnl`.
      suffix-patterns [:/?.fnl :/?/init.fnl]
      default-patterns (table.concat [:?.fnl
                                      :?/init.fnl
                                      :src/?.fnl
                                      :src/?/init.fnl]
                                     ";")
      fnl-patterns (accumulate [patterns default-patterns ;
                                _ root (ipairs runtime-fnl-roots)]
                     (do
                       (each [_ suffix (ipairs suffix-patterns)]
                         (set patterns (.. patterns ";" root "/" suffix)))
                       patterns))
      fennel-path fnl-patterns
      macro-path fnl-patterns
      config {:settings {:fennel-ls {: extra-globals
                                     : fennel-path
                                     : macro-path}}}]
      lspconfig (require :lspconfig)
 (lspconfig.setup config)
```

## Treesitter: Personalize syntax highlights

_To begin with, do not forget `;; extends` at the top
of your `after/queries/fennel/highlights.scm`
if you don't intend to override those defined by other plugins!_

```query
;; extends
```

### Distinguish keys in table

WIP

<!-- TODO: Paste Screenshot -->

```query
;; In after/queries/fennel/highlight.scm
(table_pair
  key: (string) @variable.member)
```

## Hotpot.nvim: Clear compiled Lua cache

Probably because I often run multiple nvim instances in editing nvim config
files, hotpot.nvim sometimes fails to catch up the latest. In this case,
the following codes would be useful.

```fennel
(command! :HotpotCacheClear
  [:desc "[hotpot] clear compiled Lua cache"]
  #(let [{: clear-cache} (require :hotpot.api.cache)]
     (clear-cache)))

(command! :HotpotCacheForceUpdate
  [:desc "[hotpot] clear & recache compiled Lua"]
  #(let [{: clear-cache} (require :hotpot.api.cache)]
     (clear-cache)
     (vim.fn.system [:nvim :--headless :+q])))
```

## Hotpot.nvim: Alternate Fennel file and its compiled Lua cache

A quick glance at the compiled Lua results can find the cause of a problem
more quickly and easily with than a line-by-line review through Fennel codes.

```fennel
(command! :HotpotCacheAlternate
  [:desc "Open the alternate file of current buffer."]
  #(let [path (vim.fn.expand "%:p")
         [row] (vim.api.nvim_win_get_cursor 0)
         find-fnl? (path:find "%.lua$")
         alt-path (if find-fnl?
                      (-> path
                          (: :gsub "^(.*)/lua/(.*)%.lua" "%1/fnl/%2.fnl")
                          (: :gsub "^(.*)%.lua" "%1.fnl"))
                      (-> path
                          (: :gsub "^(.*)/fnl/(.*)%.fnl" "%1/lua/%2.lua")
                          (: :gsub "^(.*)%.fnl" "%1.lua")))
         ?suffix-from-rtp ;
         (if (file-readable? alt-path)
             nil
             find-fnl?
             (-> path
                 (: :gsub "^.*/lua/hotpot%-runtime%-after/ftplugin/(.*)%.lua"
                    "after/ftplugin/%1.fnl")
                 (: :gsub "^.*/lua/hotpot%-runtime%-ftplugin/(.*)%.lua"
                    "ftplugin/%1.fnl")
                 (: :gsub "^.*/lua/(.*)%.lua$" "fnl/%1.fnl"))
             (-> (path:gsub "^.*/fnl/(.*)%.fnl$" "lua/%1.lua")
                 (#(if ($:find :/after/)
                       ($:gsub "^.*/after/ftplugin/(.*)%.fnl"
                               "lua/hotpot-runtime-after/ftplugin/%1.lua")
                       ($:gsub "^.*/ftplugin/(.*)%.fnl"
                               "lua/hotpot-runtime-ftplugin/%1.lua")))))
         alt-path* (if ?suffix-from-rtp
                       (-> ?suffix-from-rtp
                           (vim.api.nvim_get_runtime_file false)
                           (. 1))
                       alt-path)]
     (if (file-readable? alt-path*)
         (if (= "" $.mods)
             (vim.cmd (: "%s +%d %s" :format :edit row alt-path*))
             (vim.cmd (: "%s %s +%d %s" ;
                         :format ;
                         $.mods :split row alt-path*)))
         ;; Failback process. Edit below as you feel like.
         (let [hac (require :hotpot.api.cache)]
           (case (pcall require :telescope.builtin)
             (true {: find_files}) (let [prompt_title "Compiled Lua files"]
                                     (find_files {:cwd (hac.cache-prefix)
                                                  :hidden true
                                                  : prompt_title}))
             _ (hac.open-cache))
           (vim.notify (if alt-path*
                           (.. alt-path* " is not a readable file.")
                           (.. "Cannot find alternate file. Suffix: "
                               ?suffix-from-rtp))
                       vim.log.levels.WARN)))))

(augroup! :rcHotpotCacheAlternate
  (au! :BufWinEnter ["*/nvim/*.{fnl,lua}"]
       [:desc "[hotpot] Override alternate keymaps"]
       #(do
          (macro buf-nmap! [...]
            `(nmap! &default-opts {:buffer $.buf} ,...))
          (buf-nmap! [:desc ":edit <alternate>"] "[a"
                     (<Cmd> :HotpotCacheAlternate))
          (buf-nmap! [:desc ":edit <alternate>"] "]a"
                     (<Cmd> :HotpotCacheAlternate))
          (buf-nmap! [:desc ":split <alternate>"] :<C-w>a
                     (<Cmd> "below HotpotCacheAlternate"))
          (buf-nmap! [:desc ":split <alternate>"] :<C-w>a
                     (<Cmd> "below HotpotCacheAlternate"))
          (buf-nmap! [:desc ":split <alternate>"] :<C-w>A
                     (<Cmd> "vertical below HotpotCacheAlternate"))
          (buf-nmap! [:desc ":split <alternate>"] :<C-w>A
                     (<Cmd> "vertical below HotpotCacheAlternate"))
          (buf-nmap! [:desc ":split <alternate>"] "[A"
                     (<Cmd> "vertical below HotpotCacheAlternate"))
          (buf-nmap! [:desc ":split <alternate>"] "]A"
                     (<Cmd> "vertical below HotpotCacheAlternate")))))
```
