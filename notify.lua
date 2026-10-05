-- ============================================================
-- UnnamedWard - Notifications
-- ============================================================
local UW = getgenv().UW
local Services = UW.Services
local State = UW.State
local Theme = UW.Theme
local MainFont = UW.MainFont
local MainFontBold = UW.MainFontBold
local isMobile = UW.isMobile
local TweenService = Services.TweenService
local Camera = Services.Camera
local screenGui = UW.screenGui  -- set by ui.lua before this runs

local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifContainer"
local _notifWidth = math.min(isMobile and 200 or 260, (Camera and Camera.ViewportSize.X or 800) * 0.5)
notifContainer.Size = UDim2.new(0, _notifWidth, 1, -40)
notifContainer.Position = UDim2.new(1, -(_notifWidth + 10), 0, 36)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100
notifContainer.Parent = screenGui
table.insert(State.cleanUpInstances, notifContainer)

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 5)
notifLayout.Parent = notifContainer

local function ShowNotification(title, message, notifType, duration)
    if not State.isRunning then return end
    pcall(function()
        if not notifContainer or not notifContainer.Parent then return end
        duration = duration or 3.5
        notifType = notifType or "INFO"
        local barColor = Theme.AccentPink
        if notifType == "SUCCESS" then barColor = Theme.Green
        elseif notifType == "WARN" then barColor = Theme.Yellow
        elseif notifType == "ERROR" then barColor = Theme.Red end

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = Theme.CardBg
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.ZIndex = 101
        card.Parent = notifContainer

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.BorderPink
        stroke.Thickness = 1
        stroke.Parent = card

        local topAcc = Instance.new("Frame")
        topAcc.Size = UDim2.new(1, 0, 0, 1.5)
        topAcc.BackgroundColor3 = barColor
        topAcc.BorderSizePixel = 0
        topAcc.ZIndex = 102
        topAcc.Parent = card

        local tLbl = Instance.new("TextLabel")
        tLbl.Size = UDim2.new(1, -14, 0, 15)
        tLbl.Position = UDim2.new(0, 8, 0, 3)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = MainFontBold
        tLbl.Text = title
        tLbl.TextColor3 = Theme.TextPink
        tLbl.TextSize = 11.5
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.ZIndex = 102
        tLbl.Parent = card

        local mLbl = Instance.new("TextLabel")
        mLbl.Size = UDim2.new(1, -14, 0, 22)
        mLbl.Position = UDim2.new(0, 8, 0, 18)
        mLbl.BackgroundTransparency = 1
        mLbl.Font = MainFont
        mLbl.Text = message
        mLbl.TextColor3 = Theme.TextWhite
        mLbl.TextSize = 10
        mLbl.TextWrapped = true
        mLbl.TextXAlignment = Enum.TextXAlignment.Left
        mLbl.ZIndex = 102
        mLbl.Parent = card

        TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 46)}):Play()

        task.delay(duration, function()
            if card and card.Parent then
                local tw = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
                tw:Play()
                tw.Completed:Connect(function() card:Destroy() end)
            end
        end)
    end)
end

getgenv().UW.ShowNotification = ShowNotification
getgenv().ShowNotification = ShowNotification
