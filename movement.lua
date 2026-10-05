-- ============================================================
-- UnnamedWard - Movement
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Config = UW.Config
local LocalPlayer = Services.LocalPlayer
local RunService = Services.RunService
local UserInputService = Services.UserInputService

local Movement = {
    FlyBV = nil, FlyBG = nil, OriginalWalkSpeed = nil,
    InfJumpConn = nil, BhopConn = nil, FreecamActive = false,
}
local _noclipCache = {}
local _noclipActive = false

local function refreshOriginalSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and Movement.OriginalWalkSpeed == nil then
        Movement.OriginalWalkSpeed = hum.WalkSpeed
    end
end

local function stopFly()
    if Movement.FlyBV then pcall(function() Movement.FlyBV:Destroy() end) Movement.FlyBV = nil end
    if Movement.FlyBG then pcall(function() Movement.FlyBG:Destroy() end) Movement.FlyBG = nil end
end

local function startFly()
    stopFly()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "UnnamedWardFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = root
    Movement.FlyBV = bv
    local bg = Instance.new("BodyGyro")
    bg.Name = "UnnamedWardFlyGyro"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 1000
    bg.D = 50
    bg.CFrame = root.CFrame
    bg.Parent = root
    Movement.FlyBG = bg
end

local function applyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            _noclipCache[part] = true
            part.CanCollide = false
        end
    end
end

local function undoNoclip()
    for part in pairs(_noclipCache) do
        if part.Parent then pcall(function() part.CanCollide = true end) end
    end
    table.clear(_noclipCache)
end

local function setupInfiniteJump()
    if Movement.InfJumpConn then Movement.InfJumpConn:Disconnect() Movement.InfJumpConn = nil end
    Movement.InfJumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.isRunning or not Config.InfiniteJump then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    table.insert(State.activeConnections, Movement.InfJumpConn)
end

local _lastBhopJump = 0
local function setupBunnyHop()
    if Movement.BhopConn then Movement.BhopConn:Disconnect() Movement.BhopConn = nil end
    Movement.BhopConn = RunService.Heartbeat:Connect(function()
        if not State.isRunning or not Config.BunnyHop then return end
        if tick() - _lastBhopJump < 0.15 then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
            _lastBhopJump = tick()
        end
    end)
    table.insert(State.activeConnections, Movement.BhopConn)
end

setupInfiniteJump()
setupBunnyHop()

table.insert(State.activeConnections, LocalPlayer.CharacterAdded:Connect(function()
    Movement.OriginalWalkSpeed = nil
    task.wait(0.5)
    refreshOriginalSpeed()
end))
refreshOriginalSpeed()

table.insert(State.activeConnections, RunService.Heartbeat:Connect(function(dt)
    if not State.isRunning then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if hum then
        if Movement.OriginalWalkSpeed == nil then Movement.OriginalWalkSpeed = hum.WalkSpeed end
        hum.WalkSpeed = Config.SpeedHack and Config.SpeedValue or (Movement.OriginalWalkSpeed or 16)
    end

    if Config.FlyHack and root then
        if not Movement.FlyBV or Movement.FlyBV.Parent ~= root then startFly() end
        if Movement.FlyBV then
            local cam = Services.Camera
            local moveDir = Vector3.new(0, 0, 0)
            if hum and hum.MoveDirection.Magnitude > 0 then
                moveDir = cam.CFrame:VectorToWorldSpace(hum.MoveDirection)
            end
            local speed = Config.FlySpeed or 50
            local vertical = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -speed end
            Movement.FlyBV.Velocity = moveDir * speed + Vector3.new(0, vertical, 0)
            if Movement.FlyBG then Movement.FlyBG.CFrame = cam.CFrame end
        end
    elseif Movement.FlyBV then
        stopFly()
    end

    if Config.Noclip then
        if not _noclipActive then _noclipActive = true; applyNoclip() end
    elseif _noclipActive then
        _noclipActive = false
        undoNoclip()
    end
end))

table.insert(State.cleanUpInstances, {
    Destroy = function()
        stopFly()
        if Movement.InfJumpConn then pcall(function() Movement.InfJumpConn:Disconnect() end) end
        if Movement.BhopConn then pcall(function() Movement.BhopConn:Disconnect() end) end
    end
})

getgenv().UW.Movement = Movement
getgenv().UW.stopFly = stopFly
