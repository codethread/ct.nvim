local utils = require("ct.utils")
local builders = require("ct.parser.builders")

local M = {}

---Collecion structure for the types in a file
---@class ct.FileTypes
---@field private builders TypeBuilderBase[]
---@field types ct.TypeLookup

--[[ parse buffer and get all type comments

 TODO: this can be completely replaced with treesitter,
 had a doh moment forgetting luadoc was a thing, but for
 now the api is the important part

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
---@param bufn number
function M.parse(bufn)
	---@class ct.FileTypes
	local types = {
		builders = {},
		types = {},
	}

	local comment_idx = nil

	for i, line in ipairs(vim.api.nvim_buf_get_lines(bufn, 0, -1, false)) do
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
			types.builders[comment_idx] = builders.TypeClassBuilder.new(content, row)
		elseif vim.startswith(content, "@alias") then -- new alias
			-- advance idx
			comment_idx = #types.builders + 1
			types.builders[comment_idx] = builders.TypeAliasBuilder.new(content, row)
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

	return types
end

return M
