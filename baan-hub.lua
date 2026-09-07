--// BAAN HUB MULTI-GAME ROUTER
local placeId = game.PlaceId
local universeId = game.GameId

-- [FREE / NO KEY REQUIRED] MyCourt (Sequence Basketball)
if placeId == 116047689628641 or universeId == 10476380360 then
--[[
    Baan Hub - Tactical Basketball (MyCourt)
    V6.2: Precision Auto Green & Custom Brand UI
    - Official Baan Hub Branding & Custom Icon
    - Direct executor FireServer(false) release on Green Window
    - Complete Keyboard Repeat Suppression during hold
    - Clean Tabs: Shooting & Settings
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Cleanup previous execution cleanly
if getgenv()._MYCOURT_CLEANUP then
    pcall(getgenv()._MYCOURT_CLEANUP)
end

-- Network & Events
local Events = ReplicatedStorage:WaitForChild("Events", 5)
local States = Events and Events:WaitForChild("States", 5)
local ShootRemote = States and States:WaitForChild("Shoot", 5)
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
local SharedModules = Modules and Modules:WaitForChild("Shared", 5)
local Warp = SharedModules and require(SharedModules:WaitForChild("Warp"))
local DunkClient = Warp and Warp.Client("Dunk")

-- Hub Configuration State
local Config = {
    AutoGreen = true,
    AutoDunk = true,
    TimingOffset = 0, -- fine adjustment (-10 to +10)
    GreenNotice = true,
    ToggleKey = Enum.KeyCode.RightShift,
    GuiVisible = true,
}

-- Brand Logo Asset
local LogoAssetId = ""
if type(isfile) == "function" and isfile("baan-hub-logo.png") and type(getcustomasset) == "function" then
    pcall(function()
        LogoAssetId = getcustomasset("baan-hub-logo.png")
    end)
end

-- Cleanup Registry
local Connections = {}
local function regConn(conn)
    table.insert(Connections, conn)
    return conn
end

-- Helper: Check physical key press
local function isKeyPhysicallyDown(code)
    local s, down = pcall(function() return UserInputService:IsKeyDown(code) end)
    return s and down == true
end

-- Notification Manager
local function showNotice(title, desc, color)
    color = color or Color3.fromRGB(85, 255, 127)
    task.spawn(function()
        local parentGui = gethui and gethui() or game:GetService("CoreGui")
        local notifGui = parentGui:FindFirstChild("BaanHub_Notifs")
        if not notifGui then
            notifGui = Instance.new("ScreenGui")
            notifGui.Name = "BaanHub_Notifs"
            notifGui.ResetOnSpawn = false
            notifGui.Parent = parentGui
        end

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 255, 0, 56)
        frame.Position = UDim2.new(1, -275, 1, -75)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0.08
        frame.Parent = notifGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = 1.2
        stroke.Transparency = 0.25
        stroke.Parent = frame

        -- Icon in Notification
        if LogoAssetId and LogoAssetId ~= "" then
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 36, 0, 36)
            icon.Position = UDim2.new(0, 10, 0.5, -18)
            icon.BackgroundTransparency = 1
            icon.Image = LogoAssetId
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = frame

            local iCorner = Instance.new("UICorner")
            iCorner.CornerRadius = UDim.new(0, 7)
            iCorner.Parent = icon
        end

        local textOffsetX = (LogoAssetId and LogoAssetId ~= "") and 54 or 12

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -textOffsetX - 10, 0, 20)
        titleLbl.Position = UDim2.new(0, textOffsetX, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = color
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = frame

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -textOffsetX - 10, 0, 18)
        descLbl.Position = UDim2.new(0, textOffsetX, 0, 28)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = desc
        descLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 11
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = frame

        -- Fade in
        frame.Position = UDim2.new(1, -275, 1, -55)
        frame.BackgroundTransparency = 1
        titleLbl.TextTransparency = 1
        descLbl.TextTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 0.08, Position = UDim2.new(1, -275, 1, -75)}):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TweenService:Create(descLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

        task.wait(1.8)

        -- Fade out
        local fadeTween = TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = UDim2.new(1, -275, 1, -95)})
        TweenService:Create(titleLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(descLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
end

-- Find Active Meter Instance (Only if actively visible or holding)
local function getActiveMeter()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, name in ipairs({"VerticalMeter", "HorizontalMeter", "FunnelMeter"}) do
        local m = char:FindFirstChild(name)
        if m and m:IsA("BillboardGui") then
            if m:GetAttribute("MeterVisible") == true or m:GetAttribute("Holding") == true then
                return m
            end
        end
    end
    return nil
end

-- State Tracking & Anti-Freeze Lock
local shotActive = false
local shotReleased = false
local shotStartTime = 0
local waitingForPhysicalRelease = false

local dunkActive = false
local dunkReleased = false
local dunkStartTime = 0
local dunkWaitingRelease = false

local OldNamecall
local OldDunkFire

-- Metamethod Hook for Shoot Remote
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    -- Allow all calls from our executor script to pass directly through to original namecall!
    if checkcaller() then
        return OldNamecall(self, ...)
    end

    if method == "FireServer" and self == ShootRemote then
        local isStart = (args[1] == true)
        local isEnd = (args[1] == false)

        if isStart then
            -- Block keyboard repeat events while player is still holding E from just released shot!
            if waitingForPhysicalRelease then
                return nil
            end
            shotActive = true
            shotReleased = false
            shotStartTime = os.clock()
        elseif isEnd then
            -- Block late release from InputController if script already released at green!
            if shotReleased then
                return nil
            end
        end
    end

    return OldNamecall(self, ...)
end))

-- Dunk Client Hook
if DunkClient and DunkClient.Fire then
    OldDunkFire = DunkClient.Fire
    DunkClient.Fire = function(self, isDown, isActionStart, ...)
        if not checkcaller() then
            if isDown == true and isActionStart == true then
                if dunkWaitingRelease then
                    return nil
                end
                dunkActive = true
                dunkReleased = false
                dunkStartTime = os.clock()
            elseif isDown == true and isActionStart == false then
                if dunkReleased then
                    return nil
                end
            end
        end
        return OldDunkFire(self, isDown, isActionStart, ...)
    end
end

-- Reset Locks when physical key is released
regConn(UserInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
        waitingForPhysicalRelease = false
        shotActive = false
        shotReleased = false
    end
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonY then
        dunkWaitingRelease = false
        dunkActive = false
        dunkReleased = false
    end
end))

-- Per-Frame RenderStepped: Precision Timing & Release Execution
regConn(RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- Continuous safety unlock: if user is not physically holding key, unlock
    if not isKeyPhysicallyDown(Enum.KeyCode.E) then
        waitingForPhysicalRelease = false
    end
    if not isKeyPhysicallyDown(Enum.KeyCode.Space) then
        dunkWaitingRelease = false
    end

    local meter = getActiveMeter()
    if not meter then
        if not waitingForPhysicalRelease then
            shotReleased = false
            shotActive = false
        end
        if not dunkWaitingRelease then
            dunkReleased = false
            dunkActive = false
        end
        return
    end

    local isHolding = meter:GetAttribute("Holding") == true or meter:GetAttribute("MeterVisible") == true
    local mt = meter:GetAttribute("MeterTiming") or 0
    local gt = meter:GetAttribute("GreenTiming") or 85
    local isGreen = (meter:GetAttribute("MeterIsGreen") == true)

    if not isHolding then
        return
    end

    -- Sync active type
    if isKeyPhysicallyDown(Enum.KeyCode.Space) then
        dunkActive = true
    else
        shotActive = true
    end

    local target = gt + (Config.TimingOffset or 0)

    -- 1. Check Auto Green for Shoot / Layup (E)
    if Config.AutoGreen and shotActive and not shotReleased and not waitingForPhysicalRelease then
        if isGreen or (mt >= target and mt > 15) then
            shotReleased = true
            waitingForPhysicalRelease = true
            shotActive = false

            -- Send real release call via FireServer (passes checkcaller through hook)
            ShootRemote:FireServer(false)

            -- Clear character ShootingHeld to ensure game animations smoothly transition
            pcall(function()
                char:SetAttribute("ShootingHeld", false)
            end)

            if Config.GreenNotice then
                showNotice("PERFECT GREEN 🟢", string.format("Auto Released at %.1f%% (Green: %d%%)", mt, gt), Color3.fromRGB(85, 255, 127))
            end
        end
    end

    -- 2. Check Auto Green for Dunk (Space)
    if Config.AutoDunk and dunkActive and not dunkReleased and not dunkWaitingRelease then
        if isGreen or (mt >= target and mt > 15) then
            dunkReleased = true
            dunkWaitingRelease = true
            dunkActive = false

            if DunkClient and DunkClient.Fire then
                pcall(function() DunkClient:Fire(true, false) end)
            end
            pcall(function() ShootRemote:FireServer(false) end)

            if Config.GreenNotice then
                showNotice("PERFECT DUNK 🟢", string.format("Dunk Released at %.1f%% (Green: %d%%)", mt, gt), Color3.fromRGB(85, 255, 127))
            end
        end
    end
end))

-- Keybind Listener for UI
regConn(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        Config.GuiVisible = not Config.GuiVisible
        local gui = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("BaanHub_GUI")
        if gui and gui:FindFirstChild("MainFrame") then
            gui.MainFrame.Visible = Config.GuiVisible
        end
    end
end))

----------------------------------------------------------------------
-- GUI CONSTRUCTION (Baan Hub Design)
----------------------------------------------------------------------

local ParentGui = gethui and gethui() or game:GetService("CoreGui")
for _, name in ipairs({"BaanHub_GUI", "OTHUB_GUI"}) do
    local old = ParentGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "BaanHub_GUI"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = ParentGui

-- Main Container Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 700, 0, 430)
Main.Position = UDim2.new(0.5, -350, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = Screen

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 35, 42)
MainStroke.Thickness = 1.2
MainStroke.Parent = Main

-- Make Main Draggable
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 195, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 10)
SideCorner.Parent = Sidebar

local SideStroke = Instance.new("UIStroke")
SideStroke.Color = Color3.fromRGB(28, 28, 34)
SideStroke.Thickness = 1
SideStroke.Parent = Sidebar

-- Brand Logo Section
local BrandSection = Instance.new("Frame")
BrandSection.Name = "BrandSection"
BrandSection.Size = UDim2.new(1, -20, 0, 48)
BrandSection.Position = UDim2.new(0, 12, 0, 14)
BrandSection.BackgroundTransparency = 1
BrandSection.Parent = Sidebar

if LogoAssetId and LogoAssetId ~= "" then
    local LogoImg = Instance.new("ImageLabel")
    LogoImg.Name = "LogoImage"
    LogoImg.Size = UDim2.new(0, 40, 0, 40)
    LogoImg.Position = UDim2.new(0, 0, 0.5, -20)
    LogoImg.BackgroundTransparency = 1
    LogoImg.Image = LogoAssetId
    LogoImg.ScaleType = Enum.ScaleType.Fit
    LogoImg.Parent = BrandSection

    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = UDim.new(0, 8)
    lCorner.Parent = LogoImg

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = Color3.fromRGB(80, 100, 240)
    lStroke.Thickness = 1.2
    lStroke.Transparency = 0.4
    lStroke.Parent = LogoImg
end

local textLeftOffset = (LogoAssetId and LogoAssetId ~= "") and 48 or 4

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, -textLeftOffset, 0, 22)
Logo.Position = UDim2.new(0, textLeftOffset, 0, 2)
Logo.BackgroundTransparency = 1
Logo.Text = "Baan Hub"
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 18
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = BrandSection

local SubLogo = Instance.new("TextLabel")
SubLogo.Size = UDim2.new(1, -textLeftOffset, 0, 14)
SubLogo.Position = UDim2.new(0, textLeftOffset, 0, 24)
SubLogo.BackgroundTransparency = 1
SubLogo.Text = "Sequence Basketball"
SubLogo.TextColor3 = Color3.fromRGB(110, 125, 240)
SubLogo.Font = Enum.Font.GothamBold
SubLogo.TextSize = 10
SubLogo.TextXAlignment = Enum.TextXAlignment.Left
SubLogo.Parent = BrandSection

-- Tab Button Container
local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, 0, 1, -78)
TabContainer.Position = UDim2.new(0, 0, 0, 78)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 0
TabContainer.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Parent = TabContainer

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -205, 1, -16)
ContentArea.Position = UDim2.new(0, 200, 0, 8)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main

local Tabs = {}
local TabButtons = {}
local ActiveTab = nil

local function switchTab(tabName)
    if ActiveTab == tabName then return end
    ActiveTab = tabName

    for name, page in pairs(Tabs) do
        page.Visible = (name == tabName)
    end

    for name, btn in pairs(TabButtons) do
        local isCur = (name == tabName)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = isCur and Color3.fromRGB(28, 28, 36) or Color3.fromRGB(16, 16, 20)
        }):Play()
        local lbl = btn:FindFirstChild("Title")
        if lbl then
            lbl.TextColor3 = isCur and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 155)
        end
        local indicator = btn:FindFirstChild("Indicator")
        if indicator then
            indicator.Visible = isCur
        end
    end
end

local function createTab(tabName, iconText)
    -- Button in Sidebar
    local btn = Instance.new("TextButton")
    btn.Name = tabName .. "_Btn"
    btn.Size = UDim2.new(1, -18, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = TabContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 1, 0)
    icon.Position = UDim2.new(0, 12, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = iconText or "•"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 14
    icon.Parent = btn

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -44, 1, 0)
    title.Position = UDim2.new(0, 40, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = tabName
    title.TextColor3 = Color3.fromRGB(140, 140, 155)
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 18)
    indicator.Position = UDim2.new(0, 0, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(90, 120, 255)
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)

    -- Page in ContentArea
    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 55)
    page.Visible = false
    page.Parent = ContentArea

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 12)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 8)
    pagePad.PaddingBottom = UDim.new(0, 16)
    pagePad.PaddingLeft = UDim.new(0, 6)
    pagePad.PaddingRight = UDim.new(0, 10)
    pagePad.Parent = page

    Tabs[tabName] = page
    TabButtons[tabName] = btn
    return page
end

-- Section Card Builder
local function createSection(parentPage, sectionTitle, subtitle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    card.BorderSizePixel = 0
    card.Parent = parentPage

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Color3.fromRGB(28, 28, 34)
    cStroke.Thickness = 1
    cStroke.Parent = card

    local cPad = Instance.new("UIPadding")
    cPad.PaddingTop = UDim.new(0, 14)
    cPad.PaddingBottom = UDim.new(0, 14)
    cPad.PaddingLeft = UDim.new(0, 16)
    cPad.PaddingRight = UDim.new(0, 16)
    cPad.Parent = card

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 10)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Parent = card

    local hTitle = Instance.new("TextLabel")
    hTitle.Size = UDim2.new(1, 0, 0, 18)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = sectionTitle
    hTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.Parent = card

    if subtitle then
        local hSub = Instance.new("TextLabel")
        hSub.Size = UDim2.new(1, 0, 0, 14)
        hSub.BackgroundTransparency = 1
        hSub.Text = subtitle
        hSub.TextColor3 = Color3.fromRGB(110, 110, 125)
        hSub.Font = Enum.Font.Gotham
        hSub.TextSize = 11
        hSub.TextXAlignment = Enum.TextXAlignment.Left
        hSub.Parent = card
    end

    return card
end

-- Pill Toggle Builder
local function addToggle(card, labelText, defaultVal, callback)
    local state = defaultVal

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = 10
    row.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 44, 0, 22)
    pill.Position = UDim2.new(1, -44, 0.5, -11)
    pill.BackgroundColor3 = state and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(35, 35, 45)
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(1, 0)
    pCorner.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local function updateVisual(s)
        TweenService:Create(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = s and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(35, 35, 45)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = s and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        }):Play()
    end

    pill.MouseButton1Click:Connect(function()
        state = not state
        updateVisual(state)
        callback(state)
    end)
end

-- Slider Builder
local function addSlider(card, labelText, minVal, maxVal, defaultVal, suffix, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.LayoutOrder = 15
    row.Parent = card

    local topLbl = Instance.new("TextLabel")
    topLbl.Size = UDim2.new(0.7, 0, 0, 18)
    topLbl.BackgroundTransparency = 1
    topLbl.Text = labelText
    topLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    topLbl.Font = Enum.Font.GothamMedium
    topLbl.TextSize = 13
    topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.3, 0, 0, 18)
    valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(defaultVal) .. (suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(1, 0)
    bCorner.Parent = bar

    local fill = Instance.new("Frame")
    local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(90, 120, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(1, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = fill

    local thCorner = Instance.new("UICorner")
    thCorner.CornerRadius = UDim.new(1, 0)
    thCorner.Parent = thumb

    local sliding = false
    local function updateFromInput(input)
        local posX = input.Position.X
        local barLeft = bar.AbsolutePosition.X
        local barWidth = bar.AbsoluteSize.X
        local newPct = math.clamp((posX - barLeft) / barWidth, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * newPct)
        fill.Size = UDim2.new(newPct, 0, 1, 0)
        valLbl.Text = tostring(val) .. (suffix or "")
        callback(val)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
end

----------------------------------------------------------------------
-- BUILD TABS & CONTENT
----------------------------------------------------------------------

-- 1. Shooting Tab
local shootPage = createTab("Shooting", "🎯")

local shotReactCard = createSection(shootPage, "Auto Release (Hold-to-Shoot)", "Hold key (E or Space) -> Automatically releases at Green Window!")
addToggle(shotReactCard, "Auto Green (Shots / Layups)", Config.AutoGreen, function(val)
    Config.AutoGreen = val
end)
addToggle(shotReactCard, "Auto Green (Dunks)", Config.AutoDunk, function(val)
    Config.AutoDunk = val
end)
addSlider(shotReactCard, "Release Timing Offset", -10, 10, Config.TimingOffset, " %", function(val)
    Config.TimingOffset = val
end)
addToggle(shotReactCard, "Green Release Sound & Notification", Config.GreenNotice, function(val)
    Config.GreenNotice = val
end)

-- 2. Settings Tab
local settingsPage = createTab("Settings", "⚙")
local setCard = createSection(settingsPage, "Configuration", "Keybinds and script lifecycle")

local keyInfo = createSection(settingsPage, "Toggle Menu Keybind", "Press RightShift anytime to show/hide this menu")

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, 0, 0, 36)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "Unload / Close Script"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = setCard

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 6)
cCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    if getgenv()._MYCOURT_CLEANUP then
        getgenv()._MYCOURT_CLEANUP()
    end
end)

-- Set Default Active Tab
switchTab("Shooting")

-- Global Teardown Handler
getgenv()._MYCOURT_CLEANUP = function()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}
    if OldNamecall then
        hookmetamethod(game, "__namecall", OldNamecall)
    end
    if DunkClient and OldDunkFire then
        DunkClient.Fire = OldDunkFire
    end
    if Screen then
        Screen:Destroy()
    end
    local notifs = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("BaanHub_Notifs")
    if notifs then notifs:Destroy() end
    getgenv()._MYCOURT_CLEANUP = nil
end

showNotice("Baan Hub Ready", "Precision Green & Brand Theme Loaded!", Color3.fromRGB(90, 130, 255))
print("[Baan Hub] Loaded successfully!")

	return
end
--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "cem86gaDGJiE6e3b8bB5jjKqjFSaZEl+vv8oH8n2FUg="
local PAYLOAD_IV = "BqFOsRszQ0+NXmDXRVDcPg=="
local PAYLOAD_CT = "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"

local genv = getgenv()
genv.__autoSea = genv.__autoSea or {}
local S = genv.__autoSea

-- genv survives rejoins but GUIs do not: reset gate flags on every new server
if S.lastJoinId ~= game.JobId then
	S.lastJoinId = game.JobId
	S.keyOk = false
	S.keyGuiUp = false
end

local function log(...)
	print("[baan-hub]", ...)
end

---------------------------------------------------------------------
-- KEY SYSTEM
do
	local function hwid()
		local cid = ""
		pcall(function()
			cid = game:GetService("RbxAnalyticsService"):GetClientId()
		end)
		return tostring(game.Players.LocalPlayer.UserId) .. "|" .. tostring(cid)
	end

	local function keyHash(key)
		return crypt.hash(HWID_LOCK and (key .. "::" .. hwid()) or key, "sha256")
	end

	local allowed = {}
	if KEY_URL ~= "" then
		local okR, body = pcall(function()
			return request({ Url = KEY_URL, Method = "GET" }).Body
		end)
		if okR and type(body) == "string" and #body > 10 then
			for line in body:gmatch("[^\r\n]+") do
				table.insert(allowed, (line:lower():gsub("%s", "")))
			end
		else
			log("key list fetch failed; using dev keys")
		end
	end
	if #allowed == 0 then
		for _, k in ipairs(DEV_KEYS) do
			table.insert(allowed, keyHash(k))
		end
	end

	local function valid(key)
		local h = keyHash(key:gsub("%s", ""))
		for _, a in ipairs(allowed) do
			if a == h then return true end
		end
		return false
	end

	-----------------------------------------------------------------
	-- WORK.INK MODE: unique token per user, validated on work.ink servers
	if TOKEN_API ~= "" then
		local function hwidTag()
			return crypt.hash(hwid(), "sha256"):sub(1, 16)
		end

		-- single-use validation: consumes the token so sharing it is useless;
		-- grants a fresh KEY_TTL window on this device (work.ink's own expiry
		-- is only a redemption deadline, NOT the session length)
		local function tokenCheck(k)
			if #k < 8 then return nil, "token too short" end
			local okR, body = pcall(function()
				return request({ Url = TOKEN_API .. k .. "?deleteToken=1", Method = "GET" }).Body
			end)
			if not okR or type(body) ~= "string" then return nil, "network error" end
			local okJ, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(body)
			end)
			if not okJ or type(data) ~= "table" or not data.valid then
				return nil, "invalid or already-used token"
			end
			return os.time() + KEY_TTL
		end

		-- session record: hwidTag|issued|until (bound to this device)
		local sessHw, sessIssued, sessUntil = "", 0, 0
		pcall(function()
			if isfile(KEY_UNTIL_FILE) then
				local a, b, c = (readfile(KEY_UNTIL_FILE) or ""):match("^(%x+)|(%d+)|(%d+)$")
				sessHw, sessIssued, sessUntil = a or "", tonumber(b) or 0, tonumber(c) or 0
			end
		end)

		if sessHw == hwidTag() and os.time() < sessUntil and os.time() >= sessIssued - 60 then
			S.keyOk = true
			S.keyExp = sessUntil
			log(string.format("session active, %d min left", math.floor((sessUntil - os.time()) / 60)))
		else
			log("no valid session - key required")
		end

		if not S.keyOk then
			if not S.keyGuiUp then
				S.keyGuiUp = true

				local lp2 = game.Players.LocalPlayer
				local parent = (type(gethui) == "function" and gethui())
					or game:FindFirstChildOfClass("CoreGui")
					or lp2:WaitForChild("PlayerGui")

				pcall(function()
					local old = parent:FindFirstChild("BaanHubKeys")
					if old then old:Destroy() end
				end)

				local gui = Instance.new("ScreenGui")
				gui.Name = "BaanHubKeys"
				gui.ResetOnSpawn = false
				gui.DisplayOrder = 9999
				gui.Parent = parent

				local frame = Instance.new("Frame")
				frame.Size = UDim2.fromOffset(340, 244)
				frame.Position = UDim2.fromScale(0.5, 0.45)
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
				frame.BorderSizePixel = 0
				frame.Parent = gui
				Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
				local stroke = Instance.new("UIStroke", frame)
				stroke.Color = Color3.fromRGB(255, 196, 60)
				stroke.Thickness = 1.6

				local function label(txt, y, size, color)
					local t = Instance.new("TextLabel")
					t.Size = UDim2.new(1, -24, 0, size + 8)
					t.Position = UDim2.fromOffset(12, y)
					t.BackgroundTransparency = 1
					t.Font = Enum.Font.GothamBold
					t.TextSize = size
					t.TextColor3 = color
					t.TextWrapped = true
					t.TextXAlignment = Enum.TextXAlignment.Left
					t.Text = txt
					t.Parent = frame
					return t
				end

				label("BAAN HUB - Key Required", 10, 18, Color3.fromRGB(255, 196, 60))

				local getBtn = Instance.new("TextButton")
				getBtn.Size = UDim2.new(1, -24, 0, 32)
				getBtn.Position = UDim2.fromOffset(12, 42)
				getBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 60)
				getBtn.TextColor3 = Color3.fromRGB(30, 26, 8)
				getBtn.Font = Enum.Font.GothamBold
				getBtn.TextSize = 15
				getBtn.Text = "GET KEY"
				getBtn.AutoButtonColor = true
				getBtn.Parent = frame
				Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0, 6)

				local hint = label("", 80, 11, Color3.fromRGB(150, 155, 165))

				local function giveLink()
					pcall(function() setclipboard(GET_KEY_URL) end)
					hint.Text = "Link COPIED! Paste it in your browser (Ctrl+V), finish the steps, then copy your token."
				end
				giveLink()
				getBtn.MouseButton1Click:Connect(giveLink)

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(1, -24, 0, 34)
				box.Position = UDim2.fromOffset(12, 122)
				box.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
				box.TextColor3 = Color3.fromRGB(240, 240, 255)
				box.PlaceholderText = "Paste your token..."
				box.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
				box.ClearTextOnFocus = false
				box.Font = Enum.Font.Code
				box.TextSize = 14
				box.Text = ""
				box.Parent = frame
				Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -24, 0, 34)
				btn.Position = UDim2.fromOffset(12, 164)
				btn.BackgroundColor3 = Color3.fromRGB(30, 160, 90)
				btn.TextColor3 = Color3.fromRGB(235, 255, 240)
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 16
				btn.Text = "ACTIVATE"
				btn.AutoButtonColor = true
				btn.Parent = frame
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

				local msg = label("", 206, 13, Color3.fromRGB(170, 175, 185))

				btn.MouseButton1Click:Connect(function()
					local k = box.Text:gsub("%s", "")
					if #k < 8 then
						msg.TextColor3 = Color3.fromRGB(255, 90, 90)
						msg.Text = "Paste your token first - press GET KEY above."
						return
					end
					msg.TextColor3 = Color3.fromRGB(170, 175, 185)
					msg.Text = "Checking with server..."
					task.spawn(function()
						local exp, err = tokenCheck(k)
						if exp then
							pcall(function()
								writefile(KEY_FILE, k)
								writefile(KEY_UNTIL_FILE, hwidTag() .. "|" .. os.time() .. "|" .. exp)
							end)
							S.keyExp = exp
							S.keyGuiUp = false
							S.keyOk = true
							gui:Destroy()
							log("token accepted (entered)")
						else
							msg.TextColor3 = Color3.fromRGB(255, 90, 90)
							msg.Text = "Failed: " .. tostring(err)
						end
					end)
				end)
			end
			repeat task.wait(0.25) until S.keyOk
		end
	else

	local saved = ""
	pcall(function()
		if isfile(KEY_FILE) then saved = (readfile(KEY_FILE) or ""):gsub("%s", "") end
	end)

	local function activatedUntil()
		local t = 0
		pcall(function()
			if isfile(KEY_UNTIL_FILE) then t = tonumber(readfile(KEY_UNTIL_FILE)) or 0 end
		end)
		return t
	end

	if #saved > 0 and valid(saved) and os.time() < activatedUntil() then
		S.keyOk = true
		log(string.format("key accepted (saved), %d min left",
			math.floor((activatedUntil() - os.time()) / 60)))
	elseif not S.keyOk then
		if #saved > 0 and valid(saved) then
			log("key expired - get a new one via the link")
		end
		if not S.keyGuiUp then
			S.keyGuiUp = true

			local lp2 = game.Players.LocalPlayer
			local parent = (type(gethui) == "function" and gethui())
				or game:FindFirstChildOfClass("CoreGui")
				or lp2:WaitForChild("PlayerGui")

			local gui = Instance.new("ScreenGui")
			gui.Name = "BaanHubKeys"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 9999
			gui.Parent = parent

			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromOffset(340, 216)
			frame.Position = UDim2.fromScale(0.5, 0.45)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
			frame.BorderSizePixel = 0
			frame.Parent = gui
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", frame)
			stroke.Color = Color3.fromRGB(255, 196, 60)
			stroke.Thickness = 1.6

			local function label(txt, y, size, color)
				local t = Instance.new("TextLabel")
				t.Size = UDim2.new(1, -24, 0, size + 8)
				t.Position = UDim2.fromOffset(12, y)
				t.BackgroundTransparency = 1
				t.Font = Enum.Font.GothamBold
				t.TextSize = size
				t.TextColor3 = color
				t.TextWrapped = true
				t.TextXAlignment = Enum.TextXAlignment.Left
				t.Text = txt
				t.Parent = frame
				return t
			end

			label("BAAN HUB - Key Required", 10, 18, Color3.fromRGB(255, 196, 60))
			label(GET_KEY_URL ~= "" and ("Get a key: " .. GET_KEY_URL)
				or "Contact the seller to get your key.", 38, 12, Color3.fromRGB(150, 155, 165))

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -24, 0, 34)
			box.Position = UDim2.fromOffset(12, 66)
			box.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
			box.TextColor3 = Color3.fromRGB(240, 240, 255)
			box.PlaceholderText = "Enter your key..."
			box.PlaceholderColor3 = Color3.fromRGB(110, 115, 125)
			box.ClearTextOnFocus = false
			box.Font = Enum.Font.Code
			box.TextSize = 14
			box.Text = ""
			box.Parent = frame
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -24, 0, 34)
			btn.Position = UDim2.fromOffset(12, 108)
			btn.BackgroundColor3 = Color3.fromRGB(30, 160, 90)
			btn.TextColor3 = Color3.fromRGB(235, 255, 240)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 16
			btn.Text = "ACTIVATE"
			btn.AutoButtonColor = true
			btn.Parent = frame
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local msg = label("", 150, 13, Color3.fromRGB(170, 175, 185))

			btn.MouseButton1Click:Connect(function()
				local k = box.Text:gsub("%s", "")
				if #k < 4 then
					msg.TextColor3 = Color3.fromRGB(255, 90, 90)
					msg.Text = "Key too short."
					return
				end
				msg.TextColor3 = Color3.fromRGB(170, 175, 185)
				msg.Text = "Checking..."
				task.spawn(function()
					if valid(k) then
						pcall(function()
							writefile(KEY_FILE, k)
							writefile(KEY_UNTIL_FILE, tostring(os.time() + KEY_TTL))
						end)
						msg.TextColor3 = Color3.fromRGB(120, 235, 160)
						msg.Text = "Accepted! Starting..."
						task.wait(0.4)
						gui:Destroy()
						S.keyGuiUp = false
						S.keyOk = true
						log("key accepted (entered)")
					else
						msg.TextColor3 = Color3.fromRGB(255, 90, 90)
						msg.Text = "Invalid key."
					end
				end)
			end)
		end
		repeat task.wait(0.25) until S.keyOk
	end
	end
end

---------------------------------------------------------------------
-- DECRYPT AND RUN PAYLOAD
do
	local okP, payload = pcall(function()
		return crypt.decrypt(PAYLOAD_CT, PAYLOAD_KEY, PAYLOAD_IV)
	end)
	if not okP or type(payload) ~= "string" or #payload < 100 then
		log("payload decrypt FAILED: " .. tostring(payload))
		return
	end
	local fn, err = loadstring(payload, "=baan-hub-payload")
	if not fn then
		log("payload compile FAILED: " .. tostring(err))
		return
	end
	log("payload decrypted - starting bot (" .. tostring(#payload) .. " bytes)")
	fn()
end
