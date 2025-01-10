---@diagnostic disable: unused-local

_G.Ct = { is_test = false }

-- -- not sure where this has gone XXX
if table.pack == nil then
	function table.pack(...)
		return { n = select("#", ...), ... }
	end
end

----@class Assert.Are
----@field equal fun(a, b) # assert deeply
----@field same fun(a, b) # assert reference

-----@class Assert.Are<A, B>: {}
-----@field equal fun(a, b) # assert deeply
-----@field same fun(a, b) # assert reference

---@class Assert
_G.assert = assert

---@param a unknown
---@param b unknown
function assert.eq(a, b)
	(assert --[[@as any]]).are.same(a, b)
end

---@param a unknown
---@param b unknown
function assert.same_ref(a, b)
	(assert --[[@as any]]).are.equal(a, b)
end
