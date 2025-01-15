local utils = require("ct.utils")
local builders = require("ct.parser.builders")

--[[
 NOTE: @class

only supporting basic class + field syntax atm, if the api is good, will
expand the parser, anything else is undefined behaviour. syntax must be
triple dash no space, e.g "---@class ..." "---@field ..." comments must be
inline e.g "---@field foo string Comment for field foo"

 NOTE: @alias

only supporting inline separated with `|`

 NOTE: @macro

- Any types building on other types must be declared in lexical order
- macro must be used on each line and be preceeded with whitespace
- special tokens:
	- "_" will be injected
	- `<blah>` backticks is a shorthand for types

---@class Foo

---@macro _.blah(`foo`)

---@macro _.blah(
---@macro 	`foo`, `bar`
---@macro )

local other = 'stuff'
--]]

-- Module for parsing a file to extract type information
--
-- TODO: this can be completely replaced with treesitter,
-- had a doh moment forgetting luadoc was a thing, but for
-- now the api is the important part
--
-- --iterate through all 'trees' as luadocs are their own trees. check perf
-- vim.treesitter.get_parser():for_each_tree(function(n, t)
-- 	dd(vim.treesitter.get_node_text(n:root(), t:source()))
-- end)
local M = {}

---Collection structure for the types in a file
---@class ct.FileTypes
---@field private builders ct.BuilderBase[]
---@field types ct.TypeLookup

---Parse buffer and get all type comments
---@param config ct.Config
---@param bufn number
function M.parse(config, bufn)
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
				builder:add_field(content)
			end
		elseif vim.startswith(content, "|") then -- extend alias
			local builder = types.builders[comment_idx]

			if not builder or builder.get_type() ~= "alias" then
				utils.warn("| alias does not follow alias def line %i : `%s`", row, line)
			else
				builder:add_field(content)
			end
		elseif vim.startswith(content, "@generic") then
			utils.warn("generics are not supported yet")
		elseif vim.startswith(content, "@enum") then
			utils.warn("enums are not supported yet")
		elseif vim.startswith(content, config.macro_key) then
			local builder = types.builders[comment_idx]
			local macro_content = content:sub(#config.macro_key + 2) -- strip the macro bit

			if not builder then
				-- advance idx
				comment_idx = #types.builders + 1
				types.builders[comment_idx] = builders.TypeMacroBuilder.new(macro_content, row)
			elseif builder.get_type() ~= "macro" then
				utils.warn("%s needs to be preceeded with whitespace at this time, line: %s", config.macro_key, row)
			else
				builder:add_field(macro_content)
			end
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
