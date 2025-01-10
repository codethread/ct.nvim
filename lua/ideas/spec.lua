--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                        Part of the internal Lib                         │
--   ╰─────────────────────────────────────────────────────────────────────────╯

local function todo()
	return error("not implemented") --[[@as any]]
end

-- heavily inspired by:
-- - https://zod.dev/?id=primitives
-- - https://clojure.org/guides/spec

do -- class annotations
	---@class SpecError
	---@field msg string

	---Base class of all specs,
	--- XXX: would be an interface
	--- TODO most of these could generate `as` comments

	---@class SpecCustomValidator<Input>: { is: fun(input: Input): boolean, SpecError|nil }

	---@interface
	---@class SpecBase
	---@field is fun(self, data: unknown): boolean, SpecError? # checks if data matches spec
	---@field assert fun(self, data: unknown): boolean, unknown # throws if data does not conform to spec, otherwise returns data

	---@class SpecPrimitiveOpts
	---@field message? string # error message to show

	---@class SpecString : SpecBase
	---@field default? fun(self, val: string): SpecString
	---@field custom? fun(self, validator: SpecCustomValidator<string>): SpecString
	---@field min? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString
	---@field max? fun(self, size: integer, opts?: SpecPrimitiveOpts): SpecString

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

	---Not exactly sure how this will work, might end up wrapping the value
	---@class SpecFunction : SpecBase
	---@field doc? fun(self, str: string, opts?: SpecDocOpts): SpecFunction
	---@field self? fun(self, type?: string): SpecFunction # if a class, this will set the self type, can provide an optional name to inject
	---@field args? fun(self, opts?: SpecBase[]): SpecFunction
	---@field returns? fun(self, opts?: SpecBase[]): SpecFunction
	---@field default? fun(self, fn: function): SpecFunction

	---An instance of an implemented function
	---@class SpecFunctionImpl<Fn>: { call: Fn }

	---@class SpecInterface
	---@field name string
	---@field methods table<string, SpecFunction>
end

-- ## Spec builders
--
-- these build specs, which can then be composed and also passed to `Impl`
-- builders (which product value factories as opposed the Specs which are just
-- validations)
local Spec = {
	--   ╭─────────────────────────────────────────────────────────────────────────╮
	--   │                               Primitives                                │
	--   ╰─────────────────────────────────────────────────────────────────────────╯
	---@param opts? SpecPrimitiveOpts
	---@return SpecString
	string = function(opts)
		return todo()
	end,
	---@param opts? SpecPrimitiveOpts
	---@return SpecNumber
	number = function(opts)
		return todo()
	end,
	---@param opts? SpecPrimitiveOpts
	---@return SpecFunction
	fn = function(opts)
		return todo()
	end,
	-- ...etc

	--   ╭─────────────────────────────────────────────────────────────────────────╮
	--   │                                 Complex                                 │
	--   ╰─────────────────────────────────────────────────────────────────────────╯
	---@param fields table<string, SpecBase>
	---@return SpecRecord
	record = function(fields)
		return todo()
	end,

	---@param items SpecBase[]
	---@return SpecRecord
	list = function(items)
		return todo()
	end,

	---@param name string
	---@param methods table<string, SpecFunction>
	---@return SpecInterface
	interface = function(name, methods)
		return todo()
	end,
}

---## Implementation builders
---
---these create factories for runtime data structures. Most will often be built out of `Spec` values
---@class SpecImpls
local Impl = {}
do -- Impl
	---@class SpecClassData : SpecDetails
	---@field visibility? 'private' | 'public' | 'protected'

	---@class SpecClass
	---@field doc? string
	---@field super? any # do i want to add inheritance?
	---@field data? table<string, SpecClassData>
	---@field implements "__Spec.interface"[]

	---Create a 'class' object with data and behaviour
	---@param spec SpecClass
	---@return any
	function Impl:class(spec)
		return todo()
	end

	---@class SpecStruct
	---@field name string
	---@field doc? string
	---@field data SpecRecord
	---@field runtime_check? boolean # could make it this is off, but can be enabled for external API, e.g user config

	---Create a table of pure data
	---if needing behaviour, use `class`
	---@param spec SpecStruct
	---@return any
	function Impl.struct(spec)
		return todo()
	end

	---Create an implementation of a function, intended for creating runtime
	---validated function
	---@return SpecFunctionImpl
	---@generic Fn
	---@param spec SpecFunction
	---@param impl `Fn`
	---@return Fn
	function Impl.fn(spec, impl)
		return todo()
	end
end

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                        User land implementation                         │
--   ╰─────────────────────────────────────────────────────────────────────────╯
--XXX: magically this is generated from the `interface` call below
---@class IReaderWriter
---@field read fun(self: unknown, target: string): string[]
---@field write fun(self: unknown, target: string, out: string[]): boolean

-- --@class IReaderWriter<Self>: { read: fun(self: Self, target: string): string[]; write: fun(self: Self, target: string, out: string[]): boolean }

---My lovely func
---@alias AddFn SpecFunctionImpl<fun(_:number,_:number):string>
---@type AddFn
local add = Impl.fn(
	Spec
		.fn() --
		:doc([[My lovely func]])
		:args({ Spec.number():min(1), Spec.number():min(1) })
		:returns { Spec.string() },
	function(a, b)
		return tostring(a + b)
	end
)

local out = add.call(3, 2)

local email_spec = Spec.string():custom {
	is = function(input)
		local is_mail = input:match("foo@bar.com")
		if is_mail then
			return true
		end
		return false, { msg = "oh dear" }
	end,
}

local r = Spec.record {
	email = email_spec,
	y = Spec.number(),
	z = Spec.record {
		foo = Spec.string(),
		fn = Spec.fn({ message = "oh dear" })
			:doc([[ hey there ]], { dedent = false })
			:args({ Spec.string() })
			:returns { Spec.string() },
	},
}

local test = Spec.record {
	x = "hey",
}
local IReaderWriter = Spec.interface("ReaderWriter", {
	read = {
		method = true,
		args = { "string", "number" },
		returns = {
			Spec.list("string"),
			Spec.record {
				a = {
					t = "number",
					is = function(maybe)
						return type(maybe) == "number"
					end,
				},
			},
		},
	},
	write = {
		method = true,
		args = { Spec.record { a = "number", b = { t = "string", default = "hey" } } },
		returns = { "boolean", Spec.record { a = Spec.list("string") } },
	},
})

----- METHOD 1 (multiple implements)
---@class Printer
---@field print fun(self): string
---@field debug fun(self): string

local Printer = "__Spec.interface" -- quick hack to avoid typing one out

--- XXX: generate this from the data info
---
---@class CStruct
---@field x number
---@field y number # y cordinate of a vec

---@class (exact) C : CStruct, IReaderWriter, Printer -- XXX: could generate these types
---@field new fun(args: CStruct): C
---@field private priv boolean
---@field protected prot boolean
local Foo = Impl.class {
	name = "Foo",
	data = {
		x = "number",
		y = { t = "number", doc = "y cordinate of a vec" },
		priv = { t = "boolean", visibility = "private" },
		prot = { t = "boolean", visibility = "protected" },
	},
	implements = { IReaderWriter, Printer },
	---@class (exact) FooImpl : IReaderWriter , Printer -- XXX: need to generate the extra class on the fly in order to type all methods
	---@type FooImpl
	methods = {
		---@param self C XXX genereate this bit
		read = function(self, y)
			---@class C # XXX: this needs to go inside the function in order to access private members, but only needs to be written for that usecase. annoying
			self = self

			self:jump() -- amazingly this is valid even if typed further down, so can utilise all class info methods

			return todo()
		end,
		---@param self C
		write = function(self, x, y)
			---@class C
			self = self
			if self.priv then -- this is now unhappy
			end
		end,
		debug = todo,
		print = todo,
	},
}

function Foo:jump()
	if self.priv and self.prot then
	end
end

local foo = Foo.new { x = 3, y = 2 }
print(foo.priv)
print(foo.prot)

--- generated from Spec.record
---@class Vec
---@field x number
---@field y number # y cordinate of a vec

---@type fun(v: Vec): Vec -- could optinally create a factory, or just use it to create types
local Vec = Impl.struct {
	name = "Vec", -- could figure out if this is needed or not - the assignment may be enough
	data = {
		x = "number",
		y = { t = "number", doc = "y cordinate of a vec" },
	},
}

local myV = Vec { x = 1, y = 2 }

---comment
---@param v1 Vec
---@param v2 Vec
local function dot(v1, v2)
	return v1 + v2
end

local configFactory = Impl.struct {
	name = "Config",
	runtime_check = true,
	data = {
		name = "string?",
		dob = Spec.record {
			year = "integer",
			month = {
				t = "string",
				is = function(input)
					return vim.list_contains({ "Dec", "Jan", "Feb" }, input)("winter babies only")
				end,
			},
		},
	},
}

local configer = Impl.class {
	name = "Configer",
	data = {
		config = configFactory,
	},
	implements = {},
}
