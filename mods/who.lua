BASE:ENV()

INSTALL('Who', 1, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local WHO = {
        pendingQuery = false,
        WHISPER_DELAY = 4,
        whisperQueue = {},
        lastScanTime = nil,
        lastEstimatedTime = 0,
        whisperedPlayers = {},
        whisperedOrder = {},
        MAX_WHISPERED_PLAYERS = 500,
    }

    local H = {
        AddWhisperedPlayer = function(playerName)
            if WHO.whisperedPlayers[playerName] then return end

            if table.getn(WHO.whisperedOrder) >= WHO.MAX_WHISPERED_PLAYERS then
                local oldestPlayer = WHO.whisperedOrder[1]
                WHO.whisperedPlayers[oldestPlayer] = nil
                table.remove(WHO.whisperedOrder, 1)
                debugprint('H:AddWhisperedPlayer - removed oldest: ' .. oldestPlayer)
            end

            WHO.whisperedPlayers[playerName] = true
            table.insert(WHO.whisperedOrder, playerName)
        end,
    }

    -- ===================
    -- ✔️ CORE
    -- ===================
    function WHO:Scan(class, minLevel, maxLevel)
        local whoQuery = ''
        if minLevel and maxLevel then
            whoQuery = tostring(minLevel) .. '-' .. tostring(maxLevel)
        end
        if class then
            local className = string.upper(string.sub(class, 1, 1)) .. string.sub(class, 2)
            whoQuery = whoQuery .. ' c-' .. className
        end
        debugprint('WHO:Scan - query: ' .. whoQuery)
        WHO.pendingQuery = true
        WHO.lastScanTime = GetTime()
        SendWho(whoQuery)
        -- Start continuous frame hiding
        WHO.HIDE_FRAME = CreateFrame('Frame')
        WHO.HIDE_FRAME:SetScript('OnUpdate', function()
            if WHO.pendingQuery then
                if CharacterFrame and CharacterFrame:IsVisible() then
                    CharacterFrame:Hide()
                end
                if FriendsFrame and FriendsFrame:IsVisible() then
                    FriendsFrame:Hide()
                end
            else
                WHO.HIDE_FRAME:SetScript('OnUpdate', nil)
            end
        end)
        return true
    end

    function WHO:ParseResults()
        local players = {}
        local count = GetNumWhoResults()

        for i = 1, count do
            local name = GetWhoInfo(i)
            table.insert(players, name)
        end

        debugprint('WHO:ParseResults - found ' .. count .. ' players')
        debugprint('WHO:ParseResults - currentDungeon: ' .. tostring(WHO.currentDungeon))

        if not WHO.currentDungeon then
            debugprint('WHO:ParseResults - currentDungeon is nil, aborting whispers')
            return
        end

        local totalTime = self:WhisperPlayers(players, WHO.currentDungeon)
        WHO.lastEstimatedTime = totalTime
        if totalTime > 0 then
            LoadingBarManager:Destroy('whoProgress')
            local whoLoadingBar = LoadingBarManager:Create('whoProgress', 50, 2, false, 'left', totalTime)
            local GUI = GETCORE('Gui')
            if whoLoadingBar and GUI and GUI.automation and GUI.automation.whoStopBtn then
                whoLoadingBar:SetPoint('LEFT', GUI.automation.whoStopBtn, 'RIGHT', 15, 0)
                whoLoadingBar:SetParent(GUI.sectors.botRight)
                local barData = LoadingBarManager.bars['whoProgress']
                if barData and barData.bar then
                    barData.bar:SetVertexColor(0, 0.8, 0)
                end
            end
        end
        debugprint('WHO:ParseResults - whisper queue will complete in ' .. totalTime .. ' seconds')
    end

    function WHO:WhisperPlayers(playerList, dungeonName)
        debugprint('WHO:WhisperPlayers - dungeon: ' .. tostring(dungeonName))
        local message = 'Hey, want to join our ' .. tostring(dungeonName) .. '? Type "inv" for auto-invite!'
        debugprint('WHO:WhisperPlayers - message: ' .. message)

        WHO.whisperQueue = {}
        for i = 1, table.getn(playerList) do
            local playerName = playerList[i]
            if not WHO.whisperedPlayers[playerName] then
                local delay = (i - 1) * WHO.WHISPER_DELAY
                local whisperTime = GetTime() + delay

                table.insert(WHO.whisperQueue, {
                    player = playerName,
                    message = message,
                    time = whisperTime
                })
            else
                debugprint('WHO:WhisperPlayers - skipping ' .. playerName .. ' (already whispered)')
            end
        end

        local totalTime = table.getn(WHO.whisperQueue) * WHO.WHISPER_DELAY
        if table.getn(WHO.whisperQueue) > 0 then
            debugprint('WHO:WhisperPlayers - starting whisper queue with ' .. table.getn(WHO.whisperQueue) .. ' players')
            WHO.WHISPER_FRAME:SetScript('OnUpdate', function()
                local now = GetTime()
                if now < (this.tick or 0) then return end
                this.tick = now + 0.1

                for i = table.getn(WHO.whisperQueue), 1, -1 do
                    local whisperData = WHO.whisperQueue[i]
                    if now >= whisperData.time then
                        SendChatMessage(whisperData.message, 'WHISPER', nil, whisperData.player)
                        debugprint('WHO:WhisperPlayers - whispered ' .. whisperData.player)
                        H.AddWhisperedPlayer(whisperData.player)
                        table.remove(WHO.whisperQueue, i)
                    end
                end
            end)
        end
        return totalTime
    end

    function WHO:HandleInviteResponse(playerName)
        local partySize = GetNumPartyMembers()
        if partySize >= 4 then
            debugprint('WHO:HandleInviteResponse - party full, cannot invite ' .. playerName)
            SendChatMessage('Sorry, we are full!', 'WHISPER', nil, playerName)
            return
        end
        debugprint('WHO:HandleInviteResponse - inviting ' .. playerName)
        InviteByName(playerName)
    end

    function WHO:StopAll()
        self.pendingQuery = false
        self.whisperQueue = {}
        WHO.WHISPER_FRAME:SetScript('OnUpdate', nil)
        debugprint('WHO:StopAll - cleared all WHO activity')
    end

    -- ===================
    -- ✔️ EVENTS
    -- ===================
    WHO.FRAME = CreateFrame 'Frame'
    WHO.FRAME:RegisterEvent 'WHO_LIST_UPDATE'
    WHO.FRAME:RegisterEvent 'CHAT_MSG_WHISPER'
    WHO.FRAME:SetScript('OnEvent', function()
        if event == 'WHO_LIST_UPDATE' and WHO.pendingQuery then
            WHO.pendingQuery = false
            WHO:ParseResults()
            HideUIPanel(FriendsFrame)
        elseif event == 'CHAT_MSG_WHISPER' then
            local message = arg1
            local playerName = arg2
            if string.find(string.lower(message), 'inv') then
                debugprint('WHO:HandleInviteResponse - marking ' .. playerName .. ' as whispered')
                H.AddWhisperedPlayer(playerName)
                WHO:HandleInviteResponse(playerName)
            end
        end
    end)

    WHO.WHISPER_FRAME = CreateFrame 'Frame'

    INSTALLCORE('Who', WHO)
end)