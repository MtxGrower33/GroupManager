BASE:ENV()

INSTALL('Gui', 2, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local CENTRAL = GETCORE 'Central'
    local TEAMS = GETCORE 'Teams'

    local GUI = {
        MAIN_WIDTH = 1000,
        MAIN_HEIGHT = 700,
        MAIN_ALPHA = .8,

        TITLE_SIZE = 16,
        TITLE_FONT_OFFSET_X = 0,
        TITLE_FONT_OFFSET_Y = -10,

        CLOSE_SIZE = 25,
        CLOSE_BTN_OFFSET = -5,

        SECTOR_TOP_WIDTH = 485,
        SECTOR_TOP_HEIGHT = 500,
        SECTOR_BOT_WIDTH = 485,
        SECTOR_BOT_HEIGHT = 145,
        SECTOR_ALPHA = 0.3,
        SECTOR_MARGIN = 10,
        SECTOR_TOP_Y_OFFSET = -40,
        SECTOR_BOT_Y_OFFSET = 10,

        INFO_PANEL_WIDTH = 280,
        INFO_PANEL_HEIGHT = 25,
        INFO_PANEL_ALPHA = 0.3,

        CONTROL_HEIGHT = 25,
        CONTROL_MARGIN = 5,
        SCROLL_Y_OFFSET = -90,

        HEADER_SIZE = 14,
        HEADER_Y_OFFSET = -10,

        GROUPNAME_EDITBOX_WIDTH = 100,
        CREATE_BTN_WIDTH = 50,
        PLAYERNAME_EDITBOX_WIDTH = 100,
        GROUP_DROPDOWN_WIDTH = 80,
        ROLE_DROPDOWN_WIDTH = 60,
        ADD_BTN_WIDTH = 50,

        TIME_EDITBOX_WIDTH = 60,
        CALENDAR_BTN_WIDTH = 80,
        SCHEDULE_GROUP_DROPDOWN_WIDTH = 80,
        WEEKLY_CHECKBOX_WIDTH = 60,
        SCHEDULE_BTN_WIDTH = 50,

        LABEL_SIZE = 10,
        LABEL_Y_OFFSET = 45,
        CONTROLS_Y_OFFSET = -60,

        LABEL_COLOR = {0.7, 0.7, 0.7},

        BLUE_ACCENT = {0, 0.67, 1},
        GREEN_ACCENT = {0.7, 1, 0.7},
        GRAY_ACCENT = {0.5, 0.5, 0.5},

        PLAYER_TEXT_COLOR = {0.8, 0.8, 1},
        RATING_AWESOME_COLOR = {0, 1, 0},
        RATING_GOOD_COLOR = {0.5, 0.8, 1},
        RATING_DECENT_COLOR = {1, 1, 1},
        ACTION_BTN_COLOR = {1, 1, 1},

        playerElements = {}
    }

    local H = {
        GetAllGroups = function()
            local groups = {}
            for key, value in pairs(TempDB) do
                if key ~= 'scheduler' and key ~= 'info' and key ~= 'gui' and type(value) == 'table' then
                    table.insert(groups, key)
                end
            end
            return groups
        end,
    }

    -- ===================
    -- ✔️ UPDATE
    -- ===================
    function GUI:UpdatePlayerRating(groupName, playerName, newRating)
        local key = groupName .. '_' .. playerName
        local element = self.playerElements[key]
        if element then
            local ratingColor = newRating == 'Awesome' and self.RATING_AWESOME_COLOR or (newRating == 'Good' and self.RATING_GOOD_COLOR or self.RATING_DECENT_COLOR)
            element.ratingLabel:SetText(newRating)
            element.ratingLabel:SetTextColor(ratingColor[1], ratingColor[2], ratingColor[3])
        end
    end

    function GUI:UpdatePlayerRole(groupName, playerName, newRole)
        local key = groupName .. '_' .. playerName
        local element = self.playerElements[key]
        if element then
            local roleText = newRole == 'Tank' and '|cffFF9999[Tank]|r' or '[' .. newRole .. ']'
            element.roleLabel:SetText(roleText)
        end
    end

    -- ===================
    -- ✔️ CORE
    -- ===================
    function GUI:ShowPlayerSwitchMenu(playerName, fromGroup, playerBtn)
        if self.switchMenu and self.switchMenu:IsVisible() then
            self.switchMenu:Hide()
            return
        end

        if self.switchMenu then
            self.switchMenu:Hide()
        end

        local groups = H.GetAllGroups()
        local availableGroups = {}

        for i = 1, table.getn(groups) do
            local groupName = groups[i]
            if groupName ~= fromGroup then
                local groupData = GETDATA(TempDB, groupName)
                if table.getn(groupData) < TEAMS.MAX_GROUPSIZE then
                    table.insert(availableGroups, groupName)
                end
            end
        end

        if table.getn(availableGroups) == 0 then
            return
        end

        local menuHeight = table.getn(availableGroups) * 22 + 10
        local menu = Gui.Frame(UIParent, 150, menuHeight, 0.8, true)
        menu:SetPoint('TOP', playerBtn, 'BOTTOM', 0, -2)
        menu:SetFrameStrata 'DIALOG'

        for i = 1, table.getn(availableGroups) do
            local groupName = availableGroups[i]
            local btn = Gui.Button(menu, groupName, 110, 20, true)
            btn:SetPoint('TOP', menu, 'TOP', 0, -(i - 1) * 22 - 5)
            btn:SetScript('OnClick', function()
                TEAMS:SwitchPlayer(fromGroup, groupName, playerName)
                menu:Hide()
                self:RefreshGroupList()
            end)
        end

        self.switchMenu = menu
    end

    function GUI:CreateMainFrame()
        if self.mainFrame then
            debugprint 'GUI - Main frame already exists'
            return
        end

        self.mainFrame = Gui.Frame(UIParent, self.MAIN_WIDTH, self.MAIN_HEIGHT, self.MAIN_ALPHA, true, 'GroupManagerMain')
        self.mainFrame:SetPoint('CENTER', 0, 0)
        self.mainFrame:Hide()

        self.mainFrame:SetScript('OnMouseDown', function()
            this:StartMoving()
        end)
        self.mainFrame:SetScript('OnMouseUp', function()
            this:StopMovingOrSizing()
        end)
        self.mainFrame:SetMovable(true)

        -- if UISpecialFrames then -- TODO: debug
        --     table.insert(UISpecialFrames, 'GroupManagerMain')
        --     debugprint('GUI - Added to UISpecialFrames, count: ' .. table.getn(UISpecialFrames))
        -- else
        --     debugprint('GUI - UISpecialFrames is nil!')
        -- end

        local titleGroup = Gui.Font(self.mainFrame, self.TITLE_SIZE, 'Group ', {1, 1, 1}, 'CENTER')
        titleGroup:SetPoint('TOP', self.mainFrame, 'TOP', -25, self.TITLE_FONT_OFFSET_Y)

        local titleManager = Gui.Font(self.mainFrame, self.TITLE_SIZE, 'Manager', self.BLUE_ACCENT, 'CENTER')
        titleManager:SetPoint('LEFT', titleGroup, 'RIGHT', 0, 0)

        local closeBtn = Gui.Button(self.mainFrame, 'X', self.CLOSE_SIZE, self.CLOSE_SIZE, false, {1, 0, 0})
        closeBtn:SetPoint('TOPRIGHT', self.mainFrame, 'TOPRIGHT', self.CLOSE_BTN_OFFSET, self.CLOSE_BTN_OFFSET - 7)
        closeBtn:SetScript('OnClick', function()
            GUI:Toggle()
        end)
        debugprint 'GUI - Main frame created'
    end

    function GUI:CreateSectors()
        if self.sectors then return end

        self.sectors = {
            info = Gui.Frame(self.mainFrame, self.INFO_PANEL_WIDTH, self.INFO_PANEL_HEIGHT, self.INFO_PANEL_ALPHA, false),
            topLeft = Gui.Frame(self.mainFrame, self.SECTOR_TOP_WIDTH, self.SECTOR_TOP_HEIGHT, self.SECTOR_ALPHA, false),
            topRight = Gui.Frame(self.mainFrame, self.SECTOR_TOP_WIDTH, self.SECTOR_TOP_HEIGHT, self.SECTOR_ALPHA, false),
            botLeft = Gui.Frame(self.mainFrame, self.SECTOR_BOT_WIDTH, self.SECTOR_BOT_HEIGHT, self.SECTOR_ALPHA, false),
            botRight = Gui.Frame(self.mainFrame, self.SECTOR_BOT_WIDTH, self.SECTOR_BOT_HEIGHT, self.SECTOR_ALPHA, false)
        }

        self.sectors.info:SetPoint('TOPLEFT', self.mainFrame, 'TOPLEFT', self.SECTOR_MARGIN, -self.SECTOR_MARGIN)
        self.sectors.topLeft:SetPoint('TOPLEFT', self.mainFrame, 'TOPLEFT', self.SECTOR_MARGIN, self.SECTOR_TOP_Y_OFFSET)
        self.sectors.topRight:SetPoint('TOPRIGHT', self.mainFrame, 'TOPRIGHT', -self.SECTOR_MARGIN, self.SECTOR_TOP_Y_OFFSET)
        self.sectors.botLeft:SetPoint('BOTTOMLEFT', self.mainFrame, 'BOTTOMLEFT', self.SECTOR_MARGIN, self.SECTOR_BOT_Y_OFFSET)
        self.sectors.botRight:SetPoint('BOTTOMRIGHT', self.mainFrame, 'BOTTOMRIGHT', -self.SECTOR_MARGIN, self.SECTOR_BOT_Y_OFFSET)

        -- debugframe(self.sectors.info)
        -- debugframe(self.sectors.topLeft)
        -- debugframe(self.sectors.topRight)
        -- debugframe(self.sectors.botLeft)
        -- debugframe(self.sectors.botRight)

        debugprint 'GUI - Sectors created'
    end

    function GUI:CreateInfoTimer()
        if self.infoTimer then return end

        self.localText = Gui.Font(self.sectors.info, 10, '', {1, 1, 1}, 'LEFT')
        self.localText:SetPoint('LEFT', self.sectors.info, 'LEFT', 5, 0)

        self.serverText = Gui.Font(self.sectors.info, 10, '', {1, 1, 1}, 'CENTER')
        self.serverText:SetPoint('CENTER', self.sectors.info, 'CENTER', 0, 0)

        self.dateText = Gui.Font(self.sectors.info, 10, '', {1, 1, 1}, 'RIGHT')
        self.dateText:SetPoint('RIGHT', self.sectors.info, 'RIGHT', -5, 0)

        self.infoTimer = CreateFrame('Frame')
        self.infoTimer:SetScript('OnUpdate', function()
            local now = GetTime()
            if now < (this.tick or 0) then return end
            this.tick = now + 1

            local localTime = GETDATA(CENTRAL.Time, 'local') or 'N/A'
            local serverTime = GETDATA(CENTRAL.Time, 'server') or 'N/A'
            local formattedDate = Tools.CalenderData().formatForDisplay(Tools.CalenderData().getCurrentDate())

            GUI.localText:SetText('|cffB3B3B3Local:|r ' .. localTime)
            GUI.serverText:SetText('|cffB3B3B3Server:|r ' .. serverTime)
            GUI.dateText:SetText('|cffB3B3B3Date:|r ' .. formattedDate)
        end)
    end

    function GUI:CreateGroupManagement()
        if self.groupMgmt then return end

        local sector = self.sectors.topLeft

        local header = Gui.Font(sector, self.HEADER_SIZE, 'Group Management', self.BLUE_ACCENT, 'LEFT')
        header:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN, self.HEADER_Y_OFFSET)

        local groupNameLabel = Gui.Font(sector, self.LABEL_SIZE, 'Group Name', self.LABEL_COLOR, 'LEFT')
        groupNameLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN +10, -self.LABEL_Y_OFFSET)

        local createLabel = Gui.Font(sector, self.LABEL_SIZE, 'Create', self.LABEL_COLOR, 'LEFT')
        createLabel:SetPoint('LEFT', groupNameLabel, 'LEFT', self.GROUPNAME_EDITBOX_WIDTH + self.CONTROL_MARGIN, 0)

        local playerNameLabel = Gui.Font(sector, self.LABEL_SIZE, 'Player Name', self.LABEL_COLOR, 'LEFT')
        playerNameLabel:SetPoint('LEFT', createLabel, 'LEFT', self.CREATE_BTN_WIDTH + self.CONTROL_MARGIN, 0)

        local groupLabel = Gui.Font(sector, self.LABEL_SIZE, 'Group', self.LABEL_COLOR, 'LEFT')
        groupLabel:SetPoint('LEFT', playerNameLabel, 'LEFT', self.PLAYERNAME_EDITBOX_WIDTH + self.CONTROL_MARGIN, 0)

        local roleLabel = Gui.Font(sector, self.LABEL_SIZE, 'Role', self.LABEL_COLOR, 'LEFT')
        roleLabel:SetPoint('LEFT', groupLabel, 'LEFT', self.GROUP_DROPDOWN_WIDTH + self.CONTROL_MARGIN, 0)

        local groupNameBox = Gui.Editbox(sector, self.GROUPNAME_EDITBOX_WIDTH, self.CONTROL_HEIGHT, false, false, 15)
        groupNameBox:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN + 5, self.CONTROLS_Y_OFFSET)
        groupNameBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local createBtn = Gui.Button(sector, 'Create', self.CREATE_BTN_WIDTH, self.CONTROL_HEIGHT, false, self.GREEN_ACCENT)
        createBtn:SetPoint('LEFT', groupNameBox, 'RIGHT', self.CONTROL_MARGIN, 0)

        local playerNameBox = Gui.Editbox(sector, self.PLAYERNAME_EDITBOX_WIDTH, self.CONTROL_HEIGHT, true, false, 15)
        playerNameBox:SetPoint('LEFT', createBtn, 'RIGHT', self.CONTROL_MARGIN, 0)
        playerNameBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local groupDropdown = Gui.Dropdown(sector, 'Group', self.GROUP_DROPDOWN_WIDTH, self.CONTROL_HEIGHT)
        groupDropdown:SetPoint('LEFT', playerNameBox, 'RIGHT', self.CONTROL_MARGIN, 0)

        local roleDropdown = Gui.Dropdown(sector, 'Role', self.ROLE_DROPDOWN_WIDTH, self.CONTROL_HEIGHT)
        roleDropdown:SetPoint('LEFT', groupDropdown, 'RIGHT', self.CONTROL_MARGIN, 0)
        roleDropdown:AddItem('Tank')
        roleDropdown:AddItem('Healer')
        roleDropdown:AddItem('DPS')

        local addBtn = Gui.Button(sector, 'Add', self.ADD_BTN_WIDTH, self.CONTROL_HEIGHT, false, self.GREEN_ACCENT)
        addBtn:SetPoint('LEFT', roleDropdown, 'RIGHT', self.CONTROL_MARGIN, 0)

        createBtn:SetScript('OnClick', function()
            local groupName = groupNameBox:GetText()
            if groupName and groupName ~= '' then
                groupName = string.upper(groupName)
                TEAMS:CreateGroup(groupName)
                groupNameBox:SetText('')
                self:RefreshGroupList()
                self:RefreshScheduleList()
            end
        end)

        addBtn:SetScript('OnClick', function()
            local playerName = playerNameBox:GetText()
            local groupName = groupDropdown.selectedValue
            local role = roleDropdown.selectedValue
            if playerName and playerName ~= '' and groupName and role then
                TEAMS:AddPlayer(groupName, playerName, role)
                playerNameBox:SetText('')
                self:RefreshGroupList()
            end
        end)

        local scrollFrame = Gui.Scrollframe(sector, sector:GetWidth() - self.CONTROL_MARGIN * 2, sector:GetHeight() + self.SCROLL_Y_OFFSET - self.CONTROL_MARGIN)
        scrollFrame:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN, self.SCROLL_Y_OFFSET)
        self.groupMgmt = {
            groupNameBox = groupNameBox,
            createBtn = createBtn,
            playerNameBox = playerNameBox,
            groupDropdown = groupDropdown,
            roleDropdown = roleDropdown,
            addBtn = addBtn,
            scrollFrame = scrollFrame
        }

        self:RefreshGroupList()
        debugprint 'GUI - Group management created'
    end

    function GUI:RefreshGroupList()
        debugprint 'GUI:RefreshGroupList - called'
        if not self.groupMgmt or not self.groupMgmt.scrollFrame then return end

        local scrollFrame = self.groupMgmt.scrollFrame
        local groupDropdown = self.groupMgmt.groupDropdown

        local scrollPosition = scrollFrame:GetVerticalScroll()

        self.playerElements = {}
        local children = {scrollFrame.content:GetChildren()}
        debugprint('RefreshGroupList - clearing ' .. table.getn(children) .. ' existing children')
        for i = 1, table.getn(children) do
            children[i]:Hide()
        end

        groupDropdown:Clear()
        local groups = H.GetAllGroups()
        debugprint('RefreshGroupList - found ' .. table.getn(groups) .. ' groups')
        for i = 1, table.getn(groups) do
            local groupName = groups[i]
            local displayName = string.len(groupName) > 6 and string.sub(groupName, 1, 6) .. '...' or groupName
            groupDropdown:AddItem(displayName, function()
                groupDropdown.text:SetText(displayName)
                groupDropdown.selectedValue = groupName
                groupDropdown.popup:Hide()
            end)
        end

        table.sort(groups)

        local yOffset = 0
        for i = 1, table.getn(groups) do
            local groupName = groups[i]
            yOffset = self:CreateGroupDisplay(groupName, yOffset)
        end

        scrollFrame.content:SetHeight(yOffset + 10)
        scrollFrame.updateScrollBar()
        scrollFrame:SetVerticalScroll(scrollPosition)
        debugprint 'GUI:RefreshGroupList - completed'
    end

    function GUI:CreateGroupDisplay(groupName, yOffset)
        debugprint('GUI - CreateGroupDisplay: ' .. groupName)
        local scrollFrame = self.groupMgmt.scrollFrame
        local groupData = GETDATA(TempDB, groupName)

        local groupHeaderFrame = Gui.Frame(scrollFrame.content, 435, 25, 0.2, false)
        groupHeaderFrame:SetPoint('TOPLEFT', scrollFrame.content, 'TOPLEFT', 5, -yOffset)

        local groupHeader = Gui.Font(groupHeaderFrame, 12, groupName, self.BLUE_ACCENT, 'LEFT')
        groupHeader:SetPoint('LEFT', groupHeaderFrame, 'LEFT', 5, 0)

        local inviteBtn = Gui.Button(groupHeaderFrame, 'Inv', 30, 20, false, self.GREEN_ACCENT)
        inviteBtn:SetPoint('RIGHT', groupHeaderFrame, 'RIGHT', -40, 0)
        inviteBtn:SetScript('OnClick', function()
            debugprint('GUI - Invite button clicked for group: ' .. groupName)
            local totalTime = Invite(groupName)
            if totalTime and totalTime > 0 then
                local loadingBar = LoadingBar(200, 3, false, 'left', totalTime)
                loadingBar:SetParent(groupHeaderFrame)
                loadingBar:SetPoint('BOTTOM', groupHeaderFrame, 'BOTTOM', 0, 11)
            end
        end)

        local deleteBtn = Gui.Button(groupHeaderFrame, 'Del', 30, 20, false, self.GRAY_ACCENT)
        deleteBtn:SetPoint('RIGHT', groupHeaderFrame, 'RIGHT', -5, 0)
        deleteBtn:SetScript('OnClick', function()
            debugprint('GUI - Delete group button clicked for: ' .. groupName)
            Gui.Confirmbox('|cffFF0000Delete|r group "' .. groupName .. '"?', function()
                TEAMS:DeleteGroup(groupName)
                self:RefreshGroupList()
                self:RefreshScheduleList()
            end)
        end)

        yOffset = yOffset + 30

        table.sort(groupData, function(a, b)
            return a.name < b.name
        end)

        for j = 1, table.getn(groupData) do
            local player = groupData[j]
            yOffset = self:CreatePlayerDisplay(groupName, player, yOffset)
        end

        return yOffset + 10
    end

    function GUI:CreatePlayerDisplay(groupName, player, yOffset)
        debugprint('GUI - CreatePlayerDisplay: ' .. player.name)
        local scrollFrame = self.groupMgmt.scrollFrame

        local playerFrame = Gui.Frame(scrollFrame.content, 420, 20, 0.1, false)
        playerFrame:SetPoint('TOPLEFT', scrollFrame.content, 'TOPLEFT', 15, -yOffset)

        local nameX = 5
        local roleX = 120
        local ratingX = 200

        local playerBtn = CreateFrame('Button', nil, playerFrame)
        playerBtn:SetWidth(110)
        playerBtn:SetHeight(20)
        playerBtn:SetPoint('LEFT', playerFrame, 'LEFT', nameX, 0)

        local playerLabel = playerBtn:CreateFontString(nil, 'OVERLAY')
        playerLabel:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
        playerLabel:SetTextColor(self.PLAYER_TEXT_COLOR[1], self.PLAYER_TEXT_COLOR[2], self.PLAYER_TEXT_COLOR[3])
        playerLabel:SetText(player.name)
        playerLabel:SetPoint('LEFT', playerBtn, 'LEFT', 0, 0)

        local highlight = playerBtn:CreateTexture(nil, 'HIGHLIGHT')
        highlight:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
        highlight:SetAllPoints(playerBtn)
        highlight:SetBlendMode('ADD')

        playerBtn:SetScript('OnClick', function()
            self:ShowPlayerSwitchMenu(player.name, groupName, playerBtn)
        end)

        local roleLabel = playerFrame:CreateFontString(nil, 'OVERLAY')
        roleLabel:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
        roleLabel:SetTextColor(1, 1, 1)
        local roleText = player.role == 'Tank' and '|cffFF9999[Tank]|r' or '[' .. player.role .. ']'
        roleLabel:SetText(roleText)
        roleLabel:SetPoint('LEFT', playerFrame, 'LEFT', roleX, 0)

        local ratingColor = player.rating == 'Awesome' and self.RATING_AWESOME_COLOR or (player.rating == 'Good' and self.RATING_GOOD_COLOR or self.RATING_DECENT_COLOR)
        local ratingLabel = playerFrame:CreateFontString(nil, 'OVERLAY')
        ratingLabel:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
        ratingLabel:SetTextColor(ratingColor[1], ratingColor[2], ratingColor[3])
        ratingLabel:SetText(player.rating)
        ratingLabel:SetPoint('LEFT', playerFrame, 'LEFT', ratingX, 0)

        local removeBtn = Gui.Button(playerFrame, 'X', 15, 15, true, self.GRAY_ACCENT)
        removeBtn:SetPoint('RIGHT', playerFrame, 'RIGHT', -5, 0)
        removeBtn:SetScript('OnClick', function()
            debugprint('GUI - Remove button clicked for player: ' .. player.name .. ' in group: ' .. groupName)
            TEAMS:RemovePlayer(groupName, player.name)
            self:RefreshGroupList()
        end)

        local ratingBtn = Gui.Button(playerFrame, '+', 15, 15, true, self.ACTION_BTN_COLOR)
        ratingBtn:SetPoint('RIGHT', removeBtn, 'LEFT', -2, 0)
        ratingBtn:SetScript('OnClick', function()
            debugprint('GUI - Rating button clicked for player: ' .. player.name)
            local ratings = TEAMS.VALID_RATINGS
            local newRating = ratings[1]
            for i = 1, table.getn(ratings) do
                if ratings[i] == player.rating then
                    newRating = ratings[math.mod(i, table.getn(ratings)) + 1]
                    break
                end
            end
            TEAMS:ChangeRating(groupName, player.name, newRating)
            self:UpdatePlayerRating(groupName, player.name, newRating)
        end)

        local roleBtn = Gui.Button(playerFrame, 'R', 15, 15, true, self.ACTION_BTN_COLOR)
        roleBtn:SetPoint('RIGHT', ratingBtn, 'LEFT', -2, 0)
        roleBtn:SetScript('OnClick', function()
            debugprint('GUI - Role button clicked for player: ' .. player.name)
            local roles = TEAMS.VALID_ROLES
            local newRole = roles[1]
            for i = 1, table.getn(roles) do
                if roles[i] == player.role then
                    newRole = roles[math.mod(i, table.getn(roles)) + 1]
                    break
                end
            end
            TEAMS:ChangeRole(groupName, player.name, newRole)
            self:UpdatePlayerRole(groupName, player.name, newRole)
        end)

        local inviteBtn = Gui.Button(playerFrame, 'I', 15, 15, true, self.GREEN_ACCENT)
        inviteBtn:SetPoint('RIGHT', roleBtn, 'LEFT', -2, 0)
        inviteBtn:SetScript('OnClick', function()
            debugprint('GUI - Invite button clicked for player: ' .. player.name)
            local totalTime = Invite(player.name)
            if totalTime and totalTime > 0 then
                local loadingBar = LoadingBar(100, 2, false, 'left', totalTime)
                loadingBar:SetParent(playerFrame)
                loadingBar:SetPoint('BOTTOM', playerFrame, 'BOTTOM', 0, -3)
            end
        end)

        local key = groupName .. '_' .. player.name
        self.playerElements[key] = {
            playerLabel = playerLabel,
            roleLabel = roleLabel,
            ratingLabel = ratingLabel,
            playerFrame = playerFrame
        }

        return yOffset + 25
    end

    function GUI:CreateScheduleManagement()
        if self.scheduleMgmt then return end

        local sector = self.sectors.topRight

        local header = Gui.Font(sector, self.HEADER_SIZE, 'Schedule Management', self.BLUE_ACCENT, 'LEFT')
        header:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN, self.HEADER_Y_OFFSET)

        local timeLabel = Gui.Font(sector, self.LABEL_SIZE, 'Time', self.LABEL_COLOR, 'LEFT')
        timeLabel:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN +10, -self.LABEL_Y_OFFSET)

        local dateLabel = Gui.Font(sector, self.LABEL_SIZE, 'Date', self.LABEL_COLOR, 'LEFT')
        dateLabel:SetPoint('LEFT', timeLabel, 'LEFT', self.TIME_EDITBOX_WIDTH + self.CONTROL_MARGIN, 0)

        local groupLabel = Gui.Font(sector, self.LABEL_SIZE, 'Group', self.LABEL_COLOR, 'LEFT')
        groupLabel:SetPoint('LEFT', dateLabel, 'LEFT', self.CALENDAR_BTN_WIDTH + self.CONTROL_MARGIN, 0)

        local weeklyLabel = Gui.Font(sector, self.LABEL_SIZE, 'Weekly', self.LABEL_COLOR, 'LEFT')
        weeklyLabel:SetPoint('LEFT', groupLabel, 'LEFT', self.SCHEDULE_GROUP_DROPDOWN_WIDTH + self.CONTROL_MARGIN, 0)

        -- local scheduleLabel = Gui.Font(sector, self.LABEL_SIZE, 'Schedule', self.LABEL_COLOR, 'LEFT')
        -- scheduleLabel:SetPoint('LEFT', weeklyLabel, 'LEFT', self.WEEKLY_CHECKBOX_WIDTH + self.CONTROL_MARGIN, 0)

        local timeBox = Gui.Editbox(sector, self.TIME_EDITBOX_WIDTH, self.CONTROL_HEIGHT, false, true, 5)
        timeBox:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN +5, self.CONTROLS_Y_OFFSET)
        local localTime = GETDATA(CENTRAL.Time, 'local')
        debugprint('CreateScheduleManagement - localTime: ' .. tostring(localTime))
        timeBox:SetText(localTime)
        timeBox:SetScript('OnEditFocusGained', function()
            this:SetText('')
        end)
        timeBox:SetScript('OnTextChanged', function()
            local text = this:GetText()
            debugprint('OnTextChanged - text: ' .. tostring(text) .. ' len: ' .. string.len(text))
            if string.len(text) == 4 and not string.find(text, ':') then
                local hours = tonumber(string.sub(text, 1, 2))
                local minutes = tonumber(string.sub(text, 3, 4))
                if hours <= 23 and minutes <= 59 then
                    this:SetText(string.sub(text, 1, 2) .. ':' .. string.sub(text, 3, 4))
                else
                    this:SetText('23:59')
                end
            end
        end)
        timeBox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)

        local calendarBtn
        calendarBtn = Gui.Calender(sector, 'bottom', self.CALENDAR_BTN_WIDTH, self.CONTROL_HEIGHT, function(selectedDate, selectedDateRaw)
            calendarBtn.selectedDate = selectedDate
            calendarBtn.selectedDateRaw = selectedDateRaw
        end)
        calendarBtn:SetPoint('LEFT', timeBox, 'RIGHT', self.CONTROL_MARGIN, 0)

        local groupDropdown = Gui.Dropdown(sector, 'Group', self.SCHEDULE_GROUP_DROPDOWN_WIDTH, self.CONTROL_HEIGHT)
        groupDropdown:SetPoint('LEFT', calendarBtn, 'RIGHT', self.CONTROL_MARGIN, 0)

        local weeklyCheckbox = Gui.Button(sector, 'No', self.WEEKLY_CHECKBOX_WIDTH, self.CONTROL_HEIGHT)
        weeklyCheckbox:SetPoint('LEFT', groupDropdown, 'RIGHT', self.CONTROL_MARGIN, 0)
        weeklyCheckbox.checked = false
        weeklyCheckbox:SetScript('OnClick', function()
            weeklyCheckbox.checked = not weeklyCheckbox.checked
            weeklyCheckbox.text:SetText(weeklyCheckbox.checked and 'Yes' or 'No')
        end)

        local scheduleBtn = Gui.Button(sector, 'Add', self.SCHEDULE_BTN_WIDTH, self.CONTROL_HEIGHT, false, self.GREEN_ACCENT)
        scheduleBtn:SetPoint('LEFT', weeklyCheckbox, 'RIGHT', self.CONTROL_MARGIN, 0)

        scheduleBtn:SetScript('OnClick', function()
            local time = timeBox:GetText()
            local date = calendarBtn.selectedDateRaw or GETDATA(CENTRAL.Time, 'date')
            local groupName = groupDropdown.selectedValue
            if not groupName then return end
            local isWeekly = weeklyCheckbox.checked

            CENTRAL:ScheduleTask(time, date, groupName, isWeekly)
            timeBox:SetText(GETDATA(CENTRAL.Time, 'local'))
            self:RefreshScheduleList()
            debugprint('GUI - Task scheduled: ' .. groupName .. ' at ' .. time .. ' on ' .. date)
        end)

        local scrollFrame = Gui.Scrollframe(sector, sector:GetWidth() - self.CONTROL_MARGIN * 2, sector:GetHeight() + self.SCROLL_Y_OFFSET - self.CONTROL_MARGIN)
        scrollFrame:SetPoint('TOPLEFT', sector, 'TOPLEFT', self.CONTROL_MARGIN, self.SCROLL_Y_OFFSET)
        -- debugframe(scrollFrame)

        self.scheduleMgmt = {
            timeBox = timeBox,
            calendarBtn = calendarBtn,
            groupDropdown = groupDropdown,
            weeklyCheckbox = weeklyCheckbox,
            scheduleBtn = scheduleBtn,
            scrollFrame = scrollFrame
        }

        self:RefreshScheduleList()
        debugprint 'GUI - Schedule management created'
    end

    function GUI:RefreshScheduleList()
        debugprint 'GUI:RefreshScheduleList - called'
        if not self.scheduleMgmt or not self.scheduleMgmt.scrollFrame then return end

        local scrollFrame = self.scheduleMgmt.scrollFrame
        local groupDropdown = self.scheduleMgmt.groupDropdown

        local children = {scrollFrame.content:GetChildren()}
        debugprint('RefreshScheduleList - clearing ' .. table.getn(children) .. ' existing children')
        for i = 1, table.getn(children) do
            children[i]:Hide()
        end

        groupDropdown:Clear()
        local groups = H.GetAllGroups()
        for i = 1, table.getn(groups) do
            local groupName = groups[i]
            local displayName = string.len(groupName) > 6 and string.sub(groupName, 1, 6) .. '...' or groupName
            groupDropdown:AddItem(displayName, function()
                groupDropdown.text:SetText(displayName)
                groupDropdown.selectedValue = groupName
                groupDropdown.popup:Hide()
            end)
        end

        local tasks = GETDATA(TempDB, 'scheduler') or {}
        table.sort(tasks, function(a, b)
            if a.date ~= b.date then
                return a.date < b.date
            end
            return a.time < b.time
        end)
        debugprint('RefreshScheduleList - found ' .. table.getn(tasks) .. ' tasks')

        local yOffset = 0
        for i = 1, table.getn(tasks) do
            yOffset = self:CreateTaskDisplay(tasks[i], yOffset)
        end

        scrollFrame.content:SetHeight(yOffset + 10)
        scrollFrame.updateScrollBar()
        debugprint 'GUI:RefreshScheduleList - completed'
    end

    function GUI:CreateTaskDisplay(task, yOffset)
        debugprint('GUI - CreateTaskDisplay: ' .. task.groupName)
        local scrollFrame = self.scheduleMgmt.scrollFrame

        local taskFrame = Gui.Frame(scrollFrame.content, 435, 25, 0.2, false)
        taskFrame:SetPoint('TOPLEFT', scrollFrame.content, 'TOPLEFT', 5, -yOffset)

        local groupX = 5
        local dateX = 120
        local timeX = 220
        local weeklyX = 280

        local groupLabel = Gui.Font(taskFrame, 10, task.groupName, self.PLAYER_TEXT_COLOR, 'LEFT')
        groupLabel:SetPoint('LEFT', taskFrame, 'LEFT', groupX, 0)

        local formattedDate = Tools.CalenderData().formatForDisplay(task.date)
        local dateLabel = Gui.Font(taskFrame, 10, formattedDate, {1, 1, 1}, 'LEFT')
        dateLabel:SetPoint('LEFT', taskFrame, 'LEFT', dateX, 0)

        local timeLabel = Gui.Font(taskFrame, 10, task.time, {1, 1, 1}, 'LEFT')
        timeLabel:SetPoint('LEFT', taskFrame, 'LEFT', timeX, 0)

        if task.isWeekly then
            local weeklyLabel = Gui.Font(taskFrame, 10, 'weekly', self.GREEN_ACCENT, 'LEFT')
            weeklyLabel:SetPoint('LEFT', taskFrame, 'LEFT', weeklyX, 0)
        end

        local deleteBtn = Gui.Button(taskFrame, 'Del', 30, 20, false, self.GRAY_ACCENT)
        deleteBtn:SetPoint('RIGHT', taskFrame, 'RIGHT', -5, 0)
        deleteBtn:SetScript('OnClick', function()
            debugprint('GUI - Delete task button clicked: ' .. task.groupName)
            Gui.Confirmbox('|cffFF0000Delete|r task: "' .. task.groupName .. '"?', function()

                CENTRAL:RemoveTask(task.time, task.date, task.groupName)
                self:RefreshScheduleList()
            end)
        end)

        return yOffset + 30
    end

    function GUI:Toggle()
        if self.optionsFrame and self.optionsFrame:IsVisible() then
            self.optionsFrame:Hide()
        end
        if self.mainFrame:IsVisible() then
            self.mainFrame:Hide()
        else
            self.mainFrame:Show()
        end
    end

    -- ===================
    -- ✔️ INIT
    -- ===================
    GUI:CreateMainFrame()
    GUI:CreateSectors()
    GUI:CreateInfoTimer()
    GUI:CreateGroupManagement()
    GUI:CreateScheduleManagement()

    INSTALLCALLBACK('TASKS_CHANGED', function()
        GUI:RefreshScheduleList()
    end)

    BASE:SLASH('', function() GUI:Toggle() end)
    INSTALLCORE('Gui', GUI)

    -- ===================
    -- ✔️ DEBUG
    -- ===================
    local DEBUG_MODE = false
    if DEBUG_MODE then
        GUI.mainFrame:Show()
    end
end)