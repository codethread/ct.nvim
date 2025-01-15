---[[
---Going to attempt to replicate clojure spec as close as possible
---
---pros:
---everything is a predicate
---composition is easy
---
---cons:
---does this rely on global namespaces?
---are imports clunky compared to oop style
---]]
--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                                   Lib                                   │
--   ╰─────────────────────────────────────────────────────────────────────────╯
local s = {}

---@class Pred
---@field fn fun(v: unknown): boolean
---@field msg fun(v: unknown): string

---@return Pred
function s.is_string(label)
	return {
		fn = function(x)
			return type(x) == "string"
		end,
		msg = function(x)
			return string.format("spec %s expected string got %s", label, type(x))
		end,
	} --[[@as Pred]]
end

function s.is_number(label)
	return {
		fn = function(x)
			return type(x) == "number"
		end,
		msg = function(x)
			return string.format("spec %s expected number got %s", label, type(x))
		end,
	} --[[@as Pred]]
end

---@generic Fn
---@param fn Fn
---@return Fn
function s.fdef(fn)
	local orig = fn
	return function(...)
		print "wrap"
		return orig(50, ...)
	end
end

function s.valid(predicate, val)
	local valid = predicate.fn(val)
	return valid
end

function s.def(label, predicate)
	return predicate(label)
end

function s.or_(label, preds)
	return function(input)
		local success = false
		for _, pred in ipairs(preds) do
			if pred(label) then
				success = true
			end
		end
	end
end

function s.explain(predicate, val)
	local valid = predicate.fn(val)
	return valid and val or predicate.msg(val)
end

--   ╭─────────────────────────────────────────────────────────────────────────╮
--   │                                   App                                   │
--   ╰─────────────────────────────────────────────────────────────────────────╯

local n = s.def("n", s.is_string)
local s = s.def("s", s.is_number)
local n_or_s = s.def("n_or_s", s.or_(n, s))

print(s.valid(n, 3))
print(s.explain(n, 3))
print(s.valid(n, "hi"))

------@param a number
------@param b number
------@return number
---local add_bigger = function (a, b, c)
---	return a + b  + c
---end
---
---add_bigger = s.fdef(add_bigger)
---
---print(add_bigger(1, 3))
---print(add_bigger(8,8))
---
