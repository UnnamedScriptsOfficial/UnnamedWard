-- ============================================================
-- UNNAMEDWARD LOADER + KEY GATE (INLINE)
-- Animates "UnnamedWard" then reveals the key input in-place.
-- Blocking — main script does not load until verified.
-- ============================================================
local keyVerified = false
local premiumTier = "FREE"

local LoaderGate = (function()
    local HttpServiceL = game:GetService("HttpService")

    local state = {
        Verified = false,
        Closed = false,
        Tier = "FREE",
    }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UnnamedWardGate"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 2147483000
    ScreenGui.Parent = getGuiParent()

    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.4
    dim.BorderSizePixel = 0
    dim.ZIndex = 1
    dim.Parent = ScreenGui

    local panelW = isMobile and 300 or 420
    local panelH = isMobile and 260 or 280
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, panelW, 0, panelH)
    panel.Position = UDim2.new(0.5, -panelW / 2, 0.5, -panelH / 2)
    panel.BackgroundColor3 = Theme.WindowBg
    panel.BorderSizePixel = 0
    panel.ZIndex = 2
    panel.Parent = ScreenGui

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

    local titleHolder = Instance.new("Frame")
    titleHolder.Size = UDim2.new(1, 0, 0, 70)
    titleHolder.Position = UDim2.new(0, 0, 0.28, -35)
    titleHolder.BackgroundTransparency = 1
    titleHolder.ZIndex = 3
    titleHolder.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = MainFontBold
    title.RichText = true
    title.TextScaled = true
    title.Text = ""
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.ZIndex = 4
    title.Parent = titleHolder
    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = isMobile and 40 or 52
    titleConstraint.MinTextSize = isMobile and 20 or 28
    titleConstraint.Parent = title

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 18)
    subtitle.Position = UDim2.new(0, 10, 0.60, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = MainFont
    subtitle.Text = ""
    subtitle.TextColor3 = Theme.TextMuted
    subtitle.TextSize = isMobile and 11 or 12
    subtitle.TextTransparency = 1
    subtitle.ZIndex = 4
    subtitle.Parent = panel

    local keyRow = Instance.new("Frame")
    keyRow.Size = UDim2.new(1, -24, 0, 34)
    keyRow.Position = UDim2.new(0, 12, 1, -50)
    keyRow.BackgroundTransparency = 1
    keyRow.Visible = false
    keyRow.ZIndex = 3
    keyRow.Parent = panel

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -100, 1, 0)
    keyBox.BackgroundColor3 = Theme.ControlBg
    keyBox.BorderSizePixel = 0
    keyBox.Font = MainFont
    keyBox.PlaceholderText = "Enter your key..."
    keyBox.PlaceholderColor3 = Theme.TextDark
    keyBox.Text = ""
    keyBox.TextColor3 = Theme.TextWhite
    keyBox.TextSize = isMobile and 12 or 13
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox.ClearTextOnFocus = false
    keyBox.ZIndex = 4
    keyBox.Parent = keyRow

    local kPad = Instance.new("UIPadding")
    kPad.PaddingLeft = UDim.new(0, 8)
    kPad.PaddingRight = UDim.new(0, 8)
    kPad.Parent = keyBox

    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Theme.BorderCard
    kStroke.Thickness = 1
    kStroke.Parent = keyBox

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 90, 1, 0)
    submitBtn.Position = UDim2.new(1, -92, 0, 0)
    submitBtn.BackgroundColor3 = Theme.AccentPink
    submitBtn.BorderSizePixel = 0
    submitBtn.Font = MainFontBold
    submitBtn.Text = "Verify"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = isMobile and 12 or 13
    submitBtn.AutoButtonColor = false
    submitBtn.ZIndex = 4
    submitBtn.Parent = keyRow

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = Theme.AccentPinkDark
    sStroke.Thickness = 1
    sStroke.Parent = submitBtn

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -24, 0, 16)
    statusLbl.Position = UDim2.new(0, 12, 1, -14)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = MainFont
    statusLbl.Text = ""
    statusLbl.TextColor3 = Theme.Red
    statusLbl.TextSize = isMobile and 10 or 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    statusLbl.TextTransparency = 1
    statusLbl.ZIndex = 4
    statusLbl.Parent = panel

    -- ============ ANIMATED TITLE ============
    local titleFull = "UnnamedWard"
    local letters = {}
    for i = 1, #titleFull do
        table.insert(letters, titleFull:sub(i, i))
    end

    local function buildRichText(revealCount, glowProgress)
        local out = {}
        for i, ch in ipairs(letters) do
            local isPink = i <= 7
            local baseColor = isPink and "#ffa0c3" or "#96cdff"
            if i <= revealCount then
                local t = 1
                if i == revealCount and glowProgress < 1 then
                    t = glowProgress
                end
                if t < 0.99 then
                    local r = tonumber(baseColor:sub(2, 3), 16)
                    local g = tonumber(baseColor:sub(4, 5), 16)
                    local b = tonumber(baseColor:sub(6, 7), 16)
                    local dr, dg, db = 40, 40, 60
                    local cr = math.floor(dr + (r - dr) * t)
                    local cg = math.floor(dg + (g - dg) * t)
                    local cb = math.floor(db + (b - db) * t)
                    baseColor = string.format("#%02x%02x%02x", cr, cg, cb)
                end
                table.insert(out, string.format('<font color="%s">%s</font>', baseColor, ch))
            else
                table.insert(out, ' ')
            end
        end
        return table.concat(out)
    end

    local function setSubtitle(text)
        subtitle.Text = text
    end

    -- ============ ANIMATION SEQUENCE ============
    local animState = { done = false }

    local function runAnimSequence()
        panel.BackgroundTransparency = 0.6
        TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
            BackgroundTransparency = 0
        }):Play()

        task.wait(0.5)

        for i = 1, #letters do
            for glow = 0, 1, 0.12 do
                title.Text = buildRichText(i, glow)
                task.wait(0.025)
            end
            title.Text = buildRichText(i, 1)
            task.wait(0.10)
        end

        task.wait(0.4)

        setSubtitle("Enter your access key")
        TweenService:Create(subtitle, TweenInfo.new(0.4), {
            TextTransparency = 0
        }):Play()

        task.wait(0.35)

        keyRow.Visible = true
        local finalY = keyRow.Position
        keyRow.Position = UDim2.new(0, 12, 1, -20)
        TweenService:Create(keyRow, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = finalY
        }):Play()

        animState.done = true
    end

    task.spawn(runAnimSequence)

    -- ============ HTTP RESOLVER ============
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
        return function(url)
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" then return res end
            return nil
        end
    end

    local HttpGet = resolveHttpGet()

    -- ============ KEY DATABASE ============
    local cache = {wishlist=nil, wishlistT=0, blacklist=nil, blacklistT=0, free=nil, freeT=0}
    local CACHE_TTL = 60

    local function fetchJSON(url)
        if not HttpGet then return nil end
        local ok, res = pcall(HttpGet, url .. "?t=" .. tostring(math.floor(tick())))
        if not ok or type(res) ~= "string" or res == "" then return nil end
        local decOk, decoded = pcall(function() return HttpServiceL:JSONDecode(res) end)
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

    -- ============ SUBMIT LOGIC ============
    local verifying = false
    local unlocked = false

    local function finishSuccess(tier)
        if unlocked then return end
        unlocked = true

        local normalizedTier = "FREE"
        if type(tier) == "string" and tier:upper() == "PREMIUM" then
            normalizedTier = "PREMIUM"
        end

        state.Verified = true
        state.Tier = normalizedTier

        if getgenv then
            getgenv().UnnamedWardKeyVerified = true
            getgenv().UnnamedWardPremium     = (normalizedTier == "PREMIUM")
            getgenv().UnnamedWardTier        = normalizedTier
            getgenv().UnnamedWardGateClosed  = false
        end

        local rawKey = keyBox.Text or ""
        rawKey = rawKey:gsub("^%s*(.-)%s*$", "%1")
        if writefile and rawKey ~= "" then
            pcall(function() writefile("UnnamedWard_key.txt", rawKey) end)
        end

        TweenService:Create(panel, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(dim, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        pcall(function() ScreenGui:Destroy() end)
    end

    local function finishClosed()
        if unlocked then return end
        unlocked = true
        state.Closed = true
        if getgenv then getgenv().UnnamedWardGateClosed = true end
        pcall(function() ScreenGui:Destroy() end)
    end

    local function trySubmit()
        if verifying then return end
        if not animState.done then return end

        local entered = keyBox.Text or ""
        entered = entered:gsub("^%s*(.-)%s*$", "%1")

        if entered == "" then
            statusLbl.TextColor3 = Theme.Yellow
            statusLbl.Text = "Please enter a key first."
            TweenService:Create(statusLbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
            return
        end

        verifying = true
        submitBtn.Text = "..."
        submitBtn.BackgroundColor3 = Theme.AccentBlue
        statusLbl.TextColor3 = Theme.TextMuted
        statusLbl.Text = "Checking..."
        TweenService:Create(statusLbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

        task.spawn(function()
            local valid, result, tier = verifyKey(entered)
            if valid then
                statusLbl.TextColor3 = Theme.Green
                statusLbl.Text = (tostring(tier):upper() == "PREMIUM") and "PREMIUM access granted" or "FREE access granted"
                submitBtn.Text = "OK"
                submitBtn.BackgroundColor3 = Theme.Green
                task.wait(0.6)
                finishSuccess(tier)
            else
                statusLbl.TextColor3 = Theme.Red
                statusLbl.Text = tostring(result)
                submitBtn.Text = "Verify"
                submitBtn.BackgroundColor3 = Theme.AccentPink
                verifying = false
            end
        end)
    end

    submitBtn.MouseButton1Click:Connect(trySubmit)

    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then trySubmit() end
    end)

    keyBox.Focused:Connect(function()
        kStroke.Color = Theme.AccentPink
    end)

    keyBox.FocusLost:Connect(function()
        kStroke.Color = Theme.BorderCard
    end)

    submitBtn.MouseEnter:Connect(function()
        if not verifying then
            submitBtn.BackgroundColor3 = Theme.AccentPinkLight
        end
    end)

    submitBtn.MouseLeave:Connect(function()
        if not verifying then
            submitBtn.BackgroundColor3 = Theme.AccentPink
        end
    end)

    return state
end)()

-- Block until gate completes
while not LoaderGate.Verified and not LoaderGate.Closed do
    task.wait(0.1)
end

keyVerified = LoaderGate.Verified == true
premiumTier = LoaderGate.Tier or "FREE"

if type(premiumTier) ~= "string" then
    premiumTier = "FREE"
else
    premiumTier = premiumTier:gsub("%s+", ""):upper()
    if premiumTier ~= "PREMIUM" then premiumTier = "FREE" end
end

if not keyVerified then
    warn("[UnnamedWard] Key gate closed without verification. Main script will NOT load.")
    return
end

print("[UnnamedWard] Key verified! Tier: " .. tostring(premiumTier))
print("[UnnamedWard] Loading main script...")

-- Auto-activate Lag Killer now that the user is verified
task.spawn(function()
    if LagKiller and not LagKiller.IsEnabled() then
        LagKiller.Enable()
        print("[UnnamedWard] Lag Killer activated.")
    end
end)
