-- ============================================================
-- UnnamedWard - Aim (Silent + Camera Aimbot + Triggerbot)
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Config = UW.Config
local Camera = Services.Camera
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local LocalPlayer = Services.LocalPlayer
local getClosestTarget = UW.getClosestTarget
local isTeammate = UW.isTeammate
local ShowNotification = UW.ShowNotification

local isSilentKeyDown = false
local isAimbotKeyDown = false

-- Keybinding
table.insert(State.activeConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.AimbotKey or input.KeyCode == Config.AimbotKey then
        isAimbotKeyDown = true
    elseif input.KeyCode == Config.SilentKey then
        if Config.SilentKeyMode == "Toggle" then
            Config.SilentAim = not Config.SilentAim
            ShowNotification("UnnamedWard", "Silent Aim: " .. (Config.SilentAim and "ON" or "OFF"), "INFO", 1.5)
        elseif Config.SilentKeyMode == "Hold" then
            isSilentKeyDown = true
        end
    end
end))
table.insert(State.activeConnections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AimbotKey or input.KeyCode == Config.AimbotKey then
        isAimbotKeyDown = false
    elseif input.KeyCode == Config.SilentKey then
        if Config.SilentKeyMode == "Hold" then isSilentKeyDown = false end
    end
end))

-- ============================================================
-- SILENT AIM (namecall hook)
-- ============================================================
local function getSilentTargetSafe()
    if not Config.Legit_SilentAim_Enabled and not Config.SilentAim then return nil end
    if Config.SilentKeyMode == "Hold" and not isSilentKeyDown then return nil end
    return getClosestTarget(
        Config.Legit_FOV or Config.SilentFOV,
        Config.SilentVisibleOnly,
        Config.Legit_Hitscan or Config.SilentTargetPart,
        "Closest"
    )
end

if getgenv().UnnamedWardRawNamecall then
    pcall(function() hookmetamethod(game, "__namecall", getgenv().UnnamedWardRawNamecall) end)
    getgenv().UnnamedWardRawNamecall = nil
end

if not State.originalNamecall and hookmetamethod and getnamecallmethod then
    local hookOk, hookErr = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist")
                and (Config.Legit_SilentAim_Enabled or Config.SilentAim) then

                local args = table.pack(...)
                local originVec, directionVec
                if method == "Raycast" then
                    if typeof(args[1]) == "Vector3" then originVec = args[1] end
                    if typeof(args[2]) == "Vector3" then directionVec = args[2] end
                else
                    if typeof(args[1]) == "Ray" then
                        originVec = args[1].Origin
                        directionVec = args[1].Direction
                    end
                end

                local nearCamera = originVec and (originVec - Camera.CFrame.Position).Magnitude < 8
                local aligned = directionVec and directionVec.Magnitude > 0
                    and directionVec.Unit:Dot(Camera.CFrame.LookVector) > 0.7

                if nearCamera and aligned then
                    local roll = math.random(1, 100)
                    if roll <= (Config.Legit_SilentAim_HitChance or Config.SilentHitChance or 78) then
                        local target = getSilentTargetSafe()
                        if target then
                            if method == "Raycast" then
                                local origin, direction, params = table.unpack(args, 1, args.n)
                                if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                                    local newDir = target.Position - origin
                                    return oldNamecall(self, origin, newDir, params)
                                end
                            elseif method == "FindPartOnRay" then
                                local ray, ignore = table.unpack(args, 1, args.n)
                                if ray and ray.Origin then
                                    local newDir = target.Position - ray.Origin
                                    return oldNamecall(self, Ray.new(ray.Origin, newDir), ignore)
                                end
                            elseif method == "FindPartOnRayWithIgnoreList" then
                                local ray, list, extra = table.unpack(args, 1, args.n)
                                if ray and ray.Origin then
                                    local newDir = target.Position - ray.Origin
                                    return oldNamecall(self, Ray.new(ray.Origin, newDir), list, extra)
                                end
                            elseif method == "FindPartOnRayWithWhitelist" then
                                local ray, list, extra = table.unpack(args, 1, args.n)
                                if ray and ray.Origin then
                                    local newDir = target.Position - ray.Origin
                                    return oldNamecall(self, Ray.new(ray.Origin, newDir), list, extra)
                                end
                            end
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        if oldNamecall then
            State.originalNamecall = oldNamecall
            getgenv().UnnamedWardRawNamecall = oldNamecall
        end
    end)
    if not hookOk then
        warn("[UnnamedWard] Silent aim hook unavailable: " .. tostring(hookErr))
    end
end

-- ============================================================
-- CAMERA AIMBOT
-- ============================================================
table.insert(State.activeConnections, RunService.RenderStepped:Connect(function(dt)
    if not State.isRunning then return end
    if not Config.Legit_Aimbot_Enabled and not Config.Aimbot then return end

    local keyHeld = false
    if Config.AimbotKeyMode == "Hold" then
        if typeof(Config.AimbotKey) == "EnumItem" then
            if Config.AimbotKey.EnumType == Enum.UserInputType then
                keyHeld = UserInputService:IsMouseButtonPressed(Config.AimbotKey)
            else
                keyHeld = UserInputService:IsKeyDown(Config.AimbotKey)
            end
        end
    elseif Config.AimbotKeyMode == "Toggle" then
        keyHeld = isAimbotKeyDown
    else
        keyHeld = true
    end
    if not keyHeld then return end

    local target = getClosestTarget(
        Config.AimbotFOV or Config.Legit_FOV,
        Config.AimbotVisibleOnly and not Config.TrackThroughWalls,
        Config.AimbotPart or "Closest",
        "Closest"
    )
    if not target then return end

    local speed = Config.InstantCameraLock and 1 or math.clamp(1 - (Config.AimbotSmoothing or 0.28), 0.01, 1)
    local cur = Camera.CFrame
    local goal = CFrame.lookAt(cur.Position, target.Position)
    Camera.CFrame = cur:Lerp(goal, speed)
end))

-- ============================================================
-- TRIGGERBOT
-- ============================================================
table.insert(State.activeConnections, RunService.RenderStepped:Connect(function()
    if not State.isRunning then return end
    if not Config.Legit_Triggerbot_Enabled then return end
    local isHeld = false
    if Config.Legit_Triggerbot_Mode == "Hold" then
        isHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService:IsKeyDown(Config.Legit_Triggerbot_Bind)
    else
        isHeld = true
    end
    if isHeld then
        local target = getClosestTarget(5, true, Config.Legit_Hitscan, "Distance")
        if target and not isTeammate(target) then
            pcall(function() if mouse1click then mouse1click() end end)
        end
    end
end))

getgenv().UW.isAimbotKeyDown = function() return isAimbotKeyDown end
getgenv().UW.isSilentKeyDown = function() return isSilentKeyDown end
getgenv().UW.getSilentTargetSafe = getSilentTargetSafe
