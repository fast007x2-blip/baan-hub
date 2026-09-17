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

local PAYLOAD_KEY = "wNuNfd8wZdNX6Scy2sW3pNG6a8g7lDyRdLWI2O3T34w="
local PAYLOAD_IV = "HlsEYljcwuAVqjryHv/dqg=="
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
