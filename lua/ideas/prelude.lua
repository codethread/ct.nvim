---@diagnostic disable: unused-local

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
