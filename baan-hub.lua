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

local PAYLOAD_KEY = "D2NmERmAP98uaneJPJc1/efdxV60ffhFAxwMd06kKjI="
local PAYLOAD_IV = "Zv5gJQSApOfmz9IPNOSuTw=="
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
