require("ideas.prelude") -- XXX: move to init
local models = require("ideas.models")

---@class spec.Table
---@field name string
---@field only? boolean
---@field skip? boolean
---@field input unknown
---@field output unknown

---@class spec.TableTestImpl
---@field desc string
---@field fn fun():nil

---@param test_fn fun(case: spec.Table): string, function
---@param case spec.Table
---@return spec.TableTestImpl
local function build_test(test_fn, case)
	local desc, fn = test_fn(case)
	return { fn = fn, desc = desc } --[[@as spec.TableTestImpl]]
end

---@generic T : spec.Table
---@param cases T[]
---@param test_fn fun(case: T): string, function # will become `it(<string>, <function>)`
local function test_each(cases, test_fn)
	---@alias SS string string
	---@type spec.TableTestImpl[]
	local skipped = {}
	---@type spec.TableTestImpl[]
	local to_run = {}
	---@type spec.TableTestImpl?
	local only_test = nil

	for _, case in pairs(cases) do
		---@cast case spec.Table

		local test_spec = build_test(test_fn, case)
		if only_test or case.skip then
			table.insert(skipped, test_spec)
		elseif case.only then
			only_test = test_spec
		else
			table.insert(to_run, test_spec)
		end
	end

	for _, test in ipairs(skipped) do
		pending(test.desc)
	end

	for _, test in ipairs(to_run) do
		it(test.desc, test.fn)
	end

	if only_test then
		it(only_test.desc, only_test.fn)
	else
	end
end

local Spec = require("ideas.Spec")

describe("simple Specs", function()
	local S = Spec:string()

	local table_test = {
		{ "hey", true, nil },
		{ "", true, nil },
		{ {}, false, { { msg = "not a string" } } },
		{ 2, false, { { msg = "not a string" } } },
	}

	for _, case in ipairs(table_test) do
		local val, _ok, _err = unpack(case)

		it(string.format("should be %s for input %s", _ok, vim.inspect(val)), function()
			local ok, err = S:is(val)

			assert.eq(ok, _ok)
			assert.eq(err, _err)
		end)
	end
end)

--- likely the best that can be done without running is to check the arity of parms and returns
describe("function specs", function()
	-- local info = debug.getinfo(c.new)
	-- local lines = vim.fn.readfile(info.short_src)
	-- local fn = vim.list_slice(lines, info.linedefined, info.lastlinedefined)

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
{ name = "function arity 1",         spec = fn1, input = function (a) end, output = { true } },
{ name = "invalid function arity 1", spec = fn1, input = function () end,  output = { true } },
		-- stylua: ignore end
	}

	test_each(table_test, function(case)
		return "should validate " .. case.name,
			function()
				vim.print(case)
				local ok, err = case.spec:is(case.input)
				local _ok, _err = table.unpack(case.output)
				assert.eq(ok, _ok)
				vim.print(err)
				assert.eq(err, { { id = _err } })
			end
	end)
end)
