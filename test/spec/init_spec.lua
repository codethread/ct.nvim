-- local test = require "test.utils.test" -- XXX: move to init

--#region
local ok, not_ok = assert.is_true, assert.is_false
local oks = function(tbl)
	for _, tb in ipairs(tbl) do
		ok(tb)
	end
end
local not_oks = function(tbl)
	for _, tb in ipairs(tbl) do
		not_ok(tb)
	end
end

local spec = require "spec"
---@param opts? Spec.NamespaceOpts
local setup = function(opts) return spec.ns("" .. math.random(), opts or {}) end
local function is_the_anwser(val) return val == 42 end
--#endregion

describe("Spec", function()
	describe("namespaces", function()
		it("should fail", function() assert.has_error(spec.ns) end)

		it("should fail if not set", function()
			---@diagnostic disable-next-line: missing-parameter
			assert.has_error(function() spec.ns "foo" end)
		end)

		it("should create a namespace and retrieve it", function()
			local s = spec.ns("foo", {})
			assert.are_equal(s, spec.ns "foo")
		end)

		it("should scope specs to the ns but share prototypes", function()
			local s = spec.ns("foo", {})
			local s2 = spec.ns("bar", {})
			assert.are_equal(s.is_valid, s2.is_valid)
		end)
	end)

	describe("namespace opts", function()
		it("should allow duplicate if set", function()
			local s, k = setup { on_key_clash = "ignore" }
			s:def(k.dupe, s:spec(is_the_anwser))
			s:def(k.dupe, s:spec(is_the_anwser))
		end)
	end)

	pending("builtins", function()
		for _, test in ipairs {
			{ "int", 3, true },
			{ "int", 1.1, false },
			{ "int", nil, false },
			{ "int?", 3, true },
			{ "int?", 1.1, false },
			{ "int?", nil, true },
		} do
			local builtin, input, output = test[1], test[2], test[3]
			it(
				string.format("should validate builtin %s with value %s valid=%s", builtin, input or "nil", output),
				function()
					local s = setup()
					assert(s:is_valid("" .. builtin, input) == output)
				end
			)
		end
	end)

	describe("s:spec", function()
		it("should create a spec", function()
			local s = setup()
			assert.is_true(s:is_valid(s:spec(is_the_anwser), 42))
			assert.is_false(s:is_valid(s:spec(is_the_anwser), 22))
		end)
	end)

	describe("s:explain", function()
		it("should print out error", function()
			local s, k = setup()

			local err = "oh dear"
			assert.are_same(s:explain_str(s:spec(is_the_anwser), 42), "Success\n")
			assert.are_equal(s:explain_str(s:spec(function() return false, err end), ""), err)
		end)
	end)

	describe("s:def", function()
		it("should error on duplicate", function()
			local s, k = spec.ns("s:def", {})

			-- XXX: here's how to add a type to keys, ideally this could be generated
			-- more importantly than just nice autcomplete, this gives go-to-def
			--
			---@class Spec.Keys
			---@field answer Spec.Key # Hello ansert
			s:def(k.answer, s:spec(is_the_anwser))
			assert.has_error(function() s:def(k.answer, s:spec(is_the_anwser)) end)
		end)

		it("should create a spec", function()
			local s, k = setup()
			s:def(k.answer, s:spec(is_the_anwser))
			assert.is_true(s:is_valid(k.answer, 42))
			assert.is_false(s:is_valid(k.answer, 3.4))
		end)
	end)

	pending("s:and_", function()
		it("should AND all specs", function()
			local s = setup()
			s:def("positive", s:spec(function(x) return x > 0 or x == 0 end))
			assert.is_true(s:is_valid(s:and_ { "int", "positive" }, 44))
			assert.is_false(s:is_valid(s:and_ { "int", "positive" }, -4))
		end)
	end)

	-- describe("s:fspec", function()
	-- 	it("should create a higher order spec", function()
	-- 		local s = setup()
	-- 		s:fspec({
	-- 			args = { "int" },
	-- 			ret = { "int" },
	-- 		}, s:spec(function(o) return o.args[1] * 2 == o.ret[1] end))
	-- 	end)
	-- end)
end)

-- do
-- 	test.test_each("Spec is_valid validates a spec", {
-- 		{ spec = s.string, val = "", true },
-- 		{ "you" },
-- 	}, function(case)
-- 		local val = unpack(case)
-- 		return string.format("", val), function() assert.are_equal(s.valid(case.spec, case.val), case.is) end
-- 	end)
-- end
--
-- test.start {}
