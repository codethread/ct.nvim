require("plenary.reload").reload_module("ct.parser")
require("plenary.reload").reload_module("ct.utils")

local file_parser = require("ct.parser")

-- make simple type builders

-- implement
-- partial
-- required

-- other ideas
-- deep_<x>
-- extend

-- INPUTS

---@alias int number this is a number

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
local match = require("ct.api.match").new("ct.TypeComment") --[[@as fun(union: ct.TypeComment): ct.Match_TypeComment]]

local parsed = file_parser.parse(b)

local offset = 0
for _, comment in pairs(parsed.types) do
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
