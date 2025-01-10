require("ideas.types") -- XXX: move to init

local Spec = require("ideas.Spec")

describe("Specs", function()
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
