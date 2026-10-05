-- ============================================================
-- keysystem.lua - Self-contained key gate
-- Publishes:
--   getgenv().UnnamedWardKeyVerified = true|false
--   getgenv().UnnamedWardTier        = "FREE"|"PREMIUM"
--   getgenv().UnnamedWardGateClosed  = true|false
-- Reads (optional):
--   getgenv().UnnamedWardGateCtx = { Wishlist, Blacklist, Free, Discord, PlayerGui, isMobile, Theme, MainFont }
-- ============================================================

-- ============================================================
-- FALLBACKS (so this file works even if nothing else was published)
-- ============================================================
local Services   = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local HttpService= game:GetService("HttpService")
local CoreGui    = game:GetService("CoreGui")
local LocalPlayer= Services.LocalPlayer

local function safeHttp(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok then return res end
    return nil
end

local function decodeJson(str)
    local ok, res = pcall(function() return HttpService:JSONDecode(str) end)
    if ok then return res end
    return nil
end

local function getGuiParentFallback()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return CoreGui
end

local GateCtx = getgenv().UnnamedWardGateCtx or {}
local PlayerGui = GateCtx.PlayerGui or (LocalPlayer:FindFirstChild("PlayerGui"))
local isMobile  = GateCtx.isMobile or (UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled)

local Theme = GateCtx.Theme or {
    OuterBorder=Color3.fromRGB(255,182,210), BorderPink=Color3.fromRGB(255,182,210),
    BorderPinkDark=Color3.fromRGB(230,150,185), BorderBlue=Color3.fromRGB(170,215,255),
    WindowBg=Color3.fromRGB(255,248,252), WindowBgTop=Color3.fromRGB(255,252,254),
    WindowBgBottom=Color3.fromRGB(245,240,250), InnerCanvasBg=Color3.fromRGB(252,248,253),
    HeaderBg=Color3.fromRGB(255,245,250), CardBg=Color3.fromRGB(255,252,254),
    CardBgTop=Color3.fromRGB(255,254,255), CardBgBottom=Color3.fromRGB(248,244,252),
    BorderDark=Color3.fromRGB(230,210,225), BorderCard=Color3.fromRGB(240,215,235),
    AccentPink=Color3.fromRGB(255,160,195), AccentPinkLight=Color3.fromRGB(255,200,220),
    AccentPinkDark=Color3.fromRGB(235,130,175), AccentPinkDim=Color3.fromRGB(255,220,235),
    AccentBlue=Color3.fromRGB(150,205,255), AccentBlueLight=Color3.fromRGB(195,225,255),
    AccentBlueDark=Color3.fromRGB(110,175,240), AccentBlueDim=Color3.fromRGB(220,240,255),
    TextWhite=Color3.fromRGB(80,60,75), TextMuted=Color3.fromRGB(150,130,145),
    TextDark=Color3.fromRGB(180,165,180), TextPink=Color3.fromRGB(235,130,175),
    TextBlue=Color3.fromRGB(110,175,240), ControlBg=Color3.fromRGB(250,245,250),
    ButtonBg=Color3.fromRGB(255,240,248), ButtonHoverBg=Color3.fromRGB(255,225,240),
    ButtonBorder=Color3.fromRGB(245,205,225), Red=Color3.fromRGB(255,130,150),
    Yellow=Color3.fromRGB(255,210,130), Green=Color3.fromRGB(150,220,180),
}
local MainFont     = GateCtx.MainFont or Enum.Font.GothamMedium
local MainFontBold = Enum.Font.GothamBold

local WISHLIST_URL   = GateCtx.Wishlist or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/wishlist.json"
local BLACKLIST_URL  = GateCtx.Blacklist or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/blacklist.json"
local FREE_URL       = GateCtx.Free or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/refs/heads/main/free.json"
local DISCORD_INVITE = GateCtx.Discord or "https://discord.gg/g7jj8F6suv"

-- ============================================================
-- STATE
-- ============================================================
getgenv().UnnamedWardKeyVerified = false
getgenv().UnnamedWardPremium     = false
getgenv().UnnamedWardTier        = "FREE"
getgenv().UnnamedWardGateClosed  = false

local function closeGate(tier)
    getgenv().UnnamedWardTier       = tier or "FREE"
    getgenv().UnnamedWardPremium    = (getgenv().UnnamedWardTier == "PREMIUM")
    getgenv().UnnamedWardKeyVerified = true
    getgenv().UnnamedWardGateClosed  = true
    if getgenv().UnnamedWardGateCtx then
        getgenv().UnnamedWardGateCtx.KeyVerified = true
        getgenv().UnnamedWardGateCtx.GateClosed  = true
        getgenv().UnnamedWardGateCtx.Tier        = getgenv().UnnamedWardTier
    end
end

local function failGate()
    getgenv().UnnamedWardKeyVerified = false
    getgenv().UnnamedWardGateClosed  = true
    if getgenv().UnnamedWardGateCtx then
        getgenv().UnnamedWardGateCtx.GateClosed = true
    end
end

-- ============================================================
-- BUILD UI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "UnnamedWardKeyGate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = getGuiParentFallback()

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.ZIndex = 1
backdrop.Parent = gui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, isMobile and 300 or 340, 0, 260)
win.Position = UDim2.new(0.5, isMobile and -150 or -170, 0.5, -130)
win.BackgroundColor3 = Theme.WindowBg
win.BorderSizePixel = 0
win.Active = true
win.ZIndex = 2
win.Parent = gui

local winStroke = Instance.new("UIStroke")
winStroke.Color = Theme.OuterBorder
winStroke.Thickness = 1.2
winStroke.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Theme.HeaderBg
title.BorderSizePixel = 0
title.Font = MainFontBold
title.RichText = true
title.Text = '<font color="#ffa0c3">Unnamed</font><font color="#96cdff">Ward</font> <font color="#888894">— Key</font>'
title.TextColor3 = Theme.TextWhite
title.TextSize = 13
title.ZIndex = 3
title.Parent = win

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -20, 1, -80)
body.Position = UDim2.new(0, 10, 0, 38)
body.BackgroundTransparency = 1
body.ZIndex = 3
body.Parent = win

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 18)
status.BackgroundTransparency = 1
status.Font = MainFont
status.Text = "Enter your key below"
status.TextColor3 = Theme.TextMuted
status.TextSize = 11.5
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 4
status.Parent = body

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, 0, 0, 26)
keyBox.Position = UDim2.new(0, 0, 0, 24)
keyBox.BackgroundColor3 = Theme.ControlBg
keyBox.BorderSizePixel = 0
keyBox.Font = MainFont
keyBox.PlaceholderText = "Paste key here..."
keyBox.PlaceholderColor3 = Theme.TextDark
keyBox.Text = ""
keyBox.TextColor3 = Theme.TextWhite
keyBox.TextSize = 12
keyBox.TextXAlignment = Enum.TextXAlignment.Left
keyBox.ClearTextOnFocus = false
keyBox.ZIndex = 4
keyBox.Parent = body
local keyBoxPad = Instance.new("UIPadding")
keyBoxPad.PaddingLeft = UDim.new(0, 8)
keyBoxPad.Parent = keyBox
local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Color = Theme.BorderPink
keyBoxStroke.Thickness = 1
keyBoxStroke.Parent = keyBox

local verifyBtn = Instance.new("TextButton")
verifyBtn.Size = UDim2.new(1, 0, 0, 26)
verifyBtn.Position = UDim2.new(0, 0, 0, 58)
verifyBtn.BackgroundColor3 = Theme.ButtonBg
verifyBtn.BorderSizePixel = 0
verifyBtn.Font = MainFontBold
verifyBtn.Text = "Verify"
verifyBtn.TextColor3 = Theme.TextPink
verifyBtn.TextSize = 12
verifyBtn.AutoButtonColor = false
verifyBtn.ZIndex = 4
verifyBtn.Parent = body
local verifyStroke = Instance.new("UIStroke")
verifyStroke.Color = Theme.ButtonBorder
verifyStroke.Thickness = 1
verifyStroke.Parent = verifyBtn
verifyBtn.MouseEnter:Connect(function() verifyBtn.BackgroundColor3 = Theme.ButtonHoverBg end)
verifyBtn.MouseLeave:Connect(function() verifyBtn.BackgroundColor3 = Theme.ButtonBg end)

local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(1, 0, 0, 22)
getKeyBtn.Position = UDim2.new(0, 0, 0, 90)
getKeyBtn.BackgroundColor3 = Theme.ControlBg
getKeyBtn.BorderSizePixel = 0
getKeyBtn.Font = MainFont
getKeyBtn.Text = "Get key (Discord)"
getKeyBtn.TextColor3 = Theme.TextBlue
getKeyBtn.TextSize = 11
getKeyBtn.AutoButtonColor = false
getKeyBtn.ZIndex = 4
getKeyBtn.Parent = body
local gkStroke = Instance.new("UIStroke")
gkStroke.Color = Theme.BorderBlue
gkStroke.Thickness = 1
gkStroke.Parent = getKeyBtn

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 60)
hint.Position = UDim2.new(0, 0, 0, 118)
hint.BackgroundTransparency = 1
hint.Font = MainFont
hint.Text = "Premium unlocks every feature. Free keys work too.\nJoin the Discord to get a key."
hint.TextColor3 = Theme.TextDark
hint.TextSize = 10.5
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.ZIndex = 4
hint.Parent = body

local function setStatus(txt, color)
    status.Text = txt
    status.TextColor3 = color or Theme.TextMuted
end

-- ============================================================
-- VERIFY LOGIC (client-side list check; server would be better)
-- ============================================================
local function isPremiumKey(k)
    if type(k) ~= "string" then return false end
    local wishlist = safeHttp(WISHLIST_URL)
    if wishlist then
        local data = decodeJson(wishlist)
        if type(data) == "table" then
            for _, entry in ipairs(data) do
                if type(entry) == "string" and entry == k then return true end
                if type(entry) == "table" and entry.key == k then
                    local t = tostring(entry.tier or "FREE"):upper()
                    return t == "PREMIUM"
                end
            end
        end
    end
    return false
end

local function isFreeKey(k)
    if type(k) ~= "string" then return false end
    local free = safeHttp(FREE_URL)
    if free then
        local data = decodeJson(free)
        if type(data) == "table" then
            for _, entry in ipairs(data) do
                if type(entry) == "string" and entry == k then return true end
                if type(entry) == "table" and entry.key == k then return true end
            end
        end
    end
    return false
end

local function doVerify()
    local k = keyBox.Text
    if not k or k == "" then
        setStatus("Please enter a key.", Theme.Red)
        return
    end

    setStatus("Checking...", Theme.TextBlue)

    task.spawn(function()
        local blacklist = safeHttp(BLACKLIST_URL)
        if blacklist then
            local data = decodeJson(blacklist)
            if type(data) == "table" then
                for _, entry in ipairs(data) do
                    if type(entry) == "string" and entry == k then
                        setStatus("This key is blacklisted.", Theme.Red)
                        return
                    end
                    if type(entry) == "table" and entry.key == k then
                        setStatus("This key is blacklisted.", Theme.Red)
                        return
                    end
                end
            end
        end

        if isPremiumKey(k) then
            setStatus("Premium key accepted!", Theme.Green)
            task.wait(0.4)
            closeGate("PREMIUM")
            gui:Destroy()
            return
        end

        if isFreeKey(k) then
            setStatus("Free key accepted!", Theme.Green)
            task.wait(0.4)
            closeGate("FREE")
            gui:Destroy()
            return
        end

        setStatus("Invalid key. Try again.", Theme.Red)
    end)
end

verifyBtn.MouseButton1Click:Connect(doVerify)

keyBox.FocusLost:Connect(function(enter)
    if enter then doVerify() end
end)

getKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(DISCORD_INVITE) end)
    end
    setStatus("Discord link copied!", Theme.TextBlue)
end)

-- ============================================================
-- DRAG SUPPORT
-- ============================================================
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                     startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ============================================================
-- WATCHDOG: if the user closes the GUI without verifying,
-- mark the gate as closed so the loader doesn't hang.
-- ============================================================
task.spawn(function()
    while gui and gui.Parent do
        task.wait(0.5)
    end
    if not getgenv().UnnamedWardKeyVerified then
        failGate()
    end
end)
