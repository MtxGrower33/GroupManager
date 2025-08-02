BASE:ENV()

INSTALL('Gui-two', 3, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local GUI = GETCORE('Gui')
    local WHO = GETCORE('Who')
    local CHAT = GETCORE('Chat')

    local GUIT = {
        CONTROL_HEIGHT = 25,
        CONTROL_MARGIN = 15,
        HEADER_SIZE = 14,
        HEADER_Y_OFFSET = -10,
        LABEL_SIZE = 10,
        LABEL_COLOR = {0.7, 0.7, 0.7},
        BLUE_ACCENT = {0, 0.67, 1},

        WHO_SECTION_Y = -30,
        WHO_LABELS_Y = -45,
        WHO_CONTROLS_Y = -60,
        CHAT_SECTION_Y = -90,
        CHAT_LABELS_Y = -105,
        CHAT_CONTROLS_Y = -120,

        STATS_SECTION_Y = -30,
        STATS_ROW_HEIGHT = 15,
        STATS_LABEL_SIZE = 9,
        STATS_VALUE_SIZE = 9,
        STATS_VALUE_COLOR = {1, 1, 1},

        DUNGEON_EDITBOX_WIDTH = 90,
        MINLEVEL_EDITBOX_WIDTH = 40,
        MAXLEVEL_EDITBOX_WIDTH = 40,
        CLASS_DROPDOWN_WIDTH = 70,
        WHO_GO_BTN_WIDTH = 30,
        WHO_STOP_BTN_WIDTH = 40,
        KEYWORD_EDITBOX_WIDTH = 140,
        RESPONSE_EDITBOX_WIDTH = 130,
        CHAT_GO_BTN_WIDTH = 30,
        CHAT_STOP_BTN_WIDTH = 40,

        SMALL_LABEL_SIZE = 8,

        DUNGEON_EDITBOX_MAX_CHARS = 20,
        LEVEL_EDITBOX_MAX_CHARS = 2,
        KEYWORD_EDITBOX_MAX_CHARS = 50,
        RESPONSE_EDITBOX_MAX_CHARS = 100
    }

    -- ===================
    -- ✔️ CORE
    -- ===================
    function GUI:CreateAutomation()
        if self.automation then return end

        local sector = self.sectors.botRight

        -- Header
        local header = Gui.Font(sector, GUIT.HEADER_SIZE, 'Automation', GUIT.BLUE_ACCENT, 'LEFT')
        header:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.HEADER_Y_OFFSET)

        -- WHO Search Section
        local whoLabel = Gui.Font(sector, GUIT.LABEL_SIZE, 'WHO Search [supports auto-invite]', GUIT.STATS_VALUE_COLOR, 'LEFT')
        whoLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.WHO_SECTION_Y)

        -- WHO Labels
        local dungeonLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Dungeon', GUIT.LABEL_COLOR, 'LEFT')
        dungeonLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.WHO_LABELS_Y)

        local minLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Min Lvl', GUIT.LABEL_COLOR, 'LEFT')
        minLabel:SetPoint('LEFT', dungeonLabel, 'LEFT', GUIT.DUNGEON_EDITBOX_WIDTH + GUIT.CONTROL_MARGIN, 0)

        local maxLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Max Lvl', GUIT.LABEL_COLOR, 'LEFT')
        maxLabel:SetPoint('LEFT', minLabel, 'LEFT', GUIT.MINLEVEL_EDITBOX_WIDTH + GUIT.CONTROL_MARGIN, 0)

        local classLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Class', GUIT.LABEL_COLOR, 'LEFT')
        classLabel:SetPoint('LEFT', maxLabel, 'LEFT', GUIT.MAXLEVEL_EDITBOX_WIDTH + GUIT.CONTROL_MARGIN, 0)

        local actionLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Action', GUIT.LABEL_COLOR, 'LEFT')
        actionLabel:SetPoint('LEFT', classLabel, 'LEFT', GUIT.CLASS_DROPDOWN_WIDTH + GUIT.CONTROL_MARGIN, 0)

        -- WHO Controls
        local dungeonBox = Gui.Editbox(sector, GUIT.DUNGEON_EDITBOX_WIDTH, GUIT.CONTROL_HEIGHT, false, false, GUIT.DUNGEON_EDITBOX_MAX_CHARS)
        dungeonBox:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.WHO_CONTROLS_Y)
        dungeonBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local minLevelBox = Gui.Editbox(sector, GUIT.MINLEVEL_EDITBOX_WIDTH, GUIT.CONTROL_HEIGHT, false, true, GUIT.LEVEL_EDITBOX_MAX_CHARS)
        minLevelBox:SetPoint('LEFT', dungeonBox, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        minLevelBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local maxLevelBox = Gui.Editbox(sector, GUIT.MAXLEVEL_EDITBOX_WIDTH, GUIT.CONTROL_HEIGHT, false, true, GUIT.LEVEL_EDITBOX_MAX_CHARS)
        maxLevelBox:SetPoint('LEFT', minLevelBox, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        maxLevelBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local classDropdown = Gui.Dropdown(sector, 'Class', GUIT.CLASS_DROPDOWN_WIDTH, GUIT.CONTROL_HEIGHT)
        classDropdown:SetPoint('LEFT', maxLevelBox, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        classDropdown:AddItem('Warrior')
        classDropdown:AddItem('Paladin')
        classDropdown:AddItem('Hunter')
        classDropdown:AddItem('Rogue')
        classDropdown:AddItem('Priest')
        classDropdown:AddItem('Shaman')
        classDropdown:AddItem('Mage')
        classDropdown:AddItem('Warlock')
        classDropdown:AddItem('Druid')

        local whoGoBtn = Gui.Button(sector, 'Go', GUIT.WHO_GO_BTN_WIDTH, GUIT.CONTROL_HEIGHT)
        whoGoBtn:SetPoint('LEFT', classDropdown, 'RIGHT', GUIT.CONTROL_MARGIN, 0)

        local whoStopBtn = Gui.Button(sector, 'Stop', GUIT.WHO_STOP_BTN_WIDTH, GUIT.CONTROL_HEIGHT, false, {1, 0, 0})
        whoStopBtn:SetPoint('LEFT', whoGoBtn, 'RIGHT', GUIT.CONTROL_MARGIN, 0)

        local whoLoadingBar = LoadingBar(80, GUIT.CONTROL_HEIGHT, false, 'left', 1)
        whoLoadingBar:SetPoint('LEFT', whoStopBtn, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        whoLoadingBar:SetParent(sector)
        whoLoadingBar:Hide()

        -- Chat Keyword Section
        local chatLabel = Gui.Font(sector, GUIT.LABEL_SIZE, 'Chat SCANNER [supports multiple keywords: lfg mc, lfg zg]', GUIT.STATS_VALUE_COLOR, 'LEFT')
        chatLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.CHAT_SECTION_Y)

        -- Chat Labels
        local keywordLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Keywords', GUIT.LABEL_COLOR, 'LEFT')
        keywordLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.CHAT_LABELS_Y)

        local responseLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Optional: Auto-Respond', GUIT.LABEL_COLOR, 'LEFT')
        responseLabel:SetPoint('LEFT', keywordLabel, 'LEFT', GUIT.KEYWORD_EDITBOX_WIDTH + GUIT.CONTROL_MARGIN, 0)

        local chatActionLabel = Gui.Font(sector, GUIT.SMALL_LABEL_SIZE, 'Action', GUIT.LABEL_COLOR, 'LEFT')
        chatActionLabel:SetPoint('LEFT', responseLabel, 'LEFT', GUIT.RESPONSE_EDITBOX_WIDTH + GUIT.CONTROL_MARGIN, 0)

        -- Chat Controls
        local keywordBox = Gui.Editbox(sector, GUIT.KEYWORD_EDITBOX_WIDTH, GUIT.CONTROL_HEIGHT, false, false, GUIT.KEYWORD_EDITBOX_MAX_CHARS)
        keywordBox:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.CHAT_CONTROLS_Y)
        keywordBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local responseBox = Gui.Editbox(sector, GUIT.RESPONSE_EDITBOX_WIDTH, GUIT.CONTROL_HEIGHT, false, false, GUIT.RESPONSE_EDITBOX_MAX_CHARS)
        responseBox:SetPoint('LEFT', keywordBox, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        responseBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local chatGoBtn = Gui.Button(sector, 'Go', GUIT.CHAT_GO_BTN_WIDTH, GUIT.CONTROL_HEIGHT)
        chatGoBtn:SetPoint('LEFT', responseBox, 'RIGHT', GUIT.CONTROL_MARGIN, 0)

        local chatStopBtn = Gui.Button(sector, 'Stop', GUIT.CHAT_STOP_BTN_WIDTH, GUIT.CONTROL_HEIGHT, false, {1, 0, 0})
        chatStopBtn:SetPoint('LEFT', chatGoBtn, 'RIGHT', GUIT.CONTROL_MARGIN, 0)

        local chatLoadingBar = LoadingBar(50, 2, true, 'left', 2)
        chatLoadingBar:SetPoint('LEFT', chatStopBtn, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
        chatLoadingBar:SetParent(sector)
        chatLoadingBar:Hide()

        -- Button Events
        whoGoBtn:SetScript('OnClick', function()
            local dungeon = dungeonBox:GetText()
            local minLevel = minLevelBox:GetText()
            local maxLevel = maxLevelBox:GetText()
            local class = classDropdown.selectedValue
            if not class then return end

            WHO.currentDungeon = dungeon
            WHO:Scan(class, tonumber(minLevel), tonumber(maxLevel))
            debugprint('GUI - WHO scan started for: ' .. dungeon)
        end)

        whoStopBtn:SetScript('OnClick', function()
            WHO:StopAll()
            LoadingBarManager:Destroy('whoProgress')
            debugprint('GUI - WHO scan stopped')
        end)

        chatGoBtn:SetScript('OnClick', function()
            local keywords = keywordBox:GetText()
            if not keywords or keywords == '' then return end
            local response = responseBox:GetText()

            local responseMsg = (response ~= '' and response) or nil
            CHAT:AddKeyword(keywords, responseMsg)
            LoadingBarManager:Destroy('chatProgress')
            chatLoadingBar = LoadingBarManager:Create('chatProgress', 50, 2, true, 'left', 2)
            chatLoadingBar:SetPoint('LEFT', chatStopBtn, 'RIGHT', GUIT.CONTROL_MARGIN, 0)
            chatLoadingBar:SetParent(sector)
            local barData = LoadingBarManager.bars['chatProgress']
            if barData and barData.bar then
                barData.bar:SetVertexColor(0, 0.8, 0)
            end
            debugprint('GUI - Chat monitoring started for: ' .. keywords)
        end)

        chatStopBtn:SetScript('OnClick', function()
            CHAT:StopAll()
            LoadingBarManager:Destroy('chatProgress')
            debugprint('GUI - Chat monitoring stopped')
        end)

        self.automation = {
            dungeonBox = dungeonBox,
            minLevelBox = minLevelBox,
            maxLevelBox = maxLevelBox,
            classDropdown = classDropdown,
            whoGoBtn = whoGoBtn,
            whoStopBtn = whoStopBtn,
            whoLoadingBar = whoLoadingBar,
            chatLoadingBar = chatLoadingBar,
            keywordBox = keywordBox,
            responseBox = responseBox,
            chatGoBtn = chatGoBtn,
            chatStopBtn = chatStopBtn
        }

        debugprint 'GUI - Automation created'
    end

    function GUI:CreateStatistics()
        if self.statistics then return end

        local sector = self.sectors.botLeft

        -- Header
        local header = Gui.Font(sector, GUIT.HEADER_SIZE, 'Information', GUIT.BLUE_ACCENT, 'LEFT')
        header:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.HEADER_Y_OFFSET)

        -- Statistics Labels
        local groupsLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Groups:', GUIT.LABEL_COLOR, 'LEFT')
        groupsLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y)

        local rolesLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Roles:', GUIT.LABEL_COLOR, 'LEFT')
        rolesLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT)

        local ratingsLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Ratings:', GUIT.LABEL_COLOR, 'LEFT')
        ratingsLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 2)

        local invitesLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Session invites sent:', GUIT.LABEL_COLOR, 'LEFT')
        invitesLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 3)

        local lastWhoLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Last WHO search:', GUIT.LABEL_COLOR, 'LEFT')
        lastWhoLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 4)

        local whoQueueLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Active WHO queue:', GUIT.LABEL_COLOR, 'LEFT')
        whoQueueLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 5)

        local scannerQueueLabel = Gui.Font(sector, GUIT.STATS_LABEL_SIZE, 'Active SCANNER queue:', GUIT.LABEL_COLOR, 'LEFT')
        scannerQueueLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 6)

        -- Statistics Values
        local groupsValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        groupsValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y)

        local rolesValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        rolesValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT)

        local ratingsValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        ratingsValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 2)

        local invitesValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        invitesValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 3)

        local lastWhoValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        lastWhoValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 4)

        local whoQueueValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        whoQueueValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 5)

        local scannerQueueValue = Gui.Font(sector, GUIT.STATS_VALUE_SIZE, '', GUIT.STATS_VALUE_COLOR, 'RIGHT')
        scannerQueueValue:SetPoint('TOPRIGHT', sector, 'TOPRIGHT', -GUIT.CONTROL_MARGIN, GUIT.STATS_SECTION_Y - GUIT.STATS_ROW_HEIGHT * 6)

        self.statistics = {
            groupsValue = groupsValue,
            ratingsValue = ratingsValue,
            rolesValue = rolesValue,
            invitesValue = invitesValue,
            lastWhoValue = lastWhoValue,
            whoQueueValue = whoQueueValue,
            scannerQueueValue = scannerQueueValue
        }

        debugprint 'GUI - Statistics created'
    end

    function GUI:CreateStatisticsTimer()
        if self.statisticsTimer then return end

        self.statisticsTimer = CreateFrame('Frame')
        self.statisticsTimer:SetScript('OnUpdate', function()
            local now = GetTime()
            if now < (this.tick or 0) then return end
            this.tick = now + 1

            if not GUI.statistics then return end

            -- Groups count
            local groups = {}
            local totalPlayers = 0
            for key, value in pairs(TempDB) do
                if key ~= 'scheduler' and key ~= 'info' and key ~= 'gui' and type(value) == 'table' then
                    table.insert(groups, key)
                    local groupData = GETDATA(TempDB, key)
                    if groupData then
                        totalPlayers = totalPlayers + table.getn(groupData)
                    end
                end
            end
            GUI.statistics.groupsValue:SetText(table.getn(groups) .. ' total, ' .. totalPlayers .. ' players')

            -- Roles count
            local tankCount = 0
            local healerCount = 0
            local dpsCount = 0
            for key, value in pairs(TempDB) do
                if key ~= 'scheduler' and key ~= 'info' and key ~= 'gui' and type(value) == 'table' then
                    local groupData = GETDATA(TempDB, key)
                    if groupData then
                        for i = 1, table.getn(groupData) do
                            local player = groupData[i]
                            if player.role == 'Tank' then
                                tankCount = tankCount + 1
                            elseif player.role == 'Healer' then
                                healerCount = healerCount + 1
                            elseif player.role == 'DPS' then
                                dpsCount = dpsCount + 1
                            end
                        end
                    end
                end
            end
            GUI.statistics.rolesValue:SetText('T: ' .. tankCount .. ' / H: ' .. healerCount .. ' / DPS: ' .. dpsCount)

            -- Ratings count
            local decentCount = 0
            local goodCount = 0
            local awesomeCount = 0
            for key, value in pairs(TempDB) do
                if key ~= 'scheduler' and key ~= 'info' and key ~= 'gui' and type(value) == 'table' then
                    local groupData = GETDATA(TempDB, key)
                    if groupData then
                        for i = 1, table.getn(groupData) do
                            local player = groupData[i]
                            if player.rating == 'Decent' then
                                decentCount = decentCount + 1
                            elseif player.rating == 'Good' then
                                goodCount = goodCount + 1
                            elseif player.rating == 'Awesome' then
                                awesomeCount = awesomeCount + 1
                            end
                        end
                    end
                end
            end
            GUI.statistics.ratingsValue:SetText('D: ' .. decentCount .. ' / G: ' .. goodCount .. ' / A: ' .. awesomeCount)

            -- Session invites sent
            local invitesSent = WHO.sessionInvites or 0
            GUI.statistics.invitesValue:SetText(tostring(invitesSent))

            -- Last WHO search
            local lastScan = WHO.lastScanTime
            local lastScanText = lastScan and (math.floor(now - lastScan) .. 's ago') or 'Never'
            GUI.statistics.lastWhoValue:SetText(lastScanText)

            -- Active WHO queue
            local whoQueueCount = WHO.whisperQueue and table.getn(WHO.whisperQueue) or 0
            GUI.statistics.whoQueueValue:SetText(tostring(whoQueueCount))

            -- Active SCANNER queue
            local scannerQueueCount = 0
            for _ in pairs(CHAT.watchedKeywords) do
                scannerQueueCount = scannerQueueCount + 1
            end
            GUI.statistics.scannerQueueValue:SetText(tostring(scannerQueueCount))
        end)
    end

    -- ===================
    -- ✔️ INIT
    -- ===================
    GUI:CreateAutomation()
    GUI:CreateStatistics()
    GUI:CreateStatisticsTimer()
end)
