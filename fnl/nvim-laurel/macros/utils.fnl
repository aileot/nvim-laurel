;; Predicate ///1
(fn nil? [x]
  "Check if value of 'x' is nil."
  `(= nil ,x))

(fn bool? [x]
  "Check if 'x' is of boolean type."
  `(= :boolean (type ,x)))

(fn str? [x]
  "Check if `x` is of string type."
  `(= :string (type ,x)))

(fn fn? [x]
  "(Runtime time) Check if type of `x` is function."
  `(= :function (type ,x)))

(fn num? [x]
  "Check if 'x' is of number type."
  `(= :number (type ,x)))

(fn seq? [x]
  "Check if `x` is a sequence."
  `(not (nil? (. ,x 1))))

(fn tbl? [x]
  "Check if `x` is of table type.
  table?, sequence?, etc., is only available in compile time."
  `(= (type ,x) :table))

;; Number ///1
(lambda inc [x]
  "Return incremented result"
  `(+ ,x 1))

(lambda dec [x]
  "Return decremented result"
  `(- ,x 1))

(lambda ++ [x]
  "Increment `x` by 1"
  `(do
     (set ,x ,(inc x))
     ,x))

(lambda -- [x]
  "Decrement `x` by 1"
  `(do
     (set ,x ,(dec x))
     ,x))

;; Table ///1
(lambda first [xs]
  `(. ,xs 1))

(lambda second [xs]
  `(. ,xs 2))

(lambda last [xs]
  `(. ,xs ,(length xs)))

;; Type Conversion ///1
(lambda ->str [x]
  `(tostring ,x))

(lambda ->num [x]
  `(tonumber ,x))

;; Export ///1

{: nil?
 : bool?
 : str?
 : num?
 : fn?
 : seq?
 : tbl?
 : ->str
 : ->num
 : inc
 : dec
 : ++
 : --
 : first
 : second
 : last}

;; vim:fdm=marker:foldmarker=///,"""
