-- vim.cmd.Reload "ct"
-- require("ct.macros").setup()

local M = {}

---@class Foo
---@field name string

---@class Types
---@field fn1 fun(): Foo

function M._(...) end

---@generic Fn
---@param _type_annotation Fn
---@return { impl: fun(a:Fn):Fn }
function M.fn(_type_annotation)
	return {
		impl = function(fn)
			return fn
		end,
	}
end

do -- example usage
	local _ = M._
	-- local f = M.fn(_ "fun(a: number, b: string): number" --[[@as fun(a: number, b: string): number]]).impl( ------
	local f = M.fn(_ "(fn) a: (string) b: (number) @string @number" --[[@as fun(a: number, b: string): number]])
		.impl( ------
			function(a, b)
				return a + a
			end
		)
	vim.print(f(3, ""))
end

return M
