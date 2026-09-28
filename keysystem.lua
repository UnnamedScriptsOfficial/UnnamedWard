-- ============================================================
-- SECTION 3.5: KEY SYSTEM (Delta + multi-executor HTTP)
-- Final hardened build
-- ============================================================

local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local WISHLIST_URL   = "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/wishlist.json"
local BLACKLIST_URL  = "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/blacklist.json"
local FREE_URL       = "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/refs/heads/main/free.json"
local DISCORD_INVITE = "https://discord.gg/g7jj8F6suv"

-- ============================================================
-- typeof alias with Color3-aware fallback
-- ============================================================
local typeof = typeof
if type(typeof) ~= "function" then
    typeof = function(v)
        if type(v) == "userdata" then
            local ok = pcall(function() return v.R + v.G + v.B end)
            if ok then return "Color3" end
        end
        return type(v)
    end
end

-- ============================================================
-- Global state
-- ============================================================
premiumEnabled = premiumEnabled or false
premiumTier    = premiumTier or "FREE"
keyExpiry      = keyExpiry or "Never"

-- ============================================================
-- Safe time
-- ============================================================
local now = (type(tick) == "function" and tick) or os.time

-- ============================================================
-- HTTP resolver
-- ============================================================
local function resolveHttpGet()
    if type(request) == "function" then
        return function(url)
            local ok, res = pcall(request, {Url = url, Method = "GET"})
            if not ok then return nil end
            if type(res) == "string" then return res end
            if type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(http_request) == "function" then
        return function(url)
            local ok, res = pcall(http_request, {Url = url, Method = "GET"})
            if not ok then return nil end
            if type(res) == "string" then return res end
            if type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return function(url)
            local ok, res = pcall(syn.request, {Url = url, Method = "GET"})
            if not ok then return nil end
            if type(res) == "string" then return res end
            if type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(http) == "table" and type(http.request) == "function" then
        return function(url)
            local ok, res = pcall(http.request, {Url = url, Method = "GET"})
            if not ok then return nil end
            if type(res) == "string" then return res end
            if type(res) == "table" then return res.Body or res.body end
            return nil
        end
    end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then
        return function(url)
            local ok, res = pcall(fluxus.request, {Url = url, Method = "GET"})
            if not ok then return nil end
            if type(res) == "string" then return res end
            if type(res) == "table" then return res.Body or res.body end
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
local httpAvailable = HttpGet ~= nil

if not httpAvailable then
    warn("[UnnamedWard] No HTTP function available on this executor. Key validation is disabled.")
end

-- ============================================================
-- Cache
-- ============================================================
local cache = {
    wishlist = nil, wishlistTime = 0,
    blacklist = nil, blacklistTime = 0,
    free = nil, freeTime = 0,
}
local CACHE_TTL = 60

local function fetchJSON(url)
    if not HttpGet then return nil end
    local sep = url:find("?", 1, true) and "&" or "?"
    local fullUrl = url .. sep .. "t=" .. tostring(math.floor(now()))
    local ok, res = pcall(HttpGet, fullUrl)
    if not ok or not res then return nil end
    if type(res) == "table" then res = res.Body or res.body or "" end
    if type(res) ~= "string" or res == "" then return nil end
    local decoded
    local decOk = pcall(function() decoded = HttpService:JSONDecode(res) end)
    if not decOk then return nil end
    if type(decoded) ~= "table" then return nil end
    return decoded
end

-- Empty {} is a legitimate cached state: it means "the list was
-- successfully fetched and is empty." The verifyKey caller uses
-- `~= nil` to distinguish "fetched" from "not fetched" — an empty
-- table is truthy in Lua, so `{} ~= nil` correctly reports available.
local function getWishlist(force)
    local t = now()
    if not force and cache.wishlist and (t - cache.wishlistTime) < CACHE_TTL then return cache.wishlist end
    local data = fetchJSON(WISHLIST_URL)
    if type(data) == "table" then
        cache.wishlist = data
        cache.wishlistTime = t
    end
    return cache.wishlist
end

local function getBlacklist(force)
    local t = now()
    if not force and cache.blacklist and (t - cache.blacklistTime) < CACHE_TTL then return cache.blacklist end
    local data = fetchJSON(BLACKLIST_URL)
    if type(data) == "table" then
        cache.blacklist = data
        cache.blacklistTime = t
    end
    return cache.blacklist
end

local function getFreeList(force)
    local t = now()
    if not force and cache.free and (t - cache.freeTime) < CACHE_TTL then return cache.free end
    local data = fetchJSON(FREE_URL)
    if type(data) == "table" then
        cache.free = data
        cache.freeTime = t
    end
    return cache.free
end

-- ============================================================
-- Key normalization
-- ============================================================
local function normalizeKey(k)
    if type(k) ~= "string" then return "" end
    return (k:gsub("%s", "")):upper()
end

-- ============================================================
-- Flexible status / duration readers
--   Both use explicit ~= nil checks instead of `a or b or c`
--   chains: a falsy value (false) that carries meaning would
--   silently fall through the or-chain and be replaced by a
--   default. See history: round-5 readStatus, round-6 scalar
--   dict values, round-7 readDuration.
-- ============================================================
local function readStatus(entry)
    if type(entry) ~= "table" then return "active" end

    local raw
    if entry.status ~= nil then raw = entry.status
    elseif entry.Status ~= nil then raw = entry.Status
    elseif entry.state ~= nil then raw = entry.state
    elseif entry.State ~= nil then raw = entry.State
    end

    if raw == nil then
        if entry.active  == false or entry.Active  == false then return "inactive" end
        if entry.enabled == false or entry.Enabled == false then return "disabled" end
        return "active"
    end

    if raw == false then return "inactive" end
    if raw == true  then return "active"   end

    return tostring(raw)
end

local function readDuration(entry, fallback)
    if type(entry) ~= "table" then return fallback end

    local d
    if entry.duration ~= nil then d = entry.duration
    elseif entry.Duration ~= nil then d = entry.Duration
    elseif entry.expires  ~= nil then d = entry.expires
    elseif entry.Expires  ~= nil then d = entry.Expires
    end

    if d == nil then return fallback end
    -- Booleans aren't meaningful durations: fall back to the default.
    if d == false then return fallback end
    if d == true  then return fallback end
    return tostring(d)
end

-- Convert a scalar value into a status string.
local function scalarToStatus(v)
    if v == true  then return "active"   end
    if v == false then return "inactive" end
    if type(v) == "string" then return v end
    return tostring(v)
end

-- ============================================================
-- Blacklist check
--   Contract: presence of the key = banned, regardless of value.
--   {"ABC": false} still means "ABC is banned."
-- ============================================================
local function isBlacklisted(key)
    local bl = getBlacklist(false)
    if not bl then return false, false end
    local list = bl.keys or bl
    if type(list) ~= "table" then return false, true end
    local target = normalizeKey(key)

    for _, entry in ipairs(list) do
        local entryKey
        if type(entry) == "string" then entryKey = entry
        elseif type(entry) == "table" then entryKey = entry.key or entry.Key end
        if entryKey and normalizeKey(entryKey) == target then return true, true end
    end

    for k, v in pairs(list) do
        if type(k) == "string" and normalizeKey(k) == target then
            return true, true
        end
        if type(v) == "table" then
            local vKey = v.key or v.Key
            if vKey and normalizeKey(vKey) == target then return true, true end
        end
    end

    return false, true
end

-- ============================================================
-- Key lookup — supports all common schema shapes:
--   ["ABC", "DEF"]                       array of strings
--   [{key="ABC", status="active"}]       array of tables
--   {"ABC": true}                        dict key→bool
--   {"ABC": "banned"}                    dict key→scalar status
--   {"ABC": {status="active"}}           dict key→table
--   {"user_a": {key="ABC"}}              dict key→table with key field
-- ============================================================
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
            if entryKey and normalizeKey(entryKey) == target then return entry end
        end
    end

    for k, v in pairs(entries) do
        if type(k) == "string" and normalizeKey(k) == target then
            if type(v) == "table" then return v end
            return { key = k, status = scalarToStatus(v) }
        end
        if type(v) == "table" then
            local vKey = v.key or v.Key
            if vKey and normalizeKey(vKey) == target then return v end
        end
    end

    return nil
end

-- ============================================================
-- verifyKey — tri-state aware, partial-failure aware
-- ============================================================
local function verifyKey(key)
    if not key or key == "" then return false, "No key provided", nil end
    if not httpAvailable then return false, "NETWORK_ERROR", nil end

    local blHit, blAvailable = isBlacklisted(key)
    if blHit then return false, "This key has been blacklisted", nil end

    local wishlist = getWishlist(false)
    local freeList = getFreeList(false)
    local wlAvailable = wishlist ~= nil
    local frAvailable = freeList ~= nil

    if not wlAvailable and not frAvailable then
        return false, "NETWORK_ERROR", nil
    end

    local function refuseIfBlacklistUnknown()
        if not blAvailable then
            return false, "BLACKLIST_UNAVAILABLE", nil
        end
        return nil
    end

    local wlEntry = lookupKey(wishlist, key)
    if wlEntry then
        local status = readStatus(wlEntry)
        if status:lower() ~= "active" then
            return false, "Key is " .. status, nil
        end
        local r = refuseIfBlacklistUnknown()
        if r then return r end
        return true, readDuration(wlEntry, "Permanent"), "PREMIUM"
    end

    local frEntry = lookupKey(freeList, key)
    if frEntry then
        local status = readStatus(frEntry)
        if status:lower() ~= "active" then
            return false, "Free key is " .. status, nil
        end
        local r = refuseIfBlacklistUnknown()
        if r then return r end
        return true, readDuration(frEntry, "2d"), "FREE"
    end

    if not wlAvailable or not frAvailable then
        return false, "NETWORK_ERROR", nil
    end

    return false, "Key not recognized", nil
end

if type(hideFromStack) == "function" then
    pcall(hideFromStack, verifyKey)
end

-- ============================================================
-- Safe file helpers
-- ============================================================
local function safeReadFile(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, exists = pcall(isfile, path)
    if not ok or not exists then return nil end
    local rok, content = pcall(readfile, path)
    if rok and type(content) == "string" then return content end
    return nil
end

local writefileWarned = false
local function safeWriteFile(path, content)
    if type(writefile) ~= "function" then
        if not writefileWarned then
            writefileWarned = true
            warn("[UnnamedWard] writefile unavailable — your key will not persist between sessions.")
        end
        return false
    end
    return (pcall(writefile, path, content))
end

local function safeDeleteFile(path)
    if type(delfile) ~= "function" then return false end
    return (pcall(delfile, path))
end

local savedKey = nil
do
    local s = safeReadFile("UnnamedWard_key.txt")
    if s and #s > 0 then
        savedKey = s:gsub("^%s*(.-)%s*$", "%1")
    end
end

local verified = false

-- ============================================================
-- PlayerGui resolution
-- ============================================================
local PlayerGui = PlayerGui
if not PlayerGui then
    local lp = Players and Players.LocalPlayer
    if lp then
        local ok, pg = pcall(function() return lp:WaitForChild("PlayerGui", 10) end)
        if ok and pg then PlayerGui = pg end
    end
end
if not PlayerGui then
    warn("[UnnamedWard] PlayerGui unavailable — aborting key gate.")
    return
end

-- ============================================================
-- Theme fallbacks
-- ============================================================
local Theme = Theme or {}
local function col(key, fallback)
    local v = Theme[key]
    if typeof(v) == "Color3" then return v end
    return fallback
end
Theme.WindowBg         = col("WindowBg",        Color3.fromRGB(20, 20, 24))
Theme.WindowBgTop      = col("WindowBgTop",     Color3.fromRGB(30, 30, 36))
Theme.WindowBgBottom   = col("WindowBgBottom",  Color3.fromRGB(14, 14, 18))
Theme.OuterBorder      = col("OuterBorder",     Color3.fromRGB(60, 60, 70))
Theme.AccentPink       = col("AccentPink",      Color3.fromRGB(226, 120, 152))
Theme.AccentPinkLight  = col("AccentPinkLight", Color3.fromRGB(240, 160, 185))
Theme.CardBg           = col("CardBg",          Color3.fromRGB(28, 28, 34))
Theme.BorderPink       = col("BorderPink",      Color3.fromRGB(180, 90, 120))
Theme.BorderPinkDark   = col("BorderPinkDark",  Color3.fromRGB(120, 60, 85))
Theme.BorderDark       = col("BorderDark",      Color3.fromRGB(50, 50, 60))
Theme.ControlBg        = col("ControlBg",       Color3.fromRGB(34, 34, 40))
Theme.ButtonBg         = col("ButtonBg",        Color3.fromRGB(40, 40, 48))
Theme.ButtonHoverBg    = col("ButtonHoverBg",   Color3.fromRGB(52, 52, 62))
Theme.ButtonBorder     = col("ButtonBorder",    Color3.fromRGB(70, 70, 82))
Theme.TextWhite        = col("TextWhite",       Color3.fromRGB(240, 240, 245))
Theme.TextMuted        = col("TextMuted",       Color3.fromRGB(152, 148, 144))
Theme.TextDark         = col("TextDark",        Color3.fromRGB(90, 90, 96))
Theme.Red              = col("Red",             Color3.fromRGB(230, 80, 80))
Theme.Green            = col("Green",           Color3.fromRGB(80, 200, 120))
Theme.Yellow           = col("Yellow",          Color3.fromRGB(245, 195, 65))

local MainFont = MainFont or Enum.Font.Gotham

local isMobile = isMobile
if isMobile == nil then
    isMobile = UserInputService.TouchEnabled
end

-- ============================================================
-- GUI
-- ============================================================
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "UnnamedWardKeyGate"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
keyGui.DisplayOrder = 999999
keyGui.Parent = PlayerGui

local dim = Instance.new("TextButton")
dim.Size = UDim2.new(1, 0, 1, 0)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.35
dim.BorderSizePixel = 0
dim.Text = ""
dim.AutoButtonColor = false
dim.Active = true
dim.Modal = false
dim.Selectable = false
dim.ZIndex = 1
dim.Parent = keyGui

local panelW = isMobile and 320 or 380
local panelH = isMobile and 320 or 310

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, panelW, 0, panelH)
panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
panel.BackgroundColor3 = Theme.WindowBg
panel.BorderSizePixel = 0
panel.Active = true
panel.ZIndex = 2
panel.Parent = keyGui

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
    if type(setclipboard) == "function" then
        pcall(function() setclipboard(DISCORD_INVITE); copied = true end)
    end
    if copyHint and copyHint.Parent then
        copyHint.Text = copied and "✓ Copied to clipboard!" or ("Copy manually: " .. DISCORD_INVITE)
        copyHint.TextColor3 = copied and Theme.Green or Theme.Yellow
    end
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
statusLbl.TextWrapped = false
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
statusLbl.ZIndex = 3
statusLbl.Parent = panel

local function setStatus(text, color)
    if not statusLbl or not statusLbl.Parent then return end
    statusLbl.Text = text
    if color then statusLbl.TextColor3 = color end
end

local function setButtonText(btn, text)
    if not btn or not btn.Parent then return end
    btn.Text = text
end

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

local quit = Instance.new("TextButton")
quit.Size = UDim2.new(0.5, -15, 0, 30)
quit.Position = UDim2.new(0.5, 5, 0, panelH - 82)
quit.BackgroundColor3 = Theme.ButtonBg
quit.BorderSizePixel = 0
quit.Font = MainFont
quit.Text = "Continue Free"
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

local verifying = false

-- ============================================================
-- Unlock & close
-- ============================================================
local function unlockAndClose(expiry, tier)
    premiumEnabled = (tier == "PREMIUM")
    premiumTier = tier or "FREE"
    keyExpiry = tostring(expiry or "Never")
    if type(getgenv) == "function" then
        pcall(function()
            local g = getgenv()
            g.UnnamedWardKeyVerified = true
            g.UnnamedWardPremium = premiumEnabled
            g.UnnamedWardTier = premiumTier
        end)
    end
    verified = true
    verifying = false
    pcall(function()
        if keyGui and keyGui.Parent then keyGui:Destroy() end
    end)
end

-- ============================================================
-- Submit handler
-- ============================================================
local function trySubmit()
    if verifying then return end
    local entered = (keyBox.Text or ""):gsub("^%s*(.-)%s*$", "%1")
    if entered == "" then
        setStatus("Please enter a key first.", Theme.Yellow)
        return
    end

    verifying = true
    setButtonText(submit, "Verifying...")
    setStatus("Checking key databases...", Theme.TextMuted)

    task.spawn(function()
        local valid, result, tier = verifyKey(entered)

        if verified then
            verifying = false
            return
        end

        if result == "NETWORK_ERROR" or result == "BLACKLIST_UNAVAILABLE" then
            setStatus(
                (result == "BLACKLIST_UNAVAILABLE")
                    and "⚠ Security check offline — retry."
                    or  "⚠ Network issue — retry shortly.",
                Theme.Yellow
            )
            setButtonText(submit, "Retry")
            verifying = false
            return
        end

        if valid then
            setStatus("✓ " .. tostring(tier) .. " access granted — " .. tostring(result), Theme.Green)
            setButtonText(submit, "Verified")
            safeWriteFile("UnnamedWard_key.txt", entered)
            task.wait(0.7)
            if verified then
                verifying = false
                return
            end
            unlockAndClose(result, tier)
        else
            setStatus("✗ " .. tostring(result), Theme.Red)
            setButtonText(submit, "Verify Key")
            verifying = false
        end
    end)
end

submit.MouseButton1Click:Connect(trySubmit)
keyBox.FocusLost:Connect(function(enterPressed) if enterPressed then trySubmit() end end)

submit.MouseEnter:Connect(function() submit.BackgroundColor3 = Theme.ButtonHoverBg; sStroke.Color = Theme.BorderPink end)
submit.MouseLeave:Connect(function() submit.BackgroundColor3 = Theme.ButtonBg; sStroke.Color = Theme.ButtonBorder end)

gotoDiscordBtn.MouseButton1Click:Connect(function()
    local copied = false
    if type(setclipboard) == "function" then
        pcall(function() setclipboard(DISCORD_INVITE); copied = true end)
    end
    setStatus(
        copied and "✓ Discord link copied!" or ("Join: " .. DISCORD_INVITE),
        copied and Theme.Green or Theme.Yellow
    )
end)

gotoDiscordBtn.MouseEnter:Connect(function() gotoDiscordBtn.BackgroundColor3 = Theme.ButtonHoverBg; gdStroke.Color = Theme.BorderPink end)
gotoDiscordBtn.MouseLeave:Connect(function() gotoDiscordBtn.BackgroundColor3 = Theme.ButtonBg; gdStroke.Color = Theme.BorderPinkDark end)

quit.MouseButton1Click:Connect(function()
    setStatus("Get a FREE key from Discord, then Verify.", Theme.Yellow)
    if type(setclipboard) == "function" then pcall(setclipboard, DISCORD_INVITE) end
end)

quit.MouseEnter:Connect(function() quit.BackgroundColor3 = Theme.ButtonHoverBg; qStroke.Color = Theme.BorderPink; quit.TextColor3 = Theme.TextWhite end)
quit.MouseLeave:Connect(function() quit.BackgroundColor3 = Theme.ButtonBg; qStroke.Color = Theme.ButtonBorder; quit.TextColor3 = Theme.TextMuted end)

-- ============================================================
-- Saved-key auto-check
-- ============================================================
if savedKey and savedKey ~= "" then
    task.spawn(function()
        task.wait(0.2)
        if verified then return end

        if not httpAvailable then
            setStatus("⚠ No HTTP on this executor.", Theme.Yellow)
            return
        end

        setStatus("Checking saved key...", Theme.TextMuted)
        local valid, result, tier = verifyKey(savedKey)
        if verified then return end

        if result == "NETWORK_ERROR" or result == "BLACKLIST_UNAVAILABLE" then
            setStatus(
                (result == "BLACKLIST_UNAVAILABLE")
                    and "⚠ Security check offline — press Verify."
                    or  "⚠ Network issue — press Verify.",
                Theme.Yellow
            )
            return
        end

        if valid then
            setStatus("✓ Saved " .. tostring(tier) .. " key valid — " .. tostring(result), Theme.Green)
            task.wait(0.4)
            if verified then return end
            unlockAndClose(result, tier)
        else
            setStatus("Saved key invalid — get a new one.", Theme.Yellow)
            safeDeleteFile("UnnamedWard_key.txt")
        end
    end)
end

-- ============================================================
-- Wait loop (10-minute timeout)
-- ============================================================
local waitStart = now()
while not verified and keyGui and keyGui.Parent and (now() - waitStart) < 600 do
    task.wait(0.1)
end

pcall(function()
    if keyGui and keyGui.Parent then keyGui:Destroy() end
end)
