BASE:ENV()

INSTALL('Gui-three', 4, function()
    debugprint 'BOOT'

    -- ===================
    -- ✔️ DATA
    -- ===================
    local GUI = GETCORE('Gui')

    local GUITT = {
        OPTIONS_BTN_WIDTH = 60,
        OPTIONS_BTN_HEIGHT = 25,
        OPTIONS_BTN_OFFSET = -45,
        OPTIONS_FRAME_WIDTH = 150,
        OPTIONS_FRAME_HEIGHT = 500,
        OPTIONS_FRAME_ALPHA = 0.3,
        HEADER_SIZE = 14,
        HEADER_Y_OFFSET = -10,
        FIRST_ELEMENT_Y = -50,
        ELEMENT_SPACING = -30,
        ELEMENT_HEADER_SIZE = 10,
        HEADER_TO_ELEMENT_SPACING = -15,
        SLIDER_WIDTH = 100,
        SLIDER_HEIGHT = 24,
        DROPDOWN_WIDTH = 120,
        DROPDOWN_HEIGHT = 25,
        BLUE_ACCENT = {0, 0.67, 1},
        LABEL_COLOR = {0.7, 0.7, 0.7},
        patchAlpha = 0.7,
        guiData = GETDATA(TempDB, 'gui') or {},
        fonts = {
            'FRIZQT__.TTF',
            'ARIALN.TTF',
            'skurri.TTF',
            'MORPHEUS.TTF',
        },
        scales = {
            {text = '100%', value = 1.0},
            {text = '90%', value = 0.9},
            {text = '80%', value = 0.8},
            {text = '70%', value = 0.7},
            {text = '60%', value = 0.6},
            {text = '50%', value = 0.5}
        }
    }

    -- ===================
    -- ✔️ CORE
    -- ===================
    function GUI:UpdateAllFonts(newFont)
        local function updateFrameFonts(frame)
            if not frame then return end

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
                updateFrameFonts(children[i])
            end
        end

        updateFrameFonts(self.mainFrame)
        if self.optionsFrame then
            updateFrameFonts(self.optionsFrame)
        end
    end

    function GUI:InitializeSettings()
        local savedAlpha = GUITT.guiData.mainFrameAlpha or GUITT.patchAlpha
        self.mainFrame:SetBackdropColor(0, 0, 0, savedAlpha)

        local savedFont = GUITT.guiData.selectedFont or 'Fonts\\FRIZQT__.TTF'
        self:UpdateAllFonts(savedFont)

        local savedScale = GUITT.guiData.mainFrameScale or 1.0
        self.mainFrame:SetScale(savedScale)
        if self.optionsFrame then
            self.optionsFrame:SetScale(savedScale)
        end
    end

    function GUI:CreateOptionsButton()
        if self.optionsBtn then return end

        local optionsBtn = Gui.Button(self.mainFrame, 'Options', GUITT.OPTIONS_BTN_WIDTH, GUITT.OPTIONS_BTN_HEIGHT)
        optionsBtn:SetPoint('TOPRIGHT', self.mainFrame, 'TOPRIGHT', GUITT.OPTIONS_BTN_OFFSET, GUI.CLOSE_BTN_OFFSET - 7)

        optionsBtn:SetScript('OnClick', function()
            self:ToggleOptionsFrame()
        end)

        self.optionsBtn = optionsBtn
    end

    function GUI:CreateOptionsFrame()
        if self.optionsFrame then return end

        local savedAlpha = GUITT.guiData.mainFrameAlpha or GUITT.patchAlpha
        local optionsFrame = Gui.Frame(UIParent, GUITT.OPTIONS_FRAME_WIDTH, GUITT.OPTIONS_FRAME_HEIGHT, savedAlpha, true, 'GroupManagerOptions')
        optionsFrame:SetPoint('LEFT', self.mainFrame, 'RIGHT', 2, 0)
        optionsFrame:Hide()

        self.optionsFrame = optionsFrame

        local header = Gui.Font(optionsFrame, GUITT.HEADER_SIZE, 'Options', GUITT.BLUE_ACCENT, 'CENTER')
        header:SetPoint('TOP', optionsFrame, 'TOP', 0, GUITT.HEADER_Y_OFFSET)

        self.lastElement = nil
        self:CreateAlphaSlider()
        self:CreateFontDropdown()
        self:CreateScaleDropdown()

        local tocVersion = Gui.Font(optionsFrame, 12, 'Addon Version: |cffffffff' .. info.TOCversion .. '|r', GUITT.LABEL_COLOR, 'CENTER')
        tocVersion:SetPoint('BOTTOM', optionsFrame, 'BOTTOM', 0, 30)

        local dbVersion = Gui.Font(optionsFrame, 12, 'DB Version: |cffffffff' .. info.DBversion .. '|r', GUITT.LABEL_COLOR, 'CENTER')
        dbVersion:SetPoint('TOP', tocVersion, 'BOTTOM', 0, -5)
    end

    function GUI:CreateAlphaSlider()
        local alphaHeader = Gui.Font(self.optionsFrame, GUITT.ELEMENT_HEADER_SIZE, 'Change transparency', GUITT.LABEL_COLOR, 'CENTER')
        if self.lastElement then
            alphaHeader:SetPoint('TOP', self.lastElement, 'BOTTOM', 0, GUITT.ELEMENT_SPACING)
        else
            alphaHeader:SetPoint('TOP', self.optionsFrame, 'TOP', 0, GUITT.FIRST_ELEMENT_Y)
        end

        local savedAlpha = GUITT.guiData.mainFrameAlpha or GUITT.patchAlpha

        local alphaSlider = Gui.Slider(self.optionsFrame, nil, 'Main Frame Alpha', 0, 1, 0.1, '%.1f', GUITT.SLIDER_WIDTH, GUITT.SLIDER_HEIGHT)

        alphaSlider:SetPoint('TOP', alphaHeader, 'BOTTOM', 0, GUITT.HEADER_TO_ELEMENT_SPACING)
        alphaSlider:SetValue(savedAlpha)

        alphaSlider:SetScript('OnValueChanged', function()
            local newAlpha = this:GetValue()

            GUI.mainFrame:SetBackdropColor(0, 0, 0, newAlpha)
            GUI.optionsFrame:SetBackdropColor(0, 0, 0, newAlpha)
            GUITT.guiData.mainFrameAlpha = newAlpha
            SETDATA(TempDB, 'gui', GUITT.guiData)
            alphaSlider.updateValueText()
        end)

        self.alphaSlider = alphaSlider
        self.lastElement = alphaSlider
    end

    function GUI:CreateFontDropdown()
        local fontHeader = Gui.Font(self.optionsFrame, GUITT.ELEMENT_HEADER_SIZE, 'Change UI font style', GUITT.LABEL_COLOR, 'CENTER')
        fontHeader:SetPoint('TOP', self.lastElement, 'BOTTOM', 0, GUITT.ELEMENT_SPACING)

        local savedFont = GUITT.guiData.selectedFont or 'Fonts\\FRIZQT__.TTF'

        local fontDropdown = Gui.Dropdown(self.optionsFrame, 'Font', GUITT.DROPDOWN_WIDTH, GUITT.DROPDOWN_HEIGHT)

        fontDropdown:SetPoint('TOP', fontHeader, 'BOTTOM', 0, GUITT.HEADER_TO_ELEMENT_SPACING)

        for i = 1, table.getn(GUITT.fonts) do
            local fontName = GUITT.fonts[i]
            local fontPath = 'Fonts\\' .. fontName
            fontDropdown:AddItem(fontName, function()
                fontDropdown.text:SetText(fontName)
                fontDropdown.selectedValue = fontPath
                fontDropdown.popup:Hide()
                GUITT.guiData.selectedFont = fontPath
                SETDATA(TempDB, 'gui', GUITT.guiData)
                GUI:UpdateAllFonts(fontPath)
            end)
        end

        local displayName = string.gsub(savedFont, 'Fonts\\', '')
        fontDropdown.text:SetText(displayName)
        fontDropdown.selectedValue = savedFont

        self.fontDropdown = fontDropdown
        self.lastElement = fontDropdown
    end

    function GUI:CreateScaleDropdown()
        local scaleHeader = Gui.Font(self.optionsFrame, GUITT.ELEMENT_HEADER_SIZE, 'Change Scale', GUITT.LABEL_COLOR, 'CENTER')
        scaleHeader:SetPoint('TOP', self.lastElement, 'BOTTOM', 0, GUITT.ELEMENT_SPACING)

        local savedScale = GUITT.guiData.mainFrameScale or 1.0

        local scaleDropdown = Gui.Dropdown(self.optionsFrame, 'Scale', GUITT.DROPDOWN_WIDTH, GUITT.DROPDOWN_HEIGHT)

        scaleDropdown:SetPoint('TOP', scaleHeader, 'BOTTOM', 0, GUITT.HEADER_TO_ELEMENT_SPACING)

        for i = 1, table.getn(GUITT.scales) do
            local scaleData = GUITT.scales[i]
            scaleDropdown:AddItem(scaleData.text, function()
                scaleDropdown.text:SetText(scaleData.text)
                scaleDropdown.selectedValue = scaleData.value
                scaleDropdown.popup:Hide()
                GUITT.guiData.mainFrameScale = scaleData.value
                SETDATA(TempDB, 'gui', GUITT.guiData)
                GUI.mainFrame:SetScale(scaleData.value)
                if GUI.optionsFrame then
                    GUI.optionsFrame:SetScale(scaleData.value)
                end
            end)
        end

        for i = 1, table.getn(GUITT.scales) do
            if GUITT.scales[i].value == savedScale then
                scaleDropdown.text:SetText(GUITT.scales[i].text)
                scaleDropdown.selectedValue = savedScale
                break
            end
        end

        self.scaleDropdown = scaleDropdown
        self.lastElement = scaleDropdown
    end

    function GUI:ToggleOptionsFrame()
        if not self.optionsFrame then
            self:CreateOptionsFrame()
        end

        if self.optionsFrame:IsVisible() then
            self.optionsFrame:Hide()
        else
            self.optionsFrame:Show()
        end
    end

    -- ===================
    -- ✔️ INIT
    -- ===================
    GUI:CreateOptionsButton()
    GUI:InitializeSettings()
end)