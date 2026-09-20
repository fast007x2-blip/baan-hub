--// BAAN HUB MULTI-GAME ROUTER
local placeId = game.PlaceId
local universeId = game.GameId

-- [FREE / NO KEY REQUIRED] MyCourt (Sequence Basketball)
if placeId == 116047689628641 or placeId == 103130817606660 or universeId == 10476380360 then
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

-- [FREE / NO KEY REQUIRED] Karinderya!
if placeId == 116497287371701 or universeId == 10648820673 then
loadstring(game:HttpGet("https://raw.githubusercontent.com/fast007x2-blip/baan-hub/main/baan-hub.lua"))()

	return
end

-- [FREE / NO KEY REQUIRED] Anime Eggs (ขโมยและฟักไข่อนิเมะ!)
if placeId == 76377501906469 or universeId == 10747748563 then
--[[
    Baan Hub - Anime Eggs (ขโมยและฟักไข่อนิเมะ!)
    Custom Handcrafted Native GUI (Baan Hub Design)
    - 100% Native Roblox UI (Zero external loadstring dependencies)
    - Multi-Rarity Selection: เลือกได้หลายระดับพร้อมกัน (เช่น Cosmic + Mythic)
    - Rock-Solid Smooth ESP: Parented to CoreGui (Zero flickering, zero Z-fighting)
    - Egg Snatcher: Instant Rarity Warp & Safe Return Bypass
    - Auto Hatch, Equip Best Pets, Flight System [C/F]
    - Toggle Menu Keybind: RightShift / RightControl
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Cleanup previous execution cleanly
if getgenv()._AnimeEggsHubCleanup then
    pcall(getgenv()._AnimeEggsHubCleanup)
end

local Connections = {}
local function regConn(conn)
    table.insert(Connections, conn)
    return conn
end

-- Remotes & Modules
local GameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
local EggCmds = nil
pcall(function()
    local clientFolder = ReplicatedStorage:FindFirstChild("Library") and ReplicatedStorage.Library:FindFirstChild("Client")
    local eggCmdsMod = clientFolder and clientFolder:FindFirstChild("EggCmds")
    if eggCmdsMod then
        EggCmds = (require :: any)(eggCmdsMod)
    end
end)

-- Helpers
local function getChar()
    return localPlayer.Character
end

local function getRoot()
    local char = getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getMyPlot()
    local slot = tostring(localPlayer:GetAttribute("PlotSlot") or "")
    if slot ~= "" and Workspace:FindFirstChild("Plots") then
        return Workspace.Plots:FindFirstChild(slot)
    end
    return nil
end

local function getPetAreaPos()
    local plot = getMyPlot()
    if plot then
        local toUpdate = plot:FindFirstChild("ToUpdate")
        if toUpdate and toUpdate:FindFirstChild("PetArea") then
            return toUpdate.PetArea.Position
        end
        local center = toUpdate and toUpdate:FindFirstChild("CenterPoint")
        if center then
            return center.Position
        end
        return plot:GetPivot().Position
    end
    return nil
end

-- Rarity ranks & colors
local rarityRank = {
    ["Secret"] = 8,
    ["Cosmic"] = 7,
    ["Mythic"] = 6,
    ["Legendary"] = 5,
    ["Epic"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1,
}

local function getRarityColor(rarity)
    local r = tostring(rarity or ""):lower()
    if r:find("secret") then
        return Color3.fromRGB(255, 215, 0)
    elseif r:find("cosmic") then
        return Color3.fromRGB(190, 80, 255)
    elseif r:find("mythic") then
        return Color3.fromRGB(255, 65, 65)
    elseif r:find("legendary") then
        return Color3.fromRGB(255, 175, 25)
    elseif r:find("epic") then
        return Color3.fromRGB(180, 50, 240)
    elseif r:find("rare") then
        return Color3.fromRGB(40, 160, 255)
    elseif r:find("uncommon") then
        return Color3.fromRGB(50, 220, 80)
    else
        return Color3.fromRGB(220, 220, 220)
    end
end

-- Clean any old workspace-parented ESP remnants
if Workspace:FindFirstChild("LiveAreaEggs") then
    for _, egg in ipairs(Workspace.LiveAreaEggs:GetChildren()) do
        for _, d in ipairs(egg:GetDescendants()) do
            if d.Name == "MCPEggESP" or d.Name == "TestESP" then
                pcall(function() d:Destroy() end)
            end
        end
    end
end

-- Custom Notification Toast (Baan Hub Style)
local function showNotice(title, desc, color)
    color = color or Color3.fromRGB(90, 130, 255)
    task.spawn(function()
        local parentGui = gethui and gethui() or game:GetService("CoreGui")
        local notifGui = parentGui:FindFirstChild("AnimeEggsHub_Notifs")
        if not notifGui then
            notifGui = Instance.new("ScreenGui")
            notifGui.Name = "AnimeEggsHub_Notifs"
            notifGui.ResetOnSpawn = false
            notifGui.Parent = parentGui
        end

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 270, 0, 56)
        frame.Position = UDim2.new(1, -290, 1, -75)
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

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -24, 0, 20)
        titleLbl.Position = UDim2.new(0, 12, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = color
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = frame

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -24, 0, 18)
        descLbl.Position = UDim2.new(0, 12, 0, 28)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = desc
        descLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 11
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = frame

        -- Fade in
        frame.Position = UDim2.new(1, -290, 1, -55)
        frame.BackgroundTransparency = 1
        titleLbl.TextTransparency = 1
        descLbl.TextTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 0.08, Position = UDim2.new(1, -290, 1, -75)}):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TweenService:Create(descLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

        task.wait(2.2)

        -- Fade out
        local fadeTween = TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = UDim2.new(1, -290, 1, -95)})
        TweenService:Create(titleLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(descLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
end

-- Find target egg in nests matching multiple selected rarities
local function findTargetEgg(selectedRaritiesMap, targetWorld)
    local liveFolder = Workspace:FindFirstChild("LiveAreaEggs")
    if not liveFolder then return nil end
    local candidates = {}
    
    local hasAnySelection = false
    for _, enabled in pairs(selectedRaritiesMap) do
        if enabled then hasAnySelection = true; break end
    end
    local allowAll = (not hasAnySelection) or selectedRaritiesMap["Any / Best Available"] == true

    for _, egg in ipairs(liveFolder:GetChildren()) do
        if egg:IsA("Model") and egg:GetAttribute("CarriedBy") == nil and egg:GetAttribute("EggType") ~= nil then
            local r = egg:GetAttribute("Rarity") or "Common"
            local area = egg:GetAttribute("AreaId") or egg:GetAttribute("AssetCategory") or ""
            
            local matchWorld = (targetWorld == "All Worlds" or targetWorld == "All") or (area == targetWorld or egg.Name == targetWorld)
            local matchRarity = allowAll or (selectedRaritiesMap[r] == true)
            
            if matchWorld and matchRarity then
                table.insert(candidates, {
                    egg = egg,
                    name = egg.Name,
                    rarity = r,
                    rank = rarityRank[r] or 0
                })
            end
        end
    end
    
    if #candidates == 0 then return nil end
    
    table.sort(candidates, function(a, b)
        return a.rank > b.rank
    end)
    
    return candidates[1].egg, candidates[1].rarity, candidates[1].name
end

-- Egg Stealing Core Sequence
local isStealing = false
local function performStealSequence(targetEgg)
    if isStealing then return false, "Already executing a steal sequence" end
    if not targetEgg or not targetEgg.Parent then return false, "Target egg is gone or despawned" end
    
    local char = getChar()
    local root = getRoot()
    if not char or not root then return false, "Character not ready" end
    
    isStealing = true
    local eggName = targetEgg.Name
    local eggRarity = targetEgg:GetAttribute("Rarity") or "Unknown"
    
    local ok, err = pcall(function()
        -- Place held egg before starting if holding one
        if tostring(localPlayer:GetAttribute("HeldEggUid") or "") ~= "" then
            local petArea = getPetAreaPos()
            if petArea and GameRemotes and GameRemotes:FindFirstChild("PlaceEgg") then
                GameRemotes.PlaceEgg:FireServer(petArea + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3)))
                task.wait(0.2)
            end
        end
        
        -- 1. Warp directly to egg
        local eggPos = targetEgg:GetPivot().Position
        char:PivotTo(CFrame.new(eggPos + Vector3.new(0, 2, 0)))
        task.wait(0.25)
        
        -- 2. Steal remote
        if GameRemotes and GameRemotes:FindFirstChild("StealEgg") then
            GameRemotes.StealEgg:FireServer(targetEgg, targetEgg:GetAttribute("EggUid"))
        end
        task.wait(0.12)
        
        -- 3. Teleport to safe zone (X = 538 is safely behind SeparationLine X = 552.2)
        char:PivotTo(CFrame.new(538, 68, -342.5))
        task.wait(0.25)
        
        -- 4. Teleport back to player plot
        local petArea = getPetAreaPos()
        if petArea then
            char:PivotTo(CFrame.new(petArea + Vector3.new(0, 3, 0)))
            task.wait(0.3)
            -- Place egg on plot
            if GameRemotes and GameRemotes:FindFirstChild("PlaceEgg") then
                local placePos = petArea + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))
                GameRemotes.PlaceEgg:FireServer(placePos)
            end
        end
    end)
    
    isStealing = false
    
    if ok then
        showNotice("Egg Snatched! ⚡", string.format("Stole [%s] %s successfully!", eggRarity, eggName), getRarityColor(eggRarity))
    end
    
    return ok, err
end

-- Flight State
local flying = false
local flySpeed = 70
local minFlySpeed = 10
local maxFlySpeed = 300
local bv = nil
local bg = nil

local function stopFlying()
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    local hum = getHumanoid()
    if hum then
        hum.PlatformStand = false
    end
end

local function startFlying()
    stopFlying()
    local root = getRoot()
    local hum = getHumanoid()
    if not root or not hum then return end

    local newBg = Instance.new("BodyGyro")
    newBg.Name = "_FlyGyro"
    newBg.P = 9e4
    newBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    newBg.CFrame = root.CFrame
    newBg.Parent = root
    bg = newBg

    local newBv = Instance.new("BodyVelocity")
    newBv.Name = "_FlyVelocity"
    newBv.Velocity = Vector3.zero
    newBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    newBv.Parent = root
    bv = newBv

    hum.PlatformStand = true
end

local function setFlying(val)
    flying = val
    if flying then
        startFlying()
    else
        stopFlying()
    end
end

-- Key inputs for flight: C/F toggle, Z/X speed
regConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.F then
        setFlying(not flying)
    elseif input.KeyCode == Enum.KeyCode.Z then
        flySpeed = math.max(minFlySpeed, flySpeed - 10)
    elseif input.KeyCode == Enum.KeyCode.X then
        flySpeed = math.min(maxFlySpeed, flySpeed + 10)
    end
end))

regConn(RunService.RenderStepped:Connect(function()
    if not flying then return end
    local root = getRoot()
    local hum = getHumanoid()
    if not root or not hum or hum.Health <= 0 then
        stopFlying()
        return
    end

    if not bv or not bv.Parent or not bg or not bg.Parent then
        startFlying()
        return
    end

    hum.PlatformStand = true
    local camCF = camera.CFrame
    bg.CFrame = camCF

    local direction = Vector3.zero
    if not UserInputService:GetFocusedTextBox() then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.new(0, 1, 0)
        end
    end

    if direction.Magnitude > 0 then
        bv.Velocity = direction.Unit * flySpeed
    else
        bv.Velocity = Vector3.zero
    end
end))

-- States
local selectedRarities = {
    ["Cosmic"] = true,
    ["Mythic"] = true,
}
local selectedWorldFilter = "All Worlds"
local autoStealEnabled = false
local autoStealDelay = 3

local autoHatchEnabled = false
local autoEquipBestEnabled = false
local eggEspEnabled = false

-- Auto Hatch & Equip Loop
task.spawn(function()
    while true do
        task.wait(2)
        if not getgenv()._AnimeEggsHubCleanup then break end
        if autoHatchEnabled and EggCmds then
            pcall(function()
                local records = EggCmds.GetOwnerRuntimeRecords(localPlayer.UserId) or {}
                for uid, _ in pairs(records) do
                    if EggCmds.IsLocalEggReady(uid) then
                        EggCmds.RequestCompleteHatchEgg(uid)
                        task.wait(0.3)
                        if autoEquipBestEnabled and GameRemotes and GameRemotes:FindFirstChild("EquipBestPets") then
                            GameRemotes.EquipBestPets:InvokeServer()
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Steal Loop Worker
task.spawn(function()
    while true do
        task.wait(math.max(1.5, autoStealDelay))
        if not getgenv()._AnimeEggsHubCleanup then break end
        if autoStealEnabled and not isStealing then
            local liveFolder = Workspace:FindFirstChild("LiveAreaEggs")
            if liveFolder and #liveFolder:GetChildren() > 0 then
                local egg, _, _ = findTargetEgg(selectedRarities, selectedWorldFilter)
                if egg then
                    performStealSequence(egg)
                end
            end
        end
    end
end)

----------------------------------------------------------------------
-- GUI CONSTRUCTION (Baan Hub Native Design)
----------------------------------------------------------------------

local ParentGui = gethui and gethui() or game:GetService("CoreGui")
for _, name in ipairs({"BaanHub_AnimeEggs_GUI", "AnimeEggsHub_GUI", "WindUI", "AnimeEggsHub"}) do
    local old = ParentGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "BaanHub_AnimeEggs_GUI"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = ParentGui

-- Centralized ESP Container in CoreGui (Zero flickering, independent from Workspace models)
local EspContainer = Instance.new("Folder")
EspContainer.Name = "ESP_Container"
EspContainer.Parent = Screen

local activeEspMap = {} -- [egg] = { gui = BillboardGui, label = TextLabel, primary = Part }

local function clearAllESP()
    for egg, data in pairs(activeEspMap) do
        if data.gui then
            pcall(function() data.gui:Destroy() end)
        end
    end
    table.clear(activeEspMap)
    pcall(function() EspContainer:ClearAllChildren() end)
end

local function updateESP()
    if not eggEspEnabled then
        if next(activeEspMap) ~= nil then
            clearAllESP()
        end
        return
    end

    local liveFolder = Workspace:FindFirstChild("LiveAreaEggs")
    if not liveFolder then
        clearAllESP()
        return
    end

    local root = getRoot()
    local rootPos = root and root.Position or Vector3.zero

    -- Clean up despawned eggs
    for egg, data in pairs(activeEspMap) do
        if not egg.Parent or egg.Parent ~= liveFolder then
            if data.gui then pcall(function() data.gui:Destroy() end) end
            activeEspMap[egg] = nil
        end
    end

    -- Create or update active eggs smoothly
    for _, egg in ipairs(liveFolder:GetChildren()) do
        if egg:IsA("Model") and egg:GetAttribute("EggType") ~= nil then
            if egg:GetAttribute("CarriedBy") ~= nil then
                local d = activeEspMap[egg]
                if d then
                    if d.gui then pcall(function() d.gui:Destroy() end) end
                    activeEspMap[egg] = nil
                end
                continue
            end
            local primary = egg:FindFirstChild("Hitbox") or egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if primary then
                local data = activeEspMap[egg]
                if not data or not data.gui or not data.gui.Parent then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "EggESP_" .. egg.Name
                    bb.Size = UDim2.new(0, 160, 0, 42)
                    bb.AlwaysOnTop = true
                    bb.MaxDistance = 4500
                    bb.StudsOffset = Vector3.new(0, 11.5, 0)
                    bb.Adornee = primary
                    bb.ResetOnSpawn = false
                    bb.Parent = EspContainer

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Label"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 12
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.TextColor3 = getRarityColor(egg:GetAttribute("Rarity"))
                    lbl.Parent = bb

                    data = { gui = bb, label = lbl, primary = primary }
                    activeEspMap[egg] = data
                end

                local dist = math.floor((primary.Position - rootPos).Magnitude)
                local rarity = tostring(egg:GetAttribute("Rarity") or "Common")
                data.label.Text = string.format("[%s] %s\n%dm", rarity, egg.Name, dist)
                data.label.TextColor3 = getRarityColor(rarity)
            end
        end
    end
end

-- Smooth, persistent ESP heartbeat worker (every 0.25s)
task.spawn(function()
    while true do
        task.wait(0.25)
        if not getgenv()._AnimeEggsHubCleanup then break end
        pcall(updateESP)
    end
end)

-- Main Container Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 710, 0, 440)
Main.Position = UDim2.new(0.5, -355, 0.5, -220)
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
Sidebar.Size = UDim2.new(0, 200, 1, 0)
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
BrandSection.Size = UDim2.new(1, -20, 0, 50)
BrandSection.Position = UDim2.new(0, 14, 0, 14)
BrandSection.BackgroundTransparency = 1
BrandSection.Parent = Sidebar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 22)
Logo.Position = UDim2.new(0, 0, 0, 2)
Logo.BackgroundTransparency = 1
Logo.Text = "Anime Eggs"
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 18
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = BrandSection

local SubLogo = Instance.new("TextLabel")
SubLogo.Size = UDim2.new(1, 0, 0, 14)
SubLogo.Position = UDim2.new(0, 0, 0, 26)
SubLogo.BackgroundTransparency = 1
SubLogo.Text = "Baan Hub Edition"
SubLogo.TextColor3 = Color3.fromRGB(110, 125, 240)
SubLogo.Font = Enum.Font.GothamBold
SubLogo.TextSize = 10
SubLogo.TextXAlignment = Enum.TextXAlignment.Left
SubLogo.Parent = BrandSection

-- Tab Button Container
local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, 0, 1, -82)
TabContainer.Position = UDim2.new(0, 0, 0, 80)
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
ContentArea.Size = UDim2.new(1, -215, 1, -16)
ContentArea.Position = UDim2.new(0, 208, 0, 8)
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

    if subtitle and subtitle ~= "" then
        local hSub = Instance.new("TextLabel")
        hSub.Size = UDim2.new(1, 0, 0, 14)
        hSub.BackgroundTransparency = 1
        hSub.Text = subtitle
        hSub.TextColor3 = Color3.fromRGB(140, 140, 155)
        hSub.Font = Enum.Font.Gotham
        hSub.TextSize = 11
        hSub.TextXAlignment = Enum.TextXAlignment.Left
        hSub.Parent = card
    end

    return card
end

-- Toggle Builder
local function addToggle(card, labelText, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.Position = UDim2.new(1, -38, 0.5, -10)
    pill.BackgroundColor3 = defaultVal and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(35, 35, 45)
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(1, 0)
    pCorner.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local state = defaultVal
    local function updateVisual(s)
        TweenService:Create(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = s and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(35, 35, 45)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = s and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
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

    regConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end))

    regConn(UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end))
end

-- Button Builder
local function addButton(card, labelText, callback, btnColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = btnColor or Color3.fromRGB(90, 120, 255)
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = card

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (btnColor or Color3.fromRGB(90, 120, 255)):Lerp(Color3.fromRGB(255, 255, 255), 0.15)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = btnColor or Color3.fromRGB(90, 120, 255)
        }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
    return btn
end

-- Multi-Select Dropdown Builder (เลือกได้หลายระดับพร้อมกัน)
local function addMultiDropdown(card, labelText, options, defaultSelectedMap, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.Parent = card

    local rLayout = Instance.new("UIListLayout")
    rLayout.Padding = UDim.new(0, 6)
    rLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rLayout.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 36)
    mainBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    mainBtn.BorderSizePixel = 0
    mainBtn.Text = ""
    mainBtn.AutoButtonColor = false
    mainBtn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = mainBtn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Color3.fromRGB(36, 36, 46)
    bStroke.Thickness = 1
    bStroke.Parent = mainBtn

    local selLbl = Instance.new("TextLabel")
    selLbl.Size = UDim2.new(1, -36, 1, 0)
    selLbl.Position = UDim2.new(0, 12, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    selLbl.Font = Enum.Font.GothamMedium
    selLbl.TextSize = 13
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.Parent = mainBtn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = Color3.fromRGB(150, 150, 165)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = mainBtn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.Parent = row

    local lfCorner = Instance.new("UICorner")
    lfCorner.CornerRadius = UDim.new(0, 6)
    lfCorner.Parent = listFrame

    local lfStroke = Instance.new("UIStroke")
    lfStroke.Color = Color3.fromRGB(36, 36, 46)
    lfStroke.Thickness = 1
    lfStroke.Parent = listFrame

    local lfLayout = Instance.new("UIListLayout")
    lfLayout.Padding = UDim.new(0, 3)
    lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lfLayout.Parent = listFrame

    local lfPad = Instance.new("UIPadding")
    lfPad.PaddingTop = UDim.new(0, 4)
    lfPad.PaddingBottom = UDim.new(0, 4)
    lfPad.PaddingLeft = UDim.new(0, 4)
    lfPad.PaddingRight = UDim.new(0, 4)
    lfPad.Parent = listFrame

    local selectedMap = {}
    if type(defaultSelectedMap) == "table" then
        for k, v in pairs(defaultSelectedMap) do
            if v == true then
                selectedMap[k] = true
            end
        end
    end

    local function updateSummary()
        local names = {}
        for _, opt in ipairs(options) do
            if selectedMap[opt] then
                table.insert(names, opt)
            end
        end
        if #names == 0 then
            selLbl.Text = "None (Click to select)"
            selLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        elseif #names <= 2 then
            selLbl.Text = table.concat(names, ", ")
            selLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            selLbl.Text = string.format("%s, %s +%d more", names[1], names[2], #names - 2)
            selLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listFrame.Visible = isOpen
        arrow.Text = isOpen and "^" or "v"
    end)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        optBtn.BackgroundTransparency = selectedMap[opt] and 0.2 or 1
        optBtn.BorderSizePixel = 0
        optBtn.Text = ""
        optBtn.AutoButtonColor = false
        optBtn.Parent = listFrame

        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 4)
        oCorner.Parent = optBtn

        local checkMark = Instance.new("TextLabel")
        checkMark.Size = UDim2.new(0, 24, 1, 0)
        checkMark.Position = UDim2.new(0, 6, 0, 0)
        checkMark.BackgroundTransparency = 1
        checkMark.Text = selectedMap[opt] and "[✓]" or "[  ]"
        checkMark.TextColor3 = selectedMap[opt] and Color3.fromRGB(90, 130, 255) or Color3.fromRGB(120, 120, 130)
        checkMark.Font = Enum.Font.GothamBold
        checkMark.TextSize = 12
        checkMark.TextXAlignment = Enum.TextXAlignment.Center
        checkMark.Parent = optBtn

        local optLbl = Instance.new("TextLabel")
        optLbl.Size = UDim2.new(1, -38, 1, 0)
        optLbl.Position = UDim2.new(0, 34, 0, 0)
        optLbl.BackgroundTransparency = 1
        optLbl.Text = opt
        optLbl.TextColor3 = selectedMap[opt] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 195)
        optLbl.Font = Enum.Font.GothamMedium
        optLbl.TextSize = 12
        optLbl.TextXAlignment = Enum.TextXAlignment.Left
        optLbl.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            selectedMap[opt] = not selectedMap[opt]
            local isSel = selectedMap[opt]
            checkMark.Text = isSel and "[✓]" or "[  ]"
            checkMark.TextColor3 = isSel and Color3.fromRGB(90, 130, 255) or Color3.fromRGB(120, 120, 130)
            optBtn.BackgroundTransparency = isSel and 0.2 or 1
            optLbl.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 195)
            updateSummary()
            callback(selectedMap)
        end)
    end

    updateSummary()
end

-- Single Dropdown Builder
local function addDropdown(card, labelText, options, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.Parent = card

    local rLayout = Instance.new("UIListLayout")
    rLayout.Padding = UDim.new(0, 6)
    rLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rLayout.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 36)
    mainBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    mainBtn.BorderSizePixel = 0
    mainBtn.Text = ""
    mainBtn.AutoButtonColor = false
    mainBtn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = mainBtn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Color3.fromRGB(36, 36, 46)
    bStroke.Thickness = 1
    bStroke.Parent = mainBtn

    local selLbl = Instance.new("TextLabel")
    selLbl.Size = UDim2.new(1, -36, 1, 0)
    selLbl.Position = UDim2.new(0, 12, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = tostring(defaultVal or options[1])
    selLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    selLbl.Font = Enum.Font.GothamMedium
    selLbl.TextSize = 13
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.Parent = mainBtn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = Color3.fromRGB(150, 150, 165)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = mainBtn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.Parent = row

    local lfCorner = Instance.new("UICorner")
    lfCorner.CornerRadius = UDim.new(0, 6)
    lfCorner.Parent = listFrame

    local lfStroke = Instance.new("UIStroke")
    lfStroke.Color = Color3.fromRGB(36, 36, 46)
    lfStroke.Thickness = 1
    lfStroke.Parent = listFrame

    local lfLayout = Instance.new("UIListLayout")
    lfLayout.Padding = UDim.new(0, 2)
    lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lfLayout.Parent = listFrame

    local lfPad = Instance.new("UIPadding")
    lfPad.PaddingTop = UDim.new(0, 4)
    lfPad.PaddingBottom = UDim.new(0, 4)
    lfPad.PaddingLeft = UDim.new(0, 4)
    lfPad.PaddingRight = UDim.new(0, 4)
    lfPad.Parent = listFrame

    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listFrame.Visible = isOpen
        arrow.Text = isOpen and "^" or "v"
    end)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel = 0
        optBtn.Text = "  " .. tostring(opt)
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.Parent = listFrame

        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 4)
        oCorner.Parent = optBtn

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
        end)

        optBtn.MouseButton1Click:Connect(function()
            selLbl.Text = tostring(opt)
            isOpen = false
            listFrame.Visible = false
            arrow.Text = "v"
            callback(opt)
        end)
    end
end

----------------------------------------------------------------------
-- BUILD TABS & CONTENT
----------------------------------------------------------------------

-- 1. Egg Snatcher Tab
local stealPage = createTab("Egg Snatcher", "⚡")

local eggSelectCard = createSection(stealPage, "Target Egg Selection", "Choose egg tier (multi-select supported) and anime world")

local rarityOptions = {
    "Secret",
    "Cosmic",
    "Mythic",
    "Legendary",
    "Epic",
    "Rare",
    "Uncommon",
    "Common",
    "Any / Best Available"
}

addMultiDropdown(eggSelectCard, "Select Rarities (เลือกระดับไข่ - ติ๊กได้หลายระดับ)", rarityOptions, selectedRarities, function(valMap)
    selectedRarities = valMap
end)

local animeWorldsFilter = {
    "All Worlds", "Naruto", "DragonBall", "OnePiece", "Jujutsu", "SoloLeveling",
    "HeroArena", "DemonSlayer", "BlackClover", "Legends", "DarkStreet"
}
addDropdown(eggSelectCard, "World Filter (กรองโลกอนิเมะ)", animeWorldsFilter, "All Worlds", function(val)
    selectedWorldFilter = val
end)

local stealOpsCard = createSection(stealPage, "Steal & Return", "Warp to nest -> Grab egg -> Escape via safe zone -> Return to plot")

addButton(stealOpsCard, "⚡ Steal Selected Egg Now (วาร์ปไปเก็บแล้วกลับมาเลย)", function()
    local egg, rarity, name = findTargetEgg(selectedRarities, selectedWorldFilter)
    if egg then
        showNotice("Target Acquired 🎯", string.format("Snatching [%s] %s...", rarity, name), Color3.fromRGB(90, 130, 255))
        task.spawn(function()
            performStealSequence(egg)
        end)
    else
        showNotice("Not Found ⚠️", "No matching egg found on map! (Wait for spawn)", Color3.fromRGB(255, 175, 25))
    end
end, Color3.fromRGB(90, 120, 255))

addToggle(stealOpsCard, "Auto Steal Loop (วนลูปอัตโนมัติ)", false, function(state)
    autoStealEnabled = state
    showNotice("Auto Steal", state and "Auto-steal enabled!" or "Auto-steal disabled.", state and Color3.fromRGB(85, 255, 127) or Color3.fromRGB(240, 70, 70))
end)

addSlider(stealOpsCard, "Auto Steal Delay", 2, 15, 3, "s", function(val)
    autoStealDelay = val
end)

-- 2. Auto Farm Tab
local farmPage = createTab("Auto Farm", "✨")

local hatchCard = createSection(farmPage, "Hatching & Pets", "Automate egg hatching and equipping strongest pets")
addToggle(hatchCard, "Auto Hatch Ready Eggs", false, function(state)
    autoHatchEnabled = state
    showNotice("Auto Hatch", state and "Auto-hatching enabled!" or "Auto-hatching disabled.", Color3.fromRGB(90, 130, 255))
end)

addToggle(hatchCard, "Auto Equip Best Pets", false, function(state)
    autoEquipBestEnabled = state
    if state and GameRemotes and GameRemotes:FindFirstChild("EquipBestPets") then
        GameRemotes.EquipBestPets:InvokeServer()
    end
end)

addButton(hatchCard, "Equip Best Pets Now", function()
    if GameRemotes and GameRemotes:FindFirstChild("EquipBestPets") then
        GameRemotes.EquipBestPets:InvokeServer()
        showNotice("Equip Best", "Best pets equipped!", Color3.fromRGB(85, 255, 127))
    end
end, Color3.fromRGB(50, 160, 90))

local plotCard = createSection(farmPage, "Plot Actions", "Quick shortcuts for your plot and equipment")
addButton(plotCard, "Place Held Egg On Plot", function()
    local petArea = getPetAreaPos()
    if petArea and GameRemotes and GameRemotes:FindFirstChild("PlaceEgg") then
        local placePos = petArea + Vector3.new(math.random(-4, 4), 1, math.random(-4, 4))
        GameRemotes.PlaceEgg:FireServer(placePos)
        showNotice("Place Egg", "Egg placed on your plot!", Color3.fromRGB(90, 130, 255))
    end
end, Color3.fromRGB(70, 70, 85))

addButton(plotCard, "Teleport To My Plot", function()
    local petArea = getPetAreaPos()
    local char = getChar()
    if petArea and char then
        char:PivotTo(CFrame.new(petArea + Vector3.new(0, 3, 0)))
        showNotice("Teleport", "Teleported to your plot!", Color3.fromRGB(90, 130, 255))
    end
end, Color3.fromRGB(70, 70, 85))

addButton(plotCard, "Teleport To My Treadmill", function()
    local plot = getMyPlot()
    local char = getChar()
    if plot and char and plot:FindFirstChild("TreadmillModel") then
        local belt = plot.TreadmillModel:FindFirstChild("RunningBelt") or plot.TreadmillModel:FindFirstChild("Root")
        if belt then
            char:PivotTo(CFrame.new(belt.Position + Vector3.new(0, 3, 0)))
        else
            char:PivotTo(plot.TreadmillModel:GetPivot() + Vector3.new(0, 3, 0))
        end
        showNotice("Treadmill", "Teleported to your treadmill!", Color3.fromRGB(90, 130, 255))
    end
end, Color3.fromRGB(70, 70, 85))

-- 3. Anime Worlds Tab
local tpPage = createTab("Anime Worlds", "🗺")
local tpCard = createSection(tpPage, "Guard Nests Teleport", "Direct teleport to any anime guard nests")

local animeWorlds = {
    "Naruto", "DragonBall", "OnePiece", "Jujutsu", "SoloLeveling",
    "HeroArena", "DemonSlayer", "BlackClover", "Legends", "DarkStreet"
}

local selectedWorld = "Naruto"
addDropdown(tpCard, "Select Anime World", animeWorlds, "Naruto", function(val)
    selectedWorld = val
end)

addButton(tpCard, "Teleport To Selected Nests", function()
    local char = getChar()
    local guardAreas = Workspace:FindFirstChild("__OBJECTS") and Workspace.__OBJECTS:FindFirstChild("Areas") and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
    if char and guardAreas and guardAreas:FindFirstChild(selectedWorld) then
        local nests = guardAreas[selectedWorld]:FindFirstChild("Nests")
        if nests then
            char:PivotTo(nests:GetPivot() + Vector3.new(0, 5, 0))
        else
            char:PivotTo(guardAreas[selectedWorld]:GetPivot() + Vector3.new(0, 5, 0))
        end
        showNotice("Teleport", "Teleported to " .. selectedWorld, Color3.fromRGB(90, 130, 255))
    end
end, Color3.fromRGB(90, 120, 255))

-- 4. Movement Tab
local movePage = createTab("Movement", "💨")
local flyCard = createSection(movePage, "Flight System [C / F Toggle]", "Fly freely through walls with camera direction controls")

addToggle(flyCard, "Fly Enabled [C / F]", false, function(state)
    setFlying(state)
end)

addSlider(flyCard, "Fly Speed [Z: - / X: +]", 10, 300, 70, " studs/s", function(val)
    flySpeed = val
end)

local charCard = createSection(movePage, "Character Modifiers", "Adjust character speed and jump power")

addSlider(charCard, "WalkSpeed", 16, 250, 16, "", function(val)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)

addSlider(charCard, "JumpPower", 50, 250, 50, "", function(val)
    local hum = getHumanoid()
    if hum then hum.JumpPower = val end
end)

-- 5. Visuals Tab
local espPage = createTab("Visuals", "👁")
local espCard = createSection(espPage, "ESP Overlays", "Live world overlays for nest eggs (Smooth & Zero-Flicker)")

addToggle(espCard, "Anime Egg ESP (Rarity & Distance)", false, function(state)
    eggEspEnabled = state
    if not state then
        clearAllESP()
    else
        task.spawn(updateESP)
    end
end)

-- 6. Settings Tab
local setPage = createTab("Settings", "⚙")
local keyCard = createSection(setPage, "Keybinds & Controls", "Toggle menu anytime using keyboard")
local keyInfoLbl = Instance.new("TextLabel")
keyInfoLbl.Size = UDim2.new(1, 0, 0, 20)
keyInfoLbl.BackgroundTransparency = 1
keyInfoLbl.Text = "Menu Keybind: RightShift or RightControl"
keyInfoLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
keyInfoLbl.Font = Enum.Font.Gotham
keyInfoLbl.TextSize = 12
keyInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
keyInfoLbl.Parent = keyCard

local closeCard = createSection(setPage, "Script Management", "Unload and clean up all hooks and loops")
addButton(closeCard, "Unload / Close Script", function()
    if getgenv()._AnimeEggsHubCleanup then
        getgenv()._AnimeEggsHubCleanup()
    end
end, Color3.fromRGB(180, 40, 50))

-- Set Default Active Tab
switchTab("Visuals")

-- Keybind to toggle GUI
regConn(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
    end
end))

-- Top Close / Minimize Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.AutoButtonColor = false
closeBtn.Parent = Main

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 6)
cbCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    closeBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
end)
closeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    showNotice("Menu Hidden", "Press RightShift or RightControl to reopen", Color3.fromRGB(150, 150, 165))
end)

-- Global Teardown Handler
local function cleanupAll()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    stopFlying()
    clearAllESP()

    if Screen then
        Screen:Destroy()
    end
    local notifs = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("AnimeEggsHub_Notifs")
    if notifs then notifs:Destroy() end

    getgenv()._AnimeEggsHubCleanup = nil
end
getgenv()._AnimeEggsHubCleanup = cleanupAll

local stateGlobal = rawget(_G, "STATE") or (getgenv and getgenv().STATE)
if typeof(stateGlobal) == "table" and stateGlobal.onCleanup then
    stateGlobal.onCleanup(cleanupAll)
end

showNotice("Baan Hub Ready", "Zero-Flicker ESP Fixed & Loaded!", Color3.fromRGB(90, 130, 255))
print("Baan Hub - Anime Eggs loaded with zero-flicker ESP!")

	return
end
--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 24 * 60 * 60 -- seconds a validated key stays activated (24 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "wcusojB8hEzxx/DS7K+OCQc4gTPq6/g3RY4K1AE5yBI="
local PAYLOAD_IV = "xsQk+Ve24Go7kyBVYY9d7w=="
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
