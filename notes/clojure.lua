local s, spec = {}, {}

-- none if this is meant to be run, just playing with apis

---[[
---learnings:
---
---need a name in some way - using debug seems hacky... and won't work for conform
---]]
describe("what is a spec", function()
	it("creating specs", function()
		local s = spec:ns "create a namespace"

		-- if we use vars
		local s_even = s:def(s.all { s.int, s.fn(function(_) return _ % 2 == 2 end) }) -- we can use functions.
		s_even = s:def(s.all { s.int, s.fn "_ % 2 == 0" }) -- here we have a shorthand predicate
		local s_is_big_even = s:def(s.all { s_even, s.fn.gt(100) })
		s.explain(s_is_big_even, 88)
		-- failed: <spec_name> for <input>; details <spec_path> for <input path>
		-- failed: s.fn.gt(100) for 88; details s_is_big_even > gt 100 for 88)
		-- XXX how do we get the names and debug value?? would need to use debug shenanigans

		-- if we use name params
		s_even = s:def("even", s.all { s.int, s.fn "_ % 2 == 0" }) -- here we have a shorthand predicate
		s_is_big_even = s:def("is_big_even", s.all { s_even, s.fn.gt(100) })
		s.explain(s_is_big_even, 88)
		-- failed: fn.gt(100) for 88; details is_big_even > gt 100 for 88)

		-- with optional error message, a pipeline could use it's message, overridig any lower level
		s_even = s:def("even", s.all { s.int, s.fn "_ % 2 == 0" }, { msg = "value was not an even integer" })
		-- s_even = s:def("even", s.all { s.int, s.fn("_ % 2 == 0", "not even") }) -- or in fn
		s_is_big_even = s:def("is_big_even", s.all { s_even, s.fn.gt(100) })
		s.explain(s_is_big_even, -3)
		-- failed: is_big_even value was not an even integer at is_big_even.even

		s_is_big_even = s:def("is_big_even", s.all { s_even, s.fn.gt(100) }, { msg = "not big even" })
		s.explain(s_is_big_even, -3)
		-- failed: is_big_even not big even at is_big_even.even

		-- shoulw we transform?
		-- I don't think so as these can't be generated
		local s_email = s:def(
			"email",
			s.all {
				s.str,
				s.fn.trim(),
				s.fn.reg "%w+@%w.com",
				s.fn.ends_with "gmail.com",
			}
		)
	end)

	it("using function spec", function()
		local s = spec:ns "name"
		s:def("big", s.fn.gt(1000)) -- easy to use show in explain as we can write an implementation
		s:def("big", function(_) return _ > 100 end) -- like this we create a blackbox, but maybe that's ok
		s:def("big", s.fn(function(_) return _ > 100 end, "is not big")) -- like this we give ourselves more room
	end)

	it("using conform", function()
		local s = spec:ns "create a namespace"
		local A = { __tag = "A", a = 1 }
		local B = { __tag = "B", b = "hi" }
		local s_A, s_B = s.def("A", "...blah"), s.def("B", "...blah")
		local s_str_or_num = s:def("a or b", s.union { s_A, s_B })
		s.conform(s_str_or_num, { A, A, B })
		-- { {  }, { str = 'a' }, { num = 2} }
		s_str_or_num = s:def("str_or_num", s.union { s.int, s.str })
	end)

	it("specing a function", function()
		--- can we spec an existing func?
		--- needs to allow generating types
		--- needs to allow generation
		local s = spec:ns "name"
		local function f(some_string, some_int) end

		--probably just have to create a new one, wrapping the old
		local spec_f = s:fdef {
			args = { s.str, s.int },
			ret = { s.int },
			impl = f,
		}

		local fn = s:fdef {
			args = { s.str, s.int },
			ret = { s.int },
			impl = function(str, int) return 33 end,
		}
		fn = s:fdef {
			"some doc string",
			args = { s.str, s.int },
			ret = { s.int },
			function(str, int) return 33 end,
		}
		fn = s:fdef():args({ s.str, s.int }):ret({ s.int }):impl(function(str, int) return 33 end)
		fn = s:fdef "|str, int->int| tonumber($1) + $2" -- could have a string syntax
		fn = s
			:fdef() --
			:args({ s.str, s.int })
			:ret({ s.int })
			:impl(function(str, int) return 33 end)

		f "" -- error
		spec_f "" -- spec failure
		-- s/gen
		-- s/excercise
		-- s/instrument

		local range = s:fdef {
			"return a value between start..end",
			args = { s.int, s.int },
			ret = { s.int },
			-- here we can run a validation function on the returned value
			-- there might be a good reason to define this in terms of specs, but I can't think of one right now
			-- drawback of using a spec is we need to access args and ret
			fn = function(args, ret) return args[1] < ret and args[2] > ret end,
			impl = function(args, ret)
				return --[[function that does the work]]
			end,
		}

		-- ideas of what the table options might be
		---@class fdef
		---@field args? specs[]
		---@field ret? specs[]
		---@field fn? function # checks return spec
		---@field impl? function # code
		---@field pub? boolean # turns on instrumentation
		---@field instrument? { sample: number } # more granular control of instrumentation
	end)

	it("def", function()
		-- def creates a spec
		-- simple as a name and a predicate
		s:def("always_valid", function() return true end)
		s:def("never_valid", function() return false end)

		---@class Opts
		---@field gen function # generator function to override the builtin one
		---@field msg string # error string to show instea of generated one
		local opts = {}

		-- optional opts
		s:def("never_valid", function() return false end, opts)

		s:def("always_valid", function() return true end)
	end)

	--[[
	--a generator is a factory function that takes no arguments
	--s/gen produces such a factory
	--gen/string is an example of a builtin factory that creates strings
	--gen/generate runs a generator
	--]]
	it("gen", function()
		-- gen tries 100 times
		local gen = require "spec.gen"
		local s = spec:ns "name"

		gen.generate(s:gen(s.int)) -- 23
		gen.sample(s:gen(s.int)) -- { 1 2 4 55 23 }

		-- gens can be built out of specs
		local g = s:gen(s:all { s.int, s.even })
		g = s:gen(s:all { s.int, s.fn.gt(0) })

		-- but you could make a generator to unlikely
		g = s:gen(s:all { s.float, s.fn.gt(1.23334), s.fn.lt(1.28323) }) -- only tried 100 times and will fail if no match

		-- in clojure you add a generator to a spec to narrow it down
		s:def("small int", s.with_gen(s.all { s.int, s.fn.lt(5) }, s:gen(s.seq_of { 1, 2, 3, 4 }))) -- from spec
		s:def("small int", s.with_gen(s.all { s.int, s.fn.lt(5) }, s.gen(function() return math.random(1, 4) end))) -- or with function, as a spec is just a function
		s:def("small int", s.with_gen(s.all { s.int, s.fn.lt(5) }, s:gen(s.seq_of { 1, 2, 3, 4 })))
		gen.sample(s:gen "small int") -- { 1 1 2 1 2 2 2 1 }

		--- XXX:
		--  perhaps this could just be an option to the spec
		--  means you can't create an inline spec with a generator, not sure if this is an issue
		s:def("small int", s.with_gen(s.all { s.int, s.fn.lt(5) }, s:gen(s.seq_of { 1, 2, 3, 4 })))
		-- vs
		s:def("small int", s.all { s.int, s.fn.lt(5) }, { gen = s.seq_of { 1, 2, 3, 4 } })

		-- gens can't be nested, so we have gen/fmap to create a function and a generator
		--
		-- (def kw-gen-3 (gen/fmap #(keyword "my.domain" %)
		--              (gen/such-that #(not= % "")
		--                (gen/string-alphanumeric))))
		s:def(
			"kw-gen-3",
			gen.fmap(function(a) return "my.d" .. a end, gen.such_that(function(arg) return arg ~= "" end, gen.string))
		)
		s:def(
			"kw-gen-3",
			gen.fmap(
				function(a) return "my.d" .. a end,
				gen.pipe(gen.string, gen.such_that(function(arg) return arg ~= "" end))
			)
		)
		-- shorthand, but this doesn't inspire confidence
		s:def("kw-gen-3", gen.fmap(s.fn "'my.d' .. _", gen.pipe(gen.string, gen.such_that "_ ~= ''")))

		-- gen such that could probably be renamed to assert, and likely just `error`s if false
		s.gen(function(str) return "my " .. str end, gen.assert(function(a) return a ~= "" end, gen.string))

		-- OR if we just flip these args, now we have our no argument function, and the rest are fns to call - which is basically now a pipe
		s.gen(gen.string, function(str) return "my " .. str end)
		s.gen(
			gen.tuple { gen.string, gen.such_that(s.not_ "", gen.alpha) },
			function(str, alpha) return "my " .. str .. alpha end
		)

		-- i think this can only be understood with an implementation, but seems quite open to change
	end)

	it("instrument", function()
		-- (stest/instrument `ranged-rand) -- this does the magic of testing args always called (i.e turns on :args specs)
		-- (stest/instrument-full `ranged-rand) -- this doesn't exist, but i wonder if want this for internal use (i.e turns on :ret and :fn specs)
		--
		-- (stest/instrument `invoke-service {:stub #{`invoke-service}}) -- this replaces the implementation with generated stuff
		--
		-- (stest/check `ranged-rand) -- generates test data and runs the function
		-- which i think is just calling (s/exercise-fn `ranged-rand) but wrapped for tests
		--
		-- (-> (stest/enumerate-namespace 'user) stest/check)
	end)
end)

--[[
-- if strictly following clojure, conform destructures
-- conformed values are grouped by their spec
--
-- this means for maps, the result appears unchanged
--
-- in the case of sequences or unions, the values are given the symbol from the spec
-- (s/conform (s/coll-of ::n-or-s) [1 "hi" 3]) ;=> [[:n 1] [:s "hi"] [:n 3]]
--
-- trying to explore how that would feel in lua
--
-- XXX:
-- make consumption as ergonmic/typesafe as possible without compromising
-- performance (or at least giving an out)
--
-- what must the api do to not paint me in a corner
--
-- I think primitives may have to be marshalled into structs
--]]
describe("conform api exploration", function()
	it("conform?", function()
		local s = spec.ns "my space"
		s:def("string_or_int", s.union { s.int, s.string })

		s:is_valid(s.list "string_or_int", { 4, 3, "foo" }) -- true
		s:is_valid(s.list(s.union { s.string, s.positive }), { 4, 3, "foo" }) -- true

		assert.are.same(s:conform(s.list "string_or_int", { 4, 3, "foo" }), {
			{ int = 4 },
			{ int = 3 },
			{ string = "foo" },
		})
		-- by ref
		assert.are.same(s:conform(s.list "string_or_int", { 4, 3, "foo" }), {
			{ [s.int] = 4 },
			{ [s.int] = 3 },
			{ [s.string] = "foo" },
		})
		-- or by tuple ref (which may be slightly faster)
		assert.are.same(s:conform(s.list "string_or_int", { 4, 3, "foo" }), {
			{ s.int, 4 },
			{ s.int, 3 },
			{ s.string, "foo" },
		})

		-- marshalled for consistency
		assert.are.same(s:conform(s.list "string_or_int", { 4, 3, "foo" }), {
			{ __tag = "int", val = 4 },
			{ __tag = "int", val = 3 },
			{ __tag = "str", val = "foo" },
		})
	end)

	it("explore conform", function()
		---@type ( { int: number? } | { string: string? } )[]
		local conformed = nil -- { { int = 4 }, { int = 3 }, { string = "foo" } }
		local conformed_ref = { { [s.int] = 4 }, { [s.int] = 3 }, { [s.string] = "foo" } }
		local conformed_tup_ref = { { s.int, 4 }, { s.int, 3 }, { s.string, "foo" } }

		for _, c in ipairs(conformed) do
			-- c.string
			if c.int then
				print("int!", c.int)
			elseif c.string then
				print("string!", c.string)
			else
				print "oh dear"
			end
		end

		for _, c in ipairs(conformed_ref) do
			-- can we do something more interesting??
			local int, str = c[s.int], c[s.string]
			if int then print("int!", c.int) end
			if str then print("string!", c.string) end
		end

		for _, c in ipairs(conformed_tup_ref) do
			-- this is awful and would need casting inside condition as we
			-- don't have type narrowing between different values
			local t, v = unpack(c)
			if t == s.int then
				print("int!", v)
			elseif t == s.string then
				print("string!", v)
			else
				print "oh dear"
			end
		end

		for _, c in ipairs(conformed) do
			s
				.str_or_int(c) -- spec can be called... doesn't make sense
				:with_int(function(int) print "int" end)
				:with_str(function(str) print "str" end)
		end

		-- could create a match and then reuse
		-- INFO: needs to be based on the spec, not the value, that way
		-- functions can be set outside of loops
		local match_fn = s.str_or_int {
			int = function(int) print "int" end,
			str = function(str) print "str" end,
		}
		match_fn = s.match(s.str_or_int, {
			int = function(int) print "int" end,
			str = function(str) print "str" end,
			-- can this be exhaustive?
		})
		for _, c in ipairs(conformed) do
			match_fn(c)
		end
	end)

	it("explore conform complex", function()
		local s = spec.ns "my space"
		---@class A
		---@field _tag 'A'
		---@field a string
		---@class B
		---@field _tag 'B'
		---@field b number

		s:def("A", s.record { _tag = "A", a = s.string })
		s:def("B", s.record { _tag = "B", b = s.number })
		s:def("A_or_B", s.union { s.A, s.B })

		---@type ( A | B )[]
		local conformed = s:conform(s.list(s.A_or_B), {})

		for _, c in ipairs(conformed) do
			if c._tag == "A" then print(c.a) end
		end
	end)
	it("conform as parse", function()
		s:def("positive", s.all { s.int, s.fn.gt(0) })
		s:def("A", s.keys { a = s.string }) -- key will be from the predicate 'positive'
		s:def("B", s.keys { s.positive })
		s:def("A_or_B", s.union { s.A, s.B })

		assert.are.same(
			s.conform(s.list "A_or_B", { { a = "hello" }, { b = 44 } }),
			{ { __tag = "A", a = "hello" }, { __tag = "B", b = 44 } }
		)
	end)
end)
