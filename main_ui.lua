--[[
UnnamedWard UI (Standalone Menu)
- Light pink + light blue theme
- All tabs and widgets
- No key gate, no external loaders
- Toggles write to a local Config table; wire them to your own features
Discord: https://discord.gg/g7jj8F6suv
]]

-- ============================================================
-- SECTION 1: INIT
-- ============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
if not PlayerGui then
    warn("[UnnamedWard] Could not find PlayerGui")
    return
end

-- Purge old instances
do
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name == "UnnamedWardUI" or child.Name == "UnnamedWardMobileToggle" then
            pcall(function() child:Destroy() end)
        end
    end
end

local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local isRunning = true
local activeConnections = {}
local cleanUpInstances = {}

local function trackConnection(conn)
    if conn then
        table.insert(activeConnections, conn)
    end
    return conn
end

-- ============================================================
-- SECTION 2: CONFIG
-- ============================================================

local Config = {
    Aimbot = false,
    SilentAim = false,
    ESP_Master = true,
    ESP_EnemyOnly = true,
    ESP_Lobby = true,
    SpeedHack = false,
    FlyHack = false,
    Noclip = false,
    NoRecoil = true,
    NoSpread = true,
    UnlockAllSkins = false,
    Fullbright = false,
    NoFog = true,
    ThirdPerson = false,
    Freecam = false,
    MenuKey = Enum.KeyCode.RightControl,
}

-- ============================================================
-- SECTION 3: THEME
-- ============================================================

local Theme = {
    OuterBorder      = Color3.fromRGB(180, 200, 235),
    BorderPink       = Color3.fromRGB(250, 195, 215),
    BorderPinkDark   = Color3.fromRGB(220, 150, 180),
    BorderBlue       = Color3.fromRGB(180, 205, 240),

    WindowBg         = Color3.fromRGB(250, 248, 252),
    WindowBgTop      = Color3.fromRGB(255, 250, 253),
    WindowBgBottom   = Color3.fromRGB(240, 245, 252),
    InnerCanvasBg    = Color3.fromRGB(252, 250, 253),
    HeaderBg         = Color3.fromRGB(245, 240, 248),

    CardBg           = Color3.fromRGB(252, 248, 252),
    BorderDark       = Color3.fromRGB(210, 205, 220),
    BorderCard       = Color3.fromRGB(200, 195, 215),

    AccentPink       = Color3.fromRGB(245, 170, 195),
    AccentPinkLight  = Color3.fromRGB(255, 200, 220),
    AccentPinkDark   = Color3.fromRGB(215, 130, 165),

    AccentBlue       = Color3.fromRGB(150, 190, 240),
    AccentBlueLight  = Color3.fromRGB(180, 215, 250),
    AccentBlueDark   = Color3.fromRGB(110, 155, 215),

    TextWhite        = Color3.fromRGB(55, 60, 85),
    TextMuted        = Color3.fromRGB(120, 125, 145),
    TextDark         = Color3.fromRGB(160, 165, 180),
    ControlBg        = Color3.fromRGB(240, 240, 248),
    ButtonBg         = Color3.fromRGB(245, 240, 250),
    ButtonHoverBg    = Color3.fromRGB(235, 230, 245),
    ButtonBorder     = Color3.fromRGB(215, 210, 230),
    Red              = Color3.fromRGB(235, 110, 130),
    Yellow           = Color3.fromRGB(240, 200, 100),
    Green            = Color3.fromRGB(120, 210, 150),
}

local MainFont = Enum.Font.Gotham
local MonoFont = Enum.Font.RobotoMono

-- ============================================================
-- SECTION 4: SCREEN GUI
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnnamedWardUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2147483000
screenGui.Parent = PlayerGui
table.insert(cleanUpInstances, screenGui)

local function UnloadScript()
    isRunning = false
    for _, conn in ipairs(activeConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(activeConnections)
    for _, inst in ipairs(cleanUpInstances) do pcall(function() inst:Destroy() end) end
    table.clear(cleanUpInstances)
end

-- ============================================================
-- SECTION 5: NOTIFICATIONS + DROPDOWN OVERLAY
-- ============================================================

local dropdownOverlay = Instance.new("Frame")
dropdownOverlay.Name = "DropdownOverlay"
dropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
dropdownOverlay.BackgroundTransparency = 1
dropdownOverlay.ZIndex = 1000
dropdownOverlay.Parent = screenGui
table.insert(cleanUpInstances, dropdownOverlay)

local activeDropdownClose = nil

trackConnection(UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if activeDropdownClose then activeDropdownClose(input.Position) end
    end
end))

local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifContainer"
notifContainer.Size = UDim2.new(0, isMobile and 220 or 280, 1, -40)
notifContainer.Position = UDim2.new(1, isMobile and -230 or -295, 0, 40)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100
notifContainer.Parent = screenGui
table.insert(cleanUpInstances, notifContainer)

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 5)
notifLayout.Parent = notifContainer

local MAX_NOTIFS = 5
local notifSeq = 0

local function ShowNotification(title, message, notifType, duration)
    if not isRunning then return end
    pcall(function()
        if not notifContainer or not notifContainer.Parent then return end

        local frames = {}
        for _, child in ipairs(notifContainer:GetChildren()) do
            if child:IsA("Frame") then table.insert(frames, child) end
        end
        if #frames >= MAX_NOTIFS then
            table.sort(frames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
            if frames[1] then frames[1]:Destroy() end
        end

        duration = duration or 3.5
        notifType = notifType or "INFO"
        local barColor = Theme.AccentBlue
        if notifType == "SUCCESS" then barColor = Theme.Green
        elseif notifType == "WARN" then barColor = Theme.Yellow
        elseif notifType == "ERROR" then barColor = Theme.Red end

        notifSeq = notifSeq + 1

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = Theme.CardBg
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.LayoutOrder = notifSeq
        card.ZIndex = 101
        card.Parent = notifContainer

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.BorderCard
        stroke.Thickness = 1
        stroke.Parent = card

        local topAcc = Instance.new("Frame")
        topAcc.Size = UDim2.new(1, 0, 0, 1.5)
        topAcc.BackgroundColor3 = barColor
        topAcc.BorderSizePixel = 0
        topAcc.ZIndex = 102
        topAcc.Parent = card

        local tLbl = Instance.new("TextLabel")
        tLbl.Size = UDim2.new(1, -14, 0, 15)
        tLbl.Position = UDim2.new(0, 8, 0, 3)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = MainFont
        tLbl.Text = title
        tLbl.TextColor3 = Theme.AccentPinkDark
        tLbl.TextSize = 11.5
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.ZIndex = 102
        tLbl.Parent = card

        local mLbl = Instance.new("TextLabel")
        mLbl.Size = UDim2.new(1, -14, 0, 22)
        mLbl.Position = UDim2.new(0, 8, 0, 18)
        mLbl.BackgroundTransparency = 1
        mLbl.Font = MainFont
        mLbl.Text = message
        mLbl.TextColor3 = Theme.TextWhite
        mLbl.TextSize = 10
        mLbl.TextWrapped = true
        mLbl.TextXAlignment = Enum.TextXAlignment.Left
        mLbl.ZIndex = 102
        mLbl.Parent = card

        TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 46)}):Play()

        task.delay(duration, function()
            if card and card.Parent then
                local tw = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
                tw.Completed:Once(function() card:Destroy() end)
                tw:Play()
            end
        end)
    end)
end

-- ============================================================
-- SECTION 6: MAIN WINDOW
-- ============================================================

local screenSize = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
local winW = isMobile and math.clamp(screenSize.X - 30, 260, 440) or 540
local winH = isMobile and math.clamp(screenSize.Y - 80, 340, 600) or 560

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, winW, 0, winH)
mainWindow.Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
mainWindow.BackgroundColor3 = Theme.WindowBg
mainWindow.BorderSizePixel = 0
mainWindow.ClipsDescendants = false
mainWindow.Active = true
mainWindow.ZIndex = 10
mainWindow.Parent = screenGui
table.insert(cleanUpInstances, mainWindow)

local function setMenuVisible(visible)
    mainWindow.Visible = visible
    if getgenv then getgenv().UnnamedWardMenuVisible = visible end
end

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Theme.OuterBorder
windowStroke.Thickness = 1.5
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
topBar.Size = UDim2.new(1, 0, 0, isMobile and 38 or 42)
topBar.BackgroundColor3 = Theme.HeaderBg
topBar.BorderSizePixel = 0
topBar.ZIndex = 11
topBar.Parent = mainWindow

local dragConn = nil
local isDragging = false
local dragStart, startPos

trackConnection(topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainWindow.Position
        if dragConn then pcall(function() dragConn:Disconnect() end) end
        dragConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                if dragConn then
                    pcall(function() dragConn:Disconnect() end)
                    dragConn = nil
                end
            end
        end)
    end
end))
trackConnection(UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

local uwTag = Instance.new("Frame")
uwTag.Size = UDim2.new(0, 22, 0, 22)
uwTag.Position = UDim2.new(0, 12, 0.5, -11)
uwTag.BackgroundColor3 = Theme.AccentBlue
uwTag.BorderSizePixel = 0
uwTag.ZIndex = 13
uwTag.Parent = topBar

local uwTagStroke = Instance.new("UIStroke")
uwTagStroke.Color = Theme.AccentPink
uwTagStroke.Thickness = 1.2
uwTagStroke.Parent = uwTag

local uwTagCorner = Instance.new("UICorner")
uwTagCorner.CornerRadius = UDim.new(0, 5)
uwTagCorner.Parent = uwTag

local uwTagLbl = Instance.new("TextLabel")
uwTagLbl.Size = UDim2.new(1, 0, 1, 0)
uwTagLbl.BackgroundTransparency = 1
uwTagLbl.Font = MonoFont
uwTagLbl.Text = "UW"
uwTagLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
uwTagLbl.TextSize = 12
uwTagLbl.ZIndex = 14
uwTagLbl.Parent = uwTag

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, isMobile and 180 or 280, 1, 0)
titleLbl.Position = UDim2.new(0, 42, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = MonoFont
titleLbl.RichText = true
titleLbl.Text = '<font color="#d982a5">Unnamed</font><font color="#7aa8e0">Ward</font>'
titleLbl.TextSize = isMobile and 13 or 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 13
titleLbl.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, isMobile and 28 or 24, 0, isMobile and 26 or 22)
closeBtn.Position = UDim2.new(1, isMobile and -34 or -30, 0.5, isMobile and -13 or -11)
closeBtn.BackgroundColor3 = Theme.ControlBg
closeBtn.BorderSizePixel = 0
closeBtn.Font = MainFont
closeBtn.Text = "x"
closeBtn.TextColor3 = Theme.TextMuted
closeBtn.TextSize = isMobile and 18 or 16
closeBtn.ZIndex = 12
closeBtn.Parent = topBar

local cbStroke = Instance.new("UIStroke")
cbStroke.Color = Theme.BorderCard
cbStroke.Thickness = 1
cbStroke.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    setMenuVisible(false)
end)

-- Inner canvas
local innerCanvas = Instance.new("Frame")
innerCanvas.Name = "InnerCanvas"
innerCanvas.Size = UDim2.new(1, -14, 1, isMobile and -46 or -50)
innerCanvas.Position = UDim2.new(0, 7, 0, isMobile and 39 or 43)
innerCanvas.BackgroundColor3 = Theme.InnerCanvasBg
innerCanvas.BorderSizePixel = 0
innerCanvas.ZIndex = 11
innerCanvas.Parent = mainWindow

local innerStroke = Instance.new("UIStroke")
innerStroke.Color = Theme.BorderCard
innerStroke.Thickness = 1
innerStroke.Parent = innerCanvas

local tabNavFrame = Instance.new("Frame")
tabNavFrame.Name = "TabNavFrame"
tabNavFrame.Size = UDim2.new(1, -12, 0, isMobile and 30 or 26)
tabNavFrame.Position = UDim2.new(0, 6, 0, 4)
tabNavFrame.BackgroundTransparency = 1
tabNavFrame.ZIndex = 12
tabNavFrame.ClipsDescendants = true
tabNavFrame.Parent = innerCanvas

local tabNavScroll = Instance.new("ScrollingFrame")
tabNavScroll.Name = "TabNavScroll"
tabNavScroll.Size = UDim2.new(1, 0, 1, 0)
tabNavScroll.BackgroundTransparency = 1
tabNavScroll.BorderSizePixel = 0
tabNavScroll.ScrollBarThickness = 2
tabNavScroll.ScrollBarImageColor3 = Theme.AccentPink
tabNavScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabNavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabNavScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabNavScroll.ZIndex = 12
tabNavScroll.Parent = tabNavFrame

local tabNavLayout = Instance.new("UIListLayout")
tabNavLayout.FillDirection = Enum.FillDirection.Horizontal
tabNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabNavLayout.Padding = UDim.new(0, isMobile and 6 or 10)
tabNavLayout.Parent = tabNavScroll

local tabContentFrame = Instance.new("Frame")
tabContentFrame.Name = "TabContentFrame"
tabContentFrame.Size = UDim2.new(1, -12, 1, isMobile and -66 or -60)
tabContentFrame.Position = UDim2.new(0, 6, 0, isMobile and 38 or 34)
tabContentFrame.BackgroundTransparency = 1
tabContentFrame.ZIndex = 12
tabContentFrame.Parent = innerCanvas

local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -12, 0, 20)
statusBar.Position = UDim2.new(0, 6, 1, -22)
statusBar.BackgroundTransparency = 1
statusBar.ZIndex = 12
statusBar.Parent = innerCanvas

local statusLeft = Instance.new("TextLabel")
statusLeft.Size = UDim2.new(0.6, 0, 1, -2)
statusLeft.Position = UDim2.new(0, 2, 0, 2)
statusLeft.BackgroundTransparency = 1
statusLeft.Font = MonoFont
statusLeft.RichText = true
statusLeft.Text = 'hi, <font color="#d982a5">' .. LocalPlayer.DisplayName .. '</font>'
statusLeft.TextColor3 = Theme.TextMuted
statusLeft.TextSize = 10.5
statusLeft.TextXAlignment = Enum.TextXAlignment.Left
statusLeft.ZIndex = 13
statusLeft.Parent = statusBar

local statusRight = Instance.new("TextLabel")
statusRight.Size = UDim2.new(0.4, -2, 1, -2)
statusRight.Position = UDim2.new(0.6, 0, 0, 2)
statusRight.BackgroundTransparency = 1
statusRight.Font = MonoFont
statusRight.RichText = true
statusRight.Text = '<font color="#7aa8e0">[</font> <font color="#a0a5b5">uw</font> <font color="#7aa8e0">]</font>'
statusRight.TextColor3 = Theme.TextMuted
statusRight.TextSize = 10.5
statusRight.TextXAlignment = Enum.TextXAlignment.Right
statusRight.ZIndex = 13
statusRight.Parent = statusBar

-- ============================================================
-- SECTION 7: TAB SYSTEM
-- ============================================================

local tabList = {"home", "aim", "esp", "move", "guns", "world", "config"}
local tabPages = {}
local tabButtons = {}
local currentTab = "home"

local function switchTab(tabName)
    currentTab = tabName
    for tName, page in pairs(tabPages) do
        page.Visible = (tName == tabName)
    end
    for _, btnData in ipairs(tabButtons) do
        local isSelf = (btnData.name == tabName)
        btnData.btn.TextColor3 = isSelf and Theme.AccentPinkDark or Theme.TextMuted
        if btnData.indicator then btnData.indicator.Visible = isSelf end
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
    btn.TextColor3 = (tabName == currentTab) and Theme.AccentPinkDark or Theme.TextMuted
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.ZIndex = 13
    btn.Parent = tabNavScroll

    local padBtn = Instance.new("UIPadding")
    padBtn.PaddingLeft = UDim.new(0, 6)
    padBtn.PaddingRight = UDim.new(0, 6)
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
    if isMobile then
        leftCol.Size = UDim2.new(1, 0, 1, 0)
        leftCol.Position = UDim2.new(0, 0, 0, 0)
    else
        leftCol.Size = UDim2.new(0.49, 0, 1, 0)
        leftCol.Position = UDim2.new(0, 0, 0, 0)
    end
    leftCol.BackgroundTransparency = 1
    leftCol.BorderSizePixel = 0
    leftCol.ScrollBarThickness = 3
    leftCol.ScrollBarImageColor3 = Theme.AccentPink
    leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftCol.ZIndex = 14
    leftCol.Parent = page
    local lLayout = Instance.new("UIListLayout")
    lLayout.Padding = UDim.new(0, 7)
    lLayout.Parent = leftCol
    local lPad = Instance.new("UIPadding")
    lPad.PaddingBottom = UDim.new(0, 10)
    lPad.Parent = leftCol

    if not isMobile then
        local rightCol = Instance.new("ScrollingFrame")
        rightCol.Name = "RightCol"
        rightCol.Size = UDim2.new(0.49, 0, 1, 0)
        rightCol.Position = UDim2.new(0.51, 0, 0, 0)
        rightCol.BackgroundTransparency = 1
        rightCol.BorderSizePixel = 0
        rightCol.ScrollBarThickness = 3
        rightCol.ScrollBarImageColor3 = Theme.AccentPink
        rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        rightCol.ZIndex = 14
        rightCol.Parent = page
        local rLayout = Instance.new("UIListLayout")
        rLayout.Padding = UDim.new(0, 7)
        rLayout.Parent = rightCol
        local rPad = Instance.new("UIPadding")
        rPad.PaddingBottom = UDim.new(0, 10)
        rPad.Parent = rightCol
    end

    tabPages[tabName] = page
end

local function getRightCol(page)
    return page:FindFirstChild("RightCol") or page:FindFirstChild("LeftCol")
end

-- ============================================================
-- SECTION 8: UI WIDGETS
-- ============================================================

local function createGroupbox(parent, title, desc)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.ZIndex = 15
    card.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.BorderPink
    stroke.Thickness = 1
    stroke.Parent = card

    local topPinkLine = Instance.new("Frame")
    topPinkLine.Size = UDim2.new(1, 0, 0, 1.5)
    topPinkLine.BackgroundColor3 = Theme.AccentPink
    topPinkLine.BorderSizePixel = 0
    topPinkLine.ZIndex = 16
    topPinkLine.Parent = card

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, desc and 32 or 20)
    header.Position = UDim2.new(0, 0, 0, 1)
    header.BackgroundTransparency = 1
    header.ZIndex = 16
    header.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -12, 0, 16)
    titleLbl.Position = UDim2.new(0, 6, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = MainFont
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.TextWhite
    titleLbl.TextSize = 12.5
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

    return content
end

local function addCheckbox(parent, labelText, defaultVal, callback)
    local state = defaultVal or false
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, isMobile and 22 or 18)
    row.BackgroundTransparency = 1
    row.ZIndex = 16
    row.Parent = parent

    local boxSize = isMobile and 16 or 14
    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, boxSize, 0, boxSize)
    box.Position = UDim2.new(0, 0, 0.5, -boxSize/2)
    box.BackgroundColor3 = state and Theme.AccentPink or Theme.ControlBg
    box.BorderSizePixel = 0
    box.Text = state and "v" or ""
    box.Font = Enum.Font.GothamBold
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 10
    box.ZIndex = 17
    box.Parent = row

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = state and Theme.AccentPinkDark or Theme.BorderCard
    bStroke.Thickness = 1
    bStroke.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -(boxSize + 8), 1, 0)
    lbl.Position = UDim2.new(0, boxSize + 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextWhite
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = row

    local function updateState(newVal)
        state = newVal
        box.BackgroundColor3 = state and Theme.AccentPink or Theme.ControlBg
        box.Text = state and "v" or ""
        bStroke.Color = state and Theme.AccentPinkDark or Theme.BorderCard
        if type(callback) == "function" then callback(state) end
    end

    box.MouseButton1Click:Connect(function() updateState(not state) end)

    return { Set = updateState, Get = function() return state end }
end

local sliderRegistry = { isSliding = false, updateFn = nil }

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderRegistry.isSliding = false
        sliderRegistry.updateFn = nil
    end
end))

trackConnection(UserInputService.WindowFocusReleased:Connect(function()
    sliderRegistry.isSliding = false
    sliderRegistry.updateFn = nil
end))

local HasIMBP = type(UserInputService.IsMouseButtonPressed) == "function"

trackConnection(UserInputService.InputChanged:Connect(function(input)
    if not sliderRegistry.isSliding or not sliderRegistry.updateFn then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if HasIMBP and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            sliderRegistry.isSliding = false
            sliderRegistry.updateFn = nil
            return
        end
    end
    if input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch then
        sliderRegistry.updateFn(input)
    end
end))

local function addSlider(parent, labelText, minVal, maxVal, defaultVal, displayTemplate, callback)
    local curVal = defaultVal or minVal
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 34 or 30)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local trackH = isMobile and 18 or 14
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, 0, 0, trackH)
    track.Position = UDim2.new(0, 0, 0, 14)
    track.BackgroundColor3 = Theme.ControlBg
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.ZIndex = 17
    track.Parent = container

    local tStroke = Instance.new("UIStroke")
    tStroke.Color = Theme.BorderCard
    tStroke.Thickness = 1
    tStroke.Parent = track

    local fill = Instance.new("Frame")
    local pct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentBlue
    fill.BorderSizePixel = 0
    fill.ZIndex = 18
    fill.Parent = track

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
    valLbl.Font = MonoFont
    valLbl.Text = getDisplay(curVal)
    valLbl.TextColor3 = Theme.TextWhite
    valLbl.TextSize = 10.5
    valLbl.ZIndex = 19
    valLbl.Parent = track

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
            sliderRegistry.isSliding = true
            sliderRegistry.updateFn = updateFromInput
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
        end,
        Get = function() return curVal end
    }
end

local function addDropdown(parent, labelText, options, defaultValOrIdx, callback)
    local selectedIdx = 1
    if type(defaultValOrIdx) == "string" then
        for i, name in ipairs(options) do
            if name == defaultValOrIdx then
                selectedIdx = i
                break
            end
        end
    elseif type(defaultValOrIdx) == "number" then
        selectedIdx = math.clamp(defaultValOrIdx, 1, #options)
    end

    local isOpen = false

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 40 or 36)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 13)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local boxH = isMobile and 24 or 20
    local box = Instance.new("TextButton")
    box.Size = UDim2.new(1, 0, 0, boxH)
    box.Position = UDim2.new(0, 0, 0, 15)
    box.BackgroundColor3 = Theme.ControlBg
    box.BorderSizePixel = 0
    box.Font = MainFont
    box.Text = "  " .. options[selectedIdx]
    box.TextColor3 = Theme.TextWhite
    box.TextSize = 11.5
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ZIndex = 17
    box.Parent = container

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.BorderCard
    bStroke.Thickness = 1
    bStroke.Parent = box

    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.new(0, 14, 1, 0)
    chevron.Position = UDim2.new(1, -16, 0, 0)
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.GothamBold
    chevron.Text = "v"
    chevron.TextColor3 = Theme.AccentBlue
    chevron.TextSize = 10
    chevron.ZIndex = 18
    chevron.Parent = box

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.BackgroundColor3 = Theme.CardBg
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2.5
    listFrame.ScrollBarImageColor3 = Theme.AccentBlue
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listFrame.ZIndex = 1001
    listFrame.Visible = false
    listFrame.Parent = dropdownOverlay

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = Theme.BorderPinkDark
    lStroke.Thickness = 1
    lStroke.Parent = listFrame

    local optLayout = Instance.new("UIListLayout")
    optLayout.Padding = UDim.new(0, 1)
    optLayout.Parent = listFrame

    local function closeDropdown()
        isOpen = false
        listFrame.Visible = false
        chevron.Text = "v"
        bStroke.Color = Theme.BorderCard
        if activeDropdownClose == closeDropdown then activeDropdownClose = nil end
    end

    local optH = isMobile and 26 or 20

    local function refreshOptions()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for idx, optName in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, optH)
            optBtn.BackgroundColor3 = (idx == selectedIdx) and Theme.AccentPinkLight or Theme.CardBg
            optBtn.BorderSizePixel = 0
            optBtn.Font = MainFont
            optBtn.Text = "  " .. optName
            optBtn.TextColor3 = (idx == selectedIdx) and Theme.AccentPinkDark or Theme.TextWhite
            optBtn.TextSize = 11.5
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

    local function openDropdown()
        if activeDropdownClose and activeDropdownClose ~= closeDropdown then activeDropdownClose() end
        refreshOptions()
        local boxPos = box.AbsolutePosition
        local boxSize = box.AbsoluteSize
        local menuHeight = math.min(#options * (optH + 1), isMobile and 200 or 140)
        listFrame.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y + boxSize.Y + 2)
        listFrame.Size = UDim2.new(0, boxSize.X, 0, menuHeight)
        listFrame.Visible = true
        isOpen = true
        chevron.Text = "^"
        bStroke.Color = Theme.BorderPink

        activeDropdownClose = function(clickPos)
            if clickPos then
                local menuPos = listFrame.AbsolutePosition
                local menuSize = listFrame.AbsoluteSize
                local inMenu = clickPos.X >= menuPos.X and clickPos.X <= (menuPos.X + menuSize.X)
                    and clickPos.Y >= menuPos.Y and clickPos.Y <= (menuPos.Y + menuSize.Y)
                local inBox = clickPos.X >= boxPos.X and clickPos.X <= (boxPos.X + boxSize.X)
                    and clickPos.Y >= boxPos.Y and clickPos.Y <= (boxPos.Y + boxSize.Y)
                if not inMenu and not inBox then closeDropdown() end
            else
                closeDropdown()
            end
        end
    end

    box.MouseButton1Click:Connect(function()
        if isOpen then closeDropdown() else openDropdown() end
    end)

    return {
        Set = function(valOrIdx)
            local targetIdx = 1
            if type(valOrIdx) == "number" then
                targetIdx = math.clamp(valOrIdx, 1, #options)
            elseif type(valOrIdx) == "string" then
                for i, name in ipairs(options) do
                    if name == valOrIdx then
                        targetIdx = i
                        break
                    end
                end
            end
            selectedIdx = targetIdx
            box.Text = "  " .. options[selectedIdx]
            if type(callback) == "function" then callback(options[selectedIdx], selectedIdx) end
        end,
        Get = function() return options[selectedIdx] end
    }
end

local function addTextbox(parent, labelText, defaultVal, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, isMobile and 42 or 36)
    container.BackgroundTransparency = 1
    container.ZIndex = 16
    container.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.BackgroundTransparency = 1
    lbl.Font = MainFont
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 17
    lbl.Parent = container

    local tbH = isMobile and 26 or 20
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, 0, 0, tbH)
    tb.Position = UDim2.new(0, 0, 0, 14)
    tb.BackgroundColor3 = Theme.ControlBg
    tb.BorderSizePixel = 0
    tb.Font = MainFont
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = Theme.TextDark
    tb.Text = defaultVal or ""
    tb.TextColor3 = Theme.TextWhite
    tb.TextSize = 12
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.ZIndex = 17
    tb.Parent = container

    local tPad = Instance.new("UIPadding")
    tPad.PaddingLeft = UDim.new(0, 8)
    tPad.PaddingRight = UDim.new(0, 8)
    tPad.Parent = tb

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = Theme.BorderCard
    tbStroke.Thickness = 1
    tbStroke.Parent = tb

    tb.Focused:Connect(function() tbStroke.Color = Theme.BorderPink end)
    tb.FocusLost:Connect(function()
        tbStroke.Color = Theme.BorderCard
        if type(callback) == "function" then callback(tb.Text) end
    end)

    return {
        Set = function(txt)
            tb.Text = tostring(txt)
            if type(callback) == "function" then callback(tb.Text) end
        end,
        Get = function() return tb.Text end,
    }
end

local function addButton(parent, btnText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, isMobile and 32 or 26)
    btn.BackgroundColor3 = Theme.ButtonBg
    btn.BorderSizePixel = 0
    btn.Font = MainFont
    btn.Text = btnText
    btn.TextColor3 = Theme.TextWhite
    btn.TextSize = isMobile and 12.5 or 12
    btn.AutoButtonColor = false
    btn.ZIndex = 17
    btn.Parent = parent

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.BorderPink
    bStroke.Thickness = 1
    bStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Theme.ButtonHoverBg
        bStroke.Color = Theme.AccentPink
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Theme.ButtonBg
        bStroke.Color = Theme.BorderPink
    end)

    btn.MouseButton1Click:Connect(function()
        if type(callback) == "function" then callback() end
    end)
    return btn
end

-- ============================================================
-- SECTION 9: TAB CONTENTS
-- ============================================================

local uiRegistry = {}

-- HOME
local pageHome = tabPages["home"]
local homeLeft = pageHome:FindFirstChild("LeftCol")
local homeRight = getRightCol(pageHome)

local gbAccount = createGroupbox(homeLeft, "Account")
local aUser = Instance.new("TextLabel")
aUser.Size = UDim2.new(1, 0, 0, 16)
aUser.BackgroundTransparency = 1
aUser.Font = MonoFont
aUser.Text = LocalPlayer.DisplayName
aUser.TextColor3 = Theme.TextWhite
aUser.TextSize = 12.5
aUser.TextXAlignment = Enum.TextXAlignment.Left
aUser.ZIndex = 17
aUser.Parent = gbAccount

local aHandle = Instance.new("TextLabel")
aHandle.Size = UDim2.new(1, 0, 0, 16)
aHandle.BackgroundTransparency = 1
aHandle.Font = MonoFont
aHandle.Text = "@" .. LocalPlayer.Name
aHandle.TextColor3 = Theme.TextMuted
aHandle.TextSize = 11
aHandle.TextXAlignment = Enum.TextXAlignment.Left
aHandle.ZIndex = 17
aHandle.Parent = gbAccount

local gbSession = createGroupbox(homeRight, "Session")
local sInfo = Instance.new("TextLabel")
sInfo.Size = UDim2.new(1, 0, 0, 16)
sInfo.BackgroundTransparency = 1
sInfo.Font = MonoFont
sInfo.Text = #Players:GetPlayers() .. " players online"
sInfo.TextColor3 = Theme.TextWhite
sInfo.TextSize = 12.5
sInfo.TextXAlignment = Enum.TextXAlignment.Left
sInfo.ZIndex = 17
sInfo.Parent = gbSession

addButton(gbSession, "Rejoin server", function()
    ShowNotification("UnnamedWard", "Reconnecting...", "INFO", 3)
    task.spawn(function()
        task.wait(0.5)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
end)

-- AIM
local pageAim = tabPages["aim"]
local aimLeft = pageAim:FindFirstChild("LeftCol")
local aimRight = getRightCol(pageAim)

local gbAimbot = createGroupbox(aimLeft, "Aimbot")
uiRegistry["Aimbot"] = addCheckbox(gbAimbot, "Enable aimbot", Config.Aimbot, function(v) Config.Aimbot = v end)

local gbSilent = createGroupbox(aimRight, "Silent Aim")
uiRegistry["SilentAim"] = addCheckbox(gbSilent, "Enable silent aim", Config.SilentAim, function(v) Config.SilentAim = v end)

-- ESP
local pageEsp = tabPages["esp"]
local espLeft = pageEsp:FindFirstChild("LeftCol")
local espRight = getRightCol(pageEsp)

local gbEsp = createGroupbox(espLeft, "Player ESP")
uiRegistry["ESP_Master"] = addCheckbox(gbEsp, "Enable ESP", Config.ESP_Master, function(v) Config.ESP_Master = v end)
uiRegistry["ESP_EnemyOnly"] = addCheckbox(gbEsp, "Enemy only", Config.ESP_EnemyOnly, function(v) Config.ESP_EnemyOnly = v end)
uiRegistry["ESP_Lobby"] = addCheckbox(gbEsp, "Show in lobby", Config.ESP_Lobby, function(v) Config.ESP_Lobby = v end)

-- MOVE
local pageMove = tabPages["move"]
local moveLeft = pageMove:FindFirstChild("LeftCol")
local moveRight = getRightCol(pageMove)

local gbMove = createGroupbox(moveLeft, "Ground Movement")
uiRegistry["SpeedHack"] = addCheckbox(gbMove, "Speed hack", Config.SpeedHack, function(v) Config.SpeedHack = v end)

local gbAir = createGroupbox(moveRight, "Flight & Collision")
uiRegistry["FlyHack"] = addCheckbox(gbAir, "Fly hack", Config.FlyHack, function(v) Config.FlyHack = v end)
uiRegistry["Noclip"] = addCheckbox(gbAir, "Noclip", Config.Noclip, function(v) Config.Noclip = v end)

-- GUNS
local pageGuns = tabPages["guns"]
local gunsLeft = pageGuns:FindFirstChild("LeftCol")
local gunsRight = getRightCol(pageGuns)

local gbGun = createGroupbox(gunsLeft, "Weapon Mechanics")
uiRegistry["NoRecoil"] = addCheckbox(gbGun, "No recoil", Config.NoRecoil, function(v) Config.NoRecoil = v end)
uiRegistry["NoSpread"] = addCheckbox(gbGun, "No spread", Config.NoSpread, function(v) Config.NoSpread = v end)

local gbSkins = createGroupbox(gunsRight, "Cosmetics")
uiRegistry["UnlockAllSkins"] = addCheckbox(gbSkins, "Unlock all (client)", Config.UnlockAllSkins, function(v) Config.UnlockAllSkins = v end)

-- WORLD
local pageWorld = tabPages["world"]
local worldLeft = pageWorld:FindFirstChild("LeftCol")
local worldRight = getRightCol(pageWorld)

local gbWorld = createGroupbox(worldLeft, "World")
uiRegistry["Fullbright"] = addCheckbox(gbWorld, "Fullbright", Config.Fullbright, function(v) Config.Fullbright = v end)
uiRegistry["NoFog"] = addCheckbox(gbWorld, "No fog", Config.NoFog, function(v) Config.NoFog = v end)

local gbCam = createGroupbox(worldRight, "Camera")
uiRegistry["ThirdPerson"] = addCheckbox(gbCam, "Third person", Config.ThirdPerson, function(v) Config.ThirdPerson = v end)
uiRegistry["Freecam"] = addCheckbox(gbCam, "Freecam", Config.Freecam, function(v) Config.Freecam = v end)

-- CONFIG
local pageConfig = tabPages["config"]
local configLeft = pageConfig:FindFirstChild("LeftCol")
local configRight = getRightCol(pageConfig)

createGroupbox(configLeft, "Info",
    "Standalone UI build.\nWire toggles to your own feature code.")

local gbActions = createGroupbox(configRight, "Quick Actions")
addButton(gbActions, "Close menu", function()
    setMenuVisible(false)
end)
addButton(gbActions, "Unload UI", function()
    UnloadScript()
end)

-- ============================================================
-- SECTION 10: MOBILE TOGGLE + MENU KEY
-- ============================================================

if isMobile then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "UnnamedWardMobileToggle"
    mobileGui.ResetOnSpawn = false
    mobileGui.IgnoreGuiInset = true
    mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mobileGui.DisplayOrder = 2147482000
    mobileGui.Parent = PlayerGui
    table.insert(cleanUpInstances, mobileGui)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 54, 0, 54)
    toggleBtn.Position = UDim2.new(0, 14, 0.5, -27)
    toggleBtn.BackgroundColor3 = Theme.AccentBlue
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "UW"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = MonoFont
    toggleBtn.TextSize = 16
    toggleBtn.AutoButtonColor = false
    toggleBtn.ZIndex = 200
    toggleBtn.Parent = mobileGui

    local tStroke = Instance.new("UIStroke")
    tStroke.Color = Theme.AccentPink
    tStroke.Thickness = 1.5
    tStroke.Parent = toggleBtn

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        local isVis = getgenv and getgenv().UnnamedWardMenuVisible
        if isVis == nil then isVis = mainWindow.Visible end
        setMenuVisible(not isVis)
    end)
end

setMenuVisible(true)

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.MenuKey then
        local isVis = getgenv and getgenv().UnnamedWardMenuVisible
        if isVis == nil then isVis = mainWindow.Visible end
        setMenuVisible(not isVis)
    end
end))

-- ============================================================
-- STARTUP
-- ============================================================

ShowNotification("UnnamedWard", "UI loaded. " .. (isMobile and "Tap UW to toggle." or ("Press " .. Config.MenuKey.Name .. " to toggle.")), "SUCCESS", 4)
