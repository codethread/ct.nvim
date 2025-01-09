--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                        Part of the internal Lib                         │
--   ╰─────────────────────────────────────────────────────────────────────────╯

---@alias SpecValue 'boolean'
---| 'string'
---| 'integer'
---| 'number'
---| '__SpecValue' # special value for table specs

---@class SpecValueDetail
---@field val SpecValue
---@field doc? string
---@field default? unknown
---@field is? fun(v: unknown): boolean, string?

---@class SpecMethod
---@field method? boolean
---@field args (SpecValue | SpecValueDetail)[]
---@field doc? string
---@field returns? SpecValue[]

---@alias SpecObject table<string, SpecValue | SpecValueDetail>

---@param fields SpecObject
local function struct(fields) end

---@param t SpecValue
---@return '__SpecValue'
local function list(t) end

---@param name string
---@param methods table<string, SpecMethod>
---@return "__SpecInterface"
local function interface(name, methods) end

---@class SpecClass
---@field doc? string
---@field data? SpecObject
---@field implements "__SpecInterface"[]

---@param spec SpecClass
---@return any
local function class(spec) end

---@class SpecRecord
---@field name string
---@field doc? string
---@field data SpecObject
---@field runtime_check? boolean # could make it this is off, but can be enabled for external API, e.g user config

---@param spec SpecRecord
---@return any
local function record(spec) end

---@return any
local function todo() end

---Lib end

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                        User land implementation                         │
--   ╰─────────────────────────────────────────────────────────────────────────╯
---magically this is generated from the `interface` call below
---@class IReaderWriter
---@field read fun(self, target: string): string[]
---@field write fun(self, target: string, out: string[]): boolean

local IReaderWriter = interface("ReaderWriter", {
	read = {
		method = true,
		args = { "string", "number" },
		returns = {
			list("string"),
			struct {
				a = {
					val = "number",
					is = function(maybe)
						return type(maybe) == "number"
					end,
				},
			},
		},
	},
	write = {
		method = true,
		args = { struct { a = "number", b = { val = "string", default = "hey" } } },
		returns = { "boolean", struct { a = list("string") } },
	},
})

----- METHOD 1
---@class C : IReaderWriter -- could generate this line
local C = class {
	name = "Foo",
	data = { a = "string" },
	implements = { IReaderWriter },
	---@type IReaderWriter -- could generate this line, forcing methods to be correct
	methods = {
		read = function(x, y, z) -- typed!
			return ""
		end,
		write = function(x, y, z) -- typed!
			return ""
		end,
	},
}

C:write() -- typed

----- METHOD 2
----- this might work if for some reason different implementations where required... maybe this is a trait
---@class C : IReaderWriter
---@type fun(impl: IReaderWriter): C
local cFact = class {
	name = "Foo",
	implements = { IReaderWriter },
}

local C = cFact {
	read = function(x, y, z)
		return ""
	end,
}

C:write() -- typed

----- METHOD 1.1 (multiple implements)
---@class Printer
---@field print fun(self): string
---@field debug fun(self): string

local Printer = "__SpecInterface"

--- generate this from the data info
---@class CStruct
---@field x number
---@field y number # y cordinate of a vec

---@class C : CStruct, IReaderWriter -- could generate this line
---@field new fun(args: CStruct): C
local Foo = class {
	data = {
		x = "number",
		y = { val = "number", doc = "y cordinate of a vec" },
	},
	implements = { IReaderWriter, Printer },
	---@class FooImpl : IReaderWriter , Printer -- need to generate the extra class on the fly in order to type all methods
	---@type FooImpl
	methods = {
		read = todo,
		debug = todo,
		write = todo,
		print = todo,
	},
}

local foo = Foo.new { x = 3, y = 2 }

--- generated from record
---@class Vec
---@field x number
---@field y number # y cordinate of a vec

---@type fun(v: Vec): Vec -- could optinally create a factory, or just use it to create types
local Vec = record {
	name = "Vec", -- could figure out if this is needed or not - the assignment may be enough
	data = {
		x = "number",
		y = { val = "number", doc = "y cordinate of a vec" },
	},
}

local myV = Vec { x = 1, y = 2 }

---comment
---@param v1 Vec
---@param v2 Vec
local function dot(v1, v2)
	return v1 + v2
end

local configFactory
