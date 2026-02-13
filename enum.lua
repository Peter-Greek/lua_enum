local ENUM_RUN_TESTS = true
local function _pair(k, v, is_auto)
	return { __enum_key = k, __enum_val = v, __enum_auto = is_auto == true }
end
local function _symbol(name)
	return function(v)
		-- if user wrote NAME (x) then v is provided
		if v ~= nil then
			return _pair(name, v, false)
		end
		-- if user wrote NAME with no parentheses, we need a bare value in the list
		-- but Lua cannot place a function call-less identifier into a list without evaluating it
		-- so we return an auto marker by making the symbol itself evaluate to this marker:
		return _pair(name, nil, true)
	end
end
local function _build(list)
	local enum = {}
	local next_auto = 1

	for i = 1, #list do
		local item = list[i]
		if type(item) == "table" and item.__enum_key ~= nil then
			local key = item.__enum_key

			if item.__enum_auto then
				enum[key] = next_auto
				next_auto = next_auto + 1
			else
				local v = item.__enum_val
				enum[key] = v
				-- C++ style: after explicit value, next implicit continues from v+1
				if type(v) == "number" then
					next_auto = v + 1
				end
			end
		end
	end

	return enum
end
local function _stack_contains_func(target_func, max_depth)
	max_depth = max_depth or 12
	for level = 2, max_depth do
		local info = debug.getinfo(level, "f")
		if not info then break end
		if info.func == target_func then
			return true
		end
	end
	return false
end

ENUM = setmetatable({}, {
	__call = function(_, enumName)
		local prev_mt = getmetatable(_G)
		local prev_index = prev_mt and prev_mt.__index or nil

		-- function that invoked: ENUM "NAME"
		local caller = debug.getinfo(2, "f").func
		local caller_co = coroutine.running()

		local sym_cache = {}

		local function guarded_index(t, k)
			-- preserve any prior __index behavior
			if type(prev_index) == "function" then
				local v = prev_index(t, k)
				if v ~= nil then return v end
			elseif type(prev_index) == "table" then
				local v = prev_index[k]
				if v ~= nil then return v end
			end

			-- real globals
			local v = rawget(t, k)
			if v ~= nil then return v end

			-- only during the same call chain + same coroutine
			if coroutine.running() ~= caller_co then
				return nil
			end
			if not _stack_contains_func(caller) then
				return nil
			end

			v = sym_cache[k]
			if not v then
				-- IMPORTANT: return a value that can appear in the list without parentheses
				-- We make the global lookup itself return the AUTO marker table,
				-- but we also want parentheses support. So we return a callable table:
				local auto_marker = _pair(k, nil, true)
				v = setmetatable(auto_marker, {
					__call = function(_, arg)
						return _pair(k, arg, false)
					end
				})

				sym_cache[k] = v
			end

			return v
		end

		local tmp_mt = {}
		if prev_mt then
			for k, v in pairs(prev_mt) do
				tmp_mt[k] = v
			end
		end
		tmp_mt.__index = guarded_index

		setmetatable(_G, tmp_mt)

		return function(list)
			setmetatable(_G, prev_mt)

			local enum = _build(list)
			rawset(_G, enumName, enum)
			return enum
		end
	end
})

if ENUM_RUN_TESTS then
	-- note: use ENUM
	local x = ENUM "HOUSING_e" ({
		APARTMENT,        -- 1
		HOUSE,            -- 2
		MANSION,          -- 3
		SHOP(10),         -- 10
		OFFICE,           -- 11
		WAREHOUSE(20),    -- 20
		GARAGE,           -- 21
		TRAILER,          -- 22
		HIGHENDAPARTMENT, -- 23
	})

	print(HOUSING_e.APARTMENT, HOUSING_e.HIGHENDAPARTMENT, HOUSING_e.NONEXISTENT)
end

return ENUM
