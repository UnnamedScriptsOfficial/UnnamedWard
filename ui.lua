-- ============================================================
-- UnnamedWard - Main Window + UI Helper Library
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Theme = UW.Theme
local MainFont = UW.MainFont
local MainFontBold = UW.MainFontBold
local isMobile = UW.isMobile
local Config = UW.Config
local getGuiParent = UW.getGuiParent
local LocalPlayer = Services.LocalPlayer
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local Camera = Services.Camera
local PlayerGui = Services.PlayerGui

local premiumTier = getgenv().UnnamedWardTier or "FREE"

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnnamedWardUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = getGuiParent()
table.insert(State.cleanUpInstances, screenGui)

getgenv().UW.screenGui = screenGui

-- Unload
local function UnloadScript()
    State.isRunning = false
    for _, conn in ipairs(State.activeConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(State.activeConnections)
    for _, inst in ipairs(State.cleanUpInstances) do
        if typeof(inst) == "Instance" then
            pcall(function() inst:Destroy() end)
        elseif type(inst) == "table" and type(inst.Destroy) == "function" then
            pcall(inst.Destroy)
        end
    end
    table.clear(State.cleanUpInstances)
    if State.originalUtilityRaycast then
        pcall(function()
            local util = require(Services.ReplicatedStorage.Modules.Utility)
            util.Raycast = State.originalUtilityRaycast
        end)
    end
    pcall(function() Services.ContextActionService:UnbindAction("UnnamedWardMenuFreeze") end)
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if pm then
            local controls = require(pm):GetControls()
            if controls then controls:Enable() end
        end
    end)
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if Camera and Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end)
    pcall(function()
        Services.Lighting.Brightness = 1
        Services.Lighting.GlobalShadows = true
        Services.Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        Services.Lighting.FogEnd = 100000
        Services.Lighting.FogStart = 0
        if Camera then Camera.FieldOfView = 70 end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.CameraOffset = Vector3.new(0, 0, 0)
            hum.WalkSpeed = 16
        end
    end)
    if getgenv().UW.LagKiller then pcall(function() getgenv().UW.LagKiller.Disable() end) end
    if getgenv then getgenv().UnnamedWardUnload = nil end
end

getgenv().UW.UnloadScript = UnloadScript
if getgenv then getgenv().UnnamedWardUnload = UnloadScript end

-- Main window
local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, isMobile and 340 or 480, 0, isMobile and 420 or 500)
mainWindow.Position = UDim2.new(0.5, isMobile and -170 or -240, 0.5, isMobile and -210 or -250)
mainWindow.BackgroundColor3 = Theme.WindowBg
mainWindow.BorderSizePixel = 0
mainWindow.ClipsDescendants = false
mainWindow.Active = true
mainWindow.ZIndex = 10
mainWindow.Parent = screenGui
table.insert(State.cleanUpInstances, mainWindow)

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Theme.OuterBorder
windowStroke.Thickness = 1
windowStroke.Parent = mainWindow

local windowGrad = Instance.new("UIGradient")
windowGrad.Rotation = 90
windowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.WindowBgTop),
    ColorSequenceKeypoint.new(1, Theme.WindowBgBottom)
})
windowGrad.Parent = mainWindow

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, isMobile and 28 or 32)
topBar.BackgroundColor3 = Theme.HeaderBg
topBar.BorderSizePixel = 0
topBar.ZIndex = 11
topBar.Parent = mainWindow

local isDragging = false
local dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local vp = Camera.ViewportSize
        local newX = math.clamp(startPos.X.Offset + delta.X, -mainWindow.AbsoluteSize.X + 60, vp.X - 60)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - 30)
        mainWindow.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
end)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 180, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = MainFontBold
titleLbl.RichText = true
titleLbl.Text = '<font color="#ffa0c3">Unnamed</font><font color="#96cdff">Ward</font>'
titleLbl.TextSize = isMobile and 12 or 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 13
titleLbl.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 20, 0, 19)
closeBtn.Position = UDim2.new(1, -26, 0.5, -9.5)
closeBtn.BackgroundColor3 = Theme.ControlBg
closeBtn.BorderSizePixel = 0
closeBtn.Font = MainFont
closeBtn.Text = "×"
closeBtn.TextColor3 = Theme.TextMuted
closeBtn.TextSize = 14
closeBtn.ZIndex = 12
closeBtn.Parent = topBar

local cbStroke = Instance.new("UIStroke")
cbStroke.Color = Theme.BorderPink
cbStroke.Thickness = 1
cbStroke.Parent = closeBtn

-- Inner canvas
local innerCanvas = Instance.new("Frame")
innerCanvas.Name = "InnerCanvas"
innerCanvas.Size = UDim2.new(1, -14, 1, -40)
innerCanvas.Position = UDim2.new(0, 7, 0, isMobile and 30 or 33)
innerCanvas.BackgroundColor3 = Theme.InnerCanvasBg
innerCanvas.BorderSizePixel = 0
innerCanvas.ZIndex = 11
innerCanvas.Parent = mainWindow

local innerStroke = Instance.new("UIStroke")
innerStroke.Color = Theme.BorderPink
innerStroke.Thickness = 1
innerStroke.Parent = innerCanvas

-- Tab nav
local tabNavFrame = Instance.new("Frame")
tabNavFrame.Name = "TabNavFrame"
tabNavFrame.Size = UDim2.new(1, -12, 0, 22)
tabNavFrame.Position = UDim2.new(0, 6, 0, 4)
tabNavFrame.BackgroundTransparency = 1
tabNavFrame.ZIndex = 12
tabNavFrame.Parent = innerCanvas

local tabNavLayout = Instance.new("UIListLayout")
tabNavLayout.FillDirection = Enum.FillDirection.Horizontal
tabNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabNavLayout.Padding = UDim.new(0, isMobile and 4 or 8)
tabNavLayout.Parent = tabNavFrame

local tabContentFrame = Instance.new("Frame")
tabContentFrame.Name = "TabContentFrame"
tabContentFrame.Size = UDim2.new(1, -12, 1, -54)
tabContentFrame.Position = UDim2.new(0, 6, 0, 30)
tabContentFrame.BackgroundTransparency = 1
tabContentFrame.ZIndex = 12
tabContentFrame.Parent = innerCanvas

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -12, 0, 18)
statusBar.Position = UDim2.new(0, 6, 1, -20)
statusBar.BackgroundTransparency = 1
statusBar.ZIndex = 12
statusBar.Parent = innerCanvas

local statusLeft = Instance.new("TextLabel")
statusLeft.Size = UDim2.new(0.6, 0, 1, -2)
statusLeft.Position = UDim2.new(0, 2, 0, 2)
statusLeft.BackgroundTransparency = 1
statusLeft.Font = MainFont
statusLeft.RichText = true
statusLeft.Text = 'welcome back, <font color="#ffa0c3">' .. LocalPlayer.DisplayName .. '</font>'
statusLeft.TextColor3 = Theme.TextMuted
statusLeft.TextSize = 10.5
statusLeft.TextXAlignment = Enum.TextXAlignment.Left
statusLeft.ZIndex = 13
statusLeft.Parent = statusBar

local statusRight = Instance.new("TextLabel")
statusRight.Size = UDim2.new(0.4, -2, 1, -2)
statusRight.Position = UDim2.new(0.6, 0, 0, 2)
statusRight.BackgroundTransparency = 1
statusRight.Font = MainFont
statusRight.RichText = true
statusRight.Text = '<font color="#ffa0c3">[</font> <font color="#888894">' .. premiumTier .. '</font> <font color="#ffa0c3">]</font>'
statusRight.TextColor3 = Theme.TextMuted
statusRight.TextSize = 10.5
statusRight.TextXAlignment = Enum.TextXAlignment.Right
statusRight.ZIndex = 13
statusRight.Parent = statusBar

-- Tab state
local tabList = {"home", "aim", "auto", "esp", "move", "guns", "skins", "world", "view", "config"}
local tabPages = {}
local tabButtons = {}
local currentTab = "home"
local uiRegistry = {}

local function setMenuVisible(visible) mainWindow.Visible = visible end

local function switchTab(tabName)
    currentTab = tabName
    for tName, page in pairs(tabPages) do
        page.Visible = (tName == tabName)
    end
    for _, btnData in ipairs(tabButtons) do
        local isSelf = (btnData.name == tabName)
        btnData.btn.TextColor3 = isSelf and Theme.AccentPink or Theme.TextMuted
        if btnData.indicator then btnData.indicator.Visible = isSelf end
    end
    local page = tabPages[tabName]
    if page then
        page.BackgroundTransparency = 0.75
        TweenService:Create(page, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
    end
end

for idx, tabName in ipairs(tabList) do
    local btn = Instance.new("TextButton")
    btn.Name = "TabBtn_" .. tabName
    btn.LayoutOrder = idx
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.Font = MainFont
    btn.Text = tabName:sub(1, 1):upper() .. tabName:sub(2)
    btn.TextColor3 = (tabName == currentTab) and Theme.AccentPink or Theme.TextMuted
    btn.TextSize = isMobile and 10 or 12
    btn.AutoButtonColor = false
    btn.ZIndex = 13
    btn.Parent = tabNavFrame

    local padBtn = Instance.new("UIPadding")
    padBtn.PaddingLeft = UDim.new(0, isMobile and 2 or 4)
    padBtn.PaddingRight = UDim.new(0, isMobile and 2 or 4)
    padBtn.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(1, -4, 0, 1.5)
    indicator.Position = UDim2.new(0, 2, 1, -1)
    indicator.BackgroundColor3 = Theme.AccentPink
    indicator.BorderSizePixel = 0
    indicator.Visible = (tabName == currentTab)
    indicator.ZIndex = 14
    indicator.Parent = btn

    btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
    table.insert(tabButtons, {name = tabName, btn = btn, indicator = indicator})

    local page = Instance.new("Frame")
    page.Name = "Page_" .. tabName
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = (tabName == currentTab)
    page.ZIndex = 13
    page.Parent = tabContentFrame

    local leftCol = Instance.new("ScrollingFrame")
    leftCol.Name = "LeftCol"
    leftCol.Size = UDim2.new(isMobile and 1 or 0.49, 0, isMobile and 0.5 or 1, isMobile and -4 or 0)
    leftCol.Position = UDim2.new(0, 0, 0, 0)
    leftCol.BackgroundTransparency = 1
    leftCol.BorderSizePixel = 0
    leftCol.ScrollBarThickness = isMobile and 4 or 0
    leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftCol.ZIndex = 14
    leftCol.Parent = page
    local lLayout = Instance.new("UIListLayout")
    lLayout.Padding = UDim.new(0, 7)
    lLayout.Parent = leftCol

    local rightCol = Instance.new("ScrollingFrame")
    rightCol.Name = "RightCol"
    rightCol.Size = UDim2.new(isMobile and 1 or 0.49, 0, isMobile and 0.5 or 1, isMobile and -4 or 0)
    rightCol.Position = isMobile and UDim2.new(0, 0, 0.5, 4) or UDim2.new(0.51, 0, 0, 0)
    rightCol.BackgroundTransparency = 1
    rightCol.BorderSizePixel = 0
    rightCol.ScrollBarThickness = isMobile and 4 or 0
    rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightCol.ZIndex = 14
    rightCol.Parent = page
    local rLayout = Instance.new("UIListLayout")
    rLayout.Padding = UDim.new(0, 7)
    rLayout.Parent = rightCol

    tabPages[tabName] = page
end

closeBtn.MouseButton1Click:Connect(function() setMenuVisible(false) end)

-- ============================================================
-- UI HELPERS
-- ============================================================
local function createGroupbox(parent, title, desc, bottomNote)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.ZIndex = 15
    card.Parent = parent

    local cGrad = Instance.new("UIGradient")
    cGrad.Rotation = 90
    cGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.CardBgTop),
        ColorSequenceKeypoint.new(1, Theme.CardBgBottom)
    })
    cGrad.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.BorderCard
    stroke.Thickness = 1
    stroke.Parent = card

    local topPinkLine = Instance.new("Frame")
    topPinkLine.Size = UDim2.new(1, 0, 0, 1.5)
    topPinkLine.BackgroundColor3 = Theme.AccentPink
    topPinkLine.BorderSizePixel = 0
    topPinkLine.ZIndex = 16
    topPinkLine.Parent = card

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, desc and 32 or 20)
    header.Position = UDim2.new(0, 0, 0, 1)
    header.BackgroundTransparency = 1
    header.ZIndex = 16
    header.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -12, 0, 16)
    titleLbl.Position = UDim2.new(0, 6, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = MainFontBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.TextPink
    titleLbl.TextSize = isMobile and 11 or 12.5
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 17
    titleLbl.Parent = header

    if desc then
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -12, 0, 14)
        descLbl.Position = UDim2.new(0, 6, 0, 17)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = MainFont
        descLbl.Text = desc
        descLbl.TextColor3 = Theme.TextMuted
        descLbl.TextSize = 10.5
        descLbl.TextWrapped = true
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.ZIndex = 17
        descLbl.Parent = header
    end

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -12, 0, 0)
    content.Position = UDim2.new(0, 6, 0, desc and 34 or 22)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.ZIndex = 16
    content.Parent = card

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 6)
    cLayout.Parent = content

    local cPad = Instance.new("UIPadding")
    cPad.PaddingBottom = UDim.new(0, bottomNote and 3 or 7)
    cPad.Parent = content

    if bottomNote then
        local noteLbl = Instance.new("TextLabel")
        noteLbl.Size = UDim2.new(1, 0, 0, 22)
        noteLbl.BackgroundTransparency = 1
        noteLbl.Font = MainFont
        noteLbl.Text = bottomNote
        noteLbl.TextColor3 = Theme.TextDark
        noteLbl.TextSize = 10
        noteLbl.TextWrapped = true
        noteLbl.TextXAlignment = Enum.TextXAlignment.Left
        noteLbl.ZIndex = 17
        noteLbl.Parent = content
    end

    return content
end

local function addCheckbox(parent, labelText, defaultVal, callback)
    local state = defaultVal or false
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, isMobile and 22 or 16)
    row.BackgroundTransparency = 1
    row.ZIndex = 16
    row.Parent = parent

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, isMobile and 16 or 13, 0, isMobile and 16 or 13)
    box.Position = UDim2.new(0, 0, 0.5, isMobile and -8 or -6.5)
    box.BackgroundColor3 = state and Theme.AccentPink or Theme.ControlBg
    box.BorderSizePixel = 0
    box.Text = ""
    box.ZIndex = 17
    box.Parent = row

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = state and Theme.AccentPink or Theme.BorderPink
    bStroke.Thickness = 1
    bStroke.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextSize = isMobile and 11 or 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = row

    local function updateState(newVal)
        state = newVal
        box.BackgroundColor3 = state and Theme.AccentPink or Theme.ControlBg
        bStroke.Color = state and Theme.AccentPink or Theme.BorderPink
        if type(callback) == "function" then callback(state) end
    end

    box.MouseButton1Click:Connect(function() updateState(not state) end)
    return { Set = updateState, Get = function() return state end }
end

local function addSlider(parent, labelText, minVal, maxVal, defaultVal, displayTemplate, callback)
    local curVal = defaultVal or minVal
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 34 or 28)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = isMobile and 10.5 or 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, 0, 0, isMobile and 18 or 14)
    track.Position = UDim2.new(0, 0, 0, isMobile and 14 or 13)
    track.BackgroundColor3 = Theme.ControlBg
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.ZIndex = 17
    track.Parent = container

    local tStroke = Instance.new("UIStroke")
    tStroke.Color = Theme.BorderPink
    tStroke.Thickness = 1
    tStroke.Parent = track

    local fill = Instance.new("Frame")
    local pct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentPink
    fill.BorderSizePixel = 0
    fill.ZIndex = 18
    fill.Parent = track

    local fGrad = Instance.new("UIGradient")
    fGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentPinkLight),
        ColorSequenceKeypoint.new(1, Theme.AccentBlueLight)
    })
    fGrad.Parent = fill

    local decimals = 0
    if displayTemplate then
        local d = displayTemplate:match("%%%.(%d+)f")
        if d then decimals = tonumber(d)
        elseif displayTemplate:find("%%f") then decimals = 2 end
    elseif (minVal % 1 ~= 0) or (maxVal % 1 ~= 0) or (curVal % 1 ~= 0) then
        decimals = 2
    end

    local function roundVal(raw)
        if decimals > 0 then
            local mult = 10 ^ decimals
            return math.clamp(math.floor(raw * mult + 0.5) / mult, minVal, maxVal)
        else
            return math.clamp(math.floor(raw + 0.5), minVal, maxVal)
        end
    end

    local function getDisplay(v)
        if displayTemplate then return string.format(displayTemplate, v, maxVal) end
        return tostring(v)
    end

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = MainFont
    valLbl.Text = getDisplay(curVal)
    valLbl.TextColor3 = Theme.TextWhite
    valLbl.TextSize = isMobile and 10 or 10.5
    valLbl.ZIndex = 19
    valLbl.Parent = track

    local isSliding = false
    local function updateFromInput(input)
        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal - minVal) * relX
        curVal = roundVal(raw)
        local visualPct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(visualPct, 0, 1, 0)
        valLbl.Text = getDisplay(curVal)
        if type(callback) == "function" then callback(curVal) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    return {
        Set = function(v)
            local num = tonumber(v) or curVal
            curVal = roundVal(num)
            local p = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
            fill.Size = UDim2.new(p, 0, 1, 0)
            valLbl.Text = getDisplay(curVal)
            if type(callback) == "function" then callback(curVal) end
        end
    }
end

local function addDropdown(parent, labelText, options, defaultIdx, callback)
    local selectedIdx = defaultIdx or 1
    local isOpen = false
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 40 or 34)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 13)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = isMobile and 10.5 or 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(1, 0, 0, isMobile and 24 or 20)
    box.Position = UDim2.new(0, 0, 0, isMobile and 14 or 14)
    box.BackgroundColor3 = Theme.ControlBg
    box.BorderSizePixel = 0
    box.Font = MainFont
    box.Text = "  " .. options[selectedIdx]
    box.TextColor3 = Theme.TextWhite
    box.TextSize = isMobile and 10.5 or 11.5
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ZIndex = 17
    box.Parent = container

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.BorderPink
    bStroke.Thickness = 1
    bStroke.Parent = box

    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.new(0, 14, 1, 0)
    chevron.Position = UDim2.new(1, -16, 0, 0)
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.GothamBold
    chevron.Text = "▼"
    chevron.TextColor3 = Theme.AccentPink
    chevron.TextSize = 8.5
    chevron.ZIndex = 18
    chevron.Parent = box

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.BackgroundColor3 = Theme.CardBg
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2.5
    listFrame.ScrollBarImageColor3 = Theme.AccentPink
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listFrame.ZIndex = 1001
    listFrame.Visible = false
    listFrame.Parent = screenGui

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = Theme.BorderPink
    lStroke.Thickness = 1
    lStroke.Parent = listFrame

    local optLayout = Instance.new("UIListLayout")
    optLayout.Padding = UDim.new(0, 1)
    optLayout.Parent = listFrame

    local function closeDropdown()
        isOpen = false
        listFrame.Visible = false
        chevron.Text = "▼"
        bStroke.Color = Theme.BorderPink
    end

    local function refreshOptions()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for idx, optName in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 22)
            optBtn.BackgroundColor3 = (idx == selectedIdx) and Theme.ButtonHoverBg or Theme.CardBg
            optBtn.BorderSizePixel = 0
            optBtn.Font = MainFont
            optBtn.Text = "  " .. optName
            optBtn.TextColor3 = (idx == selectedIdx) and Theme.AccentPink or Theme.TextWhite
            optBtn.TextSize = isMobile and 10.5 or 11.5
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.ZIndex = 1002
            optBtn.Parent = listFrame
            optBtn.MouseButton1Click:Connect(function()
                selectedIdx = idx
                box.Text = "  " .. optName
                closeDropdown()
                if type(callback) == "function" then callback(optName, idx) end
            end)
        end
    end

    box.MouseButton1Click:Connect(function()
        if isOpen then
            closeDropdown()
        else
            refreshOptions()
            local boxPos = box.AbsolutePosition
            local boxSize = box.AbsoluteSize
            local menuHeight = math.min(#options * 23, 140)
            listFrame.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y + boxSize.Y + 2)
            listFrame.Size = UDim2.new(0, boxSize.X, 0, menuHeight)
            listFrame.Visible = true
            isOpen = true
            chevron.Text = "▲"
            bStroke.Color = Theme.AccentPink
        end
    end)

    return {
        Set = function(valOrIdx)
            local targetIdx = 1
            if type(valOrIdx) == "number" then targetIdx = math.clamp(valOrIdx, 1, #options)
            elseif type(valOrIdx) == "string" then
                for i, name in ipairs(options) do
                    if name == valOrIdx then targetIdx = i break end
                end
            end
            selectedIdx = targetIdx
            box.Text = "  " .. options[selectedIdx]
            if type(callback) == "function" then callback(options[selectedIdx], selectedIdx) end
        end,
        SetOptions = function(newOptions, newSelected)
            options = newOptions
            local targetIdx = 1
            if type(newSelected) == "number" then targetIdx = math.clamp(newSelected, 1, #options)
            elseif type(newSelected) == "string" then
                for i, name in ipairs(options) do
                    if name == newSelected then targetIdx = i break end
                end
            end
            selectedIdx = targetIdx
            box.Text = "  " .. (options[selectedIdx] or "None")
        end,
        Get = function() return options[selectedIdx] end
    }
end

local function addTextbox(parent, labelText, defaultVal, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 36 or 33)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = isMobile and 10.5 or 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, 0, 0, isMobile and 22 or 19)
    tb.Position = UDim2.new(0, 0, 0, isMobile and 14 or 13)
    tb.BackgroundColor3 = Theme.ControlBg
    tb.BorderSizePixel = 0
    tb.Font = MainFont
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = Theme.TextDark
    tb.Text = defaultVal or ""
    tb.TextColor3 = Theme.TextWhite
    tb.TextSize = isMobile and 11 or 12
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ZIndex = 17
    tb.Parent = container

    local tPad = Instance.new("UIPadding")
    tPad.PaddingLeft = UDim.new(0, 6)
    tPad.Parent = tb

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = Theme.BorderPink
    tbStroke.Thickness = 1
    tbStroke.Parent = tb

    tb.Focused:Connect(function() tbStroke.Color = Theme.AccentPink end)
    tb.FocusLost:Connect(function()
        tbStroke.Color = Theme.BorderPink
        if type(callback) == "function" then callback(tb.Text) end
    end)

    return {
        Set = function(txt) tb.Text = tostring(txt) end,
        Get = function() return tb.Text end
    }
end

local function addButton(parent, btnText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, isMobile and 26 or 22)
    btn.BackgroundColor3 = Theme.ButtonBg
    btn.BorderSizePixel = 0
    btn.Font = MainFont
    btn.Text = btnText
    btn.TextColor3 = Theme.TextPink
    btn.TextSize = isMobile and 11 or 12
    btn.AutoButtonColor = false
    btn.ZIndex = 17
    btn.Parent = parent

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.ButtonBorder
    bStroke.Thickness = 1
    bStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Theme.ButtonHoverBg
        bStroke.Color = Theme.AccentPink
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Theme.ButtonBg
        bStroke.Color = Theme.ButtonBorder
    end)
    btn.MouseButton1Click:Connect(function()
        if type(callback) == "function" then callback() end
    end)
    return btn
end

local function addKeybind(parent, labelText, defaultKey, callback)
    local currentKey = defaultKey or Enum.KeyCode.C
    local isListening = false
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 36 or 33)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = isMobile and 10.5 or 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.45, 0, 0, isMobile and 22 or 19)
    btn.Position = UDim2.new(0.55, 0, 0, isMobile and 14 or 13)
    btn.BackgroundColor3 = Theme.ControlBg
    btn.BorderSizePixel = 0
    btn.Font = MainFont
    btn.Text = tostring(currentKey.Name or currentKey)
    btn.TextColor3 = Theme.TextWhite
    btn.TextSize = isMobile and 11 or 12
    btn.ZIndex = 17
    btn.Parent = container

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.BorderPink
    bStroke.Thickness = 1
    bStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        isListening = true
        btn.Text = "[...]"
        bStroke.Color = Theme.AccentPink
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                currentKey = input.UserInputType
            elseif input.UserInputType == Enum.UserInputType.Touch then
                currentKey = input.UserInputType
            else return end
            isListening = false
            btn.Text = tostring(currentKey.Name or currentKey)
            bStroke.Color = Theme.BorderPink
            conn:Disconnect()
            if type(callback) == "function" then callback(currentKey) end
        end)
    end)

    return {
        Set = function(k) currentKey = k; btn.Text = tostring(k.Name or k) end,
        Get = function() return currentKey end
    }
end

local function addColorPicker(parent, labelText, defaultColor, callback)
    local curColor = defaultColor or Color3.fromRGB(255, 160, 195)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1
    header.ZIndex = 17
    header.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = isMobile and 10.5 or 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = header

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 30, 0, 14)
    preview.Position = UDim2.new(1, -32, 0.5, -7)
    preview.BackgroundColor3 = curColor
    preview.BorderSizePixel = 0
    preview.ZIndex = 17
    preview.Parent = header
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Theme.BorderPink
    pStroke.Thickness = 1
    pStroke.Parent = preview

    local sliders = Instance.new("Frame")
    sliders.Size = UDim2.new(1, 0, 0, 0)
    sliders.Position = UDim2.new(0, 0, 0, 22)
    sliders.AutomaticSize = Enum.AutomaticSize.Y
    sliders.BackgroundTransparency = 1
    sliders.ZIndex = 16
    sliders.Parent = container

    local function updateColor()
        preview.BackgroundColor3 = curColor
        if type(callback) == "function" then callback(curColor) end
    end

    local rSlider, gSlider, bSlider
    rSlider = addSlider(sliders, "R", 0, 255, math.floor(curColor.R * 255), "%d",
        function(v) curColor = Color3.fromRGB(v, math.floor(curColor.G * 255), math.floor(curColor.B * 255)); updateColor() end)
    gSlider = addSlider(sliders, "G", 0, 255, math.floor(curColor.G * 255), "%d",
        function(v) curColor = Color3.fromRGB(math.floor(curColor.R * 255), v, math.floor(curColor.B * 255)); updateColor() end)
    bSlider = addSlider(sliders, "B", 0, 255, math.floor(curColor.B * 255), "%d",
        function(v) curColor = Color3.fromRGB(math.floor(curColor.R * 255), math.floor(curColor.G * 255), v); updateColor() end)

    return {
        Set = function(c)
            curColor = c
            rSlider.Set(math.floor(c.R * 255))
            gSlider.Set(math.floor(c.G * 255))
            bSlider.Set(math.floor(c.B * 255))
            updateColor()
        end,
        Get = function() return curColor end
    }
end

getgenv().UW.mainWindow = mainWindow
getgenv().UW.tabPages = tabPages
getgenv().UW.tabButtons = tabButtons
getgenv().UW.switchTab = switchTab
getgenv().UW.setMenuVisible = setMenuVisible
getgenv().UW.uiRegistry = uiRegistry

getgenv().UW.UI = {
    createGroupbox = createGroupbox,
    addCheckbox    = addCheckbox,
    addSlider      = addSlider,
    addDropdown    = addDropdown,
    addTextbox     = addTextbox,
    addButton      = addButton,
    addKeybind     = addKeybind,
    addColorPicker = addColorPicker,
}
