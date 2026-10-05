-- ============================================================
-- UnnamedWard - Lag Killer (silent)
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services

local LagKiller = (function()
    local Players     = Services.Players
    local Lighting    = Services.Lighting
    local LocalPlayer = Services.LocalPlayer
    local UserSettings = UserSettings

    local state = {
        Enabled = false,
        Connections = {},
        ChangedProperties = {},
        OldQualityLevel = nil,
        OldSavedQuality = nil,
    }

    local function safeGet(inst, prop)
        local ok, v = pcall(function() return inst[prop] end)
        return ok and v or nil
    end

    local function safeSet(inst, prop, value)
        pcall(function() inst[prop] = value end)
    end

    local function rememberProperty(inst, prop)
        if not inst then return end
        local data = state.ChangedProperties[inst]
        if not data then data = {}; state.ChangedProperties[inst] = data end
        if data[prop] == nil then data[prop] = safeGet(inst, prop) end
    end

    local function rememberAndSet(inst, prop, value)
        if not inst then return end
        rememberProperty(inst, prop)
        safeSet(inst, prop, value)
    end

    local function shouldSkip(inst)
        if not inst then return true end
        local char = LocalPlayer.Character
        if char and inst:IsDescendantOf(char) then return true end
        return false
    end

    local function optimizeInstance(inst)
        if shouldSkip(inst) then return end
        if inst:IsA("BasePart") then
            rememberAndSet(inst, "Material", Enum.Material.SmoothPlastic)
            rememberAndSet(inst, "Reflectance", 0)
            rememberAndSet(inst, "CastShadow", false)
            if inst:IsA("MeshPart") then
                rememberAndSet(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
                rememberAndSet(inst, "TextureID", "")
            end
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            rememberAndSet(inst, "Transparency", 1)
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
            or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
            rememberAndSet(inst, "Enabled", false)
        elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
            rememberAndSet(inst, "Enabled", false)
        elseif inst:IsA("SpecialMesh") then
            rememberAndSet(inst, "TextureId", "")
        elseif inst:IsA("SurfaceAppearance") then
            rememberAndSet(inst, "ColorMap", "")
            rememberAndSet(inst, "MetalnessMap", "")
            rememberAndSet(inst, "NormalMap", "")
            rememberAndSet(inst, "RoughnessMap", "")
        end
    end

    local function optimizeLighting()
        rememberAndSet(Lighting, "GlobalShadows", false)
        rememberAndSet(Lighting, "FogEnd", 1e9)
        rememberAndSet(Lighting, "ShadowSoftness", 0)
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                rememberAndSet(effect, "Enabled", false)
            elseif effect:IsA("Atmosphere") then
                rememberAndSet(effect, "Density", 0)
                rememberAndSet(effect, "Haze", 0)
                rememberAndSet(effect, "Glare", 0)
            elseif effect:IsA("Sky") then
                rememberAndSet(effect, "CelestialBodiesShown", false)
                rememberAndSet(effect, "StarCount", 0)
            end
        end
    end

    local function optimizeTerrain()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return end
        rememberAndSet(terrain, "Decoration", false)
        rememberAndSet(terrain, "WaterWaveSize", 0)
        rememberAndSet(terrain, "WaterWaveSpeed", 0)
        rememberAndSet(terrain, "WaterReflectance", 0)
        rememberAndSet(terrain, "WaterTransparency", 1)
    end

    local function restoreAll()
        for inst, data in pairs(state.ChangedProperties) do
            if inst and inst.Parent then
                for prop, oldValue in pairs(data) do
                    safeSet(inst, prop, oldValue)
                end
            end
            state.ChangedProperties[inst] = nil
        end
    end

    local function setLowQuality()
        pcall(function()
            local rendering = settings().Rendering
            if state.OldQualityLevel == nil then state.OldQualityLevel = rendering.QualityLevel end
            rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            local ugs = UserSettings():GetService("UserGameSettings")
            if state.OldSavedQuality == nil then state.OldSavedQuality = ugs.SavedQualityLevel end
            ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)
    end

    local function restoreQuality()
        if state.OldQualityLevel ~= nil then
            pcall(function() settings().Rendering.QualityLevel = state.OldQualityLevel end)
        end
        if state.OldSavedQuality ~= nil then
            pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = state.OldSavedQuality end)
        end
    end

    local Api = {}

    function Api.Enable()
        if state.Enabled then return end
        state.Enabled = true
        setLowQuality()
        optimizeLighting()
        optimizeTerrain()
        for _, inst in ipairs(workspace:GetDescendants()) do optimizeInstance(inst) end
        table.insert(state.Connections,
            workspace.DescendantAdded:Connect(function(inst)
                if state.Enabled then optimizeInstance(inst) end
            end)
        )
    end

    function Api.Disable()
        if not state.Enabled then return end
        state.Enabled = false
        for _, conn in ipairs(state.Connections) do pcall(function() conn:Disconnect() end) end
        state.Connections = {}
        restoreAll()
        restoreQuality()
    end

    function Api.IsEnabled() return state.Enabled end

    return Api
end)()

getgenv().UW.LagKiller = LagKiller
getgenv().UnnamedWardLagKiller = LagKiller
