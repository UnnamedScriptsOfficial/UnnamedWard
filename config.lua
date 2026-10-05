-- ============================================================
-- UnnamedWard - Config
-- ============================================================
getgenv().UW = getgenv().UW or {}
local isMobile = getgenv().UW.isMobile

local Config = {
    -- Aimbot (legacy)
    Aimbot = false,
    TeamCheck = true,
    AimbotKey = Enum.UserInputType.MouseButton2,
    AimbotKeyMode = "Hold",
    AimbotPart = "Closest",
    AimbotSmoothing = 0.28,
    AimbotFOV = 120,
    AimbotVisibleOnly = true,
    AimbotScopeOnly = false,
    AimbotDisableReloading = true,
    ContinuousTargeting = true,
    InstantCameraLock = false,
    TrackThroughWalls = true,
    CorrectLockedShots = true,

    -- Silent Aim (legacy)
    SilentAim = true,
    SilentKey = Enum.KeyCode.C,
    SilentKeyMode = "Always",
    SilentTargetPart = "Head",
    SilentFOV = 242,
    SilentHitChance = 78,
    SilentHeadChance = 59,
    SilentVisibleOnly = true,
    SilentVulnerableOnly = true,
    SilentIgnoreDeflecting = true,
    SilentIgnoreShielded = true,

    -- Ragebot (legacy)
    Ragebot = false,
    RagebotAutoShoot = false,
    RagebotTargetStrafe = false,
    TargetStrafeRadius = 14,
    TargetStrafeSpeed = 6,
    Autoplay = false,
    AutoplayDistance = 18,
    RagebotTargetPriority = "Distance",
    RagebotWallbang = true,
    AutoRespawn = false,
    AutoQueue = false,
    QueueMode = "1v1",
    AutoVoteMaps = false,
    MapPriority = "Arena, Onyx, Crossroads",
    AutoBanWeapons = false,
    WeaponBanPriority = "Grenade Launcher, Minigun, RPG",
    SecondBanPriority = "Grenade Launcher, Minigun, RPG",
    AutoLoadout = true,
    LoadoutOnlySelected = false,
    EnabledMaps = "Arena, Crossroads",
    AntiAim = false,
    AntiAimMode = "Jitter",
    AntiAimSpeed = 10,
    HackerDetector = true,
    NotifyHackers = true,
    HackerAutoLoad = true,
    HackerProfile = "rage",
    SpeedThreshold = 180,
    SpeedDuration = 0.75,
    ModDetector = true,
    NotifyMods = true,
    MinGroupRank = 200,
    ModUsernames = "name1, name2",
    ModFriendList = "name1, name2",
    AutoPickup = false,
    PickupRadius = 25,

    -- ESP
    ESP_Master = true,
    ESP_EnemyOnly = true,
    ESP_Lobby = true,
    ESP_MaxDistance = 500,
    ESP_Boxes = true,
    ESP_Names = true,
    ESP_Distance = true,
    ESP_HealthBar = true,
    ESP_Weapon = true,
    ESP_Tracers = false,
    ESP_Chams = false,
    ESP_Skeleton = true,
    ESP_HeadDot = true,
    ESP_Tripmines = true,
    ESP_FOV = true,
    ESP_LivePreview = true,
    TargetVisualizer = true,
    TargetVisualizerHUD = true,
    TargetVisualizerPath = true,
    VisualizerArrowSpacing = 10,
    VisualizerArrowSpeed = 14,

    -- Movement
    SpeedHack = false,
    SpeedValue = 49,
    FlyHack = false,
    FlySpeed = 50,
    InfiniteJump = false,
    BunnyHop = false,
    Noclip = false,

    -- Gun mods
    NoRecoil = true,
    NoSpread = true,
    FastReload = false,
    RapidFire = false,
    InstantEquip = false,
    AutomaticGuns = false,
    InfiniteAmmo = false,

    -- Skins
    UnlockAllSkins = false,
    SelectedCategory = "Primary",
    SelectedWeapon = "Assault Rifle",
    SelectedWrap = "Liquid Gold",
    SelectedCharm = "Dice",
    SelectedFinisher = "Gingerbreadify",
    RainbowGunSkin = false,
    WeaponChams = false,
    CustomViewModelFOV = false,
    ViewModelFOVValue = 70,
    ViewModelXOffset = 0,
    ViewModelYOffset = 0,
    ViewModelZOffset = 0,
    HideViewModel = false,

    -- World
    Fullbright = false,
    NoFog = true,
    CustomFOV = false,
    FOVValue = 90,
    BulletTracers = false,
    HitSound = "Skeet",

    -- View
    ThirdPerson = false,
    ThirdPersonDist = 12,
    Freecam = false,
    FreecamSpeed = 40,

    -- UI
    MenuKey = Enum.KeyCode.RightControl,
    MobileToggle = isMobile,

    -- Legit / Silent Aim
    Legit_SilentAim_Enabled = true,
    Legit_SilentAim_HitChance = 78,
    Legit_SilentAim_KeyMode = "Always",

    -- Aim Assist
    Legit_Aimbot_Enabled = false,
    Legit_Aimbot_Speed = 0.28,
    Legit_Aimbot_Type = "Lerp",

    -- Trigger Bot
    Legit_Triggerbot_Enabled = false,
    Legit_Triggerbot_Bind = Enum.UserInputType.MouseButton2,
    Legit_Triggerbot_Mode = "Hold",

    -- FOV Settings
    Legit_UseFOV = true,
    Legit_FOV = 242,
    Legit_Hitscan = "Head",

    -- Rage Bot
    Rage_Ragebot_Enabled = false,
    Rage_SilentAim = true,
    Rage_AutoWall = true,
    Rage_ForceFullDamage = false,
    Rage_MinimumDamage = 25,
    Rage_Hitscan = {"Head", "Torso"},

    -- Miscellaneous (Rage)
    Rage_RapidFire = false,
    Rage_ForceHeadshot = false,
    Rage_DoubleTap = false,
    Rage_NoscopeIcon = false,

    -- Knife Bot
    Rage_Knifebot_Enabled = false,
    Rage_Knifebot_Radius = 12,

    -- Anti-Aim (Rage)
    Rage_AntiAim_Enabled = false,
    Rage_FakeDuck = false,
    Rage_YawBase = "Camera",
    Rage_SpinSpeed = 10,

    -- Theme editor
    ThemeAccent = "Pink",
    ThemeCustomColor = Color3.fromRGB(255, 160, 195),

    -- UI toggles
    UI_Watermark = true,
    UI_KeybindList = true,
    UI_Style = "Linear",

    -- Anti-Katana
    AntiKatana = false,
    AntiKatanaSound = true,

    -- Manipulation
    Silent_Manipulation = false,
    Silent_ClosestPart = false,
    Silent_ClosestPartBlacklist = {},
    Silent_AutoReload = true,
    Silent_FOVPosition = "",

    -- Viewmodel
    VM_Disable = {},
    VM_OverrideFPS = false,
    VM_FPS = 60,
    VM_Chams = false,
    VM_Wireframe = false,
    VM_DisableTextures = false,
    VM_Offset = false,
    VM_OffsetX = 0,
    VM_OffsetY = 0,
    VM_OffsetZ = 0,
    Arm_Appearance = false,
    Arm_DisableClothes = false,

    -- Crosshair
    Crosshair_Enabled = false,
    Crosshair_Outline = false,
    Crosshair_Rotation = 0,
    Crosshair_Speed = 0.2,
    Crosshair_Bounce = 0,
    Crosshair_Offset = 5,
    Crosshair_Length = 20,
    Crosshair_Thickness = 2,
    Crosshair_Color = Color3.fromRGB(255, 255, 255),
    Crosshair_OutlineColor = Color3.fromRGB(0, 0, 0),
    Crosshair_Position = "",
    Disable_GameCrosshair = false,

    -- Tracers
    CustomTracers_Enabled = false,
    CustomTracers_Color = Color3.fromRGB(97, 131, 255),

    -- Shoot Sound
    ShootSound_Enabled = false,
    ShootSound_Mode = "disable",
    ShootSound_CustomId = "4049646104",
    ShootSound_Speed = 1,
    ShootSound_Volume = 0.3,
    ShootSound_Start = 0,

    -- Hit Sounds
    HitSound_Enabled = false,
    HitSound_Volume = 0.5,
    HitSound_Name = "neverlose",
    HitSound_RemoveDefault = false,

    -- Hit Effects
    HitEffect_Enabled = false,
    HitEffect_Weld = false,
    HitEffect_Selected = {},
    HitEffect_Settings = {},
    HitEffect_Material = "ForceField",
    Disable_HitMarker = false,
    Disable_DamageNumbers = false,

    -- Target HUD
    TargetHUD_Enabled = false,

    -- Indicators
    Indicator_Manipulated = false,
    Indicator_Ragebot = false,
    Indicator_Ammo = false,
    Indicator_Lerp = 1,
    Indicator_OffsetX = 0,
    Indicator_OffsetY = 25,
    Indicator_Position = "",

    -- Target
    Target_Tracer = false,
    Target_TracerColor = Color3.fromRGB(255, 255, 255),
    Target_Highlight = false,
    Target_HighlightColor = Color3.fromRGB(255, 255, 255),
    Target_CullingMode = "AlwaysOnTop",

    -- Third Person
    ThirdPerson_Mode = "ThirdPerson",
    ThirdPerson_UnlockMouse = false,

    -- Anti-Aim Desync
    AntiAim_Pitch = "disabled",
    AntiAim_Yaw = "disabled",
    AntiAim_Underground = false,

    -- World Visuals
    ColorCorrection_Enabled = false,
    ColorCorrection_Saturation = 0,
    ColorCorrection_Contrast = 0,
    ColorCorrection_Brightness = 0,
    Atmosphere_Enabled = false,
    Atmosphere_Glare = 1.5,
    Atmosphere_Haze = 10,
    Atmosphere_Offset = 0.4,
    Atmosphere_Density = 0.5,
    Skybox_Enabled = false,
    Skybox_Selected = "Afternoon",
    Weather_Enabled = false,
    Weather_Selected = "Heavy Rain",
    Weather_Rate = 1,
    Weather_Lifetime = 1,
    Weather_Timescale = 1,
    Ambience_Enabled = false,
    Ambience_Selected = "Heavy Rain",
    Ambience_Volume = 0.5,
    Bloom_Enabled = false,
    Bloom_Intensity = 0.6,
    Bloom_Size = 26,
    Bloom_Threshold = 0.4,
    SunRays_Enabled = false,
    SunRays_Override = false,
    SunRays_Intensity = 0.25,
    SunRays_Spread = 1,

    -- Camera
    Camera_AntiFlashbang = false,
    Camera_AntiSmoke = false,
    Camera_FOVChanger = false,
    Camera_FOVValue = 120,
    Camera_AspectRatio = false,
    Camera_RatioX = 1,
    Camera_RatioY = 1,
    Camera_Blur = 0,

    -- Item
    Item_RemoveVignette = false,
    Item_OverrideWeaponStatus = false,
    Item_WeaponStatus = "Prime",

    -- Movement Extras
    AirJump_Enabled = false,
    AirJump_Velocity = 50,
    Movement_Velocity = false,
    Movement_VelocitySpeed = 50,
    Movement_SlideBoost = false,
    Movement_SlideBoostValue = 1,
    Movement_DoubleJumpHeight = false,
    Movement_DoubleJumpHeightValue = 1,
    Movement_MaulSlam = false,
    Movement_MaulSlamValue = 1,
    Movement_InfiniteDoubleJump = false,

    -- Projectile TP
    ProjectileTP_Enabled = false,

    -- Phase
    Phase_Enabled = false,
    Phase_Mode = "Character",
    Phase_WallSize = 5,

    -- Spin
    Spin_Enabled = false,
    Spin_Mode = "CFrame",
    Spin_Speed = 40,
    Spin_X = false,
    Spin_Y = true,
    Spin_Z = false,

    -- Target Strafe
    TargetStrafe_Enabled = false,
    TargetStrafe_SearchRange = 24,
    TargetStrafe_StrafeRange = 18,
    TargetStrafe_YFactor = 100,

    -- Chat Spam
    ChatSpam_Enabled = false,
    ChatSpam_InOrder = false,
    ChatSpam_Mode = "custom",
    ChatSpam_CustomText = "message...",

    -- Animation Player
    AnimationPlayer_Enabled = false,
    AnimationPlayer_Animation = "Floss",
    AnimationPlayer_CustomId = "",
    AnimationPlayer_Speed = 1,
    AnimationPlayer_Start = 0,
    AnimationPlayer_End = 100,

    -- Auto Queue
    AutoQueue_Enabled = false,
    AutoQueue_GameMode = "1v1",

    -- Auto Ban
    AutoBan_Enabled = false,
    AutoBan_RandomMap = false,
    AutoBan_MapDelay = 0,
    AutoBan_Weapons = true,
    AutoBan_FirstDelay = 0,
    AutoBan_SecondDelay = 0,
    AutoBan_First = "Riot Shield",
    AutoBan_Second = "Katana",

    -- Auto Load
    AutoLoad_Enabled = false,
    AutoLoad_SilentMode = false,

    -- Loadout
    Loadout_AutoSelect = false,
    Loadout_Primary = "Assault Rifle",
    Loadout_Secondary = "Handgun",
    Loadout_Melee = "Fists",
    Loadout_Utility = "Grenade",

    -- Name Spoofer
    NameSpoofer_Enabled = false,
    NameSpoofer_Name = "",

    -- Device Spoofer
    DeviceSpoofer_Enabled = false,
    DeviceSpoofer_Mode = "MouseKeyboard",

    -- Staff Detector
    StaffDetector_Enabled = false,
    StaffDetector_Mode = "Notify",

    -- Arcade
    Arcade_Enabled = false,
    Arcade_CollectDrops = true,
    Arcade_AutoRespawn = true,

    -- Hit Notifier
    HitNotifier_Enabled = false,
    HitNotifier_Duration = 1,
    HitNotifier_RandomText = "Hit {NAME} for {DMG} in the {PART}",
    HitNotifier_CustomText = "",

    -- XRay
    XRay_Enabled = false,
    XRay_Transparency = 0.5,

    -- Viewmodel Resizer
    ViewmodelResizer_Enabled = false,
    ViewmodelResizer_Size = 1,

    -- Shader
    Shader_Enabled = false,
    Shader_Time = 12,

    -- Blink
    Blink_Enabled = false,
    Blink_Type = "Movement Only",
    Blink_AutoSend = false,
    Blink_AutoSendLength = 0,

    -- Timer
    Timer_Enabled = false,
    Timer_Value = 1,

    -- Mobile Settings
    MobileSettings_Enabled = false,

    -- Weapons (Combat)
    Weapons_NoSpread = false,
    Weapons_FastShoot = false,
    Weapons_FastProjectile = false,
    Weapons_FullAuto = false,
    Weapons_AlwaysBackstab = false,
    Weapons_GrenadeOptions = {},
    Weapons_FireRate = 100,

    -- Triggerbot (new)
    Triggerbot_Enabled = false,
    Triggerbot_ReactionTime = 100,
    Triggerbot_ReactionOffset = 0,
    Triggerbot_ForgetTime = 0.5,
    Triggerbot_ShootDelay = 0,
    Triggerbot_MaxDistance = 100,
    Triggerbot_PartBlacklist = {},
    Triggerbot_Settings = {["no delay between targets"] = true, ["anti katana"] = true},
    Triggerbot_ScopedWeapons = {Sniper = true, Crossbow = true},

    -- Ragebot (new)
    Ragebot_Enabled = false,
    Ragebot_VoidSpam = true,
    Ragebot_HideTime = 0.25,
    Ragebot_ShootTime = 0.03,
    Ragebot_ShootAttempts = 1,
    Ragebot_AttackMode = "gun",
    Ragebot_PreferredWeapon = "primary",
    Ragebot_WeaponSpecialize = true,
    Ragebot_Settings = {["swap weapons when empty"] = true, ["prefer projectile weapon"] = false},
    Ragebot_AutoPriority = true,
    Ragebot_SendNotification = false,
    Ragebot_PrioritySettings = {attackers = true, ["voided players"] = true},
    Ragebot_PrioritizedPlayer = nil,
    Ragebot_Mode = "Orbit",
    Ragebot_AutoSwitch = true,

    -- ESP (new)
    ESP_WorldName = false,
    ESP_WorldImage = false,
    ESP_WorldDistance = false,
    ESP_WorldScale = 100,
    ESP_WorldWhitelist = {Grenade = true, Molotov = true, Satchel = true, Flashbang = true, ["Smoke Grenade"] = true, ["Subspace Tripmine"] = true},
    ESP_WorldFont = "monocraft bold",
    ESP_Flags_StaringText = false,
    ESP_Flags_HealthText = false,
    ESP_Flags_Font = "smallest pixel",
    ESP_Flags_Style = "upper",
    ESP_Flags_Prefix = "full",
    ESP_Flags_Bridge = ":",
    ESP_Method = "2D",
    ESP_Box_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Box_Transparency = {0, 0, 0},
    ESP_Fill_Enabled = false,
    ESP_Fill_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Fill_Transparency = {0, 0, 0},
    ESP_HealthBar_Colors = {Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 0)},
    ESP_HealthBar_Transparency = {0, 0, 0},
    ESP_Name_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Name_Transparency = {0, 0, 0},
    ESP_Weapon_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Weapon_Transparency = {0, 0, 0},
    ESP_Distance_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Distance_Transparency = {0, 0, 0},
    ESP_Skeleton_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Skeleton_Transparency = {0, 0, 0},
    ESP_DisplayName = true,
    ESP_Background = false,
    ESP_Teammates = true,
    ESP_Distance_Enabled = false,
    ESP_Distance_Limit = 64,
    ESP_HealthBar_Type = "gradient",
    ESP_HealthBar_Slices = 1,
    ESP_HealthBar_Speed = 1,
    ESP_HealthBar_Lerp = 0.05,
    ESP_OverrideAppearance = false,
    ESP_OverrideColor = false,
    ESP_OverrideColorValue = Color3.fromRGB(255, 255, 255),
    ESP_OverrideMaterial = false,
    ESP_OverrideMaterialValue = "ForceField",
    ESP_DisableAppearance = {},
    ESP_OverrideTransparency = 0,
    ESP_Highlight = false,
    ESP_Highlight_ThroughWalls = true,
    ESP_Highlight_Pulse = false,
    ESP_Highlight_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Particle = false,
    ESP_Particle_Type = "orbs",
    ESP_Particle_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_Aura = false,
    ESP_Aura_Type = "spiral",
    ESP_Aura_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    ESP_BoundingMode = "fixed",
    ESP_FixedWidth = 100,
    ESP_Font = "monocraft",
    ESP_NameType = "Name",

    -- Silent Aim (new)
    SilentAim_Enabled = true,
    SilentAim_Mode = "Mouse",
    SilentAim_Range = 100,
    SilentAim_HitChance = 100,
    SilentAim_HeadshotChance = 65,
    SilentAim_AutoFire = false,
    SilentAim_AutoReload = true,
    SilentAim_Manipulation = false,
    SilentAim_ClosestPart = false,
    SilentAim_ClosestPartBlacklist = {},
    SilentAim_VisibleOnly = false,
    SilentAim_IgnoreProtected = false,
    SilentAim_IgnoreIf = {["katana deflecting"] = true, ["blocked by riot shield"] = true},
    SilentAim_DisableOnFlash = false,
    SilentAim_LimitDistance = false,
    SilentAim_MaxDistance = 250,
    SilentAim_ReactionTime = 0,
    SilentAim_ForgetTime = 1,
    SilentAim_TargetPart = "Head",
    SilentAim_ShowFOV = true,
    SilentAim_FOV_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    SilentAim_FOV_Transparency = {0, 0, 0},
    SilentAim_Outline = false,
    SilentAim_Outline_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    SilentAim_Outline_Transparency = {0, 0, 0},
    SilentAim_Fill = false,
    SilentAim_Fill_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    SilentAim_Fill_Transparency = {0, 0, 0},
    SilentAim_Lerp = 1,
    SilentAim_MovingRotation = false,
    SilentAim_Rotation = 0,
    SilentAim_RotationSpeed = 1,
    SilentAim_FOVPosition = "",

    -- Aim Assist (new)
    AimAssist_Enabled = false,
    AimAssist_ClosestPart = false,
    AimAssist_ClosestPosition = false,
    AimAssist_DelayPosition = true,
    AimAssist_XSmooth = 100,
    AimAssist_YSmooth = 100,
    AimAssist_JumpSmoothing = 100,
    AimAssist_RangeCircle = true,
    AimAssist_RangeCircle_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    AimAssist_RangeCircle_Transparency = {0, 0, 0},
    AimAssist_Outline = false,
    AimAssist_Outline_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    AimAssist_Outline_Transparency = {0, 0, 0},
    AimAssist_Fill = false,
    AimAssist_Fill_Colors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)},
    AimAssist_Fill_Transparency = {0, 0, 0},
    AimAssist_Lerp = 1,
    AimAssist_MovingRotation = false,
    AimAssist_Rotation = 0,
    AimAssist_RotationSpeed = 1,
    AimAssist_FOVPosition = "",
    AimAssist_FOV = 100,
    AimAssist_Speed = 100,
    AimAssist_RightClick = false,
    AimAssist_ShowTarget = false,

    -- Rage Silent
    RageSilent_Enabled = false,
    RageSilent_Prediction = 0.12,
    RageSilent_HeadOffset = Vector3.new(0, 0.1, 0),

    -- Orbit
    Orbit_Enabled = false,
    Orbit_Desync = false,
    Orbit_Speed = 500,
    Orbit_Distance = 5,
    Orbit_Height = -4,
    Orbit_MaxDistance = 800,

    -- Vortex Triggerbot
    Vortex_Triggerbot_Enabled = false,
    Vortex_Triggerbot_ReactionTime = 100,
    Vortex_Triggerbot_ReactionOffset = 0,
    Vortex_Triggerbot_ForgetTime = 0.5,
    Vortex_Triggerbot_ShootDelay = 0,
    Vortex_Triggerbot_MaxDistance = 100,
    Vortex_Triggerbot_PartBlacklist = {},
    Vortex_Triggerbot_Settings = {["no delay between targets"] = true, ["anti katana"] = true},
    Vortex_Triggerbot_ScopedWeapons = {Sniper = true, Crossbow = true},

    -- Anti-Fall
    AntiFall_Enabled = false,

    -- Infinite Fly
    InfiniteFly_Enabled = false,

    -- Hitbox Expander
    HitboxExpander_Enabled = false,
    HitboxExpander_Size = 5,
    HitboxExpander_Transparency = 0.5,
    HitboxExpander_TeamCheck = true,
}

getgenv().UW = getgenv().UW or {}
getgenv().UW.Config = Config
getgenv().Config = Config
