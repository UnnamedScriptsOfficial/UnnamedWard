-- ============================================================
-- UnnamedWard - Targeting utilities
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local Players = Services.Players
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace
local isInLobby = UW.isInLobby
local isEnemyPlayer = UW.isEnemyPlayer

local TargetVis = {
    staticRayParams = nil,
    cachedEnemies = {},
    lastEnemyUpdateTime = 0,
    targetCache = {},
}

local function getEnemyPlayers()
    local now = tick()
    if (now - TargetVis.lastEnemyUpdateTime < 0.15) and (#TargetVis.cachedEnemies > 0) then
        return TargetVis.cachedEnemies
    end
    table.clear(TargetVis.cachedEnemies)
    local inLobby = isInLobby()
    local Config = getgenv().UW.Config
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if inLobby then
                if Config.ESP_Lobby then table.insert(TargetVis.cachedEnemies, p) end
            else
                if isEnemyPlayer(p) then table.insert(TargetVis.cachedEnemies, p) end
            end
        end
    end
    TargetVis.lastEnemyUpdateTime = now
    return TargetVis.cachedEnemies
end

local function getClosestTarget(maxFOV, checkVisible, partMode, targetPriority)
    local Config = getgenv().UW.Config
    local now = tick()
    local cacheKey = tostring(maxFOV) .. "_" .. tostring(checkVisible) .. "_" .. tostring(partMode)
        .. "_" .. tostring(Config.TeamCheck) .. "_" .. tostring(Config.ESP_Lobby) .. "_" .. tostring(isInLobby())
    local cached = TargetVis.targetCache[cacheKey]
    if cached and (now - cached.time < 0.06) and cached.target and cached.target.Parent then
        return cached.target
    end

    if not TargetVis.staticRayParams then
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.IgnoreWater = true
        TargetVis.staticRayParams = p
    end

    local closest, closestScore = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    local is360 = (maxFOV == nil) or (maxFOV >= 999)

    TargetVis.staticRayParams.FilterDescendantsInstances = {myChar, Camera}

    for _, p in ipairs(getEnemyPlayers()) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if char and hum and hum.Health > 0 and rootPart then
            local toRoot = rootPart.Position - camPos
            if is360 or toRoot:Dot(camLook) > -5 then
                local headCandidate = char:FindFirstChild("Head") or char:FindFirstChild("HitboxHead")
                local bodyCandidate = char:FindFirstChild("UpperTorso") or rootPart
                local hitPart = nil

                if partMode == "Head" then
                    hitPart = headCandidate or bodyCandidate
                elseif partMode == "Body" or partMode == "Torso" then
                    hitPart = bodyCandidate or headCandidate
                elseif partMode == "Closest" then
                    if headCandidate and bodyCandidate then
                        local hScr, hOn = Camera:WorldToViewportPoint(headCandidate.Position)
                        local bScr, bOn = Camera:WorldToViewportPoint(bodyCandidate.Position)
                        if hOn and bOn then
                            local hDist = (Vector2.new(hScr.X, hScr.Y) - mousePos).Magnitude
                            local bDist = (Vector2.new(bScr.X, bScr.Y) - mousePos).Magnitude
                            hitPart = (hDist <= bDist) and headCandidate or bodyCandidate
                        else
                            hitPart = headCandidate
                        end
                    else
                        hitPart = headCandidate or bodyCandidate
                    end
                else
                    hitPart = headCandidate or bodyCandidate
                end

                if hitPart then
                    local inRange = false
                    local score = math.huge
                    if is360 then
                        local worldDist = myRoot and (hitPart.Position - myRoot.Position).Magnitude or (hitPart.Position - camPos).Magnitude
                        if worldDist <= (maxFOV or math.huge) then
                            inRange = true
                            score = worldDist
                        end
                    else
                        local scrPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
                        if onScreen and scrPos.Z > 0 then
                            local fovDist = (Vector2.new(scrPos.X, scrPos.Y) - mousePos).Magnitude
                            if fovDist <= (maxFOV or math.huge) then
                                inRange = true
                                score = fovDist
                            end
                        end
                    end

                    if inRange and score < closestScore then
                        if checkVisible then
                            local dir = hitPart.Position - camPos
                            local res = Workspace:Raycast(camPos, dir, TargetVis.staticRayParams)
                            if not res or res.Instance:IsDescendantOf(char) then
                                closest = hitPart
                                closestScore = score
                            end
                        else
                            closest = hitPart
                            closestScore = score
                        end
                    end
                end
            end
        end
    end

    TargetVis.targetCache[cacheKey] = { target = closest, time = now }
    return closest
end

-- Periodic cleanup
task.spawn(function()
    while getgenv().UW.State.isRunning do
        task.wait(8)
        for k in pairs(TargetVis.targetCache) do
            TargetVis.targetCache[k] = nil
        end
    end
end)

getgenv().UW.TargetVis = TargetVis
getgenv().UW.getEnemyPlayers = getEnemyPlayers
getgenv().UW.getClosestTarget = getClosestTarget
