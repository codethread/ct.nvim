require("ideas.types") -- XXX: move to init

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

describe("function specs", function()
	-- local info = debug.getinfo(c.new)
	-- local lines = vim.fn.readfile(info.short_src)
	-- local fn = vim.list_slice(lines, info.linedefined, info.lastlinedefined)

	--- likely the best that can be done without running is to check the arity of parms and returns
	it("should validate arguments arity", function()
		local f = Spec:fn():args { Spec:string(), Spec:string() }

		local ok, err = f:is(function(a, b) end)
		assert.eq(ok, true)
		assert.eq(err, nil)

		ok, err = f:is(function() end)
		assert.eq(ok, false)
		assert.eq(err, { { msg = "wrong arg count" } })
	end)
end)
