-- ============================================================
-- UnnamedWard - Loader
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end

if getgenv and getgenv().UnnamedWardUnload then
    pcall(getgenv().UnnamedWardUnload)
end

local BASE = "https://raw.githubusercontent.com/UnnamedScriptsOfficial/UnnamedWard/main/"

local function load(mod)
    local ok, src = pcall(game.HttpGet, game, BASE .. mod .. ".lua?t=" .. tick())
    if not ok or type(src) ~= "string" or #src < 10 then
        warn("[UnnamedWard] Failed to fetch: " .. mod)
        return false
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[UnnamedWard] Compile error in " .. mod .. ": " .. tostring(err))
        return false
    end
    local ok2, err2 = pcall(fn)
    if not ok2 then
        warn("[UnnamedWard] Runtime error in " .. mod .. ": " .. tostring(err2))
        return false
    end
    return true
end

-- 1. KEY GATE
load("keysystem")

local start = tick()
while not getgenv().UnnamedWardKeyVerified
    and not getgenv().UnnamedWardGateClosed
    and (tick() - start) < 300 do
    task.wait(0.1)
end
if not getgenv().UnnamedWardKeyVerified then
    warn("[UnnamedWard] Key gate closed without verification.")
    return
end

-- 2. LOAD MODULES IN ORDER
local order = {
    "services",   -- services, State, getGuiParent, isMobile
    "theme",      -- Theme, fonts
    "config",     -- Config table
    "lagkiller",  -- LagKiller
    "helpers",    -- isInLobby, isTeammate, isEnemyPlayer
    "ui",         -- screenGui, mainWindow, UI library  ← must exist before notify
    "notify",     -- ShowNotification
    "target",     -- getClosestTarget
    "ragecore",   -- RageCore
    "esp",        -- ESP objects + render loop
    "aimbot",     -- silent aim hook + camera aim + triggerbot
    "movement",   -- speed/fly/noclip/bhop/infinitejump
    "world",      -- fog/fov/thirdperson/freecam
    "extras",     -- tracers/antiaim/knifebot/pickup
    "ui_tabs",    -- ALL tab content (home/aim/auto/esp/etc.)
    "main",       -- final glue + show menu
}

for _, mod in ipairs(order) do
    load(mod)
end

print("[UnnamedWard] All modules loaded.")
