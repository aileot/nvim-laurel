;; Note: Define wrapper functions to deal with values hidden in compile time.
;; Wrappers make it easier to debug in compiled lua codes.

(local {: keymap/->compatible-opts!} (require :nvim-laurel.utils))

(macro str? [x]
  "Check if `x` is of string type."
  `(= :string (type ,x)))

(lambda merge-api-opts [?api-opts ?extra-opts]
  "Merge `?api-opts` into `?extra-opts`.

  @param ?api-opts table
  @param ?extra-opts table Not a sequence.
  @return table"
  (if (and ?api-opts ?extra-opts)
      (collect [k v (pairs ?api-opts) &into ?extra-opts]
        (values k v))
      (or ?api-opts ?extra-opts {})))

(lambda keymap/set-maps! [modes extra-opts lhs rhs ?api-opts]
  (let [?bufnr extra-opts.buffer
        api-opts (merge-api-opts ?api-opts
                                 (keymap/->compatible-opts! extra-opts))
        set-keymap (if ?bufnr
                       (lambda [mode]
                         (vim.api.nvim_buf_set_keymap ?bufnr mode lhs rhs
                                                      api-opts))
                       (lambda [mode]
                         (vim.api.nvim_set_keymap mode lhs rhs api-opts)))]
    (if (str? modes)
        (set-keymap modes)
        (each [_ m (ipairs modes)]
          (set-keymap m)))))

{: merge-api-opts : keymap/set-maps!}
