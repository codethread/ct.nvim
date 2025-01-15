local test = require "test.utils.test" -- XXX: move to init
local models = require "old.ideas.models"

local Spec = require "old.ideas.Spec"

local S = Spec:string()

do
	local table_test = {
		{ "hey", true, nil },
		{ "", true, nil },
		{ {}, false, { { msg = "not a string" } } },
		{ 2, false, { { msg = "not a string" } } },
	}

	test.test_each("simple specs", table_test, function(case)
		local val, _ok, _err = unpack(case)

		return string.format("should be %s for input %s", _ok, vim.inspect(val)),
			function()
				local ok, err = S:is(val)

				assert.are_same(ok, _ok)
				assert.are_same(err, _err)
			end
	end)
end

--- likely the best that can be done without running is to check the arity of parms and returns
do
	---@class spec_spec.Table : spec.Table
	---@field spec SpecFunction
	---@field input unknown
	---@field output [boolean, SpecValidatorIds?]

	local fn0 = Spec:fn()
	local fn1 = Spec:fn():args { Spec:string() }
	local fn2 = Spec:fn():args { Spec:string(), Spec:string() }
	local fn_vararg = Spec:fn():args({ Spec:string() }, { vararg = true })
	local fn_vararg_invalid = Spec:fn():args({}, { vararg = true })

	---@type spec_spec.Table[]
	local table_test = {
		-- stylua: ignore start
{ name = "function",                 spec = fn0, input = function () end,  output = { true }, only = true },
{ name = "invalid function",         spec = fn0, input = 'string',         output = { false,    models.ids.is_function } },
{ name = "function arity 1",         spec = fn1, input = function (a) end, output = { true }, skip = true},
{ name = "invalid function arity 1", spec = fn1, input = function () end,  output = { true } },
		-- stylua: ignore end
	}

	test.test_each("function specs", table_test, function(case)
		return "should validate " .. case.name,
			function()
				local ok, err = case.spec:is(case.input)
				local _ok, _err = table.unpack(case.output)
				assert.are_same(ok, _ok)
				assert.are_same(err, { { id = _err } })
			end
	end)
end

test.start {}
