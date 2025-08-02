BASE:ENV()

function Tools.CalenderData()
    local daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local monthNames = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'}

    local function isLeapYear(year)
        return (math.mod(year, 4) == 0 and math.mod(year, 100) ~= 0) or (math.mod(year, 400) == 0)
    end

    local function getDaysInMonth(year, month)
        if month == 2 and isLeapYear(year) then
            return 29
        end
        return daysInMonth[month]
    end

    local function getFirstDayOfMonth(year, month)
        if month < 3 then
            month = month + 12
            year = year - 1
        end
        local k = math.mod(year, 100)
        local j = math.floor(year / 100)
        local h = math.mod((1 + math.floor((13 * (month + 1)) / 5) + k + math.floor(k / 4) + math.floor(j / 4) - 2 * j), 7)
        return math.mod((h + 5), 7)
    end

    local currentYear = tonumber(date('%Y'))
    local currentMonth = tonumber(date('%m'))

    local months = {}

    for monthOffset = 0, 23 do  -- 24 months (2 years)
        local year = currentYear
        local month = currentMonth + monthOffset

        while month > 12 do
            year = year + 1
            month = month - 12
        end

        local days = getDaysInMonth(year, month)
        local firstDay = getFirstDayOfMonth(year, month)
        local grid = {}

        for day = 1, days do
            table.insert(grid, day)
        end

        months[monthOffset + 1] = {
            year = year,
            month = month,
            monthName = monthNames[month] .. ' ' .. year,
            days = days,
            firstDay = firstDay,
            grid = grid
        }
    end

    local function getCurrentDate()
        local day = tonumber(date('%d'))
        local month = tonumber(date('%m'))
        local year = tonumber(date('%y'))
        return year .. string.format('%02d', month) .. string.format('%02d', day)
    end

    local function addDays(dateStr, days)
        local year = string.sub(dateStr, 1, 2)
        local month = string.sub(dateStr, 3, 4)
        local day = string.sub(dateStr, 5, 6)

        local d, m, y = tonumber(day), tonumber(month), tonumber('20' .. year)
        d = d + days

        while d > getDaysInMonth(y, m) do
            d = d - getDaysInMonth(y, m)
            m = m + 1
            if m > 12 then
                m = 1
                y = y + 1
            end
        end

        return string.format('%02d%02d%02d', math.mod(y, 100), m, d)
    end

    local function formatForDisplay(dateStr)
        local year = string.sub(dateStr, 1, 2)
        local month = string.sub(dateStr, 3, 4)
        local day = string.sub(dateStr, 5, 6)
        return day .. '/' .. month .. '/' .. year
    end

    local result = {
        months = months,
        currentIndex = 1,
        minIndex = 1,
        maxIndex = 24,
        getCurrentDate = getCurrentDate,
        addDays = addDays,
        formatForDisplay = formatForDisplay
    }

    return result
end