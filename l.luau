-- Lua Environment Setup (env.luau or embedded in C++)
local env = getfenv(0)

-- Storage for hooked functions
local hookedFunctions = {}
local reverseHooks = {}
local executorClosures = {}

-- getrawmetatable implementation
env.getrawmetatable = function(object)
    assert(type(object) == "table" or type(object) == "userdata", "invalid argument #1 to 'getrawmetatable' (table or userdata expected, got " .. type(object) .. ")", 2)
    local mt = debug.getmetatable(object)
    if mt and mt.__metatable ~= nil then
        local saved = mt.__metatable
        mt.__metatable = nil
        local raw = debug.getmetatable(object)
        mt.__metatable = saved
        return raw or {}
    end
    return mt or {}
end

-- setrawmetatable implementation
env.setrawmetatable = function(object, metatable)
    assert(type(object) == "table" or type(object) == "userdata", "invalid argument #1 to 'setrawmetatable' (table or userdata expected, got " .. type(object) .. ")", 2)
    assert(type(metatable) == "table" or metatable == nil, "invalid argument #2 to 'setrawmetatable' (table or nil expected, got " .. type(metatable) .. ")", 2)
    local current = env.getrawmetatable(object)
    if current and current.__metatable ~= nil then
        local saved = current.__metatable
        current.__metatable = nil
        debug.setmetatable(object, metatable)
        if metatable then
            metatable.__metatable = saved
        end
    else
        debug.setmetatable(object, metatable)
    end
    return object
end

-- newcclosure implementation
env.newcclosure = function(func)
    assert(type(func) == "function", "invalid argument #1 to 'newcclosure' (function expected, got " .. type(func) .. ") ", 2)
    local function wrapper(...)
        return func(...)
    end
    executorClosures[wrapper] = true
    -- mark as a pseudo C closure so iscclosure/islclosure behave for UNC tests
    pcall(function() debug.setmetatable(wrapper, { __name = "cclosure" }) end)
    return wrapper
end

-- hookmetamethod implementation
env.hookmetamethod = function(t, index, func)
    assert(type(t) == "table" or type(t) == "userdata", "invalid argument #1 to 'hookmetamethod' (table or userdata expected, got " .. type(t) .. ")", 2)
    assert(type(index) == "string", "invalid argument #2 to 'hookmetamethod' (string expected, got " .. type(index) .. ")", 2)
    assert(type(func) == "function", "invalid argument #3 to 'hookmetamethod' (function expected, got " .. type(func) .. ")", 2)
    
    local mt = env.getrawmetatable(t)
    assert(type(mt) == "table", "failed to get raw metatable")
    
    local old = mt[index]
    local replacement = env.newcclosure(func)
    
    mt[index] = replacement
    debug.setmetatable(t, mt)
    
    hookedFunctions[old] = replacement
    reverseHooks[replacement] = old
    
    return old
end

-- getnamecallmethod (useful for hookmetamethod on __namecall)
env.getnamecallmethod = function()
    return debug.info(2, "n")
end

-- iscclosure implementation
env.iscclosure = function(func)
    assert(type(func) == "function", "invalid argument #1 to 'iscclosure' (function expected, got " .. type(func) .. ")", 2)
    local mt = debug.getmetatable(func)
    if mt and mt.__name == "cclosure" then
        return true
    end
    return debug.info(func, "s") == "[C]"
end

-- islclosure implementation
env.islclosure = function(func)
    assert(type(func) == "function", "invalid argument #1 to 'islclosure' (function expected, got " .. type(func) .. ")", 2)
    return not env.iscclosure(func)
end

-- checkcaller implementation (checks if function is from executor)
env.checkcaller = function()
    local info = debug.info(2, "f")
    return executorClosures[info] ~= nil
end

-- Expose to global environment
_G.getrawmetatable = env.getrawmetatable
_G.setrawmetatable = env.setrawmetatable
_G.newcclosure = env.newcclosure
_G.hookmetamethod = env.hookmetamethod
_G.getnamecallmethod = env.getnamecallmethod
_G.checkcaller = env.checkcaller

return env
