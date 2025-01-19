# clojure spec

[Why spec](https://clojure.org/about/spec)
[Docs](https://clojure.org/guides/spec)

spec is amazing, to paraphrase the 'why spec' docs, along with my thoughts on how this pairs with neovim

> Docs are not enough

> We routinely deal with optional and partial data, data produced by unreliable external sources, dynamic queries etc.

> Manual parsing and error reporting is not good enough

> in all languages, dynamic or not, tests are essential to quality. Too many critical properties are not captured by common type systems. But manual testing has a very low effectiveness/effort ratio. Property-based, generative testing, as implemented for Clojure in test.check, has proved to be far more powerful than manually written tests.

## Example in clojure

```clj
; here we have a function that takes in two args, and labels them a and b, it then adds them and returns the result
(defn add-bigger [a b] (+ a b))

; now we 'def'ine some specs using things in the spec namespace, aliased here to `s`.
(s/def ::positive (s/and int? #(> % 0)))

;; if you don't know clojure or spec, here it is again with some explanation
(s/def ::positive ; first comes the label (which is clj is a globally unique thanks to namespaces), this will be put in the global registry
		(s/and ; this spec will have multiple conditions
			int? ; the value must be an integer, `int?` is a spec builtin
			#(> % 0))) ; shorthand anonymous function where `%` is a placeholder for the argument
						; fully expanded would be (def anonymous_1 [x] (> x 0))

; now we can check if something is valid
(s/valid? ::positive 1) ; => true
(s/valid? ::positive 1.0) ; => false
(s/valid? ::positive -2) ; => false


; specs can be applied to a function (which was already defined)
; here we define specs for the args, return value, and an fn to run against the returned value.
; fn is basically a unit test written inline
(s/fdef add-bigger
; here we are saying start and end must be ::positive, which will use our spec from earlier
; start must be bigger than end
  :args (s/and (s/cat :start ::positive :end ::positive)
         #(> (:start %) (:end %)))
  :ret ::positive
  :fn #(=
       	(+ (-> % :args :start) (-> % :args :end))
       	(:ret %)))

(add-bigger 10 5) ;=> 15
(add-bigger 5 10) ;=> 15 WAIT! that should have failed our spec!

; by default specs are off, so we have to turn them on
(stest/instrument `add-bigger)
(add-bigger 5 10) ;=> :failure - and some info about the failure
```

## interesting parts

```clj
(s/valid? even? 10)
;;=> true
(s/valid? (s/nilable string?) nil)
;;=> true

(doc :order/date)
; -------------------------
; :order/date
; Spec
;   inst?

(s/conform even? 1000)
;;=> 1000

(s/def :domain/name-or-id (s/or :name string?
                                :id   int?))

; conform is more interesting if a label is used, as now the returned items are 'destructured' and available via their labels
(s/conform :domain/name-or-id "abc")
;;=> [:name "abc"]
(s/conform :domain/name-or-id 100)
;;=> [:id 100]

(s/explain :deck/suit 42)
;; 42 - failed: #{:spade :heart :diamond :club} spec: :deck/suit
(s/explain :num/big-even 5)
;; 5 - failed: even? spec: :num/big-even
(s/explain :domain/name-or-id :foo)
;; :foo - failed: string? at: [:name] spec: :domain/name-or-id
;; :foo - failed: int? at: [:id] spec: :domain/name-or-id

(gen/generate (s/gen int?))
;;=> -959
(gen/sample (s/gen string?))
;;=> ("" "" "" "" "8" "W" "" "G74SmCm" "K9sL9" "82vC")

(s/exercise (s/cat :k keyword? :ns (s/+ number?)) 5)
;;=>
;;([(:y -2.0) {:k :y, :ns [-2.0]}]
;; [(:_/? -1.0 0.5) {:k :_/?, :ns [-1.0 0.5]}]
;; [(:-B 0 3.0) {:k :-B, :ns [0 3.0]}]
;; [(:-!.gD*/W+ -3 3.0 3.75) {:k :-!.gD*/W+, :ns [-3 3.0 3.75]}]
;; [(:_Y*+._?q-H/-3* 0 1.25 1.5) {:k :_Y*+._?q-H/-3*, :ns [0 1.25 1.5]}])

(s/exercise-fn `ranged-rand) ; gives back inputs and the outputs, based on gen/sample
;; =>
;; ([(-2 -1)   -2]
;;  ...
;;  [(-1 1)    -1]
;;  [(0 65)     7])

(stest/instrument `ranged-rand)
(stest/check `ranged-rand)

; To test all of the spec’ed functions in a namespace (or multiple namespaces),
; use enumerate-namespace to generate the set of symbols naming vars in the
; namespace:
(-> (stest/enumerate-namespace 'user) stest/check)

(stest/instrument `invoke-service {:stub #{`invoke-service}})

;; builtins
(lazy-prims any any-printable boolean bytes char char-alpha char-alphanumeric char-ascii double
            int keyword keyword-ns large-integer ratio simple-type simple-type-printable
            string string-ascii string-alphanumeric symbol symbol-ns uuid)
```

## error struct

https://clojure.org/guides/spec#_explain

```clj
(s/def ::n number?)
(s/def ::s string?)
(s/def ::n-or-s (s/or :n ::n :s ::s))

(s/explain-data ::n "")  ; "\"\" - failed: number? spec: :clj.core/n\n"
; #:clojure.spec.alpha{:problems
;                      [{:path [],
;                        :pred clojure.core/number?,
;                        :val "",
;                        :via [:clj.core/n],
;                        :in []}],
;                      :spec :clj.core/n,
;                      :value ""}

(s/explain-str ::n-or-s [])
; "[] - failed: number? at: [:n] spec: :clj.core/n
;  [] - failed: string? at: [:s] spec: :clj.core/s"

(s/explain-data ::n-or-s [])
; #:clojure.spec.alpha{:problems
;                      ({:path [:n],
;                        :pred clojure.core/number?,
;                        :val [],
;                        :via [:clj.core/n-or-s :clj.core/n],
;                        :in []}
;                       {:path [:s],
;                        :pred clojure.core/string?,
;                        :val [],
;                        :via [:clj.core/n-or-s :clj.core/s],
;                        :in []}),
;                      :spec :clj.core/n-or-s,
;                      :value []}

(s/def ::foo (s/keys :req [::n ::s]))

(s/explain-data ::foo {::n "hhh" ::s "hey"})
; #:clojure.spec.alpha{:problems
;                      ({:path [:clj.core/n],
;                        :pred clojure.core/number?,
;                        :val "hhh",
;                        :via [:clj.core/foo :clj.core/n],
;                        :in [:clj.core/n]}),
;                      :spec :clj.core/foo,
;                      :value #:clj.core{:n "hhh", :s "hey"}}


```

## how this could work in lua

most lives in [ here ](./clojure.lua)
