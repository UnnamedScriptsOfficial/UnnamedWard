-- ============================================================
-- UnnamedWard - Services & Shared State
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Services = {}
Services.Players           = game:GetService("Players")
Services.Workspace         = game:GetService("Workspace")
Services.RunService        = game:GetService("RunService")
Services.UserInputService  = game:GetService("UserInputService")
Services.ContextActionService = game:GetService("ContextActionService")
Services.TweenService      = game:GetService("TweenService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.HttpService       = game:GetService("HttpService")
Services.TeleportService   = game:GetService("TeleportService")
Services.Lighting          = game:GetService("Lighting")
Services.SoundService      = game:GetService("SoundService")
Services.CoreGui           = game:GetService("CoreGui")
Services.PathfindingService= game:GetService("PathfindingService")
Services.VirtualInputManager = game:GetService("VirtualInputManager")

Services.LocalPlayer = Services.Players.LocalPlayer
Services.Camera      = Services.Workspace.CurrentCamera

local PlayerGui
pcall(function()
    PlayerGui = Services.LocalPlayer:WaitForChild("PlayerGui", 5)
end)
Services.PlayerGui = PlayerGui

-- Shared state
local State = {
    isRunning = true,
    activeConnections = {},
    cleanUpInstances = {},
    originalNamecall = nil,
    originalUtilityRaycast = nil,
}
Services.State = State

-- GUI parent resolver
local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, gui = pcall(function() return Services.CoreGui end)
    if ok and gui then return gui end
    return PlayerGui
end
Services.getGuiParent = getGuiParent

-- Stack hiding helper
local function hideFromStack(fn)
    if typeof(fn) == "function" and setstackhidden then
        pcall(setstackhidden, fn, true)
    end
end
Services.hideFromStack = hideFromStack

-- Mobile detection
local isMobile = Services.UserInputService.TouchEnabled
    and not Services.UserInputService.KeyboardEnabled
    and not Services.UserInputService.MouseEnabled
local isSmallScreen = isMobile or (Services.Camera and Services.Camera.ViewportSize.X < 900)
Services.isMobile = isMobile
Services.isSmallScreen = isSmallScreen

getgenv().UW = getgenv().UW or {}
getgenv().UW.Services = Services
getgenv().UW.State = State
getgenv().UW.isMobile = isMobile
getgenv().UW.isSmallScreen = isSmallScreen
getgenv().UW.getGuiParent = getGuiParent
getgenv().UW.hideFromStack = hideFromStack
