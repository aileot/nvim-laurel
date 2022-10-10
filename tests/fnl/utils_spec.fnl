(import-macros {: contains? : ++ : --} :nvim-laurel.macros.utils)

(describe :utils ;
          (fn []
            (describe "++"
                      (fn []
                        (it "increments a number by 1"
                            (fn []
                              (var x 1)
                              (++ x)
                              (assert.is.same 2 x)))))
            (describe "--"
                      (fn []
                        (it "decrements a number by 1"
                            (fn []
                              (var x 1)
                              (-- x)
                              (assert.is.same 0 x)))))
            ;; (describe :any?
            ;;           (fn []
            ;;             (it "returns true if any of the elements returns true with the predicate"
            ;;                 #(let [pred #(< 0 $)]
            ;;                    (assert.is_true (any? pred [1 2 3 4]))))
            ;;             (it "returns true if any the elements returns true with the predicate"
            ;;                 #(let [pred #(< 0 $)]
            ;;                    (assert.is_true (any? pred [0 1 2 3]))))
            ;;             (it "returns false if none of the elements returns true with the predicate"
            ;;                 #(let [pred #(< 0 $)]
            ;;                    (assert.is_false (any? pred [0 -1 -2 -3]))))))
            ;; (describe :all?
            ;;           (fn []
            ;;             (it "returns true if all the elements returns true with the predicate"
            ;;                 #(let [pred #(< 0 $)]
            ;;                    (assert (= true (all? pred [1 2 3 4])))))
            ;;             (it "returns false if any of the elements returns false with the predicate"
            ;;                 #(let [pred #(< 0 $)]
            ;;                    (assert.is_false (all? pred [0 1 2 3]))))))
            (describe :contains?
                      (fn []
                        (it "returns true if x is in xs."
                            (fn []
                              (assert.is_true (contains? [:a :b :c] :a))
                              (assert.is_true (contains? [:a :b :c] :b))
                              (assert.is_true (contains? [:a :b :c] :c))))
                        (it "returns false if x is not in xs."
                            #(assert.is_false (contains? [:a :b :c] :z)))))))
