BASE:ENV()

INSTALL('Chat', 1, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local CHAT = {
        watchedKeywords = {},
        respondedPlayers = {},
        respondedOrder = {},
        MAX_RESPONDED_PLAYERS = 500,
    }

    local H = {
        AddRespondedPlayer = function(playerName)
            if CHAT.respondedPlayers[playerName] then return false end

            if table.getn(CHAT.respondedOrder) >= CHAT.MAX_RESPONDED_PLAYERS then
                local oldestPlayer = CHAT.respondedOrder[1]
                CHAT.respondedPlayers[oldestPlayer] = nil
                table.remove(CHAT.respondedOrder, 1)
                debugprint('H:AddRespondedPlayer - removed oldest: ' .. oldestPlayer)
            end

            CHAT.respondedPlayers[playerName] = true
            table.insert(CHAT.respondedOrder, playerName)
            return true
        end,
    }
    -- ===================
    -- ✔️ CORE
    -- ===================
    function CHAT:AddKeyword(keywords, responseMessage)
        local keywordList = {}
        local current = ''
        for i = 1, string.len(keywords) do
            local char = string.sub(keywords, i, i)
            if char == ';' or char == ',' then
                if current ~= '' then
                    table.insert(keywordList, current)
                    current = ''
                end
            else
                current = current .. char
            end
        end
        if current ~= '' then
            table.insert(keywordList, current)
        end

        for i = 1, table.getn(keywordList) do
            local keyword = string.lower(keywordList[i])
            self.watchedKeywords[keyword] = responseMessage or true
            debugprint('CHAT:AddKeyword - added ' .. keyword)
        end
    end

    function CHAT:ScanMessage(message, sender)
        local lowerMessage = string.lower(message)
        for keyword, response in self.watchedKeywords do
            if string.find(lowerMessage, keyword) then
                print('CHAT SCANNER: [' .. sender .. '] ' .. message)
                PlaySound('TellMessage')
                if type(response) == 'string' and H.AddRespondedPlayer(sender) then
                    SendChatMessage(response, 'WHISPER', nil, sender)
                    debugprint('CHAT:ScanMessage - auto-whispered ' .. sender .. ': ' .. response)
                elseif type(response) == 'string' then
                    debugprint('CHAT:ScanMessage - skipping ' .. sender .. ' (already responded)')
                end
                debugprint('CHAT:ScanMessage - found keyword ' .. keyword .. ' from ' .. sender)
                break
            end
        end
    end

    function CHAT:StopAll()
        self.watchedKeywords = {}
        debugprint('CHAT:StopAll - cleared all keywords')
    end

    -- ===================
    -- ✔️ EVENTS
    -- ===================
    CHAT.FRAME = CreateFrame 'Frame'
    CHAT.FRAME:RegisterEvent 'CHAT_MSG_CHANNEL'
    CHAT.FRAME:SetScript('OnEvent', function()
        if event == 'CHAT_MSG_CHANNEL' then
            CHAT:ScanMessage(arg1, arg2)
        end
    end)

    INSTALLCORE('Chat', CHAT)
end)