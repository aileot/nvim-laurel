;; Note: Define wrapper functions to deal with values hidden in compile time.
;; Wrappers make it easier to debug in compiled lua codes.

(lambda merge-api-opts [?api-opts ?extra-opts]
  "Merge `?api-opts` into `?extra-opts`.

  @param ?api-opts table
  @param ?extra-opts table Not a sequence.
  @return table"
  (if (and ?api-opts ?extra-opts)
      (collect [k v (pairs ?api-opts) &into ?extra-opts]
        (values k v))
      (or ?api-opts ?extra-opts {})))

{: merge-api-opts}
