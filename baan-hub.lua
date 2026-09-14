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
--// BAAN HUB v9 DISTRIBUTION - key system + AES-256 encrypted payload
local KEY_URL = "https://pastebin.com/raw/LRU4XByY"          -- raw paste url with sha256 lines (fallback mode)
local TOKEN_API = "https://work.ink/_api/v2/token/isValid/"  -- work.ink key system (unique token per user); empty = pastebin mode
local GET_KEY_URL = "https://work.ink/2Tq7/baanhub-key"      -- shown in prompt: where users get a key/token
local HWID_LOCK = false     -- true = each key works on one device only
local KEY_FILE = "baan_hub_key.txt"
local KEY_UNTIL_FILE = "baan_hub_key_until.txt"
local KEY_TTL = 3 * 60 * 60 -- seconds a validated key stays activated (3 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "6ey2wS82XHEElW+Ym5h5yGlnNbEFVkAnsSg7ZWBwjiA="
local PAYLOAD_IV = "efuB7cns67+dbW7flY3/9A=="
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
