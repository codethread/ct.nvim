local models = require("ideas.models")
--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                        Part of the internal Lib                         │
--   ╰─────────────────────────────────────────────────────────────────────────╯

function Todo()
	return error("not implemented") --[[@as any]]
end

local function debug_log(fn)
	if Ct and Ct.is_test then
		return function(...)
			vim.print("inputs: ", ...)
			local out = table.pack(fn(...))
			vim.print("outputs:", out)
			return unpack(out)
		end
	else
		return fn
	end
end

-- heavily inspired by:
-- - https://zod.dev/?id=primitives
-- - https://clojure.org/guides/spec

do -- class annotations
	---@class SpecError
	---@field id string
	---@field msg string

	---Base class of all specs,
	--- XXX: would be an interface
	--- TODO most of these could generate `as` comments

	---@class SpecCustomValidator<Input>: { is: fun(input: Input): boolean, SpecError? }

	----@interface
	----@class SpecBase
	----@field protected data any
	----@field is fun(self, data: unknown): boolean, SpecError? # checks if data matches spec
	----@field assert fun(self, data: unknown): boolean, unknown # throws if data does not conform to spec, otherwise returns data
	----@field seal fun(self): SpecBase # convenience to help autocomplete

	---@class SpecPrimitiveOpts
	---@field message? string # error message to show

	--	---@class SpecString : SpecBase
	--	---@field default? fun(self, val: string): SpecString
	--	---@field custom? fun(self, validator: SpecCustomValidator<string>): SpecString
	--	---@field min? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString
	--	---@field max? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString

	---@class SpecNumber : SpecBase
	---@field default? fun(self, val: number): SpecNumber
	---@field custom? fun(self, validator: SpecCustomValidator<number>): SpecNumber
	---@field min? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString
	---@field max? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString

	---@class SpecRecord : SpecBase
	---@field default? fun(self, val: table): SpecRecord
	---@field custom? fun(self, validator: SpecCustomValidator<table>): SpecRecord
	---@field required? fun(self, opts?: SpecPrimitiveOpts): SpecRecord # mark all members in the spec as required
	---@field partial? fun(self, opts?: SpecPrimitiveOpts): SpecRecord # mark all members in the spec as optional

	---@class SpecDocOpts
	---@field trim? boolean
	---@field dedent? boolean

	----Not exactly sure how this will work, might end up wrapping the value
	----most likely it can do an init validation, just runtime, but others can
	----use the `Impl.fn` to get validation
	----@class SpecFunction : SpecBase
	----@field doc? fun(self, str: string, opts?: SpecDocOpts): SpecFunction
	----@field self? fun(self, type?: string): SpecFunction # if a class, this will set the self type, can provide an optional name to inject
	----@field args? fun(self, opts?: SpecBase[]): SpecFunction
	----@field returns? fun(self, opts?: SpecBase[]): SpecFunction
	----@field default? fun(self, fn: function): SpecFunction

	---An instance of an implemented function
	---@class SpecFunctionImpl<Fn>: { call: Fn }

	---@class SpecInterface
	---@field name string
	---@field methods table<string, SpecFunction>
end

---@class SpecBaseStruct
---@field protected specs SpecCustomValidator<unknown>[]

---@interface
---@class SpecBase : SpecBaseStruct
---@field protected add_spec fun(self, spec: SpecCustomValidator<unknown>)
local SpecBase = {}

---@package
function SpecBase.new()
	---@type SpecBaseStruct
	local b = { specs = {} }
	return setmetatable(b, { __index = SpecBase }) --[[@as SpecBase]]
end

function SpecBase:add_spec(spec)
	table.insert(self.specs, spec)
end

---convenience to help autocomplete
---@return SpecBase
function SpecBase:seal()
	return self
end

---@overload fun(self, val: unknown): true, nil # is ok true, no errors
---@overload fun(self, val: unknown): false, SpecError[] # is not valid, returns errors[]
function SpecBase:is(val)
	local errs = {}

	for _, spec in ipairs(self.specs) do
		local ok, err = spec.is(val)
		if not ok then
			table.insert(errs, err)
		end
	end

	if #errs == 0 then
		return true
	end
	return false, errs
end

---@type SpecCustomValidator<string>
local is_string = {
	_id = "is string",
	is = debug_log(function(str)
		local ok = type(str) == "string"
		if ok then
			return true, nil
		else
			return false, { msg = "not a string" }
		end
	end),
}

---@type SpecCustomValidator<function>
local is_function = {
	_id = models.ids.is_function,
	is = debug_log(function(fn)
		local ok = type(fn) == "function"
		if ok then
			return true, nil
		else
			return false, { id = models.ids.is_function, msg = "not a function" }
		end
	end),
}
---@type fun(count: number): SpecCustomValidator<function>
local function is_function_arity(count)
	return {
		_id = models.ids.is_function_arity,
		is = debug_log(function(fn)
			local info = debug.getinfo(fn)
			vim.print(count, info.nparams)
			local ok = info.nparams == count
			if ok then
				return true, nil
			else
				return false, { id = models.ids.is_function_arity, msg = "wrong arg count" }
			end
		end),
	}
end

---@class SpecString : SpecBase
---@field default? fun(self, val: string): SpecString
---@field custom? fun(self, validator: SpecCustomValidator<string>): SpecString
---@field min? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString
---@field max? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString
local SpecString = setmetatable({}, { __index = SpecBase })

---@package
---@return SpecString
function SpecString.new()
	local base = SpecBase.new()
	base:add_spec(is_string)
	return setmetatable(base, { __index = SpecString }) --[[@as SpecString]]
end

---Not exactly sure how this will work, might end up wrapping the value
---most likely it can do an init validation, just runtime, but others can
---use the `Impl.fn` to get validation
---@class SpecFunction : SpecBase
---@field doc? fun(self, str: string, opts?: SpecDocOpts): SpecFunction
---@field self? fun(self, type?: string): SpecFunction # if a class, this will set the self type, can provide an optional name to inject
---@field returns? fun(self, opts?: SpecBase[]): SpecFunction
---@field default? fun(self, fn: function): SpecFunction
local SpecFunction = setmetatable({}, { __index = SpecBase })

---@package
---@return SpecFunction
function SpecFunction.new()
	local base = SpecBase.new()
	base:add_spec(is_function)
	return setmetatable(base, { __index = SpecFunction }) --[[@as SpecFunction]]
end
---@class SpecFunctionOpts
---@field vararg? boolean

---@param specs? SpecBase[]
---@param opts? SpecFunctionOpts
---@return SpecFunction
function SpecFunction:args(specs, opts)
	local arity = #specs
	self:add_spec(is_function_arity(arity))
	return self
end

-- ## Spec builders
--
-- these build specs, which can then be composed and also passed to `Impl`
-- builders (which produce value factories as opposed to `Spec`s which are just
-- validations)
local Spec = {}
do -- Spec Impls
	--   ╭─────────────────────────────────────────────────────────────────────────╮
	--   │                               Primitives                                │
	--   ╰─────────────────────────────────────────────────────────────────────────╯
	---@param opts? SpecPrimitiveOpts
	---@return SpecString
	function Spec:string(opts)
		return SpecString.new()
	end
	---@param opts? SpecPrimitiveOpts
	---@return SpecNumber
	function Spec:number(opts)
		return Todo()
	end
	---@param opts? SpecPrimitiveOpts
	---@return SpecFunction
	function Spec:fn(opts)
		return SpecFunction.new()
	end
	-- ...etc

	--   ╭─────────────────────────────────────────────────────────────────────────╮
	--   │                                 Complex                                 │
	--   ╰─────────────────────────────────────────────────────────────────────────╯
	---@param fields table<string, SpecBase>
	---@return SpecRecord
	function Spec:record(fields)
		return Todo()
	end

	---@param items SpecBase[]
	---@return SpecRecord
	function Spec:list(items)
		return Todo()
	end

	---@param name string
	---@param methods table<string, SpecFunction>
	---@return SpecInterface
	function Spec:interface(name, methods)
		return Todo()
	end
end

return Spec
