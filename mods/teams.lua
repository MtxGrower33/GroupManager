BASE:ENV()

INSTALL('Teams', 1, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local TEAMS = {
        pendingInvites = {},
        MAX_GROUPSIZE = 39,
        RESERVED_NAMES = {'scheduler', 'info'},
        VALID_ROLES = {'Tank', 'Healer', 'DPS'},
        VALID_RATINGS = {'Decent', 'Good', 'Awesome'},
    }

    local H = {
        SanitizePlayerName = function(name)
            if not name or name == '' then return nil end
            name = string.lower(name)
            return string.gsub(name, '^%l', string.upper)
        end,

        ValidateGroupName = function(groupName)
            for i = 1, table.getn(TEAMS.RESERVED_NAMES) do
                if groupName == TEAMS.RESERVED_NAMES[i] then
                    error('Group name "' .. groupName .. '" is reserved')
                end
            end
        end,

        ValidateRole = function(role)
            for i = 1, table.getn(TEAMS.VALID_ROLES) do
                if role == TEAMS.VALID_ROLES[i] then return end
            end
            error('Invalid role: ' .. role .. '. Valid roles: Tank, Healer, DPS')
        end,

        ValidateRating = function(rating)
            for i = 1, table.getn(TEAMS.VALID_RATINGS) do
                if rating == TEAMS.VALID_RATINGS[i] then return end
            end
            error('Invalid rating: ' .. rating .. '. Valid ratings: Decent, Good, Awesome')
        end,

        FindPlayerIndex = function(group, playerName)
            for i = 1, table.getn(group) do
                local player = group[i]
                if player.name == playerName then
                    return i
                end
            end
            return nil
        end,

        GetValidatedGroup = function(groupName, functionName)
            local group = GETDATA(TempDB, groupName)
            return group
        end
    }

    -- ===================
    -- ✔️ CORE
    -- ===================
    function TEAMS:CreateGroup(groupName)
        H.ValidateGroupName(groupName)
        SETDATA(TempDB, groupName, {})
        debugprint('TEAMS:CreateGroup - created group ' .. groupName)
    end

    function TEAMS:DeleteGroup(groupName)
        if not GETDATA(TempDB, groupName) then
            debugprint('TEAMS:DeleteGroup - group ' .. groupName .. ' does not exist')
            return
        end
        SETDATA(TempDB, groupName, nil)
        debugprint('TEAMS:DeleteGroup - deleted group ' .. groupName)
    end

    function TEAMS:AddPlayer(groupName, playerName, role)
        H.ValidateGroupName(groupName)
        H.ValidateRole(role)

        playerName = H.SanitizePlayerName(playerName)

        local group = GETDATA(TempDB, groupName)
        if not group then
            SETDATA(TempDB, groupName, {})
            group = GETDATA(TempDB, groupName)
        end

        if table.getn(group) >= self.MAX_GROUPSIZE then
            debugprint('TEAMS:AddPlayer - group ' .. groupName .. ' is full (' .. self.MAX_GROUPSIZE .. ' players)')
            return
        end

        if H.FindPlayerIndex(group, playerName) then
            debugprint('TEAMS:AddPlayer - ' .. playerName .. ' already exists in ' .. groupName)
            return
        end

        table.insert(group, {name = playerName, role = role, rating = 'Decent'})
        debugprint('TEAMS:AddPlayer - added ' .. playerName .. ' (' .. role .. ') to ' .. groupName)
    end

    function TEAMS:RemovePlayer(groupName, playerName)
        playerName = H.SanitizePlayerName(playerName)

        local group = H.GetValidatedGroup(groupName, 'TEAMS:RemovePlayer')
        local playerIndex = H.FindPlayerIndex(group, playerName)

        if playerIndex then
            table.remove(group, playerIndex)
            debugprint('TEAMS:RemovePlayer - removed ' .. playerName .. ' from ' .. groupName)
        else
            debugprint('TEAMS:RemovePlayer - ' .. playerName .. ' not found in ' .. groupName)
        end
    end

    function TEAMS:SwitchPlayer(fromGroup, toGroup, playerName)
        playerName = H.SanitizePlayerName(playerName)

        local fromGroupData = H.GetValidatedGroup(fromGroup, 'TEAMS:SwitchPlayer')
        local toGroupData = H.GetValidatedGroup(toGroup, 'TEAMS:SwitchPlayer')

        if table.getn(toGroupData) >= self.MAX_GROUPSIZE then
            debugprint('TEAMS:SwitchPlayer - target group ' .. toGroup .. ' is full')
            return
        end

        local playerIndex = H.FindPlayerIndex(fromGroupData, playerName)

        local player = fromGroupData[playerIndex]
        table.remove(fromGroupData, playerIndex)
        table.insert(toGroupData, player)
        debugprint('TEAMS:SwitchPlayer - moved ' .. playerName .. ' from ' .. fromGroup .. ' to ' .. toGroup)
    end

    function TEAMS:ChangeRole(groupName, playerName, newRole)
        H.ValidateRole(newRole)

        playerName = H.SanitizePlayerName(playerName)

        local group = H.GetValidatedGroup(groupName, 'TEAMS:ChangeRole')
        local playerIndex = H.FindPlayerIndex(group, playerName)

        group[playerIndex].role = newRole
        debugprint('TEAMS:ChangeRole - changed ' .. playerName .. ' role to ' .. newRole .. ' in ' .. groupName)
    end

    function TEAMS:ChangeRating(groupName, playerName, newRating)
        H.ValidateRating(newRating)

        playerName = H.SanitizePlayerName(playerName)

        local group = H.GetValidatedGroup(groupName, 'TEAMS:ChangeRating')
        local playerIndex = H.FindPlayerIndex(group, playerName)

        group[playerIndex].rating = newRating
        debugprint('TEAMS:ChangeRating - changed ' .. playerName .. ' rating to ' .. newRating .. ' in ' .. groupName)
    end

    -- ===================
    -- ✔️ SHARED
    -- ===================
    local f = CreateFrame('Frame')
    f.queue = {}
    f.active = false
    f.total = 0
    f.current = 0

    function Invite(playerOrGrp)
        local group = GETDATA(TempDB, playerOrGrp)
        if group then
            if f.active then return false end
            f.queue = {}
            for i = 1, table.getn(group) do
                table.insert(f.queue, group[i].name)
            end
            local totalTime = table.getn(f.queue) * 0.5
            f.active = true
            f.index = 1
            f.total = table.getn(f.queue)
            f.current = 0
            f:SetScript('OnUpdate', function()
                if this.tick and GetTime() < this.tick then return end
                this.tick = GetTime() + 0.5
                if this.index <= table.getn(this.queue) then
                    InviteByName(this.queue[this.index])
                    this.current = this.index
                    this.index = this.index + 1
                else
                    this:SetScript('OnUpdate', nil)
                    this.active = false
                    this.current = 0
                    this.total = 0
                end
            end)
            debugprint('Invite - started delayed group invite for ' .. playerOrGrp)
            return totalTime
        else
            playerOrGrp = H.SanitizePlayerName(playerOrGrp)
            if playerOrGrp then
                InviteByName(playerOrGrp)
                debugprint('Invite - invited player ' .. playerOrGrp)
            end
            return 0
        end
    end

    INSTALLCORE('Teams', TEAMS)
end)