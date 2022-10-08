(import-macros {: set! : setglobal! : setlocal!} :nvim-laurel.macros)

(describe :options
          (before_each (fn []
                          (vim.cmd.new)
                          (vim.cmd.only)))
          (describe :setglobal!/setlocal!
                    (fn []
                      (it "updates options independently"
                          (fn []
                              (assert.is_true vim.go.wrap)
                              (assert.is_true vim.wo.wrap)
                              (assert.is.same "" vim.go.bufhidden)
                              (assert.is.same "" vim.bo.bufhidden)
                              (setglobal! :wrap false)
                              (setlocal! :bufhidden "hide")
                              ;; Note: Make sure options are updated as most
                              ;; API functions are deferred.
                              (assert.has_error #(assert.is_true vim.go.wrap))
                              (assert.is_false vim.go.wrap)
                              (assert.is_true vim.wo.wrap)
                              (assert.is.same "" vim.go.bufhidden)
                              (assert.is.same "hide"
                                              vim.bo.bufhidden))))))
