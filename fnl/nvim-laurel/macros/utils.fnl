;; Predicate ///1
(lambda nil? [x]
  "Check if value of 'x' is nil."
  `(= nil ,x))

(lambda bool? [x]
  "Check if 'x' is of boolean type."
  `(= :boolean (type ,x)))

(lambda str? [x]
  "Check if `x` is of string type."
  `(= :string (type ,x)))

(lambda fn? [x]
  "(Runtime time) Check if type of `x` is function."
  `(= :function (type ,x)))

(lambda num? [x]
  "Check if 'x' is of number type."
  `(= :number (type ,x)))

(lambda seq? [x]
  "Check if `x` is a sequence."
  `(not (nil? (. ,x 1))))

(lambda tbl? [x]
  "Check if `x` is of table type.
  table?, sequence?, etc., is only available in compile time."
  `(= (type ,x) :table))

;; Decision ///1
(lambda when-not [cond ...]
  `(when (not ,cond)
     ,...))

(lambda if-not [cond ...]
  `(if (not ,cond)
       ,...))

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

{: when-not
 : if-not
 : nil?
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
