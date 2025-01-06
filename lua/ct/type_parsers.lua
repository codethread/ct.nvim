local utils = require("ct.utils")
local M = {}

---comment
---@param parts string[]
---@param union string[]
---@return { variants: string[], doc?: string }
local function get_parts(parts, union)
	local a = parts[1]
	local b = parts[2]

	table.insert(union, a)

	if b == "|" then -- more variants
		return get_parts(vim.list_slice(parts, 3), union)
	elseif not b then -- final variant
		return { variants = union }
	else -- rest must be comments
		return { variants = union, doc = table.concat(vim.list_slice(parts, 2), " ") }
	end
end

---comment
---@param str string
---@param rest string[]
function M.parse_alias_string(str, rest)
	-- TODO handle rest
	local single_line = true

	local out = {}
	local parts = vim.split(str, " ", { plain = true, trimempty = true })
	local union = false
	if vim.list_contains(parts, "|") then
		union = true
	end

	out.name = parts[2] -- foo
	---@type string[]
	out.variants = { parts[3] } -- number

	if parts[4] then
		local slice = vim.list_slice(parts, 3)
		if union then
			local unions = get_parts(slice, {})
			out.variants = unions.variants
			out.doc = unions.doc
		else
			out.doc = table.concat(slice, " ")
		end
	end
	return out
end

---@param s string
function M.parse_class_string(s)
	local inherits = false
	if utils.string_includes(s, ":") then
		-- TODO: add this, shouldn't be hard...
		utils.warn("inheritance isn't fully supported")
	end

	local out = {}
	local parts = vim.split(s, " ", { plain = true, trimempty = true })
	out.exact = parts[2] == "(exact)"
	out.name = out.exact and parts[3] or parts[2]
	return out
end

---@enum ct.FieldScopes
local scopes = {
	"private",
	"protected",
	"public",
	"package",
}

---@class ct.ParsedField
---@field name string
---@field optional boolean
---@field scoped ct.FieldScopes | false
---@field type string[]

--- TODO: At this point being very lazy with the returned types, just keeping
--- everything, not parsing... one for later
---
---@param ss string[] field [scope] <name[?]> <type> [description]
function M.parse_class_fields(ss)
	---@type ct.ParsedField[]
	local fields = {}
	for _, s in ipairs(ss) do
		local parts = vim.split(s, " ", { plain = true, trimempty = true })
		---@type ct.ParsedField
		local out = {}
		out.scoped = false
		if vim.list_contains(scopes, parts[2]) then
			out.scoped = parts[2] --[[@as ct.FieldScopes]]
		end
		out.name = out.scoped and parts[3] or parts[2]
		out.optional = vim.endswith(out.name, "?")
		if out.optional then
			out.name = out.name:sub(1, -2)
		end
		out.type = vim.list_slice(parts, out.scoped and 4 or 3)
		table.insert(fields, out)
	end
	return fields
end

return M
