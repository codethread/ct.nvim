# Class with inheritance

## Basic Class

Here is an example of writing classes in lua. It allows for a single line of inheritance, which can be great for encapsulating data and behaviour.

### Pros

- No magic
- Single types for each class, making it easy to find and track things

### Cons

- new method should come last
- new method needs to be set up to apply the fields directly and this is error prone, our LSP is only so much help here

```lua
---@class Base
---@field x integer
---@field y integer
local Base = {}

function Base:sum()
	return self.x + self.y
end

---@param x integer
---@return Base
function Base.new(x, y)
	---@type Base
	local _B = { x = x, y = y }
	-- ^ this has a type error because of missing methods
	-- but it does give us some auto complete
	return setmetatable(_B, { __index = Base })
end

---@class A : Base
---@field z string
local A = setmetatable({}, { __index = Base })

---@param x integer
---@param y integer
---@param z integer
---@return A
function A.new(x, y, z)
	local _base = Base.new(x, y)
	---@type A
	local _A = _base
	_A.z = z -- set additional properties
	return setmetatable(_A, { __index = A })
end

function A:inherited_sum()
	return self.x + self.y
end

function A:sum_all()
	return self:sum() + self.z
end

for _, i in ipairs({
	{ 1, 2, 3 },
	{ 3, 2, 3 },
	{ 5, 5, 5 },
}) do
	local instance = A.new(unpack(i))
	print(instance:inherited_sum(), instance:sum_all())
end
```

## Separation of data and methods

Here we create **our own convention** of separating data from behaviour types with a `Struct` suffix. This has not syntactic meaning, but we can use this as pattern to then make it easy to type the `constructors` for our classes by ensuring all data is set up correctly and then adding methods

### Pros

- No magic
- Type safe
- pattern, but easy to use

### Cons

- new method should come last
- have to remember a convention
- lsp won't do quite as well when jumping to definition
- separation of types could be confusing, but hopefully in practice these are almost identical

```lua
---@class BaseStruct
---@field x number
---@field y number

---@class Base : BaseStruct
local Base = {}

function Base:sum()
	return self.x + self.y
end

---@param x number
---@return Base
function Base.new(x, y)
	---@type BaseStruct
	local _B = { x = x, y = y } -- fully typed!
	-- our return type is out of sync, so we have to cast the type
	return setmetatable(_B, { __index = Base }) --[[@as any]]
end

---@class AStruct
---@field z number

---@class A : AStruct, Base
local A = setmetatable({}, { __index = Base })

---@param x number
---@param y number
---@param z number
---@return A
function A.new(x, y, z)
	local _base = Base.new(x, y)
	---@type AStruct
	local _A = { z = z }

	-- now we merge and tbl_extend at this time just returns
	-- `table`. If this becomes generic, we'd need a type assertion
	local a = vim.tbl_extend('force', _base, _A)
	return setmetatable(a, { __index = A })
end

function A:inherited_sum()
	return self.x + self.y
end

function A:sum_all()
	return self:sum() + self.z
end

for _, i in ipairs({
	{ 1, 2, 3 },
	{ 3, 2, 3 },
	{ 5, 5, 5 },
}) do
	local instance = A.new(unpack(i))
	print(instance:inherited_sum(), instance:sum_all())
end
```
