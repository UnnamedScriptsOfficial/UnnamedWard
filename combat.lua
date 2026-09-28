local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    ESP = { Enabled = true, Rainbow = true, Thickness = 1.5, CornerLength = 8, ShowNames = true, ShowDistance = true, ShowHealth = true },
    Tracker = { Enabled = true, Rainbow = true, Thickness = 1.5 },
    Aimbot = { Enabled = true, Key = Enum.UserInputType.MouseButton2, FOV = 150, Smoothness = 0.15, CheckVisibility = true, ShowFOV = true },
    Misc = { TeamCheck = false, Crosshair = true }
}

local ESP_Objects = {}

local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Thickness = 1
FOV_Circle.NumSides = 60
FOV_Circle.Filled = false
FOV_Circle.Visible = false

local CrosshairH = Drawing.new("Line")
CrosshairH.Thickness = 1
CrosshairH.Color = Color3.fromRGB(255, 255, 255)
CrosshairH.Visible = false

local CrosshairV = Drawing.new("Line")
CrosshairV.Thickness = 1
CrosshairV.Color = Color3.fromRGB(255, 255, 255)
CrosshairV.Visible = false

local function GetRainbow()
    return Color3.fromHSV((tick() / 4) % 1, 1, 1)
end

local function GetBoundingBox(Character)
    local Head = Character:FindFirstChild("Head")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Head or not HRP then return nil end

    local headPos, headOnScreen = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(HRP.Position - Vector3.new(0, 3, 0))

    if not headOnScreen or not rootOnScreen then return nil end

    local height = math.abs(headPos.Y - rootPos.Y)
    local width = height * 0.6

    return {
        TopLeft = Vector2.new(headPos.X - width / 2, headPos.Y),
        TopRight = Vector2.new(headPos.X + width / 2, headPos.Y),
        BottomLeft = Vector2.new(rootPos.X - width / 2, rootPos.Y),
        BottomRight = Vector2.new(rootPos.X + width / 2, rootPos.Y),
        Center = Vector2.new(headPos.X, (headPos.Y + rootPos.Y) / 2),
        Distance = math.floor((Camera.CFrame.Position - HRP.Position).Magnitude),
        Head = Head
    }
end

local function IsVisible(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    return not result
end

local function HideAllESPObjects(obj)
    obj.TL1.Visible = false; obj.TL2.Visible = false
    obj.TR1.Visible = false; obj.TR2.Visible = false
    obj.BL1.Visible = false; obj.BL2.Visible = false
    obj.BR1.Visible = false; obj.BR2.Visible = false
    obj.Name.Visible = false
    obj.Distance.Visible = false
    obj.HealthBg.Visible = false
    obj.HealthBar.Visible = false
    obj.Tracker.Visible = false
end

local function InitPlayer(Player)
    if Player == LocalPlayer then return end
    ESP_Objects[Player] = {
        TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"),
        TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
        BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"),
        BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line"),
        Tracker = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        HealthBg = Drawing.new("Line"),
    }
    for _, line in pairs(ESP_Objects[Player]) do
        if line.Thickness then line.Thickness = 1.5 end
        line.Visible = false
    end
    ESP_Objects[Player].Name.Size = 12
    ESP_Objects[Player].Name.Center = true
    ESP_Objects[Player].Name.Outline = true
    ESP_Objects[Player].Distance.Size = 11
    ESP_Objects[Player].Distance.Center = true
    ESP_Objects[Player].Distance.Outline = true
end

local function CleanupPlayer(Player)
    if ESP_Objects[Player] then
        for _, line in pairs(ESP_Objects[Player]) do line:Remove() end
        ESP_Objects[Player] = nil
    end
end

Players.PlayerAdded:Connect(InitPlayer)
Players.PlayerRemoving:Connect(CleanupPlayer)
for _, p in ipairs(Players:GetPlayers()) do InitPlayer(p) end

RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local color = Config.ESP.Rainbow and GetRainbow() or Color3.fromRGB(255, 255, 255)
    local aimTarget = nil
    local closestDist = Config.Aimbot.FOV

    if Config.Aimbot.ShowFOV then
        FOV_Circle.Position = screenCenter
        FOV_Circle.Radius = Config.Aimbot.FOV
        FOV_Circle.Color = color
        FOV_Circle.Visible = true
    else
        FOV_Circle.Visible = false
    end

    if Config.Misc.Crosshair then
        CrosshairH.From = screenCenter + Vector2.new(-5, 0)
        CrosshairH.To = screenCenter + Vector2.new(5, 0)
        CrosshairH.Visible = true
        CrosshairV.From = screenCenter + Vector2.new(0, -5)
        CrosshairV.To = screenCenter + Vector2.new(0, 5)
        CrosshairV.Visible = true
    else
        CrosshairH.Visible = false
        CrosshairV.Visible = false
    end

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and ESP_Objects[Player] then
            local Character = Player.Character
            local obj = ESP_Objects[Player]
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

            if Config.Misc.TeamCheck and Player.Team == LocalPlayer.Team then
                HideAllESPObjects(obj)
                continue
            end

            local bbox = nil
            if Character and humanoid and humanoid.Health > 0 then
                bbox = GetBoundingBox(Character)
            end

            if bbox then
                if Config.ESP.Enabled then
                    local cLen = Config.ESP.CornerLength
                    local tl, tr, bl, br = bbox.TopLeft, bbox.TopRight, bbox.BottomLeft, bbox.BottomRight
                    
                    local corners = {
                        {obj.TL1, tl, tl + Vector2.new(cLen, 0)}, {obj.TL2, tl, tl + Vector2.new(0, cLen)},
                        {obj.TR1, tr, tr - Vector2.new(cLen, 0)}, {obj.TR2, tr, tr + Vector2.new(0, cLen)},
                        {obj.BL1, bl, bl + Vector2.new(cLen, 0)}, {obj.BL2, bl, bl - Vector2.new(0, cLen)},
                        {obj.BR1, br, br - Vector2.new(cLen, 0)}, {obj.BR2, br, br - Vector2.new(0, cLen)},
                    }
                    for _, c in ipairs(corners) do
                        c[1].From = c[2]; c[1].To = c[3]; c[1].Color = color; c[1].Visible = true
                    end

                    if Config.ESP.ShowNames then
                        obj.Name.Text = Player.Name
                        obj.Name.Position = Vector2.new(bbox.Center.X, bbox.TopLeft.Y - 15)
                        obj.Name.Color = color
                        obj.Name.Visible = true
                    else
                        obj.Name.Visible = false
                    end

                    if Config.ESP.ShowDistance then
                        obj.Distance.Text = "[" .. bbox.Distance .. "m]"
                        obj.Distance.Position = Vector2.new(bbox.Center.X, bbox.BottomLeft.Y + 5)
                        obj.Distance.Color = color
                        obj.Distance.Visible = true
                    else
                        obj.Distance.Visible = false
                    end

                    if Config.ESP.ShowHealth then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        obj.HealthBg.From = bbox.BottomLeft - Vector2.new(5, 0)
                        obj.HealthBg.To = bbox.TopLeft - Vector2.new(5, 0)
                        obj.HealthBg.Thickness = 3
                        obj.HealthBg.Color = Color3.fromRGB(0, 0, 0)
                        obj.HealthBg.Visible = true
                        
                        local healthHeight = (bbox.BottomLeft.Y - bbox.TopLeft.Y) * healthPercent
                        obj.HealthBar.From = bbox.BottomLeft - Vector2.new(5, 0)
                        obj.HealthBar.To = Vector2.new(bbox.TopLeft.X - 5, bbox.BottomLeft.Y - healthHeight)
                        obj.HealthBar.Thickness = 2
                        obj.HealthBar.Color = Color3.fromRGB(255, 0, 0) * (1 - healthPercent) + Color3.fromRGB(0, 255, 0) * healthPercent
                        obj.HealthBar.Visible = true
                    else
                        obj.HealthBg.Visible = false
                        obj.HealthBar.Visible = false
                    end
                else
                    obj.TL1.Visible = false; obj.TL2.Visible = false
                    obj.TR1.Visible = false; obj.TR2.Visible = false
                    obj.BL1.Visible = false; obj.BL2.Visible = false
                    obj.BR1.Visible = false; obj.BR2.Visible = false
                    obj.Name.Visible = false
                    obj.Distance.Visible = false
                    obj.HealthBg.Visible = false
                    obj.HealthBar.Visible = false
                end

                if Config.Tracker.Enabled then
                    obj.Tracker.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                    obj.Tracker.To = bbox.Center
                    obj.Tracker.Color = color
                    obj.Tracker.Visible = true
                else
                    obj.Tracker.Visible = false
                end

                if Config.Aimbot.Enabled then
                    local dist = (bbox.Center - screenCenter).Magnitude
                    if dist < closestDist then
                        local isVisible = true
                        if Config.Aimbot.CheckVisibility then
                            isVisible = IsVisible(bbox.Head)
                        end
                        
                        if isVisible then
                            closestDist = dist
                            aimTarget = bbox.Head
                        end
                    end
                end
            else
                HideAllESPObjects(obj)
            end
        end
    end

    if aimTarget and UserInputService:IsMouseButtonPressed(Config.Aimbot.Key) then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Config.Aimbot.Smoothness)
    end
end)
