--[[
UnnamedWard Key Gate (keysystem.lua)
- ALWAYS shows the input UI. Never auto-verifies from disk.
- User must manually enter a wishlisted (or free) key.
- Censors key input: first 3 chars visible, rest masked as bullets.
- Writes real key (not censored) to UnnamedWard_key.txt on success.
- Sets getgenv().UnnamedWardTier to EXACTLY "PREMIUM" or "FREE".
- On close: sets UnnamedWardGateClosed = true.
- Destroys its own UI in both cases.
- Theme: light pink + light blue (matches main script).
]]

-- ============================================================
-- HTTP RESOLVER
-- ============================================================

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
    -- Always fall back to game:HttpGet
    return function(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" then return res end
        return nil
    end
end

local HttpGet = resolveHttpGet()

-- ============================================================
-- CONTEXT (from main script via getgenv)
-- ============================================================

local ctx = getgenv().UnnamedWardGateCtx or {}

local WISHLIST_URL   = ctx.Wishlist   or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/wishlist.json"
local BLACKLIST_URL  = ctx.Blacklist  or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/blacklist.json"
local FREE_URL       = ctx.Free       or "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/refs/heads/main/free.json"
local DISCORD_INVITE = ctx.Discord    or "https://discord.gg/g7jj8F6suv"

-- ============================================================
-- THEME — light pink + light blue
-- ============================================================

local Theme = {
    OuterBorder      = Color3.fromRGB(180, 200, 235),
    BorderPink       = Color3.fromRGB(250, 195, 215),
    BorderPinkDark   = Color3.fromRGB(220, 150, 180),
    BorderBlue       = Color3.fromRGB(180, 205, 240),
    BorderBlueDark   = Color3.fromRGB(140, 175, 220),

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

local isMobile = ctx.isMobile
if isMobile == nil then
    local UIS = game:GetService("UserInputService")
    isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
end

local PlayerGui = ctx.PlayerGui
    or (game:GetService("Players").LocalPlayer
        and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 10))

if not PlayerGui then
    warn("[keysystem] No PlayerGui; cannot show key gate.")
    getgenv().UnnamedWardGateClosed = true
    return
end

-- ============================================================
-- KEY DATABASE
-- ============================================================

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

-- ============================================================
-- VERIFY KEY
-- ============================================================

local function verifyKey(key)
    if not key or key == "" then return false, "No key provided", nil end
    if isBlacklisted(key) then return false, "This key has been blacklisted", nil end

    local wishlist = getWishlist()
    local wlEntry = lookupKey(wishlist, key)
    if wlEntry then
        local status = wlEntry.status or "active"
        if status:lower() ~= "active" then
            return false, "Key is " .. tostring(status), nil
        end
        local dur = wlEntry.duration or "Never"
        return true, tostring(dur), "PREMIUM"
    end

    local freeList = getFreeList()
    local frEntry = lookupKey(freeList, key)
    if frEntry then
        local status = frEntry.status or "active"
        if status:lower() ~= "active" then
            return false, "Free key is " .. tostring(status), nil
        end
        local dur = frEntry.duration or "2d"
        return true, tostring(dur), "FREE"
    end

    if not wishlist and not freeList then
        return false, "Could not reach key server. Check your connection.", nil
    end
    return false, "Key not recognized", nil
end

-- ============================================================
-- UI
-- ============================================================

local _existingGate = PlayerGui:FindFirstChild("UnnamedWardKeyGate")
if _existingGate then
    pcall(function() _existingGate:Destroy() end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "UnnamedWardKeyGate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2147483000
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
    ColorSequenceKeypoint.new(1, Theme.WindowBgBottom),
})
pGrad.Parent = panel

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.BackgroundColor3 = Theme.AccentPink
topLine.BorderSizePixel = 0
topLine.ZIndex = 3
topLine.Parent = panel

local titleBadge = Instance.new("Frame")
titleBadge.Size = UDim2.new(0, 20, 0, 20)
titleBadge.Position = UDim2.new(0, 10, 0, 12)
titleBadge.BackgroundColor3 = Theme.AccentBlue
titleBadge.BorderSizePixel = 0
titleBadge.ZIndex = 3
titleBadge.Parent = panel

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Theme.AccentPink
tbStroke.Thickness = 1
tbStroke.Parent = titleBadge

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 4)
tbCorner.Parent = titleBadge

local tbLbl = Instance.new("TextLabel")
tbLbl.Size = UDim2.new(1, 0, 1, 0)
tbLbl.BackgroundTransparency = 1
tbLbl.Font = MonoFont
tbLbl.Text = "UW"
tbLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
tbLbl.TextSize = 10
tbLbl.ZIndex = 4
tbLbl.Parent = titleBadge

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 20)
title.Position = UDim2.new(0, 36, 0, 12)
title.BackgroundTransparency = 1
title.Font = MonoFont
title.RichText = true
title.Text = '<font color="#d982a5">Unnamed</font><font color="#7aa8e0">Ward</font>  <font color="#a0a5b5">ACCESS</font>'
title.TextColor3 = Theme.TextWhite
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = panel

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

local dTopLine = Instance.new("Frame")
dTopLine.Size = UDim2.new(1, 0, 0, 1.5)
dTopLine.BackgroundColor3 = Theme.AccentPink
dTopLine.BorderSizePixel = 0
dTopLine.ZIndex = 4
dTopLine.Parent = discordCard

local dTitle = Instance.new("TextLabel")
dTitle.Size = UDim2.new(1, -20, 0, 16)
dTitle.Position = UDim2.new(0, 12, 0, 6)
dTitle.BackgroundTransparency = 1
dTitle.Font = MainFont
dTitle.RichText = true
dTitle.Text = '<font color="#d982a5">●</font> Get keys from Discord'
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
dLink.TextColor3 = Theme.AccentPinkDark
dLink.TextSize = 11
dLink.TextXAlignment = Enum.TextXAlignment.Left
dLink.AutoButtonColor = false
dLink.ZIndex = 4
dLink.Parent = discordCard

local dPad = Instance.new("UIPadding")
dPad.PaddingLeft = UDim.new(0, 6)
dPad.Parent = dLink

local dLinkStroke = Instance.new("UIStroke")
dLinkStroke.Color = Theme.BorderCard
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
    copyHint.Text = copied and "Copied to clipboard!" or ("Copy manually: " .. DISCORD_INVITE)
    copyHint.TextColor3 = copied and Theme.Green or Theme.Yellow
    task.delay(2.5, function()
        if copyHint and copyHint.Parent then
            copyHint.Text = "Tap to copy  •  Premium + Free keys available"
            copyHint.TextColor3 = Theme.TextMuted
        end
    end)
end)

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, -20, 0, 14)
keyLabel.Position = UDim2.new(0, 10, 0, 114)
keyLabel.BackgroundTransparency = 1
keyLabel.Font = MainFont
keyLabel.Text = "Access Key"
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
keyBox.Text = ""
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
kStroke.Color = Theme.BorderCard
kStroke.Thickness = 1
kStroke.Parent = keyBox

-- ============================================================
-- KEY CENSOR
-- ============================================================

local VISIBLE_PREFIX = 3

local function censorString(raw)
    if type(raw) ~= "string" then return "" end
    local visible = math.min(VISIBLE_PREFIX, #raw)
    local masked = string.rep("•", math.max(0, #raw - visible))
    return raw:sub(1, visible) .. masked
end

local function setRawKey(raw)
    keyBox:SetAttribute("RawKey", raw or "")
    keyBox.Text = censorString(raw or "")
    keyBox.CursorPosition = #keyBox.Text + 1
end

local function getRawKey()
    return keyBox:GetAttribute("RawKey") or ""
end

keyBox:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = keyBox.Text or ""
    local raw = keyBox:GetAttribute("RawKey") or ""

    if newText == censorString(raw) then return end

    -- Full clear: user wiped the field entirely
    if newText == "" and raw ~= "" then
        keyBox:SetAttribute("RawKey", "")
        return
    end

    local bullets = select(2, newText:gsub("•", "•"))
    local rawBullets = select(2, censorString(raw):gsub("•", "•"))
    if bullets > rawBullets then
        keyBox.Text = censorString(raw)
        return
    end

    if #newText > #censorString(raw) then
        local clean = newText:gsub("•", "")
        if #clean > #raw then
            local added = clean:sub(#raw + 1)
            raw = raw .. added
        else
            raw = clean
        end
    elseif #newText < #censorString(raw) then
        raw = raw:sub(1, math.max(0, #raw - 1))
    end

    keyBox:SetAttribute("RawKey", raw)
    keyBox.Text = censorString(raw)
    keyBox.CursorPosition = #keyBox.Text + 1
end)

keyBox.Focused:Connect(function() kStroke.Color = Theme.BorderPink end)
keyBox.FocusLost:Connect(function() kStroke.Color = Theme.BorderCard end)

setRawKey("")

-- Status label
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

-- Buttons
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
sStroke.Color = Theme.BorderPink
sStroke.Thickness = 1
sStroke.Parent = submit

local gotoDiscordBtn = Instance.new("TextButton")
gotoDiscordBtn.Size = UDim2.new(0.5, -15, 0, 30)
gotoDiscordBtn.Position = UDim2.new(0, 10, 0, panelH - 82)
gotoDiscordBtn.BackgroundColor3 = Theme.ButtonBg
gotoDiscordBtn.BorderSizePixel = 0
gotoDiscordBtn.Font = MainFont
gotoDiscordBtn.Text = "Get Key"
gotoDiscordBtn.TextColor3 = Theme.AccentPinkDark
gotoDiscordBtn.TextSize = 12
gotoDiscordBtn.AutoButtonColor = false
gotoDiscordBtn.ZIndex = 3
gotoDiscordBtn.Parent = panel

local gdStroke = Instance.new("UIStroke")
gdStroke.Color = Theme.BorderPinkDark
gdStroke.Thickness = 1
gdStroke.Parent = gotoDiscordBtn

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
hintLbl.Text = '<font color="#989490">Keys are announced in the Discord</font>'
hintLbl.TextColor3 = Theme.TextMuted
hintLbl.TextSize = 9.5
hintLbl.TextXAlignment = Enum.TextXAlignment.Center
hintLbl.ZIndex = 3
hintLbl.Parent = panel

-- ============================================================
-- LOGIC
-- ============================================================

local verifying = false
local unlocked = false

local function finishSuccess(expiry, tier)
    if unlocked then return end
    unlocked = true

    local normalizedTier = "FREE"
    if type(tier) == "string" and tier:upper() == "PREMIUM" then
        normalizedTier = "PREMIUM"
    end

    getgenv().UnnamedWardKeyVerified = true
    getgenv().UnnamedWardPremium     = (normalizedTier == "PREMIUM")
    getgenv().UnnamedWardTier        = normalizedTier
    getgenv().UnnamedWardGateClosed  = false

    local rawKey = getRawKey()
    if writefile and rawKey and rawKey ~= "" then
        pcall(function() writefile("UnnamedWard_key.txt", rawKey) end)
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
    local entered = getRawKey()
    entered = entered:gsub("^%s*(.-)%s*$", "%1")

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
            local label = (tostring(tier):upper() == "PREMIUM") and "PREMIUM" or "FREE"
            statusLbl.TextColor3 = Theme.Green
            statusLbl.Text = label .. " access granted. Duration: " .. tostring(result)
            submit.Text = "Verified"
            task.wait(0.7)
            finishSuccess(result, tier)
        else
            statusLbl.TextColor3 = Theme.Red
            statusLbl.Text = tostring(result)
            submit.Text = "Verify Key"
            verifying = false
        end
    end)
end

submit.MouseButton1Click:Connect(trySubmit)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then trySubmit() end
end)

submit.MouseEnter:Connect(function()
    submit.BackgroundColor3 = Theme.ButtonHoverBg
    sStroke.Color = Theme.AccentPink
end)
submit.MouseLeave:Connect(function()
    submit.BackgroundColor3 = Theme.ButtonBg
    sStroke.Color = Theme.BorderPink
end)

gotoDiscordBtn.MouseButton1Click:Connect(function()
    local copied = false
    if setclipboard then
        pcall(function() setclipboard(DISCORD_INVITE); copied = true end)
    end
    statusLbl.TextColor3 = copied and Theme.Green or Theme.Yellow
    statusLbl.Text = copied and "Discord link copied!" or ("Join: " .. DISCORD_INVITE)
end)

gotoDiscordBtn.MouseEnter:Connect(function()
    gotoDiscordBtn.BackgroundColor3 = Theme.ButtonHoverBg
    gdStroke.Color = Theme.AccentPink
end)
gotoDiscordBtn.MouseLeave:Connect(function()
    gotoDiscordBtn.BackgroundColor3 = Theme.ButtonBg
    gdStroke.Color = Theme.BorderPinkDark
end)

quit.MouseButton1Click:Connect(finishClosed)
quit.MouseEnter:Connect(function()
    quit.BackgroundColor3 = Theme.ButtonHoverBg
    qStroke.Color = Theme.AccentPink
    quit.TextColor3 = Theme.TextWhite
end)
quit.MouseLeave:Connect(function()
    quit.BackgroundColor3 = Theme.ButtonBg
    qStroke.Color = Theme.ButtonBorder
    quit.TextColor3 = Theme.TextMuted
end)
