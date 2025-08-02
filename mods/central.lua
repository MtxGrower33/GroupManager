BASE:ENV()

INSTALL('Central', 0, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local CENTRAL = {
        Calender = Tools.CalenderData(),
        Time = {},
        Scheduler = GETDATA(TempDB, 'scheduler') or {},
        UPDATERATE = 1,
        tick = 0,
    }

    -- ===================
    -- ✔️ CORE
    -- ===================
    function CENTRAL:UpdateDateTime()
        SETDATA(self.Time, 'local', date('%H:%M:%S'))
        local serverHour, serverMinute = GetGameTime()
        SETDATA(self.Time, 'server', string.format('%.2d:%.2d', serverHour, serverMinute))
        SETDATA(self.Time, 'date', self.Calender.getCurrentDate())
        -- debugprint('UpdateDateTime - Local: ' .. self.Time['local'] .. ' | Server: ' .. self.Time['server'] .. ' | Date: ' .. self.Time['date'])
    end

    function CENTRAL:CheckScheduler()
        local currentTime = string.sub(GETDATA(self.Time, 'local'), 1, 5)
        local currentDate = GETDATA(self.Time, 'date')
        local toRemove = {}

        -- debugprint('CheckScheduler - Checking ' .. table.getn(self.Scheduler) .. ' tasks')
        for i = 1, table.getn(self.Scheduler) do
            local task = self.Scheduler[i]
            debugprint('CheckScheduler - Checking task: ' .. task.time .. ' ' .. task.date)

            if task.date < currentDate or (task.date == currentDate and task.time <= currentTime) then
                if task.date == currentDate and task.time == currentTime then
                    self:ExecuteTask(task)
                end
                table.insert(toRemove, i)
            end
        end

        for i = table.getn(toRemove), 1, -1 do
            debugprint('CheckScheduler - Removing task: ' .. self.Scheduler[toRemove[i]].time .. ' ' .. self.Scheduler[toRemove[i]].date .. ' ' .. self.Scheduler[toRemove[i]].groupName)
            table.remove(self.Scheduler, toRemove[i])
        end

        if table.getn(toRemove) > 0 then
            ACTIVATECALLBACK('TASKS_CHANGED')
        end
    end

    function CENTRAL:ExecuteTask(task)
        Invite(task.groupName)

        if task.isWeekly then
            local nextWeekDate = self.Calender.addDays(GETDATA(self.Time, 'date'), 7)
            self:ScheduleTask(task.time, nextWeekDate, task.groupName, task.isWeekly)
            debugprint('ExecuteTask - Rescheduled weekly task for: ' .. nextWeekDate)
        end
    end

    function CENTRAL:ScheduleTask(time, date, groupName, isWeekly)
        table.insert(self.Scheduler, {time = time, date = date, groupName = groupName, isWeekly = isWeekly})
        SETDATA(TempDB, 'scheduler', self.Scheduler)
        debugprint('CENTRAL:ScheduleTask - scheduled ' .. groupName .. ' for ' .. time .. ' ' .. date)
    end

    function CENTRAL:RemoveTask(time, date, groupName)
        for i = table.getn(self.Scheduler), 1, -1 do
            local task = self.Scheduler[i]
            if task.time == time and task.date == date and task.groupName == groupName then
                table.remove(self.Scheduler, i)
                SETDATA(TempDB, 'scheduler', self.Scheduler)
                debugprint('CENTRAL:RemoveTask - removed task: ' .. time .. ' ' .. date .. ' ' .. groupName)
                return
            end
        end
        debugprint('CENTRAL:RemoveTask - task not found: ' .. time .. ' ' .. date .. ' ' .. groupName)
    end

    -- ===================
    -- ✔️ EVENTS
    -- ===================
    CreateFrame'Frame':SetScript('OnUpdate', function()
        local now = GetTime()
        if now < CENTRAL.tick then return end
        CENTRAL.tick = math.floor(now / CENTRAL.UPDATERATE + 1) * CENTRAL.UPDATERATE

        CENTRAL:UpdateDateTime()

        if not allBooted then
            BOOTMODULES()
            return
        end

        if allBooted then
            CENTRAL:CheckScheduler()
        end
    end)

    CreateFrame'Frame':SetScript('OnUpdate', function()
        BOOTMODULES()
        this:SetScript('OnUpdate', nil)
    end)

    INSTALLCORE('Central', CENTRAL)
end)