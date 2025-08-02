BASE:ENV()
debugprint 'BOOT'

function Gui.Frame(parent, width, height, alpha, mouse, name)
    parent = parent or UIParent
    local f = CreateFrame("Frame", name, parent)
    f:SetWidth(width or 100)
    f:SetHeight(height or 100)
    f:EnableMouse(mouse or false)
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    f:SetBackdropColor(0, 0, 0, alpha or 0.5)
    return f
end

function Gui.Scrollframe(parent, width, height)
    local SCROLLBAR_WIDTH = 2
    local THUMB_WIDTH = 4
    local THUMB_HEIGHT = 20
    local SCROLL_STEP = 6

    local scroll = CreateFrame('ScrollFrame', nil, parent or UIParent)
    scroll:SetWidth(width or 200)
    scroll:SetHeight(height or 300)

    local content = CreateFrame('Frame', nil, scroll)
    content:SetWidth(width or 200)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local scrollBar = CreateFrame('Slider', nil, scroll)
    scrollBar:SetWidth(SCROLLBAR_WIDTH)
    scrollBar:SetHeight(height or 300)
    scrollBar:SetPoint('TOPRIGHT', scroll, 'TOPRIGHT', 0, 0)
    scrollBar:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8'})
    scrollBar:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    scrollBar:SetOrientation('VERTICAL')

    local thumb = scrollBar:CreateTexture(nil, 'OVERLAY')
    thumb:SetTexture('Interface\\Buttons\\WHITE8X8')
    thumb:SetWidth(THUMB_WIDTH)
    thumb:SetHeight(THUMB_HEIGHT)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript('OnValueChanged', function()
        local value = this:GetValue()
        scroll:SetVerticalScroll(value)
    end)

    local velocity = 0

    scroll:EnableMouseWheel(true)
    scroll:SetScript('OnMouseWheel', function()
        velocity = velocity + (arg1 * -SCROLL_STEP)
        if not scroll:GetScript('OnUpdate') then
            scroll:SetScript('OnUpdate', function()
                if math.abs(velocity) > 0.5 and scroll:IsVisible() then
                    local current = scroll:GetVerticalScroll()
                    local maxScroll = math.max(0, content:GetHeight() - scroll:GetHeight())
                    local newScroll = math.max(0, math.min(maxScroll, current + velocity))
                    scroll:SetVerticalScroll(newScroll)
                    scrollBar:SetMinMaxValues(0, maxScroll)
                    scrollBar:SetValue(newScroll)
                    velocity = velocity * 0.85
                else
                    velocity = 0
                    scroll:SetScript('OnUpdate', nil)
                end
            end)
        end
    end)

    scroll.updateScrollBar = function()
        local maxScroll = math.max(0, content:GetHeight() - scroll:GetHeight())
        if maxScroll <= 0 then
            scrollBar:Hide()
        else
            scrollBar:Show()
            scrollBar:SetMinMaxValues(0, maxScroll)
            scrollBar:SetValue(0)
        end
    end

    scroll.content = content
    scroll.scrollBar = scrollBar
    return scroll
end

function Gui.Button(parent, text, width, height, noBackdrop, textColor, noHighlight)
    local btn = CreateFrame("Button", nil, parent or UIParent)
    btn:SetWidth(width or 140)
    btn:SetHeight(height or 30)
    if not noBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        btn:SetBackdropColor(0, 0, 0, .5)
        btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end

    local btnTxt = btn:CreateFontString(nil, 'OVERLAY')
    btnTxt:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
    btnTxt:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btnTxt:SetText(text)

    if textColor then
        btnTxt:SetTextColor(textColor[1], textColor[2], textColor[3])
    else
        btnTxt:SetTextColor(1, 1, 1)
    end

    btn.text = btnTxt

    local origEnable = btn.Enable
    local origDisable = btn.Disable

    btn.Enable = function(self)
        origEnable(self)
        if textColor then
            btnTxt:SetTextColor(textColor[1], textColor[2], textColor[3])
        else
            btnTxt:SetTextColor(1, 1, 1)
        end
    end

    btn.Disable = function(self)
        origDisable(self)
        btnTxt:SetTextColor(0.5, 0.5, 0.5)
    end

    if not noHighlight then
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -4)
        highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 4)
        highlight:SetBlendMode("ADD")
    end

    return btn
end

function Gui.Font(parent, size, text, colour, align)
    local font = parent:CreateFontString(nil, 'OVERLAY')
    font:SetFont('Fonts\\FRIZQT__.TTF', size or 14, 'OUTLINE')
    colour = colour or {1, 1, 1}
    font:SetTextColor(colour[1], colour[2], colour[3])
    font:SetText(text)
    font.align = align or 'CENTER'
    font:SetJustifyH(font.align)
    return font
end

function Gui.Editbox(parent, width, height, letters, numbers, max, onEnter, onEscape, clickOutside)
    local box = CreateFrame("EditBox", nil, parent or UIParent)
    box:SetWidth(width or 100)
    box:SetHeight(height or 20)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    box:SetBackdropColor(0, 0, 0, 0.8)
    box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    box:SetFont('Fonts\\FRIZQT__.TTF', 14, 'OUTLINE')
    box:SetTextColor(1, 1, 1)
    box:SetTextInsets(5, 5, 5, 5)
    box:SetAutoFocus(false)
    box:SetMaxLetters(max or 33)

    if clickOutside then
        box.clickCatcher = CreateFrame("Frame", nil, UIParent)
        box.clickCatcher:SetFrameStrata("TOOLTIP")
        box.clickCatcher:SetAllPoints(UIParent)
        box.clickCatcher:EnableMouse(true)
        box.clickCatcher:Hide()

        box.clickCatcher:SetScript("OnMouseDown", function()
            box:ClearFocus()
            this:Hide()
        end)

        box:SetScript("OnEditFocusGained", function()
            box.clickCatcher:Show()
        end)

        box:SetScript("OnEditFocusLost", function()
            box.clickCatcher:Hide()
        end)
    end

    if onEscape then
        box:SetScript("OnEscapePressed", onEscape)
    end

    if onEnter then
        box:SetScript("OnEnterPressed", onEnter)
    end

    if letters then
        box:SetScript("OnChar", function()
            if not string.find(arg1, "[a-zA-Z]") then
                this:SetText(string.gsub(this:GetText(), "[^a-zA-Z]", ""))
            end
        end)
    elseif numbers then
        box:SetScript("OnChar", function()
            if not string.find(arg1, "[0-9]") then
                this:SetText(string.gsub(this:GetText(), "[^0-9]", ""))
            end
        end)
    end

    return box
end

function Gui.Checkbox(parent, text, width, height)
    local checkbox = CreateFrame("CheckButton", nil, parent or UIParent, "UICheckButtonTemplate")
    checkbox:SetWidth(width or 20)
    checkbox:SetHeight(height or 20)

    local label = checkbox:CreateFontString(nil, 'BACKGROUND')
    label:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(text or "Checkbox")
    label:SetTextColor(.9,.9,.9)
    checkbox.label = label

    checkbox:SetChecked(false)

    local origEnable = checkbox.Enable
    local origDisable = checkbox.Disable

    checkbox.Enable = function(self)
        origEnable(self)
        self.label:SetTextColor(.9,.9,.9)
    end

    checkbox.Disable = function(self)
        origDisable(self)
        self.label:SetTextColor(0.5, 0.5, 0.5)
    end

    return checkbox
end

function Gui.Dropdown(parent, text, width, height)
    local btn = Gui.Button(parent, text or "Dropdown", width or 120, height or 25)

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetWidth(btn:GetWidth())
    popup:SetHeight(50)
    popup:SetPoint("TOP", btn, "BOTTOM", 0, -2)
    popup:SetFrameLevel(btn:GetFrameLevel() + 1)
    popup:SetFrameStrata("DIALOG")
    popup:EnableMouse(true)
    popup:Hide()

    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints(popup)
    bg:SetVertexColor(0, 0, 0, 0.8)

    btn.popup = popup
    btn.selectedValue = nil
    btn.items = {}

    btn.Clear = function(self)
        for i = 1, table.getn(self.items) do
            self.items[i]:Hide()
        end
        self.items = {}
        popup:SetHeight(10)
    end

    btn.AddItem = function(self, itemText, callback)
        local itemBtn = Gui.Button(popup, itemText, popup:GetWidth() - 4, 20, true)
        itemBtn:SetPoint("TOP", popup, "TOP", 0, -(table.getn(self.items)) * 22 - 5)
        itemBtn:SetScript("OnClick", callback or function()
            btn.text:SetText(itemText)
            btn.selectedValue = itemText
            popup:Hide()
        end)
        table.insert(self.items, itemBtn)
        popup:SetHeight(table.getn(self.items) * 22 + 10)
    end

    btn:SetScript("OnClick", function()
        if popup:IsVisible() then
            popup:Hide()
        else
            popup:Show()
        end
    end)

    return btn
end

function Gui.Slider(parent, name, text, minVal, maxVal, step, format, width, height)
    local slider = CreateFrame("Slider", name, parent)
    slider:SetWidth(width or 136)
    slider:SetHeight(height or 24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    slider:SetMinMaxValues(minVal or 0, maxVal or 5)
    slider:SetValueStep(step or 0.1)

    local label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, -0)
    label:SetText(text or "Slider")
    label:SetFont('Fonts\\FRIZQT__.TTF', 12, "OUTLINE")
    label:SetTextColor(.9,.9,.9)
    slider.label = label

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("LEFT", slider, "RIGHT", 1, -0)
    valueText:SetTextColor(1, 1, 1)
    valueText:SetFont('Fonts\\FRIZQT__.TTF', 12, "OUTLINE")
    slider.valueText = valueText

    local fmt = format or "%.1f"

    slider:SetValue(minVal or 0)
    valueText:SetText(string.format(fmt, minVal or 0))

    local function updateValueText()
        local newValue = slider:GetValue()
        local roundedValue = math.floor(newValue * 10 + 0.5) / 10
        valueText:SetText(string.format(fmt, roundedValue))
    end

    slider.updateValueText = updateValueText
    slider:SetScript("OnValueChanged", updateValueText)

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function()
        local wheelStep = step or 0.1
        local value = this:GetValue()
        local minValue, maxValue = this:GetMinMaxValues()

        if arg1 > 0 then
            value = math.min(value + wheelStep, maxValue)
        else
            value = math.max(value - wheelStep, minValue)
        end
        this:SetValue(value)
    end)

    local origEnable = slider.Enable
    local origDisable = slider.Disable

    slider.Enable = function(self)
        origEnable(self)
        self.label:SetTextColor(.9,.9,.9)
        self.valueText:SetTextColor(1, 1, 1)
    end

    slider.Disable = function(self)
        origDisable(self)
        self.label:SetTextColor(0.5, 0.5, 0.5)
        self.valueText:SetTextColor(0.5, 0.5, 0.5)
    end

    return slider
end

function Gui.ColorPicker(parent, initialColor, callback)
    local GRID_SIZE = 6
    local SWATCH_SIZE = 20

    local colors = {
        {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}, {1, 0, 1}, {0, 1, 1},
        {1, 0.5, 0}, {0.5, 1, 0}, {0, 0.5, 1}, {1, 0, 0.5}, {0.5, 0, 1}, {0, 1, 0.5},
        {0.8, 0.8, 0.8}, {0.6, 0.6, 0.6}, {0.4, 0.4, 0.4}, {0.2, 0.2, 0.2}, {0, 0, 0}, {1, 1, 1},
        {0.5, 0.25, 0}, {0.25, 0.5, 0}, {0, 0.25, 0.5}, {0.5, 0, 0.25}, {0.25, 0, 0.5}, {0, 0.5, 0.25},
        {1, 0.8, 0.8}, {0.8, 1, 0.8}, {0.8, 0.8, 1}, {1, 1, 0.8}, {1, 0.8, 1}, {0.8, 1, 1},
        {0.6, 0.3, 0.3}, {0.3, 0.6, 0.3}, {0.3, 0.3, 0.6}, {0.6, 0.6, 0.3}, {0.6, 0.3, 0.6}, {0.3, 0.6, 0.6}
    }

    local btn = Gui.Button(parent, '', 30, 25, false)
    btn.selectedColor = initialColor or {1, 1, 1}

    local swatch = btn:CreateTexture(nil, 'OVERLAY')
    swatch:SetTexture('Interface\\Buttons\\WHITE8X8')
    swatch:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    swatch:SetWidth(20)
    swatch:SetHeight(15)
    swatch:SetVertexColor(btn.selectedColor[1], btn.selectedColor[2], btn.selectedColor[3])
    btn.swatch = swatch

    local popup = CreateFrame('Frame', nil, UIParent)
    popup:SetWidth(GRID_SIZE * SWATCH_SIZE + 10)
    popup:SetHeight(GRID_SIZE * SWATCH_SIZE + 10)
    popup:SetPoint('TOP', btn, 'BOTTOM', 0, -2)
    popup:SetFrameLevel(btn:GetFrameLevel() + 1)
    popup:SetFrameStrata('DIALOG')
    popup:EnableMouse(true)
    popup:Hide()

    popup:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8'})
    popup:SetBackdropColor(0, 0, 0, 0.8)

    for i = 1, table.getn(colors) do
        local colorBtn = CreateFrame('Button', nil, popup)
        colorBtn:SetWidth(SWATCH_SIZE)
        colorBtn:SetHeight(SWATCH_SIZE)

        local row = math.floor((i - 1) / GRID_SIZE)
        local col = math.mod(i - 1, GRID_SIZE)
        colorBtn:SetPoint('TOPLEFT', popup, 'TOPLEFT', col * SWATCH_SIZE + 5, -row * SWATCH_SIZE - 5)

        local colorTex = colorBtn:CreateTexture(nil, 'BACKGROUND')
        colorTex:SetTexture('Interface\\Buttons\\WHITE8X8')
        colorTex:SetAllPoints(colorBtn)
        colorTex:SetVertexColor(colors[i][1], colors[i][2], colors[i][3])

        local color = colors[i]
        colorBtn:SetScript('OnClick', function()
            btn.selectedColor = color
            swatch:SetVertexColor(color[1], color[2], color[3])
            popup:Hide()
            if callback then
                callback(color)
            end
        end)
    end

    btn:SetScript('OnClick', function()
        if popup:IsVisible() then
            popup:Hide()
        else
            popup:Show()
        end
    end)

    btn.popup = popup
    return btn
end

function Gui.ToggleButton(parent, text, width, height, initialState)
    local btn = Gui.Button(parent, text or 'Toggle', width or 100, height or 25, false)
    btn.isToggled = initialState or false

    local function updateAppearance()
        if btn.isToggled then
            btn:SetBackdropColor(0.3, 0.6, 0.3, 0.8)  -- Green when toggled
            btn.text:SetTextColor(1, 1, 1)
        else
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)  -- Dark when not toggled
            btn.text:SetTextColor(0.9, 0.9, 0.9)
        end
    end

    btn:SetScript('OnClick', function()
        btn.isToggled = not btn.isToggled
        updateAppearance()
        if btn.onToggle then
            btn.onToggle(btn.isToggled)
        end
    end)

    btn.SetToggled = function(self, state)
        self.isToggled = state
        updateAppearance()
    end

    btn.IsToggled = function(self)
        return self.isToggled
    end

    updateAppearance()
    return btn
end

function Gui.Highlight(buttons, texture, color)
    debugprint('Highlight - Adding highlights')

    if not buttons then
        return
    end

    -- Convert single button to table
    if buttons.SetScript then
        buttons = {buttons}
    end

    texture = texture or 'Interface\\QuestFrame\\UI-QuestTitleHighlight'
    color = color or {1, 1, 1, 0.5}

    for i = 1, table.getn(buttons) do
        local btn = buttons[i]
        if btn and btn.SetScript then
            local highlight = btn:CreateTexture(nil, 'OVERLAY')
            highlight:SetTexture(texture)
            highlight:SetPoint('TOPLEFT', btn, 'TOPLEFT', 2, -4)
            highlight:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', -2, 4)
            highlight:SetBlendMode('ADD')
            highlight:SetAlpha(0)

            if texture == 'Interface\\Buttons\\WHITE8X8' then
                highlight:SetVertexColor(color[1], color[2], color[3], color[4] or 0.5)
            end

            btn:SetScript('OnEnter', function()
                UIFrameFadeRemoveFrame(highlight)
                highlight:SetAlpha(1)
            end)

            btn:SetScript('OnLeave', function()
                UIFrameFadeOut(highlight, 0.3, 1, 0)
            end)
        end
    end
end

function Gui.PushFrame(parent, width, height, maxLines)
    debugprint('PushFrame - Init')
    local LINE_HEIGHT = 16
    local PADDING = 5

    local pushFrame = Gui.Scrollframe(parent, width or 300, height or 200)
    pushFrame.messages = {}
    pushFrame.maxLines = maxLines or 100

    local function updateLayout()
        local currentScroll = pushFrame:GetVerticalScroll()
        local yOffset = 0
        for i = 1, table.getn(pushFrame.messages) do
            local msg = pushFrame.messages[i]
            msg.fontString:SetPoint('TOPLEFT', pushFrame.content, 'TOPLEFT', PADDING, -yOffset - PADDING)
            yOffset = yOffset + LINE_HEIGHT
        end
        pushFrame.content:SetHeight(yOffset + PADDING * 2)
        pushFrame.updateScrollBar()

        -- Restore scroll position within valid range
        local maxScroll = math.max(0, pushFrame.content:GetHeight() - pushFrame:GetHeight())
        local validScroll = math.max(0, math.min(currentScroll, maxScroll))
        pushFrame:SetVerticalScroll(validScroll)
        pushFrame.scrollBar:SetValue(validScroll)
    end

    pushFrame.ScrollToBottom = function(self)
        local maxScroll = math.max(0, pushFrame.content:GetHeight() - pushFrame:GetHeight())
        if maxScroll > 0 then
            pushFrame:SetVerticalScroll(maxScroll)
            pushFrame.scrollBar:SetValue(maxScroll)
        end
    end

    pushFrame.AddMessage = function(self, text, color, position)
        debugprint('PushFrame - AddMessage: ' .. text)
        color = color or {1, 1, 1}
        position = position or 'bottom'

        local fontString = pushFrame.content:CreateFontString(nil, 'OVERLAY')
        fontString:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
        fontString:SetTextColor(color[1], color[2], color[3])
        fontString:SetText(text)
        fontString:SetWidth(pushFrame:GetWidth() - PADDING * 2)
        fontString:SetJustifyH('LEFT')

        local message = {
            text = text,
            fontString = fontString,
            color = color
        }

        if position == 'top' then
            table.insert(self.messages, 1, message)
        else
            table.insert(self.messages, message)
        end

        -- Remove old messages if over limit
        while table.getn(self.messages) > self.maxLines do
            local oldMsg = table.remove(self.messages, 1)
            oldMsg.fontString:Hide()
        end

        updateLayout()
    end

    pushFrame.Clear = function(self)
        debugprint('PushFrame - Clear')
        for i = 1, table.getn(self.messages) do
            self.messages[i].fontString:Hide()
        end
        self.messages = {}
        updateLayout()
    end

    return pushFrame
end

function Gui.Confirmbox(message, onAccept, onDecline)
    if Gui.activeConfirm then return end
    debugprint('Confirmbox - Init')
    local frame = Gui.Frame(UIParent, 200, 100, 0.9, true)
    frame:SetPoint('CENTER', 0, 0)
    frame:SetFrameStrata('DIALOG')
    Gui.activeConfirm = frame

    local text = Gui.Font(frame, 11, message or 'Confirm?', {1, 1, 1}, 'CENTER')
    text:SetPoint('TOP', frame, 'TOP', 0, -15)
    text:SetWidth(180)

    local acceptBtn = Gui.Button(frame, 'Accept', 70, 25)
    acceptBtn:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 15, 10)
    acceptBtn:SetScript('OnClick', function()
        frame:Hide()
        Gui.activeConfirm = nil
        if onAccept then onAccept() end
    end)

    local declineBtn = Gui.Button(frame, 'Decline', 70, 25)
    declineBtn:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -15, 10)
    declineBtn:SetScript('OnClick', function()
        frame:Hide()
        Gui.activeConfirm = nil
        if onDecline then onDecline() end
    end)

    return frame
end

function Gui.UpdateAllFonts(frame, newFont)
    local regions = {frame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region and region.SetFont then
            local _, size, flags = region:GetFont()
            region:SetFont(newFont, size, flags)
        end
    end

    local children = {frame:GetChildren()}
    for i = 1, table.getn(children) do
        local child = children[i]
        if child then
            Gui.UpdateAllFonts(child, newFont)
        end
    end
end

local data = Tools.CalenderData()
function Gui.Calender(parent, side, width, height, onDateSelected)
    debugprint('Calender - Data loaded, currentIndex: ' .. data.currentIndex)

    local todayDate = date('%d/%m/%y')
    local btn = Gui.Button(parent or UIParent, todayDate, width or 60, height or 25)
    local frame = Gui.Frame(UIParent, 300, 225, 0.8, true)
    frame:Hide()

    -- Set frame strata to button strata + 1
    local btnStrata = btn:GetFrameStrata()
    local strataLevels = {'BACKGROUND', 'LOW', 'MEDIUM', 'HIGH', 'DIALOG', 'FULLSCREEN', 'FULLSCREEN_DIALOG', 'TOOLTIP'}
    local btnStrataIndex = 1
    for i = 1, table.getn(strataLevels) do
        if strataLevels[i] == btnStrata then
            btnStrataIndex = i
            break
        end
    end
    local frameStrataIndex = math.min(btnStrataIndex + 1, table.getn(strataLevels))
    frame:SetFrameStrata(strataLevels[frameStrataIndex])

    local selectedDate = todayDate

    -- Header area
    local prevBtn = Gui.Button(frame, '<', 30, 25)
    prevBtn:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -10)

    local monthLabel = Gui.Font(frame, 12, data.months[data.currentIndex].monthName, {1, 1, 1}, 'CENTER')
    monthLabel:SetPoint('TOP', frame, 'TOP', 0, -20)
    debugprint('Calender - Initial month: ' .. data.months[data.currentIndex].monthName)

    local nextBtn = Gui.Button(frame, '>', 30, 25)
    nextBtn:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -10)

    -- Navigation logic
    prevBtn:SetScript('OnClick', function()
        debugprint('Calender - Prev clicked, current: ' .. data.currentIndex)
        if data.currentIndex > data.minIndex then
            data.currentIndex = data.currentIndex - 1
            monthLabel:SetText(data.months[data.currentIndex].monthName)
            debugprint('Calender - Changed to: ' .. data.months[data.currentIndex].monthName)
        end
    end)

    nextBtn:SetScript('OnClick', function()
        debugprint('Calender - Next clicked, current: ' .. data.currentIndex)
        if data.currentIndex < data.maxIndex then
            data.currentIndex = data.currentIndex + 1
            monthLabel:SetText(data.months[data.currentIndex].monthName)
            debugprint('Calender - Changed to: ' .. data.months[data.currentIndex].monthName)
        end
    end)

    local dayButtons = {}
    local function refreshGrid()
        local current = data.months[data.currentIndex]
        debugprint('Calender - Refreshing grid: ' .. current.days .. ' days, firstDay: ' .. current.firstDay)

        for i = 1, table.getn(dayButtons) do
            dayButtons[i]:Hide()
        end

        local buttonIndex = 1
        for week = 0, 5 do
            for day = 0, 6 do
                local gridPos = week * 7 + day + 1
                local dayNum = gridPos - current.firstDay

                if dayNum >= 1 and dayNum <= current.days then
                    if not dayButtons[buttonIndex] then
                        dayButtons[buttonIndex] = Gui.Button(frame, '', 35, 25)
                        dayButtons[buttonIndex]:SetScript('OnClick', function()
                            local current = data.months[data.currentIndex]
                            local dateStr = string.format('%02d/%02d/%02d', dayNum, current.month, math.mod(current.year, 100))
                            local dateRaw = string.format('%02d%02d%02d', math.mod(current.year, 100), current.month, dayNum)
                            debugprint('Calender - Day clicked: ' .. dayNum .. ' -> ' .. dateStr)

                            selectedDate = dateStr
                            btn.text:SetText(dateStr)
                            frame:Hide()

                            if onDateSelected then
                                onDateSelected(selectedDate, dateRaw)
                            end
                        end)
                    end

                    local dayBtn = dayButtons[buttonIndex]
                    dayBtn.text:SetText(dayNum)
                    dayBtn:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10 + day * 40, -50 - week * 30)
                    dayBtn:Show()
                    buttonIndex = buttonIndex + 1
                end
            end
        end

        debugprint('Calender - Created ' .. (buttonIndex - 1) .. ' day buttons')
    end

    refreshGrid()

    local origPrevClick = prevBtn:GetScript('OnClick')
    prevBtn:SetScript('OnClick', function()
        origPrevClick()
        refreshGrid()
    end)

    local origNextClick = nextBtn:GetScript('OnClick')
    nextBtn:SetScript('OnClick', function()
        origNextClick()
        refreshGrid()
    end)

    if side == 'top' then
        frame:SetPoint('BOTTOM', btn, 'TOP', 0, 5)
    else
        frame:SetPoint('TOP', btn, 'BOTTOM', 0, -5)
    end

    btn:SetScript('OnClick', function()
        if frame:IsVisible() then
            frame:Hide()
        else
            frame:Show()
        end
    end)

    return btn
end

LoadingBarManager = {
    bars = {},
    nextId = 1
}

function LoadingBarManager:Create(id, width, height, repeating, direction, time)
    if self.bars[id] then
        self:Destroy(id)
    end

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetWidth(width)
    frame:SetHeight(height)

    local bg = frame:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture('Interface\\Buttons\\WHITE8X8')
    bg:SetAllPoints(frame)
    bg:SetVertexColor(0.2, 0.2, 0.2, 1)

    local bar = frame:CreateTexture(nil, 'ARTWORK')
    bar:SetTexture('Interface\\Buttons\\WHITE8X8')
    bar:SetPoint('LEFT', frame, 'LEFT', 0, 0)
    bar:SetHeight(height)
    bar:SetWidth(0)

    local barData = {
        frame = frame,
        bar = bar,
        width = width,
        height = height,
        repeating = repeating,
        direction = direction or 'left',
        time = time,
        elapsed = 0,
        progress = 0
    }

    frame:SetScript('OnUpdate', function()
        LoadingBarManager:Update(id)
    end)

    self.bars[id] = barData
    return frame
end

function LoadingBarManager:Update(id)
    local data = self.bars[id]
    if not data then return end

    local parent = data.frame:GetParent()
    if parent and not parent:IsVisible() then return end

    data.elapsed = data.elapsed + arg1
    data.progress = data.elapsed / data.time

    if data.progress >= 1 then
        if data.repeating then
            data.elapsed = 0
            data.progress = 0
        else
            self:Destroy(id)
            return
        end
    end

    self:UpdateTexture(data)
end

function LoadingBarManager:UpdateTexture(data)
    local newWidth = data.width * data.progress
    if data.direction == 'right' then
        data.bar:SetPoint('RIGHT', data.frame, 'RIGHT', 0, 0)
        data.bar:SetWidth(newWidth)
    else
        data.bar:SetWidth(newWidth)
    end
end

function LoadingBarManager:Destroy(id)
    local data = self.bars[id]
    if data then
        data.frame:Hide()
        data.frame = nil
        self.bars[id] = nil
    end
end

function LoadingBar(width, height, repeating, direction, time)
    local id = 'bar_' .. LoadingBarManager.nextId
    LoadingBarManager.nextId = LoadingBarManager.nextId + 1
    return LoadingBarManager:Create(id, width, height, repeating, direction, time)
end

-- function Gui.TabFrame(parent, width, height, tabHeight, subtabIndent)
--     debugprint('TabFrame - Init')
--     local TAB_HEIGHT = tabHeight or 25
--     local SUBTAB_INDENT = subtabIndent or 15
--     local TAB_WIDTH = width or 120

--     local tabScroll = Gui.Scrollframe(parent, TAB_WIDTH, height or 300)

--     tabScroll.tabs = {}
--     tabScroll.expandedTab = nil
--     tabScroll.animating = false
--     tabScroll.onTabClick = nil

--     local function updateLayout()
--         debugprint('TabFrame - updateLayout')
--         local yOffset = 0
--         local totalHeight = 0
--         local needsAnimation = false

--         for i = 1, table.getn(tabScroll.tabs) do
--             local tab = tabScroll.tabs[i]
--             tab.targetY = -yOffset

--             if not tab.currentY then
--                 tab.currentY = tab.targetY
--             end

--             if math.abs(tab.targetY - tab.currentY) > 0.5 then
--                 needsAnimation = true
--             end

--             yOffset = yOffset + TAB_HEIGHT
--             totalHeight = totalHeight + TAB_HEIGHT

--             if tabScroll.expandedTab == i and tab.subtabs then
--                 for j = 1, table.getn(tab.subtabs) do
--                     local subtab = tab.subtabs[j]
--                     subtab.targetY = -yOffset

--                     if not subtab.currentY then
--                         subtab.currentY = subtab.targetY
--                     end

--                     if math.abs(subtab.targetY - subtab.currentY) > 0.5 then
--                         needsAnimation = true
--                     end

--                     yOffset = yOffset + TAB_HEIGHT
--                     totalHeight = totalHeight + TAB_HEIGHT
--                 end
--             end
--         end

--         tabScroll.content:SetHeight(totalHeight)
--         tabScroll.updateScrollBar()

--         if needsAnimation and not tabScroll.animating then
--             debugprint('TabFrame - Starting animation')
--             tabScroll.animating = true
--             tabScroll:SetScript('OnUpdate', function()
--                 local stillAnimating = false

--                 for i = 1, table.getn(tabScroll.tabs) do
--                     local tab = tabScroll.tabs[i]
--                     if math.abs(tab.targetY - tab.currentY) > 0.5 then
--                         tab.currentY = tab.currentY + (tab.targetY - tab.currentY) * 0.3
--                         stillAnimating = true
--                     else
--                         tab.currentY = tab.targetY
--                     end
--                     tab.button:SetPoint('TOPLEFT', tabScroll.content, 'TOPLEFT', 0, tab.currentY)

--                     if tabScroll.expandedTab == i and tab.subtabs then
--                         for j = 1, table.getn(tab.subtabs) do
--                             local subtab = tab.subtabs[j]
--                             if math.abs(subtab.targetY - subtab.currentY) > 0.5 then
--                                 subtab.currentY = subtab.currentY + (subtab.targetY - subtab.currentY) * 0.3
--                                 stillAnimating = true
--                             else
--                                 subtab.currentY = subtab.targetY
--                             end
--                             subtab.button:SetPoint('TOPLEFT', tabScroll.content, 'TOPLEFT', SUBTAB_INDENT, subtab.currentY)
--                         end
--                     end
--                 end

--                 if not stillAnimating then
--                     debugprint('TabFrame - Animation complete')
--                     tabScroll.animating = false
--                     tabScroll:SetScript('OnUpdate', nil)
--                 end
--             end)
--         elseif not needsAnimation then
--             for i = 1, table.getn(tabScroll.tabs) do
--                 local tab = tabScroll.tabs[i]
--                 tab.currentY = tab.targetY
--                 tab.button:SetPoint('TOPLEFT', tabScroll.content, 'TOPLEFT', 0, tab.currentY)

--                 if tabScroll.expandedTab == i and tab.subtabs then
--                     for j = 1, table.getn(tab.subtabs) do
--                         local subtab = tab.subtabs[j]
--                         subtab.currentY = subtab.targetY
--                         subtab.button:SetPoint('TOPLEFT', tabScroll.content, 'TOPLEFT', SUBTAB_INDENT, subtab.currentY)
--                     end
--                 end
--             end
--         end
--     end

--     local function collapseAll()
--         debugprint('TabFrame - collapseAll')
--         if tabScroll.expandedTab then
--             local tab = tabScroll.tabs[tabScroll.expandedTab]
--             if tab.subtabs then
--                 for i = 1, table.getn(tab.subtabs) do
--                     tab.subtabs[i].button:Hide()
--                 end
--             end
--             tabScroll.expandedTab = nil
--         end
--     end

--     local function expandTab(tabIndex)
--         debugprint('TabFrame - expandTab: ' .. tabIndex)
--         local tab = tabScroll.tabs[tabIndex]
--         if tab.subtabs then
--             tabScroll.expandedTab = tabIndex
--             for i = 1, table.getn(tab.subtabs) do
--                 tab.subtabs[i].button:Show()
--             end
--         end
--     end

--     tabScroll.AddTab = function(self, name, subtabs)
--         debugprint('TabFrame - AddTab: ' .. name)
--         local tabIndex = table.getn(self.tabs) + 1

--         local btn = Gui.Button(tabScroll.content, name, TAB_WIDTH, TAB_HEIGHT, false, nil, true)
--         btn:SetScript('OnClick', function()
--             collapseAll()

--             if subtabs then
--                 if tabScroll.expandedTab == tabIndex then
--                     tabScroll.expandedTab = nil
--                 else
--                     expandTab(tabIndex)
--                 end
--             else
--                 if tabScroll.onTabClick then
--                     tabScroll.onTabClick(tabIndex)
--                 end
--             end

--             updateLayout()
--         end)

--         local tab = {
--             name = name,
--             button = btn,
--             subtabs = nil,
--             targetY = 0
--         }

--         if subtabs then
--             tab.subtabs = {}
--             for i = 1, table.getn(subtabs) do
--                 local subtabName = subtabs[i]
--                 local subBtn = Gui.Button(tabScroll.content, subtabName, TAB_WIDTH - SUBTAB_INDENT, TAB_HEIGHT, false, nil, true)
--                 subBtn:SetScript('OnClick', function()
--                     if tabScroll.onTabClick then
--                         tabScroll.onTabClick(tabIndex, i)
--                     end
--                 end)
--                 subBtn:Hide()

--                 table.insert(tab.subtabs, {
--                     name = subtabName,
--                     button = subBtn,
--                     targetY = 0
--                 })
--             end
--         end

--         table.insert(self.tabs, tab)
--         updateLayout()
--     end

--     return tabScroll
-- end
