-- ============================================================
-- UnnamedWard - Main (glue + final render loop additions)
-- ============================================================
local UW = getgenv().UW
local State = UW.State
local RunService = UW.Services.RunService
local UserInputService = UW.Services.UserInputService

-- Rage tick
table.insert(State.activeConnections, RunService.Stepped:Connect(function(_, dt)
    if not State.isRunning then return end
    task.spawn(UW.RageCore.Start, dt)
end))

-- Show menu
UW.setMenuVisible(true)
UW.ShowNotification("UnnamedWard", "Loaded successfully. Tier: " .. (getgenv().UnnamedWardTier or "FREE"), "SUCCESS", 4)
print("[UnnamedWard] Extended features loaded.")
