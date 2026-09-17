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

local PAYLOAD_KEY = "UAQwg9i4aZD9J7XAf1hzUAeV7LjGRAyROISRuaLVzhY="
local PAYLOAD_IV = "dSObbMthxaE5/nV3Eb1w5w=="
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
