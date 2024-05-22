(import-macros {: before-each : describe* : it*} :test._busted_macros)
(import-macros {: highlight!} :laurel.macros)
(import-macros {: bold-highlight!} :test._wrapper_macros)

(macro get-hl-of-rgb-color [name]
  `(vim.api.nvim_get_hl_by_name ,name true))

(macro get-hl-of-256-color [name]
  `(vim.api.nvim_get_hl_by_name ,name false))

(local predefined-namespace-id
       (vim.api.nvim_create_namespace "namespace: test module highlight"))

(macro module-hi! [...]
  `(highlight! predefined-namespace-id ,...))

(local test-hl-name :HlTest)

(lambda get-hl [ns-id opts]
  (vim.api.nvim_get_hl ns-id opts))

(lambda hex->decimal [hex]
  (let [t (type hex)]
    (assert (= t :string) (.. "expected string, got " t))
    (let [hex-map {:0 0
                   :1 1
                   :2 2
                   :3 3
                   :4 4
                   :5 5
                   :6 6
                   :7 7
                   :8 8
                   :9 9
                   :a 10
                   :b 11
                   :c 12
                   :d 13
                   :e 14
                   :f 15
                   :A 10
                   :B 11
                   :C 12
                   :D 13
                   :E 14
                   :F 15}]
      (accumulate [decimal 0 m (hex:gmatch "%x")]
        (+ (* 16 decimal) (. hex-map m))))))

(describe* :highlight!
  (it* "can define hl-group with color name"
    (highlight! :Foo {:fg :Red :bg :Black :bold true})
    (highlight! :Bar {:ctermfg :Red :ctermbg :Black :bold true})
    (highlight! :Baz {:fg :Red
                      :bg :Black
                      :bold true
                      :ctermfg :Red
                      :ctermbg :Black}))
  (it* "can define hl-group with 256-color code"
    (highlight! :Foo {:ctermfg 0 :ctermbg 255 :bold true})
    (highlight! :Bar {:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255})
    (assert.is_same {:foreground 0 :background 255 :bold true}
                    (get-hl-of-256-color :Foo))
    (assert.is_same {:foreground 0 :background 255 :bold true}
                    (get-hl-of-256-color :Bar)))
  (it* "for gui can define hl-group with color code"
    (highlight! :FooBar {:fg "#000000" :bg "#FFFFFF" :bold true})
    (assert.is_same {:foreground (hex->decimal "#000000")
                     :background (hex->decimal "#FFFFFF")
                     :bold true}
                    (get-hl-of-rgb-color :FooBar)))
  (it* "can link to another hl-group"
    (highlight! :Foo {:ctermfg 0 :ctermbg 255 :bold true})
    (highlight! :Bar {:link :Foo})
    (assert.is_same {:foreground 0 :background 255 :bold true}
                    (get-hl-of-256-color :Bar)))
  (it* "can link to another hl-group with other attributes, but discard the attributes other than those from link"
    (highlight! :Foo {:ctermfg 0 :ctermbg 255 :bold true})
    (highlight! :Bar {:link :Foo :italic true :fg :Blue :ctermbg 1})
    (assert.is_same {:foreground 0 :background 255 :bold true}
                    (get-hl-of-256-color :Bar))
    (assert.is_same {:bold true} (get-hl-of-rgb-color :Bar)))
  (describe* "with its value in bare-kv-table"
    (it* "can set fg/bg in cterm table instead of ctermfg/ctermbg"
      (highlight! :FooBar {:cterm {:fg 0 :bg 255 :bold true}})
      (assert.is_same {:foreground 0 :background 255 :bold true}
                      (get-hl-of-256-color :FooBar))))
  (describe* "whose kv-table value in symbol"
    (it* "can define hl-group with color name"
      (let [foo {:fg :Red :bg :Black :bold true}
            bar {:ctermfg :Red :ctermbg :Black :bold true}
            baz {:fg :Red :bg :Black :bold true :ctermfg :Red :ctermbg :Black}]
        (highlight! :Foo foo)
        (highlight! :Bar bar)
        (highlight! :Baz baz)))
    (it* "can define hl-group with 256-color code"
      (let [foo {:ctermfg 0 :ctermbg 255 :bold true}
            bar {:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255}]
        (highlight! :Foo foo)
        (highlight! :Bar bar)
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Foo))
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Bar))))
    (it* "for gui can define hl-group with color code"
      (let [foobar {:fg "#000000" :bg "#FFFFFF" :bold true}]
        (highlight! :FooBar foobar)
        (assert.is_same {:foreground (hex->decimal "#000000")
                         :background (hex->decimal "#FFFFFF")
                         :bold true}
                        (get-hl-of-rgb-color :FooBar))))
    (it* "can link to another hl-group"
      (let [foo {:ctermfg 0 :ctermbg 255 :bold true}
            bar {:link :Foo}]
        (highlight! :Foo foo)
        (highlight! :Bar bar))
      (assert.is_same {:foreground 0 :background 255 :bold true}
                      (get-hl-of-256-color :Bar)))
    (describe* "with its value in bare-kv-table"
      (it* "cannot set fg/bg in cterm table instead of ctermfg/ctermbg"
        (let [foobar {:cterm {:fg 0 :bg 255 :bold true}}]
          ;; Note: fg/bg in `cterm` table is invalid; instead, use
          ;; ctermfg/ctermbg respectively.
          (assert.has_error #(highlight! :FooBar foobar))))))
  (describe* "whose kv-table value in list"
    (it* "can define hl-group with color name"
      (let [foo #{:fg :Red :bg :Black :bold true}
            bar #{:ctermfg :Red :ctermbg :Black :bold true}
            baz #{:fg :Red :bg :Black :bold true :ctermfg :Red :ctermbg :Black}]
        (highlight! :Foo (foo))
        (highlight! :Bar (bar))
        (highlight! :Baz (baz))))
    (it* "can define hl-group with 256-color code"
      (let [foo #{:ctermfg 0 :ctermbg 255 :bold true}
            bar #{:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255}]
        (highlight! :Foo (foo))
        (highlight! :Bar (bar))
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Foo))
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Bar))))
    (it* "for gui can define hl-group with color code"
      (let [foobar #{:fg "#000000" :bg "#FFFFFF" :bold true}]
        (highlight! :FooBar (foobar))
        (assert.is_same {:foreground (hex->decimal "#000000")
                         :background (hex->decimal "#FFFFFF")
                         :bold true}
                        (get-hl-of-rgb-color :FooBar))))
    (it* "can link to another hl-group"
      (let [foo #{:ctermfg 0 :ctermbg 255 :bold true}
            bar #{:link :Foo}]
        (highlight! :Foo (foo))
        (highlight! :Bar (bar)))
      (assert.is_same {:foreground 0 :background 255 :bold true}
                      (get-hl-of-256-color :Bar)))
    (describe* "with its value in bare-kv-table"
      (it* "cannot set fg/bg in cterm table instead of ctermfg/ctermbg"
        (let [foobar #{:cterm {:fg 0 :bg 255 :bold true}}]
          ;; Note: fg/bg in `cterm` table is invalid; instead, use
          ;; ctermfg/ctermbg respectively.
          (assert.has_error #(highlight! :FooBar (foobar)))))))
  (describe* "(wrapper)"
    ;; TODO: Also test them in the versions < 0.9.0, where `nvim_get_hl` does
    ;; not exist.
    (when vim.api.nvim_get_hl
      (describe* "with predefined-namespace-id"
        (before-each (fn []
                       (vim.api.nvim_set_hl predefined-namespace-id
                                            test-hl-name {})
                       (assert.is_same (vim.empty_dict)
                                       (get-hl predefined-namespace-id
                                               {:name test-hl-name}))))
        (it* "can be embedded in a macro"
          (module-hi! test-hl-name {:ctermfg 0 :ctermbg 255})
          (assert.is_not_same (vim.empty_dict)
                              (get-hl predefined-namespace-id
                                      {:name test-hl-name}))
          (assert.is_same {:ctermfg 0 :ctermbg 255}
                          (get-hl predefined-namespace-id {:name test-hl-name}))))
      (describe* "defined in another file"
        (describe* "with &default-opts"
          (describe* "{: bold true}"
            (it* "creates bold highlight by default"
              (bold-highlight! test-hl-name {:ctermfg 0 :ctermbg 255})
              (assert.is_true (-> (get-hl 0 {:name test-hl-name})
                                  (. :bold))))
            (it* "can remove bold option"
              (bold-highlight! test-hl-name
                               {:ctermfg 0 :ctermbg 255 :bold false})
              (assert.is_falsy (-> (get-hl 0 {:name test-hl-name})
                                   (. :bold))))))))))
