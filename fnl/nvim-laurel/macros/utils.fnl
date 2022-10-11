;; Predicate ///1
(lambda nil? [x]
  "checks if value of 'x' is nil."
  `(= nil ,x))

(lambda bool? [x]
  "checks if 'x' is of boolean type."
  `(= :boolean (type ,x)))

(lambda str? [x]
  "Check if `x` is of string type."
  `(= :string (type ,x)))

(lambda num? [x]
  "checks if 'x' is of number type."
  `(= :number (type ,x)))

(lambda odd? [x]
  "checks if 'x' is mathematically of odd parity ;}"
  `(and ,(num? x) (= 1 (% ,x 2))))

(lambda even? [x]
  "checks if 'x' is mathematically of even parity ;}"
  `(and ,(num? x) (= 0 (% ,x 2))))

(lambda fn? [x]
  "Check if type of `x` is function."
  (let [ref `(?. ,x 1 1)]
    `(contains? [:fn :hashfn :lambda :partial] ,ref)))

(lambda quote? [x]
  (let [ref `(?. ,x 1 1)]
    `(= ,ref :quote)))

(lambda seq? [x]
  "Check if `x` is a sequence."
  `(not (nil? (. ,x 1))))

(lambda tbl? [x]
  ;; Note: table?, sequence?, etc. only available in macro.
  `(= (type ,x) :table))

(lambda empty? [tbl]
  "checks if 'tbl' is empty."
  (if (tbl? tbl)
      `(not (next ,tbl))
      (error (: "expected table, got %s: %s" :format (type tbl) (view tbl)))))

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
  `(?. ,xs 1))

(lambda second [xs]
  `(?. ,xs 2))

(lambda last [xs]
  `(?. ,xs ,(length xs)))

(lambda slice [xs ?first ?last ?step]
  `(fcollect [i# (or ,?first 1) (or ,?last (length ,xs) (or ,?step 1))]
             (. ,xs i#)))

;; Type Conversion ///1
(lambda ->str [x]
  `(tostring ,x))

(lambda ->num [x]
  `(tonumber ,x))

;; Debug ///1
(lambda notify! [x ?level]
  (let [msg (view x)]
    `(vim.notify ,msg ,?level)))

(lambda warn! [x]
  (notify! x _G.vim.levels.WARN))

(lambda error! [x]
  (notify! x _G.vim.levels.ERROR))

;; Lua ///1
(lambda get-script-path []
  `(: ;
      (. (debug.getinfo 1 :S) :source) ;
      :match "@?(.*)"))

;; Export ///1

{: warn!
 : error!
 : when-not
 : if-not
 : nil?
 : bool?
 : str?
 : num?
 : odd?
 : even?
 : fn?
 : quote?
 : seq?
 : tbl?
 : empty?
 : ->str
 : ->num
 : inc
 : dec
 : ++
 : --
 : first
 : second
 : last
 : slice
 : get-script-path}

;; vim:fdm=marker:foldmarker=///,"""
