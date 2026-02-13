# Lua ENUM DSL (Lua 5.4)

Tiny enum helper that lets you write C++-style enums in plain Lua.

## Features

- No strings in enum declarations
- Supports explicit values: `NAME(10)`
- Supports implicit auto values: `NAME` (auto increments)
- Auto values start at `1`
- After an explicit value, the next implicit continues from `value + 1` (C++ behavior)
- Enum table is written to `_G[enumName]` (global) and also returned

## Usage

```lua
local ENUM = require("ENUM") -- wherever you put the file

ENUM "HOUSING_e" {
  APARTMENT,        -- 1
  HOUSE,            -- 2
  MANSION,          -- 3
  SHOP(10),         -- 10
  OFFICE,           -- 11
  WAREHOUSE(20),    -- 20
  GARAGE,           -- 21
  TRAILER,          -- 22
  HIGHENDAPARTMENT, -- 23
}

print(HOUSING_e.APARTMENT)         -- 1
print(HOUSING_e.SHOP)              -- 10
print(HOUSING_e.HIGHENDAPARTMENT)  -- 23
print(HOUSING_e.NONEXISTENT)       -- nil
