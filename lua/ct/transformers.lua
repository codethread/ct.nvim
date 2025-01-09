local M = {}

---A transform stores the mechanism to create and delete a macro expansion
---@class ct.Transform
---@field private id string Not yet sure if I want this, but thinking this would help with deletion, if added to a comment
---@field private bufn? number
---@field private file? string
---@field private target { start: number, end_:number } lines to write to
---@field private code string[]
---@field private written boolean
local Transform = {}

---@class ct.TransformWriteOpts
---@field bufn? number

function Transform:write() end

function Transform:delete() end

---@return ct.Transform
function Transform.new()
	for _, m in pairs(Ct.macro_cache) do
	end
	return {}
end

---comment
---@param macro ct.Type
local function eval(macro) end

---Process (expand) all macros
---@param config ct.Config
---@param types ct.FileTypes
---@return ct.Transform[]
function M.run(config, types)
	Ct = { types = types } -- smash into global
	for _, t in pairs(types.types) do
		if t._tag == "macro" then
			local code_lines = vim.list_extend({
				[[local _ = _G.Ct]],
			}, t.to_string())
			local t = vim.fn.tempname()
			vim.fn.writefile(code_lines, t)
			vim.cmd.edit(t)

			local code = table.concat(code_lines, "\n")

			local out, err = loadstring(code)
			if out then
				dd(out())
			else
				error(err)
			end
		end
	end
	return {}
end

return M
