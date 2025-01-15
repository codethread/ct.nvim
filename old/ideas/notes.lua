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
