-- ============================================================
-- UnnamedWard - ESP
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Theme = UW.Theme
local MainFont = UW.MainFont
local isMobile = UW.isMobile
local Config = UW.Config
local Players = Services.Players
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local RunService = Services.RunService
local TweenService = Services.TweenService
local screenGui = UW.screenGui
local isEnemyPlayer = UW.isEnemyPlayer

-- ============================================================
-- LIVE PREVIEW
-- ============================================================
local previewFrame = Instance.new("Frame")
previewFrame.Name = "ESPLivePreview"
previewFrame.Size = UDim2.new(0, isMobile and 90 or 110, 0, isMobile and 110 or 130)
previewFrame.Position = UDim2.new(1, isMobile and -100 or -120, 0, 40)
previewFrame.BackgroundColor3 = Theme.CardBg
previewFrame.BorderSizePixel = 0
previewFrame.ZIndex = 85
previewFrame.Visible = false
previewFrame.Parent = screenGui
table.insert(State.cleanUpInstances, previewFrame)

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Theme.BorderPink
previewStroke.Thickness = 1
previewStroke.Parent = previewFrame

local previewTitle = Instance.new("TextLabel")
previewTitle.Size = UDim2.new(1, 0, 0, 16)
previewTitle.BackgroundTransparency = 1
previewTitle.Font = UW.MainFontBold
previewTitle.Text = "ESP Live Preview"
previewTitle.TextColor3 = Theme.TextPink
previewTitle.TextSize = isMobile and 9 or 10
previewTitle.ZIndex = 86
previewTitle.Parent = previewFrame

local previewBox = Instance.new("Frame")
previewBox.Size = UDim2.new(0, isMobile and 70 or 90, 0, isMobile and 80 or 100)
previewBox.Position = UDim2.new(0.5, isMobile and -35 or -45, 0, 18)
previewBox.BackgroundColor3 = Theme.InnerCanvasBg
previewBox.BorderSizePixel = 0
previewBox.ZIndex = 86
previewBox.Parent = previewFrame

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Theme.AccentPink
boxStroke.Thickness = 1.2
boxStroke.Parent = previewBox

local sampleName = Instance.new("TextLabel")
sampleName.Size = UDim2.new(1, 0, 0, 12)
sampleName.Position = UDim2.new(0, 0, 0, 2)
sampleName.BackgroundTransparency = 1
sampleName.Font = MainFont
sampleName.Text = "Player"
sampleName.TextColor3 = Theme.TextWhite
sampleName.TextSize = isMobile and 8 or 9
sampleName.ZIndex = 87
sampleName.Parent = previewBox

local sampleHpBg = Instance.new("Frame")
sampleHpBg.Size = UDim2.new(0.8, 0, 0, 4)
sampleHpBg.Position = UDim2.new(0, 8, 0, 18)
sampleHpBg.BackgroundColor3 = Theme.ControlBg
sampleHpBg.BorderSizePixel = 0
sampleHpBg.ZIndex = 87
sampleHpBg.Parent = previewBox

local sampleHp = Instance.new("Frame")
sampleHp.Size = UDim2.new(1, 0, 1, 0)
sampleHp.BackgroundColor3 = Theme.Green
sampleHp.BorderSizePixel = 0
sampleHp.ZIndex = 88
sampleHp.Parent = sampleHpBg

local sampleDist = Instance.new("TextLabel")
sampleDist.Size = UDim2.new(1, 0, 0, 12)
sampleDist.Position = UDim2.new(0, 0, 0, 26)
sampleDist.BackgroundTransparency = 1
sampleDist.Font = MainFont
sampleDist.Text = "32m"
sampleDist.TextColor3 = Theme.AccentPink
sampleDist.TextSize = isMobile and 8 or 9
sampleDist.ZIndex = 87
sampleDist.Parent = previewBox

local espLivePreview = {
    frame = previewFrame,
    box = previewBox,
    update = function(name, hpPct, dist)
        if name then sampleName.Text = name end
        if hpPct then sampleHp.Size = UDim2.new(math.clamp(hpPct, 0, 1), 0, 1, 0) end
        if dist then sampleDist.Text = tostring(math.floor(dist)) .. "m" end
    end
}

-- ============================================================
-- ESP OBJECTS
-- ============================================================
local espObjects = {}
local SKELETON_CONNECTIONS_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" },
}
local SKELETON_CONNECTIONS_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" }
}

local function createGuiLine(parent, zIndex)
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Theme.AccentPinkLight
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.ZIndex = zIndex or 2
    line.Parent = parent
    return line
end

local function updateGuiLine(line, p1, p2, thickness, color)
    local diff = p2 - p1
    local dist = diff.Magnitude
    if dist < 1 then line.Visible = false return end
    line.Size = UDim2.new(0, dist, 0, thickness or 1.2)
    line.Position = UDim2.new(0, (p1.X + p2.X) * 0.5, 0, (p1.Y + p2.Y) * 0.5)
    line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
    if color then line.BackgroundColor3 = color end
    line.Visible = true
end

local function createESPForPlayer(p)
    local holder = Instance.new("Folder")
    holder.Name = "ESP_" .. p.Name
    holder.Parent = screenGui
    table.insert(State.cleanUpInstances, holder)

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.ZIndex = 2
    box.Parent = holder
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.AccentPink
    bStroke.Thickness = 1.2
    bStroke.Parent = box

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, 120, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = MainFont
    nameLbl.Text = p.DisplayName
    nameLbl.TextColor3 = Theme.TextWhite
    nameLbl.TextSize = 11.5
    nameLbl.Visible = false
    nameLbl.ZIndex = 3
    nameLbl.Parent = holder

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(0, 60, 0, 14)
    distLbl.BackgroundTransparency = 1
    distLbl.Font = MainFont
    distLbl.Text = "0m"
    distLbl.TextColor3 = Theme.AccentPink
    distLbl.TextSize = 10.5
    distLbl.Visible = false
    distLbl.ZIndex = 3
    distLbl.Parent = holder

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0, 2, 1, 0)
    healthBg.Position = UDim2.new(0, -6, 0, 0)
    healthBg.BackgroundColor3 = Theme.ControlBg
    healthBg.BorderSizePixel = 0
    healthBg.Visible = false
    healthBg.ZIndex = 3
    healthBg.Parent = box

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.BackgroundColor3 = Theme.AccentPink
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 4
    healthFill.Parent = healthBg

    local headDot = Instance.new("Frame")
    headDot.Size = UDim2.new(0, 4, 0, 4)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.BackgroundColor3 = Theme.AccentPinkLight
    headDot.BorderSizePixel = 0
    headDot.Visible = false
    headDot.ZIndex = 5
    headDot.Parent = holder
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    local chamsHighlight = Instance.new("Highlight")
    chamsHighlight.FillColor = Theme.AccentPink
    chamsHighlight.FillTransparency = 0.6
    chamsHighlight.OutlineColor = Theme.AccentPinkLight
    chamsHighlight.OutlineTransparency = 0.1
    chamsHighlight.Enabled = false

    local weapLbl = Instance.new("TextLabel")
    weapLbl.Size = UDim2.new(0, 120, 0, 14)
    weapLbl.BackgroundTransparency = 1
    weapLbl.Font = MainFont
    weapLbl.Text = "Weapon"
    weapLbl.TextColor3 = Theme.AccentPink
    weapLbl.TextSize = 10.5
    weapLbl.Visible = false
    weapLbl.ZIndex = 3
    weapLbl.Parent = holder

    local skeletonLines = {}
    for i = 1, #SKELETON_CONNECTIONS_R15 do
        table.insert(skeletonLines, createGuiLine(holder, 2))
    end
    local tracerLine = createGuiLine(holder, 2)

    espObjects[p] = {
        holder = holder, box = box, nameLbl = nameLbl, distLbl = distLbl, weapLbl = weapLbl,
        healthBg = healthBg, healthFill = healthFill, headDot = headDot,
        highlight = chamsHighlight, skeletonLines = skeletonLines, tracerLine = tracerLine,
        isShown = false
    }
end

local function hideESP(esp)
    if esp.isShown then
        esp.isShown = false
        esp.box.Visible = false
        esp.nameLbl.Visible = false
        esp.distLbl.Visible = false
        esp.headDot.Visible = false
        esp.healthBg.Visible = false
        if esp.weapLbl then esp.weapLbl.Visible = false end
        if esp.highlight then esp.highlight.Enabled = false end
        if esp.skeletonLines then
            for _, line in ipairs(esp.skeletonLines) do line.Visible = false end
        end
        if esp.tracerLine then esp.tracerLine.Visible = false end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESPForPlayer(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then createESPForPlayer(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        espObjects[p].holder:Destroy()
        espObjects[p] = nil
    end
end)

-- ============================================================
-- RENDER LOOP
-- ============================================================
table.insert(State.activeConnections, RunService.RenderStepped:Connect(function(dt)
    if not State.isRunning then return end
    pcall(function()
        if not Config.ESP_Master then
            for _, esp in pairs(espObjects) do hideESP(esp) end
            if espLivePreview then espLivePreview.frame.Visible = false end
            return
        end

        local camPos = Camera.CFrame.Position
        local camLook = Camera.CFrame.LookVector
        local maxDist = tonumber(Config.ESP_MaxDistance) or 500
        local closestPreview = nil
        local closestPreviewDist = math.huge

        for p, esp in pairs(espObjects) do
            local pChar = p.Character
            local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
            local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
            local pHead = pChar and (pChar:FindFirstChild("Head") or pChar:FindFirstChild("HitboxHead"))

            if isEnemyPlayer(p) and pChar and pHum and pRoot and pHead and pHum.Health > 0 then
                local toRoot = pRoot.Position - camPos
                local distStuds = toRoot.Magnitude
                local inFront = toRoot:Dot(camLook) > 0

                if (not inFront) or (distStuds > maxDist) then
                    hideESP(esp)
                else
                    local top3D = pHead.Position + Vector3.new(0, 0.8, 0)
                    local bot3D = pRoot.Position - Vector3.new(0, 2.85, 0)
                    local top2D, tOn = Camera:WorldToViewportPoint(top3D)
                    local bot2D, bOn = Camera:WorldToViewportPoint(bot3D)
                    local head2D, hOn = Camera:WorldToViewportPoint(pHead.Position)
                    local root2D = Camera:WorldToViewportPoint(pRoot.Position)

                    if tOn and bOn and top2D.Z > 0 and bot2D.Z > 0 then
                        esp.isShown = true
                        local boxHeight = math.abs(bot2D.Y - top2D.Y)
                        local boxWidth = boxHeight * 0.65
                        local boxTopY = top2D.Y
                        local boxLeftX = root2D.X - (boxWidth / 2)

                        esp.box.Visible = Config.ESP_Boxes
                        if Config.ESP_Boxes then
                            esp.box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                            esp.box.Position = UDim2.new(0, boxLeftX, 0, boxTopY)
                        end

                        esp.nameLbl.Visible = Config.ESP_Names
                        if Config.ESP_Names then
                            esp.nameLbl.Position = UDim2.new(0, root2D.X - 60, 0, boxTopY - 16)
                        end

                        esp.distLbl.Visible = Config.ESP_Distance
                        if Config.ESP_Distance then
                            esp.distLbl.Text = tostring(math.floor(distStuds * 0.28)) .. "m"
                            esp.distLbl.Position = UDim2.new(0, root2D.X - 30, 0, bot2D.Y + 2)
                        end

                        if Config.ESP_Weapon and esp.weapLbl then
                            esp.weapLbl.Visible = true
                            esp.weapLbl.Position = UDim2.new(0, root2D.X - 60, 0, bot2D.Y + (Config.ESP_Distance and 16 or 2))
                        elseif esp.weapLbl then
                            esp.weapLbl.Visible = false
                        end

                        esp.healthBg.Visible = Config.ESP_HealthBar
                        if Config.ESP_HealthBar then
                            local hpPct = math.clamp(pHum.Health / pHum.MaxHealth, 0, 1)
                            esp.healthFill.Size = UDim2.new(1, 0, hpPct, 0)
                        end

                        esp.headDot.Visible = Config.ESP_HeadDot and hOn and head2D.Z > 0
                        if esp.headDot.Visible then
                            esp.headDot.Position = UDim2.new(0, head2D.X, 0, head2D.Y)
                        end

                        if Config.ESP_Chams then
                            esp.highlight.Enabled = true
                            esp.highlight.Adornee = pChar
                        else
                            esp.highlight.Enabled = false
                        end

                        if distStuds < closestPreviewDist then
                            closestPreviewDist = distStuds
                            closestPreview = { player = p, hum = pHum }
                        end
                    else
                        hideESP(esp)
                    end
                end
            else
                hideESP(esp)
            end
        end

        if espLivePreview then
            if Config.ESP_LivePreview and closestPreview then
                espLivePreview.frame.Visible = true
                local hpPct = math.clamp(closestPreview.hum.Health / closestPreview.hum.MaxHealth, 0, 1)
                espLivePreview.update(closestPreview.player.DisplayName, hpPct, closestPreviewDist * 0.28)
            else
                espLivePreview.frame.Visible = false
            end
        end
    end)
end))

getgenv().UW.espObjects = espObjects
getgenv().UW.espLivePreview = espLivePreview
