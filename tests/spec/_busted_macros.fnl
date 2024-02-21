;; fennel-ls: macro-file

(local fmt string.format)

(lambda inject-fn [name ...]
  (assert (< 0 (select "#" ...)) (fmt "expected one or more args for %s" name))
  `((. (require :busted) ,name (fn []
                                 ,...))))

(lambda inject-desc-fn [name desc ...]
  (assert (< 0 (select "#" ...))
          (fmt "expected one or more args for %s(\"%s\")" name desc))
  `((. (require :busted) ,name) ,desc
                                (fn []
                                  ,...)))

{:after_each (partial inject-fn :after_each)
 :before_each (partial inject-fn :before_each)
 :expose (partial inject-desc-fn :expose)
 :insulate (partial inject-desc-fn :insulate)
 :it (partial inject-desc-fn :it)
 :setup (partial inject-fn :setup)
 :teardown (partial inject-fn :teardown)
 :describe (partial inject-desc-fn :describe)}
