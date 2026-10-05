-- ============================================================
-- UnnamedWard - Extras (Tracers, AntiAim, Knifebot, AutoPickup, etc)
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Config = UW.Config
local Theme = UW.Theme
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local Workspace = Services.Workspace
local Players = Services.Players
local RunService = Services.RunService
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local isEnemyPlayer = UW.isEnemyPlayer
local getClosestTarget = UW.getClosestTarget

-- ============================================================
-- ANTI-AIM
-- ============================================================
local aaSpinAngle = 0
local _aaOriginalHipHeight = nil

table.insert(State.activeConnections, RunService.Heartbeat:Connect(function(dt)
    if not State.isRunning or not Config.Rage_AntiAim_Enabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if _aaOriginalHipHeight == nil then _aaOriginalHipHeight = hum.HipHeight end
    if Config.Rage_FakeDuck then
        hum.HipHeight = _aaOriginalHipHeight - 3
    else
        hum.HipHeight = _aaOriginalHipHeight
    end
    local yaw = 0
    if Config.Rage_YawBase == "Spin" then
        aaSpinAngle = aaSpinAngle + (Config.Rage_SpinSpeed or 10) * dt * 50
        yaw = math.rad(aaSpinAngle % 360)
    elseif Config.Rage_YawBase == "Random" then
        yaw = math.rad(math.random(-180, 180))
    else
        yaw = math.rad(180)
    end
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
end))

-- ============================================================
-- KNIFE BOT
-- ============================================================
table.insert(State.activeConnections, RunService.Heartbeat:Connect(function()
    if not State.isRunning or not Config.Rage_Knifebot_Enabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not root or not tool then return end
    if not tool.Name:lower():find("knife") then return end
    local radius = Config.Rage_Knifebot_Radius or 12
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and isEnemyPlayer(p) then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            if pr and (pr.Position - root.Position).Magnitude <= radius then
                pcall(function() tool:Activate() end)
                break
            end
        end
    end
end))

-- ============================================================
-- AUTO PICKUP
-- ============================================================
table.insert(State.activeConnections, RunService.Heartbeat:Connect(function()
    if not State.isRunning or not Config.AutoPickup then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local radius = Config.PickupRadius or 25
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    params.MaxParts = 20
    local parts = Workspace:GetPartBoundsInRadius(root.Position, radius, params)
    for _, handle in ipairs(parts) do
        local tool = handle.Parent
        if tool and tool:IsA("Tool") and tool.Parent ~= char then
            pcall(function()
                if firetouchinterest then
                    firetouchinterest(root, handle, 0)
                    firetouchinterest(root, handle, 1)
                end
            end)
        end
    end
end))

-- ============================================================
-- BULLET TRACERS
-- ============================================================
local Tracers = { Container = nil }
do
    local function ensureContainer()
        if Tracers.Container and Tracers.Container.Parent then return Tracers.Container end
        local folder = Instance.new("Folder")
        folder.Name = "UnnamedWardTracers"
        folder.Parent = Workspace
        Tracers.Container = folder
        return folder
    end
    local function spawnTracer(from, to)
        local folder = ensureContainer()
        local dist = (to - from).Magnitude
        if dist < 0.5 then return end
        local beam = Instance.new("Part")
        beam.Anchored = true
        beam.CanCollide = false
        beam.Material = Enum.Material.Neon
        beam.Color = Theme.AccentPink
        beam.Size = Vector3.new(0.08, 0.08, dist)
        beam.CFrame = CFrame.lookAt((from + to) / 2, to)
        beam.Parent = folder
        TweenService:Create(beam, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {Transparency = 1}):Play()
        task.delay(0.36, function() if beam and beam.Parent then beam:Destroy() end end)
    end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if rem then
        for _, sub in ipairs(rem:GetDescendants()) do
            if sub:IsA("RemoteEvent") and (sub.Name:lower():find("useitem") or sub.Name:lower():find("fire")) then
                sub.OnClientEvent:Connect(function(...)
                    if not State.isRunning or not Config.BulletTracers then return end
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local mouse = LocalPlayer:GetMouse()
                    if mouse and mouse.Hit then
                        spawnTracer(root.Position, mouse.Hit.Position)
                    end
                end)
                break
            end
        end
    end
end
table.insert(State.cleanUpInstances, {
    Destroy = function()
        if Tracers.Container and Tracers.Container.Parent then
            pcall(function() Tracers.Container:Destroy() end)
        end
    end
})

-- ============================================================
-- RAINBOW GUN SKIN
-- ============================================================
table.insert(State.activeConnections, RunService.Heartbeat:Connect(function()
    if not State.isRunning or not Config.RainbowGunSkin then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local hue = (tick() * 0.15) % 1
    local color = Color3.fromHSV(hue, 0.55, 1)
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.Color = color end)
        end
    end
end))

-- ============================================================
-- TARGET VISUALIZER PATH
-- ============================================================
local TargetVisLine = nil
pcall(function()
    if Drawing and Drawing.new then
        TargetVisLine = Drawing.new("Line")
        TargetVisLine.Visible = false
        TargetVisLine.Thickness = 1.5
        TargetVisLine.Color = Theme.AccentPink
        TargetVisLine.Transparency = 0.85
    end
end)
table.insert(State.cleanUpInstances, {
    Destroy = function()
        if TargetVisLine then pcall(function() TargetVisLine:Remove() end) end
    end
})

table.insert(State.activeConnections, RunService.RenderStepped:Connect(function()
    if not State.isRunning or not TargetVisLine then return end
    if not Config.TargetVisualizer or not Config.TargetVisualizerPath then
        TargetVisLine.Visible = false
        return
    end
    local target = getClosestTarget(9999, false, "Closest", "Closest")
    if not target then TargetVisLine.Visible = false return end
    local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
    if not onScreen or screenPos.Z <= 0 then TargetVisLine.Visible = false return end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    TargetVisLine.From = center
    TargetVisLine.To = Vector2.new(screenPos.X, screenPos.Y)
    TargetVisLine.Visible = true
end))

getgenv().UW.Tracers = Tracers
