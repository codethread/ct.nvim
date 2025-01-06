require("plenary.reload").reload_module("ct.TypeBuilder")
require("plenary.reload").reload_module("ct.utils")

local TypeBuilder = require("ct.TypeBuilder")
local utils = require("ct.utils")

-- make simple type builders

-- implement
-- partial
-- required

-- other ideas
-- deep_<x>
-- extend

-- INPUTS

---@class ct.Foo here
---@field name string
---@field age number
---@field private kA number hi there!

---oiwjef
---@class (exact) ct.Bar
---@field name? string here is a comment
---@field age? number
-- foiwjef oiwjef----
-- foiwjef oiwjef----
-- foiwjef oiwjef----
-- foiwjef oiwjef----
---@field foo? number
---@field name? number

--[[@ct.required ct.Bar]]
--[[@ct.partial ct.Foo]]
local b = vim.api.nvim_get_current_buf()

do --test code only to remove old insertions
	local offset = 0
	for id, text in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
		if vim.startswith(text, "---XXX:") then
			local line = (id - 1) - offset
			vim.api.nvim_buf_set_lines(b, line, line + 1, false, {})
			offset = offset + 1
		end
	end
end

---somehow @as is generated::
local match = require("ct.match").new("ct.TypeComment") --[[@as fun(union: ct.TypeComment): ct.Match_TypeComment]]

---Collecion structure for the types in a file
---@class ct.FileTypes
local types = {
	---@type TypeBuilderBase[]
	builders = {},
	---@type ct.TypeLookup
	types = {},
}

local comment_idx = nil

--[[ parse buffer and get all type comments

 NOTE: @class

only supporting basic class + field syntax atm, if the api is good, will expand
the parser, anything else is undefined behaviour.
syntax must be triple dash no space, e.g "---@class ..." "---@field ..."
comments must be inline e.g "---@field foo string Comment for field foo"

 NOTE: @alias

only supporting inline separated with `|`

 NOTE: @macro

Any types building on other types must be declared in lexical order at this time

--]]
for i, line in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
	local row = i + 1
	-- iterate LuaCATS comments
	if not vim.startswith(line, "---") then
		-- if we were processing a block, it is assumed finished
		comment_idx = nil
		goto continue
	end

	-- trim off comment dash and remove whitespace
	local content = vim.trim(line:sub(4))

	if vim.startswith(content, "@class") then -- new class, so we want to create a new comment
		-- advance idx
		comment_idx = #types.builders + 1
		types.builders[comment_idx] = TypeBuilder.TypeClassBuilder.new(content, row)
	elseif vim.startswith(content, "@alias") then -- new alias
		-- advance idx
		comment_idx = #types.builders + 1
		types.builders[comment_idx] = TypeBuilder.TypeAliasBuilder.new(content, row)
	elseif vim.startswith(content, "@field") then -- add field to class
		local builder = types.builders[comment_idx]

		if not builder or builder.get_type() ~= "class" then
			utils.warn("@field does not follow class line %i : `%s`", row, line)
		else
			types.builders[comment_idx]:add_field(content)
		end
	elseif vim.startswith(content, "|") then -- extend alias
		local builder = types.builders[comment_idx]

		if not builder or builder.get_type() ~= "alias" then
			utils.warn("| alias does not follow alias def line %i : `%s`", row, line)
		else
			types.builders[comment_idx]:add_field(content)
		end
	elseif vim.startswith(content, "@generic") then
		utils.warn("generics are not supported yet")
	elseif vim.startswith(content, "@enum") then
		utils.warn("enums are not supported yet")
	end

	::continue::
end

for i, builder in ipairs(types.builders) do
	local type_info = builder:build(types.types)
	types.types[type_info.id] = type_info
end

local offset = 0
for _, comment in pairs(types.types) do
	local line = comment.end_ + offset

	local comments = comment:to_string()

	local lines = vim.iter(comments)
		:map(function(l)
			---TEMP: just for testing
			return string.format("---XXX: %s", l)
		end)
		:totable()

	offset = offset + #lines
	vim.api.nvim_buf_set_lines(b, line, line, false, lines)
end
