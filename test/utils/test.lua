local M = {}

---@class spec.Suite
---@field desc string
---@field skipped spec.TableTestImpl[]
---@field to_run spec.TableTestImpl[]

---@type spec.Suite[]
local suites = {}

---@type spec.TableTestImpl?
local only_test = nil

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
---@param desc string
---@param cases T[]
---@param test_fn fun(case: T): string, function # will become `it(<string>, <function>)`
function M.test_each(desc, cases, test_fn)
	---@type spec.Suite
	local suite = {
		desc = desc,
		skipped = {},
		to_run = {},
	}

	for _, case in pairs(cases) do
		---@cast case spec.Table

		local test_spec = build_test(test_fn, case)
		if only_test or case.skip then
			table.insert(suite.skipped, test_spec)
		elseif case.only then
			test_spec.desc = desc .. " " .. test_spec.desc
			only_test = test_spec
		else
			table.insert(suite.to_run, test_spec)
		end
	end

	table.insert(suites, suite)
end

---@class spec.SuiteOpts
---@field debug? boolean

---@param opts? spec.SuiteOpts
function M.start(opts)
	opts = opts or {}
	_G.Ct = { is_test = opts.debug }

	local is_CI = vim.fn.getenv("CI") == "true"

	if only_test then
		if only_test then
			it(only_test.desc, only_test.fn)
		end

		for _, suite in ipairs(suites) do
			describe(suite.desc, function()
				if is_CI and (only_test or (#suite.skipped > 0)) then
					error("FAILED PENDING | SKIPPED TEST IN CI")
				end

				for _, test in ipairs(suite.skipped) do
					pending(test.desc)
				end

				for _, test in ipairs(suite.to_run) do
					pending(test.desc)
				end
			end)
		end
	else
		for _, suite in ipairs(suites) do
			describe(suite.desc, function()
				if is_CI and (only_test or (#suite.skipped > 0)) then
					error("FAILED PENDING | SKIPPED TEST IN CI")
				end

				for _, test in ipairs(suite.skipped) do
					pending(test.desc)
				end

				for _, test in ipairs(suite.to_run) do
					it(test.desc, test.fn)
				end
			end)
		end
	end
end

return M
