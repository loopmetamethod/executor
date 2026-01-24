if not getgenv().folder then
    getgenv().folder = {}
end

local game = game
local Instance = Instance

local http = {}
http.request = request or http_request or syn_request

getgenv().http = http
getgenv().syn = getgenv().syn or {}
getgenv().syn.request = http.request

local cache = cache or {}
getgenv().cache = cache

local crypt = crypt or {}
getgenv().crypt = crypt

local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

function Signal:Connect(callback)
    local connection = {
        Connected = true,
        Callback = callback,
        Disconnect = function(self)
            self.Connected = false
        end
    }
    table.insert(self._connections, connection)
    return connection
end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection.Callback, ...)
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

getgenv().getconnections = getconnections or function(signal)
    local connections = {}
    
    if typeof(signal) == "RBXScriptSignal" then
        local temp = signal:Connect(function() end)
        
        connections[1] = {
            Enabled = true,
            ForeignState = false,
            LuaConnection = true,
            Function = function() end,
            Thread = coroutine.running(),
            Fire = function(self, ...)
                if self.Enabled then
                    task.spawn(self.Function, ...)
                end
            end,
            Defer = function(self, ...)
                if self.Enabled then
                    task.defer(self.Function, ...)
                end
            end,
            Disconnect = function(self)
                self.Enabled = false
                temp:Disconnect()
            end,
            Disable = function(self)
                self.Enabled = false
            end,
            Enable = function(self)
                self.Enabled = true
            end
        }
    end
    
    return connections
end

getgenv().getscripts = getscripts or function()
    local scripts = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
    end
    return scripts
end

getgenv().getloadedmodules = getloadedmodules or function()
    local modules = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            table.insert(modules, obj)
        end
    end
    return modules
end

getgenv().getrunningscripts = getrunningscripts or function()
    local scripts = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") and obj.Enabled then
            table.insert(scripts, obj)
        end
    end
    return scripts
end

local bit32 = bit32 or bit or {}

if not bit32.band then
    bit32.band = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 and b > 0 do
            if a % 2 == 1 and b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
end

if not bit32.bor then
    bit32.bor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 == 1 or b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
end

if not bit32.bxor then
    bit32.bxor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if (a % 2) ~= (b % 2) then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
end

if not bit32.bnot then
    bit32.bnot = function(n)
        return (-1) - n
    end
end

if not bit32.lshift then
    bit32.lshift = function(a, b)
        return a * (2 ^ b)
    end
end

if not bit32.rshift then
    bit32.rshift = function(a, b)
        return math.floor(a / (2 ^ b))
    end
end

if not bit32.arshift then
    bit32.arshift = function(a, b)
        local result = math.floor(a / (2 ^ b))
        if a < 0 and b > 0 then
            result = result + (2 ^ (32 - b)) - 1
        end
        return result
    end
end

if not bit32.lrotate then
    bit32.lrotate = function(a, b)
        b = b % 32
        return bit32.bor(bit32.lshift(a, b), bit32.rshift(a, 32 - b))
    end
end

if not bit32.rrotate then
    bit32.rrotate = function(a, b)
        b = b % 32
        return bit32.bor(bit32.rshift(a, b), bit32.lshift(a, 32 - b))
    end
end

if not bit32.extract then
    bit32.extract = function(n, field, width)
        width = width or 1
        return bit32.band(bit32.rshift(n, field), (2 ^ width) - 1)
    end
end

if not bit32.replace then
    bit32.replace = function(n, v, field, width)
        width = width or 1
        local mask = (2 ^ width) - 1
        return bit32.bor(
            bit32.band(n, bit32.bnot(bit32.lshift(mask, field))),
            bit32.lshift(bit32.band(v, mask), field)
        )
    end
end

getgenv().bit32 = bit32
getgenv().bit = bit32

local debug_backup = {}
for k, v in pairs(debug) do
    debug_backup[k] = v
end

getgenv().debug = setmetatable({}, {
    __index = function(_, key)
        return debug_backup[key]
    end,
    __newindex = function(_, key, value)
        debug_backup[key] = value
    end
})

local task_backup = {}
for k, v in pairs(task) do
    task_backup[k] = v
end

getgenv().task = setmetatable({}, {
    __index = function(_, key)
        return task_backup[key]
    end,
    __newindex = function(_, key, value)
        task_backup[key] = value
    end
})
