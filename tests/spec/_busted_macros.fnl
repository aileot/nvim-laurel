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

{:after_each (partial inject-fn :after_each)
 :before_each (partial inject-fn :before_each)
 :describe (partial inject-desc-fn :describe)
 :expose (partial inject-desc-fn :expose)
 :insulate (partial inject-desc-fn :insulate)
 :it (partial inject-desc-fn :it)
 :setup (partial inject-fn :setup)
 :teardown (partial inject-fn :teardown)
 :pending (fn [...]
            (if (= :string (type (select 1 ...)))
                (inject-desc-fn :pending ...)
                (inject-fn :pending ...)))}
