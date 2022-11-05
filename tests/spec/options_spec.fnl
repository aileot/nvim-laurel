(import-macros {: set! : setglobal! : setlocal!} :nvim-laurel.macros)

(describe :options ;
          (fn []
            (before_each (fn []
                           (vim.cmd.setglobal :wrap)
                           (vim.cmd.setglobal :bufhidden=)
                           (vim.cmd.setglobal "backspace=indent,eol,start")
                           (vim.cmd.setglobal "listchars=tab:>\\ ,trail:-,nbsp:+")
                           (vim.cmd.new)
                           (vim.cmd.only)
                           (assert.is_true vim.go.wrap)
                           (assert.is.same "" vim.go.bufhidden)
                           (assert.is.same "indent,eol,start" vim.go.backspace)
                           (assert.is.same "tab:> ,trail:-,nbsp:+"
                                           vim.go.listchars)
                           (assert.is_true vim.wo.wrap)
                           (assert.is.same "" vim.bo.bufhidden)))
            (describe :setglobal!/setlocal!
                      (fn []
                        (it "updates options independently"
                            (fn []
                              (setglobal! :wrap false)
                              (setlocal! :bufhidden :hide)
                              ;; Note: Make sure options are updated as most
                              ;; API functions are deferred.
                              (assert.has_error #(assert.is_true vim.go.wrap))
                              (assert.is_false vim.go.wrap)
                              (assert.is_true vim.wo.wrap)
                              (assert.is.same "" vim.go.bufhidden)
                              (assert.is.same :hide vim.bo.bufhidden)))
                        (it "inherits global value when local is set to nil"
                            (fn []
                              (setlocal! :bufhidden :hide)
                              (assert.is.not.same vim.bo.bufhidden
                                                  vim.go.bufhidden)
                              (setlocal! :bufhidden nil)
                              (assert.is.same vim.bo.bufhidden vim.go.bufhidden)))
                        (it "accepts camelCase/PascalCase option name in raw string"
                            (fn []
                              (setglobal! :bufHidden :hide)
                              (setglobal! :BufHidden :wipe)
                              (let [name :BufHidden]
                                (assert.has_error #(setglobal! name :hide)))))))
            (describe :setglobal-
                      (fn []
                        (it "removes values in string"
                            (fn []
                              (setglobal! :backspace- :eol)
                              (assert.is.same "indent,start" vim.go.backspace)))
                        (it "cannot remove values in comma seraprated strings"
                            (fn []
                              (setglobal! :backspace- "eol,start")
                              (assert.is.not.same :indent vim.go.backspace)
                              (assert.is.same "indent,eol,start"
                                              vim.go.backspace)))
                        (it "removes values in Fennel sequential table"
                            (fn []
                              (setglobal! :backspace- [:start :eol])
                              (assert.is.same :indent vim.go.backspace)))
                        (it "removes values in Fennel kv table"
                            (fn []
                              (setglobal! :listChars- :tab)
                              (let [[res1 res2] [(pcall assert.is.same
                                                        "trail:-,nbsp:+"
                                                        vim.go.listchars)
                                                 (pcall assert.is.same
                                                        "nbsp:+,trail:-"
                                                        vim.go.listchars)]]
                                (or res1 res2))))
                        (it "removes values in Fennel kv table"
                            (fn []
                              (setglobal! :listChars- [:tab :nbsp])
                              (assert.is.same "trail:-" vim.go.listchars)))))))
