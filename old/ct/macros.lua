local utils = require "ct.utils"
local M = {}

---@class FnData
---@field start_row number
---@field start_col number
---@field end_row number
---@field end_col number
---@field replacement string

---@package
---Thinking something like @nil? after assignment puts a check after
---```lua
---local foo = get() --@nil
---if not foo then return end -- < gets inserted
---
---local foo = get() --@nil {}
---if not foo then return {} end -- < gets inserted
---```
function M.get_nil() end

---@package
---Thinking something like odin's `or_*` calls
---```lua
---local foo = get() --@or_return
---if not foo then error("oh dear") end -- < gets inserted
---```
function M.get_or() end

---@param b number
---@return FnData[]
function M.get_fn(b)
	---@type FnData[]
	local defs = {}
	-- capture our `fn()` calls
	local fn_query_id = {
		type_def = "type_def",
		type_comment = "type_comment",
	}
	local fn_query = vim.treesitter.query.parse(
		"lua",
		[[
(function_call
  name: [ ; check our function call is ours
		 (identifier) @fn_call (#eq? @fn_call "fn") ; fn(blah)
		 (dot_index_expression
		   table: (_)
		   field: (identifier) @fn_call (#eq? @fn_call "fn")) ; M.fn(blah)
		 ]
  arguments: (arguments
			   (function_call
				 name: (_) @_type_fn (#eq? @_type_fn "_") ; fn(_"") check for use of cast fun
				 arguments: (arguments
							  (string content: (_) @type_def))) ; just get the first string argument
			   (comment (_) @type_comment)?
		))
]]
	)
	local parser = vim.treesitter.get_parser(b, "lua", {})
	if not parser then
		return {}
	end
	local tree = parser:parse()[1]
	local root_node = tree:root()
	for id, node, metadata, match in fn_query:iter_captures(root_node, b) do
		local name = fn_query.captures[id] -- name of the capture in the query

		if name == fn_query_id.type_def then
			local row1, col1, row2, col2 = node:range() -- range of the capture
			if not row1 or not row2 or not col1 or not col2 then
				error "?"
			end
			---@type FnData
			local def = {
				start_row = row1,
				end_row = row2,
				start_col = col2,
				end_col = col2,
				replacement = "@as " .. vim.treesitter.get_node_text(node, b),
			}
			table.insert(defs, def)
		elseif name == fn_query_id.type_comment then
			-- if we have a type comment, replace it
			local row1, col1, row2, col2 = node:range() -- range of the capture
			if not row1 or not row2 or not col1 or not col2 then
				error "?"
			end
			local def = defs[#defs]
			def.start_row = row1
			def.end_col = col2
			def.end_row = row2
			def.start_col = col1
		end
	end

	return defs
end

function M.setup()
	dd "setup autocmds"
	-- resize splits if window got resized
	vim.api.nvim_create_autocmd({ "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("codethread_ct", { clear = true }),
		callback = function(opts)
			local b = opts.buf
			local changes = M.get_fn(b)
			for _, change in ipairs(changes) do
				vim.api.nvim_buf_set_text(
					b, --
					change.start_row,
					change.start_col,
					change.end_row,
					change.end_col,
					{ change.replacement }
				)
			end
		end,
	})
end

return M
