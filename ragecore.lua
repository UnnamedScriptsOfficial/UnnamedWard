-- ============================================================
-- UnnamedWard - RageCore (Ragebot)
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Players = Services.Players
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local Workspace = Services.Workspace
local isEnemyPlayer = UW.isEnemyPlayer
local isRunning = State.isRunning

local RageCore = {}
do
    local FOVCircle = nil
    pcall(function()
        if Drawing and Drawing.new then
            FOVCircle = Drawing.new("Circle")
            FOVCircle.Visible = false
            FOVCircle.Thickness = 1.4
            FOVCircle.NumSides = 64
            FOVCircle.Transparency = 0.55
            FOVCircle.Color = getgenv().UW.Theme.AccentPink
            FOVCircle.Filled = false
        end
    end)
    RageCore.FOVCircle = FOVCircle

    RageCore.State = { LastShotTick = 0, LastReloadTick = 0, LastFireTick = 0 }
    RageCore.HitboxMultipliers = { Head = 1.75, HitboxHead = 1.75, HitboxHeadSmall = 1.5, UpperTorso = 1.25, LowerTorso = 1.2, Torso = 1.25 }
    RageCore.DefaultValues = { Range = 8192, Penetration = 300, MinDamage = 25, AutoWallFalloff = 0.85, MaxIterations = 6 }

    RageCore.GetHitboxes = function(char, hitscanList)
        local list = {}
        if not char then return list end
        local wanted = hitscanList or {"Head", "Torso"}
        for _, name in ipairs(wanted) do
            if name == "Head" then
                local h = char:FindFirstChild("Head") or char:FindFirstChild("HitboxHead")
                if h then table.insert(list, h) end
            elseif name == "Torso" then
                local t = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                local lt = char:FindFirstChild("LowerTorso")
                if t then table.insert(list, t) end
                if lt then table.insert(list, lt) end
            elseif name == "Arms" then
                for _, n in ipairs({"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Left Arm", "Right Arm"}) do
                    local p = char:FindFirstChild(n)
                    if p then table.insert(list, p) end
                end
            elseif name == "Legs" then
                for _, n in ipairs({"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg"}) do
                    local p = char:FindFirstChild(n)
                    if p then table.insert(list, p) end
                end
            end
        end
        return list
    end

    RageCore.IncrementAmmo = function(tool)
        pcall(function()
            if not tool or not tool:IsA("Tool") then return end
            tool:SetAttribute("Ammo", 9999)
            tool:SetAttribute("MaxAmmo", 9999)
            if tool:FindFirstChild("Ammo") and tool.Ammo:IsA("NumberValue") then
                tool.Ammo.Value = 9999
            end
        end)
    end

    RageCore.FireEvent = function(tool, target, hitPos, silent, autoWall, forceFull)
        pcall(function()
            local rep = Services.ReplicatedStorage
            local rem = rep:FindFirstChild("Remotes")
            if not rem then return end
            local useRemote = rem:FindFirstChild("UseItem") or rem:FindFirstChild("UseItemFeedback")
            if not useRemote then
                for _, sub in ipairs(rem:GetDescendants()) do
                    if sub:IsA("RemoteEvent") and (sub.Name:lower():find("useitem") or sub.Name:lower():find("fire")) then
                        useRemote = sub
                        break
                    end
                end
            end
            if useRemote then
                local args = {}
                if silent and hitPos then table.insert(args, hitPos)
                elseif target then table.insert(args, target.Position) end
                if autoWall then table.insert(args, true) end
                if forceFull then table.insert(args, 999999) end
                useRemote:FireServer(unpack(args))
            end
        end)
    end

    RageCore.ArmorDamageLoss = function(hum, damage)
        if not hum or not hum.Parent then return damage end
        local armor = hum.Parent:GetAttribute("Armor") or 0
        if armor <= 0 then return damage end
        return math.max(1, damage - (armor * 0.15))
    end

    RageCore.DistanceDamageLoss = function(origin, target, damage)
        if not origin or not target then return damage end
        local dist = (origin - target).Magnitude
        if dist <= 50 then return damage end
        local falloff = math.clamp(1 - ((dist - 50) / 1000), 0.35, 1)
        return damage * falloff
    end

    RageCore.AutoWall = function(origin, target, hum, params)
        params = params or {}
        local maxIter = params.MaxIterations or RageCore.DefaultValues.MaxIterations
        local penetration = params.Penetration or RageCore.DefaultValues.Penetration
        local Config = getgenv().UW.Config
        local minDmg = params.MinDamage or Config.Rage_MinimumDamage or 25
        local currentDamage = params.Damage or 100
        local finalPos = target
        for i = 1, maxIter do
            local currentDamageAfterArmor = RageCore.ArmorDamageLoss(hum, currentDamage)
            local currentDamageAfterDist = RageCore.DistanceDamageLoss(origin, finalPos, currentDamageAfterArmor)
            if currentDamageAfterDist >= minDmg then break end
            local dir = (finalPos - origin).Unit
            finalPos = finalPos + dir * math.min(penetration / maxIter, 50)
            currentDamage = currentDamage * RageCore.DefaultValues.AutoWallFalloff
        end
        return finalPos, currentDamage
    end

    RageCore.ShootTarget = function(tool, target, hum, opts)
        opts = opts or {}
        local silent = opts.Silent ~= false
        local autoWall = opts.AutoWall == true
        local forceFull = opts.ForceFull == true
        local origin = Camera.CFrame.Position
        if not target then return end
        local finalPos = target.Position
        if autoWall and hum then
            finalPos = RageCore.AutoWall(origin, target.Position, hum, {
                MinimumDamage = opts.MinimumDamage or getgenv().UW.Config.Rage_MinimumDamage,
                Penetration = opts.Penetration or RageCore.DefaultValues.Penetration,
                Damage = forceFull and 200 or 100,
            })
        end
        if not silent then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, finalPos)
        end
        RageCore.FireEvent(tool, target, silent and finalPos or nil, silent, autoWall, forceFull)
        RageCore.State.LastShotTick = tick()
    end

    RageCore.Start = function(dt)
        if not getgenv().UW.State.isRunning then return end
        local Config = getgenv().UW.Config
        local Theme = getgenv().UW.Theme

        if RageCore.FOVCircle then
            local mousePos = Services.UserInputService:GetMouseLocation()
            RageCore.FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
            RageCore.FOVCircle.Radius = Config.Legit_FOV or 242
            RageCore.FOVCircle.Visible = (Config.Legit_UseFOV == true) and (Config.Rage_Ragebot_Enabled or Config.Legit_Aimbot_Enabled or Config.Legit_SilentAim_Enabled)
            RageCore.FOVCircle.Color = Theme.AccentPink
        end

        if not Config.Rage_Ragebot_Enabled then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        local bestTarget, bestTargetPart, bestHum, bestDist = nil, nil, nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pChar = p.Character
                local pHum = pChar:FindFirstChildOfClass("Humanoid")
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pHum and pRoot and pHum.Health > 0 and isEnemyPlayer(p) then
                    local hitboxes = RageCore.GetHitboxes(pChar, Config.Rage_Hitscan)
                    for _, hb in ipairs(hitboxes) do
                        local dist = (hb.Position - root.Position).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            bestTarget = p
                            bestTargetPart = hb
                            bestHum = pHum
                        end
                    end
                end
            end
        end

        if not bestTarget or not bestTargetPart then return end

        if Config.Rage_ForceHeadshot then
            local head = bestTarget.Character:FindFirstChild("Head") or bestTarget.Character:FindFirstChild("HitboxHead")
            if head then bestTargetPart = head end
        end

        local now = tick()
        local cooldown = Config.Rage_RapidFire and 0.05 or 0.12
        if now - RageCore.State.LastFireTick < cooldown then return end
        RageCore.State.LastFireTick = now

        RageCore.ShootTarget(tool, bestTargetPart, bestHum, {
            Silent = Config.Rage_SilentAim ~= false,
            AutoWall = Config.Rage_AutoWall == true,
            ForceFull = Config.Rage_ForceFullDamage == true,
            MinimumDamage = Config.Rage_MinimumDamage,
        })

        if Config.Rage_RapidFire or Config.Rage_DoubleTap then
            RageCore.IncrementAmmo(tool)
        end
    end
end

getgenv().UW.RageCore = RageCore
