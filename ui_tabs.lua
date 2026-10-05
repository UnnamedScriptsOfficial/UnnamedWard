-- ============================================================
-- UnnamedWard - Tab UI Content
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Config = UW.Config
local Theme = UW.Theme
local MainFont = UW.MainFont
local LocalPlayer = Services.LocalPlayer
local Camera = Services.Camera
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local TeleportService = Services.TeleportService
local ReplicatedStorage = Services.ReplicatedStorage
local isMobile = UW.isMobile

local tabPages = UW.tabPages
local uiRegistry = UW.uiRegistry
local ShowNotification = UW.ShowNotification
local UnloadScript = UW.UnloadScript
local UI = UW.UI
local createGroupbox   = UI.createGroupbox
local addCheckbox      = UI.addCheckbox
local addSlider        = UI.addSlider
local addDropdown      = UI.addDropdown
local addTextbox       = UI.addTextbox
local addButton        = UI.addButton
local addKeybind       = UI.addKeybind
local addColorPicker   = UI.addColorPicker

-- ⬇⬇⬇ PASTE YOUR ORIGINAL TAB BLOCKS HERE ⬇⬇⬇
-- (home, aim, auto, esp, move, guns, skins, world, view, config)

-- Also paste: MOBILE TOGGLE BUTTON block, ApplyWeaponModifications,
-- UnlockAllCosmeticsClientSide, ApplySelectedCosmeticsClientSide helpers.
