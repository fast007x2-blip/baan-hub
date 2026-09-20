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

local PAYLOAD_KEY = "Ha8KhBDbUy3x//nlnHuZFT0FG+Jq+07w0sJ2OBJJ1mg="
local PAYLOAD_IV = "hzz4qCVYU14SmST3/1cwJA=="
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
