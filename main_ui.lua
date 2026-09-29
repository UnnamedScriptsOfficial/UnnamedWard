--[[
UnnamedWard UI (Mobile + PC Safe)
- Lazy tab building: only the visible tab allocates widgets
- Two shared UIS connections total (not two-per-slider)
- No Drawing, no getrawmetatable, no external fetches
- Toggles write to a local Config table; wire modules to it later
Discord: https://discord.gg/g7jj8F6suv
]]

-- ============================================================
-- INIT
-- ============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    local waited = 0
    while not Players.LocalPlayer and waited < 10 do
        task.wait(0.1)
        waited = waited + 0.1
    end
    LocalPlayer = Players.LocalPlayer
end
if not LocalPlayer then
    warn("[UnnamedWard] LocalPlayer unavailable.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
if not PlayerGui then
    warn("[UnnamedWard] No PlayerGui.")
    return
end

-- Purge previous instances
for _, child in ipairs(PlayerGui:GetChildren()) do
    if child.Name == "UnnamedWardUI" or child.Name == "UnnamedWardMobileToggle" then
        pcall(function() child:Destroy() end)
    end
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- CONFIG
-- ============================================================

local Config = {
    Aimbot = false,
    SilentAim = false,
    ESP_Master = true,
    ESP_EnemyOnly = true,
    ESP_Lobby = true,
    SpeedHack = false,
    SpeedValue = 49,
    FlyHack = false,
    FlySpeed = 50,
    Noclip = false,
    InfiniteJump = false,
    BunnyHop = false,
    NoRecoil = true,
    NoSpread = true,
    FastReload = false,
    RapidFire = false,
    InfiniteAmmo = false,
    UnlockAllSkins = false,
    HideViewModel = false,
    Fullbright = false,
    NoFog = true,
    CustomFOV = false,
    FOVValue = 90,
    ThirdPerson = false,
    Freecam = false,
    MenuKey = Enum.KeyCode.RightControl,
}

-- Public API so external scripts can read/write Config
if getgenv then getgenv().UnnamedWardUIConfig = Config end

-- ============================================================
-- THEME
-- ============================================================

local Theme = {
    OuterBorder      = Color3.fromRGB(180, 200, 235),
    BorderPink       = Color3.fromRGB(250, 195, 215),
    BorderPinkDark   = Color3.fromRGB(220, 150, 180),

    WindowBg         = Color3.fromRGB(250, 248, 252),
    WindowBgTop      = Color3.fromRGB(255, 250, 253),
    WindowBgBottom   = Color3.fromRGB(240, 245, 252),
    InnerCanvasBg    = Color3.fromRGB(252, 250, 253),
    HeaderBg         = Color3.fromRGB(245, 240, 248),

    CardBg           = Color3.fromRGB(252, 248, 252),
    BorderCard       = Color3.fromRGB(200, 195, 215),

    AccentPink       = Color3.fromRGB(245, 170, 195),
    AccentPinkLight  = Color3.fromRGB(255, 200, 220),
    AccentPinkDark   = Color3.fromRGB(215, 130, 165),

    AccentBlue       = Color3.fromRGB(150, 190, 240),

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
-- SCREEN GUI + UNLOAD
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnnamedWardUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = PlayerGui

local activeConnections = {}
local function track(conn)
    if conn then table.insert(activeConnections, conn) end
    return conn
end

local function UnloadUI()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(activeConnections)
    pcall(function() screenGui:Destroy() end)
    if getgenv then getgenv().UnnamedWardUIUnload = nil end
end

if getgenv then getgenv().UnnamedWardUIUnload = UnloadUI end

-- ============================================================
-- DROPDOWN OVERLAY + NOTIFICATIONS
-- ============================================================

local dropdownOverlay = Instance.new("Frame")
dropdownOverlay.Name = "DropdownOverlay"
dropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
dropdownOverlay.BackgroundTransparency = 1
dropdownOverlay.ZIndex = 1000
dropdownOverlay.Parent = screenGui

local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifContainer"
notifContainer.Size = UDim2.new(0, isMobile and 220 or 280, 1, -40)
notifContainer.Position = UDim2.new(1, isMobile and -230 or -295, 0, 40)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 5)
notifLayout.Parent = notifContainer

local MAX_NOTIFS = 5
local notifSeq = 0

local function ShowNotification(title, message, notifType, duration)
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

if getgenv then getgenv().UnnamedWardNotify = ShowNotification end

-- ============================================================
-- MAIN WINDOW
-- ============================================================

local screenSize = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
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

track(topBar.InputBegan:Connect(function(input)
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
track(UserInputService.InputChanged:Connect(function(input)
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
-- TAB SYSTEM (lazy)
-- ============================================================

local tabList = {"home", "aim", "esp", "move", "guns", "world", "config"}
local tabButtons = {}
local currentTab = nil

local function getRightCol(page)
    return page:FindFirstChild("RightCol") or page:FindFirstChild("LeftCol")
end

-- Forward declaration — each tab provides its own build function
local tabBuilders = {}

local function switchTab(tabName)
    if currentTab == tabName then return end
    currentTab = tabName

    -- Destroy previous page
    for _, child in ipairs(tabContentFrame:GetChildren()) do
        pcall(function() child:Destroy() end)
    end

    -- Update button styles
    for _, btnData in ipairs(tabButtons) do
        local isSelf = (btnData.name == tabName)
        btnData.btn.TextColor3 = isSelf and Theme.AccentPinkDark or Theme.TextMuted
        btnData.indicator.Visible = isSelf
    end

    -- Build new page
    local page = Instance.new("Frame")
    page.Name = "Page_" .. tabName
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
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

    local builder = tabBuilders[tabName]
    if builder then
        pcall(builder, page)
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
    btn.TextColor3 = Theme.TextMuted
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
    indicator.Visible = false
    indicator.ZIndex = 14
    indicator.Parent = btn

    btn.MouseButton1Click:Connect(function() switchTab(tabName) end)

    table.insert(tabButtons, {name = tabName, btn = btn, indicator = indicator})
end

-- ============================================================
-- UI WIDGETS
-- ============================================================

local function createGroupbox(parent, title)
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

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 1.5)
    topLine.BackgroundColor3 = Theme.AccentPink
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 16
    topLine.Parent = card

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
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

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -12, 0, 0)
    content.Position = UDim2.new(0, 6, 0, 22)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.ZIndex = 16
    content.Parent = card

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 6)
    cLayout.Parent = content

    local cPad = Instance.new("UIPadding")
    cPad.PaddingBottom = UDim.new(0, 8)
    cPad.Parent = content

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

-- Two shared UIS connections for all sliders
local sliderRegistry = { isSliding = false, updateFn = nil }

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderRegistry.isSliding = false
        sliderRegistry.updateFn = nil
    end
end))

track(UserInputService.InputChanged:Connect(function(input)
    if not sliderRegistry.isSliding or not sliderRegistry.updateFn then return end
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
    elseif (minVal % 1 ~= 0) or (maxVal % 1 ~= 0) or (
