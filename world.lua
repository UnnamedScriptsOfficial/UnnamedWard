-- ============================================================
-- UnnamedWard - World / View (Fog, FOV, Third Person, Freecam)
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Config = UW.Config
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local Lighting = Services.Lighting
local UserInputService = Services.UserInputService
local RunService = Services.RunService

local OriginalFog = { End = Lighting.FogEnd, Start = Lighting.FogStart }

table.insert(State.activeConnections, RunService.RenderStepped:Connect(function()
    if not State.isRunning then return end
    if Config.NoFog then
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
    else
        Lighting.FogEnd = OriginalFog.End
        Lighting.FogStart = OriginalFog.Start
    end
    if Camera and Config.CustomFOV then
        Camera.FieldOfView = Config.FOVValue
    end
    if Config.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
    end
end))

-- Third person + freecam
local FreecamInputs = { W=false, A=false, S=false, D=false, Q=false, E=false, Shift=false }

table.insert(State.activeConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not Config.Freecam then return end
    if input.KeyCode == Enum.KeyCode.W then FreecamInputs.W = true
    elseif input.KeyCode == Enum.KeyCode.A then FreecamInputs.A = true
    elseif input.KeyCode == Enum.KeyCode.S then FreecamInputs.S = true
    elseif input.KeyCode == Enum.KeyCode.D then FreecamInputs.D = true
    elseif input.KeyCode == Enum.KeyCode.Q then FreecamInputs.Q = true
    elseif input.KeyCode == Enum.KeyCode.E then FreecamInputs.E = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then FreecamInputs.Shift = true
    end
end))
table.insert(State.activeConnections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then FreecamInputs.W = false
    elseif input.KeyCode == Enum.KeyCode.A then FreecamInputs.A = false
    elseif input.KeyCode == Enum.KeyCode.S then FreecamInputs.S = false
    elseif input.KeyCode == Enum.KeyCode.D then FreecamInputs.D = false
    elseif input.KeyCode == Enum.KeyCode.Q then FreecamInputs.Q = false
    elseif input.KeyCode == Enum.KeyCode.E then FreecamInputs.E = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then FreecamInputs.Shift = false
    end
end))

table.insert(State.activeConnections, RunService.RenderStepped:Connect(function(dt)
    if not State.isRunning then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.ThirdPerson then
            hum.CameraOffset = Vector3.new(0, 0, Config.ThirdPersonDist or 12)
        elseif hum.CameraOffset.Magnitude > 0 then
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end
    end

    if Config.Freecam then
        if Camera.CameraType ~= Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Scriptable
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
        local move = Vector3.new(0, 0, 0)
        if FreecamInputs.W then move = move + Camera.CFrame.LookVector end
        if FreecamInputs.S then move = move - Camera.CFrame.LookVector end
        if FreecamInputs.A then move = move - Camera.CFrame.RightVector end
        if FreecamInputs.D then move = move + Camera.CFrame.RightVector end
        if FreecamInputs.E then move = move + Vector3.new(0, 1, 0) end
        if FreecamInputs.Q then move = move - Vector3.new(0, 1, 0) end
        local speed = (Config.FreecamSpeed or 40) * (FreecamInputs.Shift and 2 or 1)
        if move.Magnitude > 0 then
            Camera.CFrame = Camera.CFrame + move.Unit * speed * dt
        end
    else
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end))

getgenv().UW.FreecamInputs = FreecamInputs
