-- ============================================================
-- UnnamedWard - Theme Module
-- ============================================================
local Theme = {
    OuterBorder     = Color3.fromRGB(255, 182, 210),
    BorderPink      = Color3.fromRGB(255, 182, 210),
    BorderPinkDark  = Color3.fromRGB(230, 150, 185),
    BorderBlue      = Color3.fromRGB(170, 215, 255),
    BorderBlueDark  = Color3.fromRGB(130, 185, 235),

    WindowBg        = Color3.fromRGB(255, 248, 252),
    WindowBgTop     = Color3.fromRGB(255, 252, 254),
    WindowBgBottom  = Color3.fromRGB(245, 240, 250),
    InnerCanvasBg   = Color3.fromRGB(252, 248, 253),
    HeaderBg        = Color3.fromRGB(255, 245, 250),

    CardBg          = Color3.fromRGB(255, 252, 254),
    CardBgTop       = Color3.fromRGB(255, 254, 255),
    CardBgBottom    = Color3.fromRGB(248, 244, 252),
    BorderDark      = Color3.fromRGB(230, 210, 225),
    BorderCard      = Color3.fromRGB(240, 215, 235),

    AccentPink      = Color3.fromRGB(255, 160, 195),
    AccentPinkLight = Color3.fromRGB(255, 200, 220),
    AccentPinkDark  = Color3.fromRGB(235, 130, 175),
    AccentPinkDim   = Color3.fromRGB(255, 220, 235),

    AccentBlue      = Color3.fromRGB(150, 205, 255),
    AccentBlueLight = Color3.fromRGB(195, 225, 255),
    AccentBlueDark  = Color3.fromRGB(110, 175, 240),
    AccentBlueDim   = Color3.fromRGB(220, 240, 255),

    TextWhite       = Color3.fromRGB(80, 60, 75),
    TextMuted       = Color3.fromRGB(150, 130, 145),
    TextDark        = Color3.fromRGB(180, 165, 180),
    TextPink        = Color3.fromRGB(235, 130, 175),
    TextBlue        = Color3.fromRGB(110, 175, 240),

    ControlBg       = Color3.fromRGB(250, 245, 250),
    ButtonBg        = Color3.fromRGB(255, 240, 248),
    ButtonHoverBg   = Color3.fromRGB(255, 225, 240),
    ButtonBorder    = Color3.fromRGB(245, 205, 225),

    Red             = Color3.fromRGB(255, 130, 150),
    Yellow          = Color3.fromRGB(255, 210, 130),
    Green           = Color3.fromRGB(150, 220, 180),

    AccentGreen     = Color3.fromRGB(255, 160, 195),
    AccentGreenLight= Color3.fromRGB(255, 200, 220),
    AccentGreenDark = Color3.fromRGB(235, 130, 175),
    AccentGreenDim  = Color3.fromRGB(255, 220, 235),
}

local MainFont = Enum.Font.GothamMedium
local MainFontBold = Enum.Font.GothamBold

getgenv().UW = getgenv().UW or {}
getgenv().UW.Theme = Theme
getgenv().UW.MainFont = MainFont
getgenv().UW.MainFontBold = MainFontBold
