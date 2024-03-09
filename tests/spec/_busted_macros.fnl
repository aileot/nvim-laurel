;; fennel-ls: macro-file

(macro when-not [pred ...]
  `(when (not ,pred)
     ,...))

(lambda inject-fn [name ...]
  (assert (< 0 (select "#" ...)) (: "expected one or more args for %s" :format
                                    name))
  `((. (require :busted) ,name
       ;; TODO: Uncomment `(fn []` and remove `fn` lists in the specs if
       ;; a formatter makes reasonable indentations in the future.
       ;; (fn []
       ,...)))

(lambda inject-desc-fn [name desc ...]
  (when-not (varg? desc)
    (assert (< 0 (select "#" ...))
            (: "expected one or more args for %s(\"%s\")" :format name desc)))
  `((. (require :busted) ,name) ,desc
                                (fn []
                                  ,...)))

(local after_each (partial inject-fn :after_each))
(local before_each (partial inject-fn :before_each))
(local describe (partial inject-desc-fn :describe))
(local expose (partial inject-desc-fn :expose))
(local insulate (partial inject-desc-fn :insulate))
(local it (partial inject-desc-fn :it))
(local setup (partial inject-fn :setup))
(local teardown (partial inject-fn :teardown))

(fn pending [desc ...]
  ;; WIP
  (if (varg? desc)
      (inject-desc-fn :pending desc ...)
      (inject-fn :pending desc ...)))

{: after_each
 : before_each
 : describe
 : expose
 : insulate
 : it
 : pending
 : setup
 : teardown}
