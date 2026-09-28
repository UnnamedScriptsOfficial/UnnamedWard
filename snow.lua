-- ============================================================
-- PINK + BLUE SNOW EFFECT (always on, bug-fixed, ship-ready)
-- ============================================================
-- Fixes applied:
--  #1  tick() -> running elapsed accumulator
--  #2  Viewport change -> reflow instead of re-init (no flicker)
--  #3  math.random with float bounds -> math.random() * vp.X
--  #4  Camera swap -> force reflow, no teardown/rebuild
--  #5  Recycle resets Phase/Tint/Speed/DriftAmp
--  #6  Safe Init (flakes guarded)
--  #7  Re-run cleanup (_G.__SnowConn / __SnowFlakes)
--  #8  Visible used as off-screen cull (both axes)
--  #9  Edge fade uses relative margin (no vanish on tiny windows)
--  #10 Alpha clamped to [0,1]
--  #11 NumSides auto-bumps to 20 for tiny/low-round flakes
--  #12 dt clamped to 1/30 to prevent teleport on lag spikes
--
-- NOTE: Rounded = true by default (see SNOW.Rounded below).
--       This renders softer 20-sided flakes instead of 6-sided blobs.
--       Flip to false only if you want the cheapest path and accept
--       angular flakes at small radii.
-- ============================================================

local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera     = Workspace.CurrentCamera

local SNOW = {
    Count         = 140,
    SpeedMin      = 35,
    SpeedMax      = 110,
    DriftStrength = 28,
    DriftSpeed    = 1.4,
    SizeMin       = 1,
    SizeMax       = 3,
    ColorPink     = Color3.fromRGB(255, 220, 235),
    ColorBlue     = Color3.fromRGB(215, 235, 255),
    Transparency  = 0.15,
    WindX         = 14,
    FadeNearEdges = true,
    Rounded       = true,   -- see header note (#11)
}

local Snow = { Flakes = {}, LastViewport = Vector2.new(0, 0) }
local elapsed = 0

local function RandomFlake()
    local vp = Camera.ViewportSize
    local c = Drawing.new("Circle")
    local radius = math.random() * (SNOW.SizeMax - SNOW.SizeMin) + SNOW.SizeMin
    c.NumSides     = (SNOW.Rounded or radius < 2) and 20 or 6
    c.Filled       = true
    c.Thickness    = 1
    c.Visible      = true
    c.Transparency = SNOW.Transparency
    c.Radius       = radius
    c.Color        = (math.random() < 0.5) and SNOW.ColorPink or SNOW.ColorBlue

    return {
        Obj      = c,
        X        = math.random() * vp.X,
        Y        = (math.random() * 2 - 1) * vp.Y,
        Speed    = math.random() * (SNOW.SpeedMax - SNOW.SpeedMin) + SNOW.SpeedMin,
        Phase    = math.random() * math.pi * 2,
        DriftAmp = math.random() * SNOW.DriftStrength,
        Tint     = c.Color,
    }
end

function Snow:Init()
    elapsed = 0                                    -- polish #4: reset drift phase
    for _, f in ipairs(self.Flakes or {}) do
        pcall(function() f.Obj:Remove() end)
    end
    self.Flakes = {}
    for _ = 1, SNOW.Count do
        table.insert(self.Flakes, RandomFlake())
    end
    self.LastViewport = Camera.ViewportSize
    _G.__SnowFlakes = self.Flakes                  -- fix #2: keep global ref fresh
end

function Snow:Update(dt)
    dt = math.min(dt, 1/30)
    elapsed = elapsed + dt

    local vp = Camera.ViewportSize

    if vp ~= self.LastViewport then
        for _, f in ipairs(self.Flakes) do
            f.X = math.clamp(f.X, 0, vp.X)
            f.Y = math.clamp(f.Y, -vp.Y, vp.Y)
        end
        self.LastViewport = vp
    end

    local margin = math.max(20, math.min(vp.X, vp.Y) * 0.08)

    for _, f in ipairs(self.Flakes) do
        f.Y = f.Y + f.Speed * dt
        local drift = math.sin(elapsed * SNOW.DriftSpeed + f.Phase) * f.DriftAmp
        f.X = f.X + (drift + SNOW.WindX) * dt

        if f.Y > vp.Y + 5 then
            f.Y        = -5
            f.X        = math.random() * vp.X
            f.Phase    = math.random() * math.pi * 2
            f.DriftAmp = math.random() * SNOW.DriftStrength
            f.Speed    = math.random() * (SNOW.SpeedMax - SNOW.SpeedMin) + SNOW.SpeedMin
            f.Tint     = (math.random() < 0.5) and SNOW.ColorPink or SNOW.ColorBlue
        end
        if f.X < -5 then f.X = vp.X + 5
        elseif f.X > vp.X + 5 then f.X = -5 end

        local alpha = SNOW.Transparency
        if SNOW.FadeNearEdges then
            local edgeX = math.min(f.X, vp.X - f.X) / margin
            local edgeY = math.min(f.Y, vp.Y - f.Y) / margin
            local edge  = math.clamp(math.min(edgeX, edgeY), 0, 1)
            alpha = math.clamp(SNOW.Transparency + (1 - edge) * 0.55, 0, 1)
        end

        f.Obj.Position     = Vector2.new(f.X, f.Y)
        f.Obj.Transparency = alpha
        f.Obj.Color        = f.Tint
        -- fix #3: cull on both axes
        f.Obj.Visible = (f.Y > -10 and f.Y < vp.Y + 10
                     and f.X > -10 and f.X < vp.X + 10)
    end
end

-- Fix #7: disconnect and remove flakes from any previous run
if _G.__SnowConn then pcall(function() _G.__SnowConn:Disconnect() end) end
if _G.__SnowFlakes then
    for _, f in ipairs(_G.__SnowFlakes) do
        pcall(function() f.Obj:Remove() end)
    end
end

Snow:Init()   -- also sets _G.__SnowFlakes (fix #2)

_G.__SnowConn = RunService.RenderStepped:Connect(function(dt)
    -- Fix #4 (polish #1): camera swap -> force reflow, don't rebuild
    if Workspace.CurrentCamera ~= Camera then
        Camera = Workspace.CurrentCamera
        Snow.LastViewport = Vector2.new(0, 0)  -- makes Update take the reflow branch
    end
    Snow:Update(dt)
end)
