local type_parsers = require("ct.parser.type_parsers")

---Module of type builders
local M = {}

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                           Raw string builders                           │
--   ╰─────────────────────────────────────────────────────────────────────────╯
--   these are set up to just get all the raw text from a file, as we may need
--   all of it before we can parse all types

---@class (exact) ct.RawTypeBase
---@field _tag string Descriminant
---@field start number Row start of comment
---@field end_ number Row end of comment

---@class (exact) ct.RawTypeClass : ct.RawTypeBase
---@field _tag 'class'
---@field doc_string? string[] Todo..
---@field class string
---@field fields string[]

---@class (exact) ct.RawTypeAlias : ct.RawTypeBase
---@field _tag 'alias'
---@field doc_string? string Todo..
---@field alias string main declaration
---@field values? string[] Additional alias values

---@class (exact) ct.RawTypeMacro : ct.RawTypeBase
---@field _tag 'macro'
---@field lines string[] lines of macro content

---@alias ct.RawType ct.RawTypeClass | ct.RawTypeAlias | ct.RawTypeMacro

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                     Types for external consumption                      │
--   ╰─────────────────────────────────────────────────────────────────────────╯
--   these are a poor mans AST of all the gathered information about a type

---Base interface for a ct.TypeComment
---@class (exact) ct.TypeBase
---@field id string
---@field _tag string Descriminant
---@field start number Row start of comment
---@field end_ number Row end of comment
---@field to_string fun(self): string[] Print out content for debugging XXX

---An instance of a comment class block. See [luals](https://luals.github.io/wiki/annotations/#class) for class syntax
---@class (exact) ct.TypeClass : ct.TypeBase
---@field _tag 'class'
---@field class string
---@field exact boolean
---@field fields ct.ParsedField[]

---An instance of an alias comment. See [luals](https://luals.github.io/wiki/annotations/#alias) for alias syntax
---@class (exact) ct.TypeAlias : ct.TypeBase
---@field _tag 'alias'
---@field name string
---@field variants { type: string, doc_comment?: string }[]

---An instance of a type macro
---@class (exact) ct.TypeMacro : ct.TypeBase
---@field _tag 'macro'
---@field block string

---Union of all types
---@alias ct.Type ct.TypeClass | ct.TypeMacro | ct.TypeAlias
---@alias ct.TypeLookup table<string, ct.Type> Lookup dict of all previously built types

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                       Type Builder implementation                       │
--   ╰─────────────────────────────────────────────────────────────────────────╯

---@class ct.BuilderBase
---@field private text ct.RawType
---@field get_type fun(self): 'class' | 'alias' | 'macro'
---@field build fun(self, types: ct.TypeLookup): ct.Type

---@class ct.TypeClassBuilder : ct.BuilderBase
---@field private text ct.RawTypeClass
M.TypeClassBuilder = {}

---@param str string comment line expected to start with @class
---@param row number
---@return ct.TypeClassBuilder
M.TypeClassBuilder.new = function(str, row)
	---@type ct.RawTypeClass
	local text = {
		_tag = "class",
		start = row,
		end_ = row + 1,
		fields = {},
		class = str,
	}

	---@type ct.BuilderBase
	local new_type = {
		text = text,
		get_type = function()
			return text._tag
		end,
	}
	return setmetatable(new_type, { __index = M.TypeClassBuilder }) --[[@as any]]
end

---comment
---@param str string
---@return ct.TypeClassBuilder
function M.TypeClassBuilder:add_field(str)
	table.insert(self.text.fields, str)
	self.text.end_ = self.text.end_ + 1
	return self
end

---@param types ct.TypeLookup
function M.TypeClassBuilder:build(types)
	local info = type_parsers.parse_class_string(self.text.class)
	local fields = type_parsers.parse_class_fields(self.text.fields)

	---@type ct.TypeClass
	local class_type = {
		id = info.name .. ":" .. self.text.start,
		_tag = "class",
		start = self.text.start,
		end_ = self.text.end_,
		class = info.name,
		exact = info.exact,
		fields = fields,
		to_string = function()
			return {}
		end,
	}

	class_type.to_string = function()
		local str = {
			string.format("---@class %s%s", class_type.exact and "(exact) " or "", class_type.class),
		}

		for _, field in ipairs(class_type.fields) do
			table.insert(
				str,
				string.format(
					"---@field %s%s%s %s",
					field.scoped and field.scoped .. " " or "",
					field.name,
					field.optional and "?" or "",
					table.concat(field.type, " ")
				)
			)
		end

		return str
	end

	return class_type
end

---@class ct.TypeAliasBuilder :ct.BuilderBase
---@field private text ct.RawTypeAlias
M.TypeAliasBuilder = {}

---comment
---@param str string
---@param row number
---@return ct.TypeClassBuilder
M.TypeAliasBuilder.new = function(str, row)
	---@type ct.RawTypeAlias
	local text = {
		_tag = "alias",
		start = row,
		end_ = row + 1,
		alias = str,
	}

	---@type ct.BuilderBase
	local new_type = {
		text = text,
		get_type = function()
			return text._tag
		end,
	}

	return setmetatable(new_type, { __index = M.TypeAliasBuilder }) --[[@as any]]
end

---comment
---@param str string
---@return ct.TypeAliasBuilder
function M.TypeAliasBuilder:add_field(str)
	self.text.values = self.text.values or {}
	table.insert(self.text.values, str)
	self.text.end_ = self.text.end_ + 1
	return self
end

---@param types ct.TypeLookup
function M.TypeAliasBuilder:build(types)
	local info = type_parsers.parse_alias_string(self.text.alias, self.text.values)

	---@type ct.TypeAlias
	local alias_type = {
		_tag = "alias",
		id = info.name .. ":" .. self.text.start,
		start = self.text.start,
		end_ = self.text.end_,
		to_string = function()
			return {}
		end,
		name = info.name,
		variants = vim.iter(info.variants)
			:map(function(v)
				return { type = v }
			end)
			:totable(),
	}

	alias_type.to_string = function()
		local str = {
			string.format("---@alias %s", alias_type.name),
		}
		for _, field in ipairs(alias_type.variants) do
			table.insert(str, string.format("---| %s", field.type))
		end
		return str
	end
	return alias_type
end

---@class ct.TypeMacroBuilder : ct.BuilderBase
---@field private text ct.RawTypeMacro
M.TypeMacroBuilder = {}

---@param str string
---@return ct.TypeMacroBuilder
function M.TypeMacroBuilder:add_field(str)
	table.insert(self.text.lines, str)
	self.text.end_ = self.text.end_ + 1
	return self
end

---@param types ct.TypeLookup
function M.TypeMacroBuilder:build(types)
	---@type ct.TypeMacro
	local macro_type = {
		id = math.random(), -- TODO
		_tag = "macro",
		start = self.text.start,
		end_ = self.text.end_,
		to_string = function()
			return {}
		end,
		block = vim.iter(self.text.lines)
			:map(
				---@param line string
				function(line)
					local replacements = {
						-- text between backticks `foo.bar`
						["`[%a%.]+`"] = function(match)
							return string.format('_.types["%s"]', match:sub(2, -2))
						end,
					}
					for pat, fn in pairs(replacements) do
						line = line:gsub(pat, fn)
					end
					return line
				end
			)
			:join("\n"),
	}

	macro_type.to_string = function()
		return vim.split(macro_type.block, "\n", { plain = true })
	end

	return macro_type
end

---@param str string comment line expected to start with @class
---@param row number
---@return ct.TypeMacroBuilder
function M.TypeMacroBuilder.new(str, row)
	---@type ct.RawTypeMacro
	local text = {
		_tag = "macro",
		start = row,
		end_ = row + 1,
		lines = { str },
	}

	---@type ct.BuilderBase
	local new_type = {
		text = text,
		get_type = function()
			return text._tag
		end,
	}

	return setmetatable(new_type, { __index = M.TypeMacroBuilder }) --[[@as any]]
end

return M
