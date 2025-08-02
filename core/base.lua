-- ===================
-- ✔️ SETUP
-- ===================
---@type function
debugprint = debugprint
function debugprint() end
debugprint('BOOT')

local NAME = 'GroupManager'
local _G = getfenv()

-- ===================
-- ✔️ DATA
-- ===================
local SLASH = {}

BASE = setmetatable({}, {
    __index = function(t, k)
        local stack = debugstack(2)
        if not string.find(stack, NAME) then
            error('BASE:' .. k .. ' - Access denied: Not a ' .. NAME .. ' file')
            return
        end
        return rawget(t, k)
    end
})

local ENV = setmetatable({NAME = NAME, centralBooted = false, allBooted = false}, {__index = getfenv()})
ENV.info = {
    TOCversion = GetAddOnMetadata(NAME, 'Version'),
    DBversion = GetAddOnMetadata(NAME, 'X-DBVersion'),
    author = GetAddOnMetadata(NAME, 'Author'),
}

-- ===================
-- ✔️ SHARED
-- ===================
function BASE:ENV()
    local _, _, filename = string.find(debugstack(2), '\\([^\\]+%.lua)')
    local oldEnv = getfenv(2)
    ENV._G = _G
    setfenv(2, ENV)
    debugprint('BASE:ENV - FILE: ' .. (filename or 'unknown') .. ' - ENV: ' .. tostring(oldEnv) .. ' -> ' .. tostring(ENV))
end

function BASE:SLASH(cmd, func)
    SLASH[cmd or ''] = func
    debugprint('BASE:SLASH - Registering command: ' .. cmd .. ' -> ' .. tostring(func))
end

function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFEEEEEEGroup|cFF00AAFFManager|r: " .. tostring(msg))
end

-- ===================
-- ✔️ SLASH SYSTEM
-- ===================
SLASH_GRPM1 = '/grpm'
SlashCmdList['GRPM'] = function(msg)
    if SLASH[msg] then
        SLASH[msg]()
    elseif SLASH[''] then
        SLASH['']()
    end
end
