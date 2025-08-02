-- ===================
-- ✔️ SETUP
-- ===================
BASE:ENV()

local INIT = CreateFrame 'Frame'

-- ===================
-- ✔️ DATA
-- ===================
_G.GM_GROUPS = {}

local Callbacks = {}
local Modules = {}

ModuleCores = {}
TempDB = {}
Tools = {}
Gui = {}

-- ===================
-- ✔️ CORE
-- ===================
function INIT:LoadTempDB()
    _G.GM_GROUPS.info = _G.GM_GROUPS.info or {}
    if not _G.GM_GROUPS.info.DBversion or _G.GM_GROUPS.info.DBversion ~= info.DBversion then
        debugprint('LoadTempDB - DB v: ' .. (_G.GM_GROUPS.info.DBversion or 'nil') .. ' -> v: ' .. info.DBversion .. ', wiping')
        TempDB = {}
        _G.GM_GROUPS = {}
        _G.GM_GROUPS.info = {DBversion = info.DBversion}
    end

    for name, saved in _G.GM_GROUPS do
        TempDB[name] = saved
        debugprint('LoadTempDB - ' .. name .. ' copied to TempDB')
    end
end

function INIT:Reset()
    debugprint 'Reset - wiping TempDB and GM_GROUPS'
    TempDB = {}
    _G.GM_GROUPS = {}
    ReloadUI()
end

-- ===================
-- ✔️ SHARED
-- ===================
function INSTALL(name, priority, func)
    table.insert(Modules, {name = name, priority = priority, func = func})
    debugprint('INSTALL - ' .. name .. ' module installed with priority ' .. priority)
end

function BOOTMODULES()
    table.sort(Modules, function(a, b) return a.priority < b.priority end)
    local totalModules = table.getn(Modules)
    local loadedModules = 0

    for i = 1, totalModules do
        local module = Modules[i]
        if not centralBooted then
            if module.name == 'Central' then
                debugprint('BOOTMODULES - executing ' .. module.name .. ' (priority ' .. module.priority .. ')')
                local success, err = pcall(module.func)
                if success then
                    loadedModules = loadedModules + 1
                else
                    debugprint('BOOTMODULES - ERROR in ' .. module.name .. ': ' .. err)
                    error('BOOTMODULES - ERROR in ' .. module.name .. ': ' .. err)
                end
            end
        else
            if module.name ~= 'Central' then
                debugprint('BOOTMODULES - executing ' .. module.name .. ' (priority ' .. module.priority .. ')')
                local success, err = pcall(module.func)
                if success then
                    loadedModules = loadedModules + 1
                else
                    debugprint('BOOTMODULES - ERROR in ' .. module.name .. ': ' .. err)
                    error('BOOTMODULES - ERROR in ' .. module.name .. ': ' .. err)
                end
            end
        end
    end

    if not centralBooted then
        centralBooted = true
    elseif loadedModules == (totalModules - 1) then
        allBooted = true
        debugprint('BOOTMODULES - all ' .. totalModules .. ' modules loaded')
    end
end

function INSTALLCALLBACK(eventName, callback)
    Callbacks[eventName] = Callbacks[eventName] or {}
    table.insert(Callbacks[eventName], callback)
end

function ACTIVATECALLBACK(eventName)
    if Callbacks[eventName] then
        for i = 1, table.getn(Callbacks[eventName]) do
            Callbacks[eventName][i]()
        end
    end
end

function INSTALLCORE(name, moduleTable)
    ModuleCores[name] = moduleTable
    debugprint('InstallCore - ' .. name .. ' registered')
end

function GETCORE(name)
    debugprint('GetCore - ' .. name .. ' requested')
    return ModuleCores[name]
end

function SETDATA(table, key, value)
    assert(key and key ~= '', 'SETDATA - invalid key')
    assert(table, 'SETDATA - table required')
    if value == nil then
        debugprint('SETDATA - WARNING: setting ' .. key .. ' to nil')
    end
    table[key] = value
    -- debugprint('SETDATA - ' .. key .. ' = ' .. tostring(value))
end

function GETDATA(table, key)
    assert(key and key ~= '', 'GETDATA - invalid key')
    assert(table, 'GETDATA - table required')
    local value = table[key]
    if value == nil then
        debugprint('GETDATA - WARNING: ' .. key .. ' is nil')
    end
    debugprint('GETDATA - ' .. key .. ' = ' .. tostring(value))
    return value
end

-- ===================
-- ✔️ EVENTS
-- ===================
INIT:RegisterEvent 'ADDON_LOADED'
INIT:RegisterEvent 'PLAYER_LOGOUT'
INIT:SetScript('OnEvent', function()
    if event == 'ADDON_LOADED' and arg1 == NAME then
        debugprint('ADDON_LOADED: ' .. NAME)
        this:LoadTempDB()
        BOOTMODULES()
        BASE:SLASH('reset', function() INIT:Reset() end)
        print("Welcome to GroupManager v" .. info.DBversion .. " - /grpm for options")
        this:UnregisterEvent 'ADDON_LOADED'
    elseif event == 'PLAYER_LOGOUT' then
        _G.GM_GROUPS = TempDB
        debugprint('PLAYER_LOGOUT - ' .. table.getn(TempDB) .. ' entries saved')
    end
end)
