# lua lsp

The lsp is amazing, and the more can be pushed into static analysis, the better.

## 'Holes' in the system

### nested table fields

Using tables in fields will not be picked up correctly

```lua
---@class (exact) Struct
---@field a integer
---@field b { x: integer, b: integer }

---@param st Struct
local function sum(st) end

sum({ a = 1, b = {} }) -- 😞 no error
```

solution, define all structs

```lua
---@class NestedStruct
---@field x integer
---@field y integer

---@class (exact) Struct
---@field a integer
---@field b NestedStruct

---@param st Struct
local function sum(st) end

print(sum({ a = 1, b = {} })) -- error yay
```

### Meta methods are assumed to work

Understandably, anything on the `metatable` is assumed to work, e.g `+` or `..`, so it's easy to try it on things that don't work

```lua
---@class (exact) Struct
---@field a integer
---@field b { x: integer, b: integer }

---@param st Struct
local function sum(st)
	local t = st.a + st.b -- no error as `__add could be implemented`
	return t -- type unknown
end
```

Solution? None, tried playing with traits but it's a struggle and falls over due to lack of generics

### Interfaces don't need to be upheld

```lua
---@class Interface
---@field read fun(self, target: string): string[]
---@field write fun(self, target: string, out: string[]): boolean

---@class FileIo : Interface
local FileIo = {}
-- write isn't implemented

---@param t string
function FileIo:read(t) -- incorrect implementation
end

---@param reader Interface
local function process(reader)
	local lines = reader:read('target')
end

print(process(FileIo))
```

### generics can't be inheritied from

```lua
---@class XX<T>: { foo: T }

---@type XX<string>
local xx = {}
print(xx.foo:lower()) -- all good

---@class YY : XX<string>
local xxYY = {}

xxYY.foo -- no type
```
