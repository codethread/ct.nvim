---@diagnostic disable: unused-local

----@class Assert.Are
----@field equal fun(a, b) # assert deeply
----@field same fun(a, b) # assert reference

-----@class Assert.Are<A, B>: {}
-----@field equal fun(a, b) # assert deeply
-----@field same fun(a, b) # assert reference

---@class Assert.has
---@field error function # something that will error
---@field no Assert.has

---@class Assert
---@field has Assert.has
_G.assert = assert

---@class _G
---@field pending fun(desc: string):nil

---Same deep value
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
