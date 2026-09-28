--[[
UnnamedWard Key Gate (keysystem.lua)
Loaded by the main script via loadstring.
Contract:
  - Reads getgenv().WISHLIST_URL, BLACKLIST_URL, FREE_URL, DISCORD_INVITE, savedKey
  - Reads getgenv().PlayerGui, Theme, MainFont, isMobile for context
  - On success: sets getgenv().UnnamedWardKeyVerified/UnnamedWardPremium/UnnamedWardTier
  - On close : sets getgenv().UnnamedWardGateClosed = true
  - Destroys its own UI in both cases
]]

-- ---------- HTTP resolver ----------
local function resolveHttpGet()
    if type(request) == "function" then
        return function(url)
            local ok, res = pcall(request, {Url = url, Method = "GET"})
            if ok and type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(http_request) == "function" then
        return function(url)
            local ok, res = pcall(http_request, {Url = url, Method = "GET"})
            if ok and type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return function(url)
            local ok, res = pcall(syn.request, {Url = url, Method = "GET"})
            if ok and type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then
        return function(url)
            local ok, res = pcall(fluxus.request, {Url = url, Method = "GET"})
            if ok and type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    local ok, httpGet = pcall(function() return game.HttpGet end)
    if ok and type(httpGet) == "function" then
        return function(url)
            local ok2, res = pcall(function() return game:HttpGet(url) end)
            if ok2 and type(res) == "string" then return res end
            return nil
        end
    end
    return nil
end

local HttpGet = resolveHttpGet()

-- ---------- URLs (from main script via getgenv, or fallback) ----------
local WISHLIST_URL   = getgenv().WISHLIST_URL   or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/wishlist.json"
local BLACKLIST_URL  = getgenv().BLACKLIST_URL  or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/blacklist.json"
local FREE_URL       = getgenv().FREE_URL       or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/refs/heads/main/free.json"
local DISCORD_INVITE = getgenv().DISCORD_INVITE or "https://discord.gg/g7jj8F6suv"

-- ---------- Context from main script ----------
local PlayerGui = getgenv().PlayerGui
    or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 10))
local Theme     = getgenv().Theme
local MainFont  = getgenv().MainFont or Enum.Font.RobotoMono
local isMobile  = getgenv().isMobile
if isMobile == nil then
    local UIS = game:GetService("UserInputService")
    isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
end
local savedKey  = getgenv().savedKey

-- Fallback Theme (in case main script didn't publish one)
if type(Theme) ~= "table" then
    Theme = {
        OuterBorder      = Color3.fromRGB(215, 106, 141),
        BorderPink       = Color3.fromRGB(215, 106, 141),
        BorderPinkDark   = Color3.fromRGB(150, 60, 92),
        WindowBg         = Color3.fromRGB(22, 17, 21),
        WindowBgTop      = Color3.fromRGB(28, 20, 26),
        WindowBgBottom   = Color3.fromRGB(16, 12, 15),
        CardBg           = Color3.fromRGB(33, 24, 30),
        BorderDark       = Color3.fromRGB(56, 40, 52),
        AccentPink       = Color3.fromRGB(226, 120, 152),
        AccentPinkLight  = Color3.fromRGB(245, 152, 182),
        TextWhite        = Color3.fromRGB(242, 240, 243),
        TextMuted        = Color3.fromRGB(152, 132, 144),
        TextDark         = Color3.fromRGB(105, 88, 100),
        ControlBg        = Color3.fromRGB(15, 11, 14),
        ButtonBg         = Color3.fromRGB(32, 23, 29),
        ButtonHoverBg    = Color3.fromRGB(48, 34, 44),
        ButtonBorder     = Color3.fromRGB(68, 48, 62),
        Red              = Color3.fromRGB(235, 75, 75),
        Yellow           = Color3.fromRGB(245, 195, 65),
        Green            = Color3.fromRGB(100, 220, 120),
    }
end

if not PlayerGui then
    warn("[keysystem] No PlayerGui; cannot show key gate.")
    getgenv().UnnamedWardGateClosed = true
    return
end

-- ---------- JSON helpers ----------
local HttpService = game:GetService("HttpService")

local cache = {wishlist=nil, wishlistT=0, blacklist=nil, blacklistT=0, free=nil, freeT=0}
local CACHE_TTL = 60

local function fetchJSON(url)
    if not HttpGet then return nil end
    local ok, res = pcall(HttpGet, url .. "?t=" .. tostring(math.floor(tick())))
    if not ok or type(res) ~= "string" or res == "" then return nil end
    local decOk, decoded = pcall(function() return HttpService:JSONDecode(res) end)
    if not decOk then return nil end
    return decoded
end

local function getWishlist()
    local now = tick()
    if cache.wishlist and (now - cache.wishlistT) < CACHE_TTL then return cache.wishlist end
    local data = fetchJSON(WISHLIST_URL)
    if data then cache.wishlist = data; cache.wishlistT = now end
    return cache.wishlist
end

local function getBlacklist()
    local now = tick()
    if cache.blacklist and (now - cache.blacklistT) < CACHE_TTL then return cache.blacklist end
    local data = fetchJSON(BLACKLIST_URL)
    if data then cache.blacklist = data; cache.blacklistT = now end
    return cache.blacklist
end

local function getFreeList()
    local now = tick()
    if cache.free and (now - cache.freeT) < CACHE_TTL then return cache.free end
    local data = fetchJSON(FREE_URL)
    if data then cache.free = data; cache.freeT = now end
    return cache.free
end

local function normalizeKey(k)
    if type(k) ~= "string" then return "" end
    return k:gsub("%s", ""):upper()
end

local function isBlacklisted(key)
    local bl = getBlacklist()
    if not bl then return false end
    local list = bl.keys or bl
    if type(list) ~= "table" then return false end
    local target = normalizeKey(key)
    for _, entry in ipairs(list) do
        local entryKey
        if type(entry) == "string" then entryKey = entry
        elseif type(entry) == "table" then entryKey = entry.key or entry.Key end
        if entryKey and normalizeKey(entryKey) == target then return true end
    end
    return false
end

local function lookupKey(list, key)
    if type(list) ~= "table" then return nil end
    local entries = list.keys or list
    if type(entries) ~= "table" then return nil end
    local target = normalizeKey(key)
    for _, entry in ipairs(entries) do
        if type(entry) == "string" then
            if normalizeKey(entry) == target then
                return { key = entry, status = "active" }
            end
        elseif type(entry) == "table" then
            local entryKey = entry.key or entry.Key
            if entryKey and normalizeKey(entryKey) == target then
                return entry
            end
        end
    end
    return nil
end

local function verifyKey(key)
    if not key or key == "" then return false, "No key provided", nil end
    if isBlacklisted(key) then return false, "This key has been blacklisted", nil end

    local wishlist = getWishlist()
    local wlEntry = lookupKey(wishlist, key)
    if wlEntry then
        local status = wlEntry.status or "active"
        if status:lower() ~= "active" then return false, "Key is " .. tostring(status), nil end
        return true, tostring(wlEntry.duration or "Never"), "PREMIUM"
    end

    local freeList = getFreeList()
    local frEntry = lookupKey(freeList, key)
    if frEntry then
        local status = frEntry.status or "active"
        if status:lower() ~= "active" then return false, "Free key is " .. tostring(status), nil end
        return true, tostring(frEntry.duration or "2d"), "FREE"
    end

    if not wishlist and not freeList then
        return false, "Could not reach key server. Check your connection.", nil
    end
    return false, "Key not recognized", nil
end

-- ---------- UI ----------
local gui = Instance.new("ScreenGui")
gui.Name = "UnnamedWardKeyGate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
gui.Parent = PlayerGui

local dim = Instance.new("Frame")
dim.Size = UDim2.new(1, 0, 1, 0)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.35
dim.BorderSizePixel = 0
dim.ZIndex = 1
dim.Parent = gui

local panelW = isMobile and 320 or 380
local panelH = isMobile and 320 or 310

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, panelW, 0, panelH)
panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
panel.BackgroundColor3 = Theme.WindowBg
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = gui

local pStroke = Instance.new("UIStroke")
pStroke.Color = Theme.OuterBorder
pStroke.Thickness = 1.5
pStroke.Parent = panel

local pGrad = Instance.new("UIGradient")
pGrad.Rotation = 90
pGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.WindowBgTop),
    ColorSequenceKeypoint.new(1, Theme.WindowBgBottom)
})
pGrad.Parent = panel

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.BackgroundColor3 = Theme.AccentPink
topLine.BorderSizePixel = 0
topLine.ZIndex = 3
topLine.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Font = MainFont
title.RichText = true
title.Text = '<font color="#ffffff">Unnamed</font><font color="#e27898">Ward</font>  <font color="#f5c341">PREMIUM</font>'
title.TextColor3 = Theme.TextWhite
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = panel

-- Discord card
local discordCard = Instance.new("Frame")
discordCard.Size = UDim2.new(1, -20, 0, 62)
discordCard.Position = UDim2.new(0, 10, 0, 42)
discordCard.BackgroundColor3 = Theme.CardBg
discordCard.BorderSizePixel = 0
discordCard.ZIndex = 3
discordCard.Parent = panel

local dStroke = Instance.new("UIStroke")
dStroke.Color = Theme.BorderPink
dStroke.Thickness = 1
dStroke.Parent = discordCard

local dTitle = Instance.new("TextLabel")
dTitle.Size = UDim2.new(1, -20, 0, 16)
dTitle.Position = UDim2.new(0, 12, 0, 6)
dTitle.BackgroundTransparency = 1
dTitle.Font = MainFont
dTitle.RichText = true
dTitle.Text = '<font color="#e27898">●</font> Get premium & free keys from Discord'
dTitle.TextColor3 = Theme.TextWhite
dTitle.TextSize = 11.5
dTitle.TextXAlignment = Enum.TextXAlignment.Left
dTitle.ZIndex = 4
dTitle.Parent = discordCard

local dLink = Instance.new("TextButton")
dLink.Size = UDim2.new(1, -20, 0, 20)
dLink.Position = UDim2.new(0, 12, 0, 24)
dLink.BackgroundColor3 = Theme.ControlBg
dLink.BorderSizePixel = 0
dLink.Font = MainFont
dLink.Text = DISCORD_INVITE
dLink.TextColor3 = Theme.AccentPinkLight
dLink.TextSize = 11
dLink.TextXAlignment = Enum.TextXAlignment.Left
dLink.AutoButtonColor = false
dLink.ZIndex = 4
dLink.Parent = discordCard

local dPad = Instance.new("UIPadding")
dPad.PaddingLeft = UDim.new(0, 6)
dPad.Parent = dLink

local dLinkStroke = Instance.new("UIStroke")
dLinkStroke.Color = Theme.BorderDark
dLinkStroke.Thickness = 1
dLinkStroke.Parent = dLink

local copyHint = Instance.new("TextLabel")
copyHint.Size = UDim2.new(1, -20, 0, 14)
copyHint.Position = UDim2.new(0, 12, 0, 46)
copyHint.BackgroundTransparency = 1
copyHint.Font = MainFont
copyHint.Text = "Tap to copy  •  Premium + Free keys available"
copyHint.TextColor3 = Theme.TextMuted
copyHint.TextSize = 9.5
copyHint.TextXAlignment = Enum.TextXAlignment.Left
copyHint.ZIndex = 4
copyHint.Parent = discordCard

dLink.MouseButton1Click:Connect(function()
    local copied = false
    if setclipboard then
        pcall(function() setclipboard(DISCORD_INVITE); copied = true end)
    end
    copyHint.Text = copied and "✓ Copied to clipboard!" or ("Copy manually: " .. DISCORD_INVITE)
    copyHint.TextColor3 = copied and Theme.Green or Theme.Yellow
    task.delay(2.5, function()
        if copyHint and copyHint.Parent then
            copyHint.Text = "Tap to copy  •  Premium + Free keys available"
            copyHint.TextColor3 = Theme.TextMuted
        end
    end)
end)

-- Key input
local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, -20, 0, 14)
keyLabel.Position = UDim2.new(0, 10, 0, 114)
keyLabel.BackgroundTransparency = 1
keyLabel.Font = MainFont
keyLabel.Text = "Premium or Free Access Key"
keyLabel.TextColor3 = Theme.TextMuted
keyLabel.TextSize = 11
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.ZIndex = 3
keyLabel.Parent = panel

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -20, 0, 32)
keyBox.Position = UDim2.new(0, 10, 0, 130)
keyBox.BackgroundColor3 = Theme.ControlBg
keyBox.BorderSizePixel = 0
keyBox.Font = MainFont
keyBox.PlaceholderText = "Enter your key..."
keyBox.PlaceholderColor3 = Theme.TextDark
keyBox.Text = savedKey or ""
keyBox.TextColor3 = Theme.TextWhite
keyBox.TextSize = 13
keyBox.ClearTextOnFocus = false
keyBox.ZIndex = 3
keyBox.Parent = panel

local kPad = Instance.new("UIPadding")
kPad.PaddingLeft = UDim.new(0, 8)
kPad.PaddingRight = UDim.new(0, 8)
kPad.Parent = keyBox

local kStroke = Instance.new("UIStroke")
kStroke.Color = Theme.BorderDark
kStroke.Thickness = 1
kStroke.Parent = keyBox

keyBox.Focused:Connect(function() kStroke.Color = Theme.BorderPink end)
keyBox.FocusLost:Connect(function() kStroke.Color = Theme.BorderDark end)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -20, 0, 18)
statusLbl.Position = UDim2.new(0, 10, 0, 166)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = MainFont
statusLbl.Text = ""
statusLbl.TextColor3 = Theme.Red
statusLbl.TextSize = 10.5
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextWrapped = true
statusLbl.ZIndex = 3
statusLbl.Parent = panel

-- Verify button
local submit = Instance.new("TextButton")
submit.Size = UDim2.new(1, -20, 0, 30)
submit.Position = UDim2.new(0, 10, 0, panelH - 118)
submit.BackgroundColor3 = Theme.ButtonBg
submit.BorderSizePixel = 0
submit.Font = MainFont
submit.Text = "Verify Key"
submit.TextColor3 = Theme.TextWhite
submit.TextSize = 12.5
submit.AutoButtonColor = false
submit.ZIndex = 3
submit.Parent = panel

local sStroke = Instance.new("UIStroke")
sStroke.Color = Theme.ButtonBorder
sStroke.Thickness = 1
sStroke.Parent = submit

-- Get Premium button
local gotoDiscordBtn = Instance.new("TextButton")
gotoDiscordBtn.Size = UDim2.new(0.5, -15, 0, 30)
gotoDiscordBtn.Position = UDim2.new(0, 10, 0, panelH - 82)
gotoDiscordBtn.BackgroundColor3 = Theme.ButtonBg
gotoDiscordBtn.BorderSizePixel = 0
gotoDiscordBtn.Font = MainFont
gotoDiscordBtn.Text = "Get Premium"
gotoDiscordBtn.TextColor3 = Theme.AccentPinkLight
gotoDiscordBtn.TextSize = 12
gotoDiscordBtn.AutoButtonColor = false
gotoDiscordBtn.ZIndex = 3
gotoDiscordBtn.Parent = panel

local gdStroke = Instance.new("UIStroke")
gdStroke.Color = Theme.BorderPinkDark
gdStroke.Thickness = 1
gdStroke.Parent = gotoDiscordBtn

-- Close / Continue Free button
local quit = Instance.new("TextButton")
quit.Size = UDim2.new(0.5, -15, 0, 30)
quit.Position = UDim2.new(0.5, 5, 0, panelH - 82)
quit.BackgroundColor3 = Theme.ButtonBg
quit.BorderSizePixel = 0
quit.Font = MainFont
quit.Text = "Close"
quit.TextColor3 = Theme.TextMuted
quit.TextSize = 12
quit.AutoButtonColor = false
quit.ZIndex = 3
quit.Parent = panel

local qStroke = Instance.new("UIStroke")
qStroke.Color = Theme.ButtonBorder
qStroke.Thickness = 1
qStroke.Parent = quit

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.new(1, -20, 0, 20)
hintLbl.Position = UDim2.new(0, 10, 0, panelH - 46)
hintLbl.BackgroundTransparency = 1
hintLbl.Font = MainFont
hintLbl.RichText = true
hintLbl.Text = '<font color="#989490">Free keys are announced in the Discord</font>'
hintLbl.TextColor3 = Theme.TextMuted
hintLbl.TextSize = 9.5
hintLbl.TextXAlignment = Enum.TextXAlignment.Center
hintLbl.ZIndex = 3
hintLbl.Parent = panel

-- ---------- Logic ----------
local verifying = false
local unlocked = false

local function finishSuccess(expiry, tier)
    if unlocked then return end
    unlocked = true

    getgenv().UnnamedWardKeyVerified = true
    getgenv().UnnamedWardPremium     = (tier == "PREMIUM")
    getgenv().UnnamedWardTier        = tier or "FREE"
    getgenv().UnnamedWardGateClosed  = false

    if writefile then
        pcall(function() writefile("UnnamedWard_key.txt", (keyBox.Text or ""):gsub("^%s*(.-)%s*$", "%1")) end)
    end

    pcall(function() if gui then gui:Destroy() end end)
end

local function finishClosed()
    if unlocked then return end
    unlocked = true
    getgenv().UnnamedWardGateClosed = true
    pcall(function() if gui then gui:Destroy() end end)
end

local function trySubmit()
    if verifying then return end
    local entered = (keyBox.Text or ""):gsub("^%s*(.-)%s*$", "%1")
    if entered == "" then
        statusLbl.TextColor3 = Theme.Yellow
        statusLbl.Text = "Please enter a key first."
        return
    end

    verifying = true
    submit.Text = "Verifying..."
    statusLbl.TextColor3 = Theme.TextMuted
    statusLbl.Text = "Checking key databases..."

    task.spawn(function()
        local valid, result, tier = verifyKey(entered)
        if valid then
            statusLbl.TextColor3 = Theme.Green
            statusLbl.Text = "✓ " .. tostring(tier) .. " access granted! Duration: " .. tostring(result)
            submit.Text = "Verified"
            task.wait(0.7)
            finishSuccess(result, tier)
        else
            statusLbl.TextColor3 = Theme.Red
            statusLbl.Text = "✗ " .. tostring(result)
            submit.Text = "Verify Key"
            verifying = false
        end
    end)
end

submit.MouseButton1Click:Connect(trySubmit)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then trySubmit() end
end)

submit.MouseEnter:Connect(function() submit.BackgroundColor3 = Theme.ButtonHoverBg; sStroke.Color = Theme.BorderPink end)
submit.MouseLeave:Connect(function() submit.BackgroundColor3 = Theme.ButtonBg; sStroke.Color = Theme.ButtonBorder end)

gotoDiscordBtn.MouseButton1Click:Connect(function()
    local copied = false
    if setclipboard then
        pcall(function() setclipboard(DISCORD_INVITE); copied = true end)
    end
    statusLbl.TextColor3 = copied and Theme.Green or Theme.Yellow
    statusLbl.Text = copied and "✓ Discord link copied! Get premium there." or ("Join: " .. DISCORD_INVITE)
end)

gotoDiscordBtn.MouseEnter:Connect(function() gotoDiscordBtn.BackgroundColor3 = Theme.ButtonHoverBg; gdStroke.Color = Theme.BorderPink end)
gotoDiscordBtn.MouseLeave:Connect(function() gotoDiscordBtn.BackgroundColor3 = Theme.ButtonBg; gdStroke.Color = Theme.BorderPinkDark end)

quit.MouseButton1Click:Connect(finishClosed)
quit.MouseEnter:Connect(function() quit.BackgroundColor3 = Theme.ButtonHoverBg; qStroke.Color = Theme.BorderPink; quit.TextColor3 = Theme.TextWhite end)
quit.MouseLeave:Connect(function() quit.BackgroundColor3 = Theme.ButtonBg; qStroke.Color = Theme.ButtonBorder; quit.TextColor3 = Theme.TextMuted end)

-- Auto-verify saved key on load
if savedKey and savedKey ~= "" then
    task.spawn(function()
        task.wait(0.3)
        if unlocked then return end
        statusLbl.TextColor3 = Theme.TextMuted
        statusLbl.Text = "Checking saved key..."
        local valid, result, tier = verifyKey(savedKey)
        if unlocked then return end
        if valid then
            statusLbl.TextColor3 = Theme.Green
            statusLbl.Text = "✓ Saved " .. tostring(tier) .. " key valid. Duration: " .. tostring(result)
            task.wait(0.5)
            finishSuccess(result, tier)
        else
            statusLbl.TextColor3 = Theme.Yellow
            statusLbl.Text = "Saved key invalid: " .. tostring(result)
            if delfile then pcall(function() delfile("UnnamedWard_key.txt") end) end
        end
    end)
end
