-- ============================================================
-- UnnamedWard - Lobby / Team Helpers
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Players = Services.Players
local LocalPlayer = Services.LocalPlayer
local hideFromStack = UW.hideFromStack

local LOBBY_CENTER = Vector3.new(109, -680, 1184)

local function isInLobby()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    return (root.Position - LOBBY_CENTER).Magnitude < 450
end

local function isTeammate(p)
    if not p then return false end
    if p == LocalPlayer then return true end
    local pl = nil
    if typeof(p) == "Instance" then
        if p:IsA("Player") then
            pl = p
        elseif LocalPlayer.Character and (p == LocalPlayer.Character or p:IsDescendantOf(LocalPlayer.Character)) then
            return true
        else
            pl = Players:GetPlayerFromCharacter(p:IsA("Model") and p or p:FindFirstAncestorOfClass("Model"))
        end
    end
    if pl and LocalPlayer.Team and pl.Team and LocalPlayer.Team == pl.Team then return true end
    if pl then
        local myT = LocalPlayer:GetAttribute("TeamID") or LocalPlayer:GetAttribute("Team")
        local theirT = pl:GetAttribute("TeamID") or pl:GetAttribute("Team")
        if myT ~= nil and theirT ~= nil and myT == theirT then return true end
    end
    return false
end
hideFromStack(isTeammate)

local function isEnemyPlayer(p)
    if not p or p == LocalPlayer then return false end
    local Config = getgenv().UW.Config
    if isInLobby() then return Config and Config.ESP_Lobby == true end
    if isTeammate(p) then return false end
    if Config and Config.ESP_EnemyOnly and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then
        return false
    end
    return true
end
hideFromStack(isEnemyPlayer)

getgenv().UW.isInLobby = isInLobby
getgenv().UW.isTeammate = isTeammate
getgenv().UW.isEnemyPlayer = isEnemyPlayer
getgenv().UW.LOBBY_CENTER = LOBBY_CENTER
