(import-macros {: highlight!} :nvim-laurel.macros)

(macro get-hl-of-rgb-color [name]
  `(vim.api.nvim_get_hl_by_name ,name true))

(macro get-hl-of-256-color [name]
  `(vim.api.nvim_get_hl_by_name ,name false))

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

(describe :highlight!
  (fn []
    (it "can define hl-group with color name"
      (fn []
        (highlight! :Foo {:fg :Red :bg :Black :bold true})
        (highlight! :Bar {:ctermfg :Red :ctermbg :Black :bold true})
        (highlight! :Baz {:fg :Red
                          :bg :Black
                          :bold true
                          :ctermfg :Red
                          :ctermbg :Black})))
    (it "can define hl-group with 256-color code"
      (fn []
        (highlight! :Foo {:ctermfg 0 :ctermbg 255 :bold true})
        (highlight! :Bar {:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255})
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Foo))
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Bar))))
    (it "for gui can define hl-group with color code"
      (fn []
        (highlight! :FooBar {:fg "#000000" :bg "#FFFFFF" :bold true})
        (assert.is_same {:foreground (hex->decimal "#000000")
                         :background (hex->decimal "#FFFFFF")
                         :bold true}
                        (get-hl-of-rgb-color :FooBar))))
    (it "can link to another hl-group"
      (fn []
        (highlight! :Foo {:ctermfg 0 :ctermbg 255 :bold true})
        (highlight! :Bar {:link :Foo})
        (assert.is_same {:foreground 0 :background 255 :bold true}
                        (get-hl-of-256-color :Bar))))
    (describe "with its value in bare-kv-table"
      (fn []
        (it "can set fg/bg in cterm table instead of ctermfg/ctermbg"
          (fn []
            (highlight! :FooBar {:cterm {:fg 0 :bg 255 :bold true}})
            (assert.is_same {:foreground 0 :background 255 :bold true}
                            (get-hl-of-256-color :FooBar))))))
    (describe "whose kv-table value in symbol"
      (it "can define hl-group with color name"
        (fn []
          (let [foo {:fg :Red :bg :Black :bold true}
                bar {:ctermfg :Red :ctermbg :Black :bold true}
                baz {:fg :Red
                     :bg :Black
                     :bold true
                     :ctermfg :Red
                     :ctermbg :Black}]
            (highlight! :Foo foo)
            (highlight! :Bar bar)
            (highlight! :Baz baz))))
      (it "can define hl-group with 256-color code"
        (fn []
          (let [foo {:ctermfg 0 :ctermbg 255 :bold true}
                bar {:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255}]
            (highlight! :Foo foo)
            (highlight! :Bar bar)
            (assert.is_same {:foreground 0 :background 255 :bold true}
                            (get-hl-of-256-color :Foo))
            (assert.is_same {:foreground 0 :background 255 :bold true}
                            (get-hl-of-256-color :Bar)))))
      (it "for gui can define hl-group with color code"
        (fn []
          (let [foobar {:fg "#000000" :bg "#FFFFFF" :bold true}]
            (highlight! :FooBar foobar)
            (assert.is_same {:foreground (hex->decimal "#000000")
                             :background (hex->decimal "#FFFFFF")
                             :bold true}
                            (get-hl-of-rgb-color :FooBar)))))
      (it "can link to another hl-group"
        (fn []
          (let [foo {:ctermfg 0 :ctermbg 255 :bold true}
                bar {:link :Foo}]
            (highlight! :Foo foo)
            (highlight! :Bar bar))
          (assert.is_same {:foreground 0 :background 255 :bold true}
                          (get-hl-of-256-color :Bar))))
      (describe "with its value in bare-kv-table"
        (fn []
          (it "cannot set fg/bg in cterm table instead of ctermfg/ctermbg"
            (fn []
              (let [foobar {:cterm {:fg 0 :bg 255 :bold true}}]
                ;; Note: fg/bg in `cterm` table is invalid; instead, use
                ;; ctermfg/ctermbg respectively.
                (assert.has_error #(highlight! :FooBar foobar))))))))
    (describe "whose kv-table value in list"
      (it "can define hl-group with color name"
        (fn []
          (let [foo #{:fg :Red :bg :Black :bold true}
                bar #{:ctermfg :Red :ctermbg :Black :bold true}
                baz #{:fg :Red
                      :bg :Black
                      :bold true
                      :ctermfg :Red
                      :ctermbg :Black}]
            (highlight! :Foo (foo))
            (highlight! :Bar (bar))
            (highlight! :Baz (baz)))))
      (it "can define hl-group with 256-color code"
        (fn []
          (let [foo #{:ctermfg 0 :ctermbg 255 :bold true}
                bar #{:fg 0 :bg 255 :bold true :ctermfg 0 :ctermbg 255}]
            (highlight! :Foo (foo))
            (highlight! :Bar (bar))
            (assert.is_same {:foreground 0 :background 255 :bold true}
                            (get-hl-of-256-color :Foo))
            (assert.is_same {:foreground 0 :background 255 :bold true}
                            (get-hl-of-256-color :Bar)))))
      (it "for gui can define hl-group with color code"
        (fn []
          (let [foobar #{:fg "#000000" :bg "#FFFFFF" :bold true}]
            (highlight! :FooBar (foobar))
            (assert.is_same {:foreground (hex->decimal "#000000")
                             :background (hex->decimal "#FFFFFF")
                             :bold true}
                            (get-hl-of-rgb-color :FooBar)))))
      (it "can link to another hl-group"
        (fn []
          (let [foo #{:ctermfg 0 :ctermbg 255 :bold true}
                bar #{:link :Foo}]
            (highlight! :Foo (foo))
            (highlight! :Bar (bar)))
          (assert.is_same {:foreground 0 :background 255 :bold true}
                          (get-hl-of-256-color :Bar))))
      (describe "with its value in bare-kv-table"
        (fn []
          (it "cannot set fg/bg in cterm table instead of ctermfg/ctermbg"
            (fn []
              (let [foobar #{:cterm {:fg 0 :bg 255 :bold true}}]
                ;; Note: fg/bg in `cterm` table is invalid; instead, use
                ;; ctermfg/ctermbg respectively.
                (assert.has_error #(highlight! :FooBar (foobar)))))))))))
