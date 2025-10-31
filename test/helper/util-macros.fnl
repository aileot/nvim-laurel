;; fennel-ls: macro-file

(λ evaluate [f ...]
  "Evaluate function `f` with args `...`.
@param f function
@param ... any args for `f`
@return any"
  `(,f ,...))

{: evaluate}
