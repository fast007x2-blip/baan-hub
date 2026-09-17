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

local PAYLOAD_KEY = "kWadWKpqwyR9EoBjUjZrCuVlzmXC4XAk2xfJRtNfV8A="
local PAYLOAD_IV = "F0wpKe/uqVql8DH1aOn5xg=="
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
