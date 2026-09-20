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

-- [KEY PROTECTED] +1 Loot To Forge (Baan Hub Cloudflare Edge Verified)
if placeId == 118805555015549 or universeId == 10684750879 then
	loadstring(game:HttpGet("https://baanhub-auth.forgepanel-fast007x2.workers.dev/api/loader?service=loot-to-forge"))()
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

local PAYLOAD_KEY = "UqBx5gloDEH+59oqCEBA39Adia60siMwilM+oyN8ARM="
local PAYLOAD_IV = "gdMFNgGnWxkQKWsKZugqhg=="
local PAYLOAD_CT = "Oi9BPIljw36QC+uPraoXMjyyxM7+2+PXdAmHMf3IZXSrzp4NjyOtGcxjCZ89HBDqFFTvtfvdC9EPs3PnNNIgDr1BUBv75XzCx97tKG+jRNlH39cuZPl+FQxVlCKzMRVt1EHKHtnZmKezBqQ46XqWN1TvSj+SYI93nsiRDGXxhKekCpsguK7Vl+R5FzBa26BsUZRJONLzDvleiq/E+2pUd+divRXRo+9V6TDM8IThyaRX8y311jWwPbHF66Uw8F6ai2Z0fWUkstvmjXwhPRiI16FeYUDH7cRpvEz+kIFMg3z1lyf/QkA7IgJCO98NN6ENm4yuwbPluSMBjkSatHsNcr4y72rgDAZbj+Ef4IG0tidLKK22H1jNv8DPKlfw5Qxap40vseWYRlJ9XSbJ5AA4rzYEaK1O2n3iqfNWlY/4x9Yh8vmrzTgfjnH9TwrtKw5d1BgpwGDfWGHQA/6XoYEPZChqPSrCrSycM3fi/TWC32Ro5S7GuqFbEZCHe1oAtLL7qxs2x2ffCBTO64vaI7wKCrQS4Z4TqiQ31R7npjJpLSXlFDyzoYUWZA3KAvd9ToSjtwTG/QDf7f3cWATtUHyOlm4TU8EDZSqhCqEqQXIMLq4qM6y4Nh1I4Pvz0H7aKkC3qHo+wL6g0DcVldx3U/08dIUfrNFChrVKd1InRT94+y/XDG0ZmWpQPDiPasf1i+O6olTQrr7HptlHjWBA/agDrxwzBj2d7Ho0OYuQZI4uq9aE5AR40/0FljnDE411OJquzXX2y6q9DUvj54AUkISKw+T/3ulP/hSz0+Gvk2ZP5LEXr9PfKhEnStDNBZMFE2miI4LV5TmIKGJpkusKZKl2wHuZtPnjp+zDj64ixXXuvPLI/P3CpnpHfnDqxXGHEVxHk1EkkJqlrPTMfDisQjUC1iikIm0V81SV7jRzErDHxxYBc+W8dPeEo9lLz/8pxsxFuoWw1vsheUyvBbURXSG2TV+Qb6KWmovKiFz4+6qZ/EMn6MqnNPbg0JmwCEkqIVmB1wvANJn0lRXFzqbc27LyvI9aTSiGkeKjNAPFZvgjqr91DeDBKPxjUwrI4834yU2ojTm95g9FvkveqNbE57IwOnkAExq5+RWZfUr98wcvJQOQu1n63ahyqLTfMTP4pVCjuQLmcc95unQHSxnqa5ez8K7RiU+QwyWn7D6KsnqVc2pEP0Ej2UP9NsgQGRJof1W4jjWNCiG1dlcbAlr5jDwENiyxGh8Aq6IPv65HyvcbHH5mHwzfk2DoWoQmw9dc4FJrK2J7pv1S8nhVWpr3slA+Ip2KeUs8qX5/77qGqxJ91/dlkpNfZ2TEUO3XjdCf0sV/8Yv+gf26ykVPWJuwNXtzvwAx/7HRYnqPijJjeE7tucfW7URuDKD64vkBwjcJ4NxbBkLtAy3+/GWX8oyN1veEvFsUKve8FEY2pJnes90UmlqUKqW61lXSnOwcT7CHPidkNiXl/39p9+rhpzmex5AeFt/7psUFUMFeDBfB9WE22G9L8SVIPUMnwPLk+9pfgjicwdWYjri51We+lc4eYxiLeQvEi5JgIuu6CSUxhOgR8K1ciJUiHfdxCQ+wdExKhYzMsvDjWcMLHkMg+kbokwJ+FENUGb+4IKnezS6l+5A4zLEC/+int/LsySNUGNDykf3YhWNCfNOZmyJCCkPRyVPIgp/BnMk4GspPLtYhRrVJbZoniUdmH3xnrLzmiBONeGU3Ebj0vhjOGXPN/ojrET31nXC+KJENg8w7pIyIWAP2MP6xUDi/NnXA2gX1S9HtBwSV6zu5hZY9vEwtV9tHRqBi5KVfhkw5yPII+aEfUhJVyh+8fGkJV0cEVvsPimnsPMzRiHv/op6d/vA8RBUdtYEU7lWAJMyFsRZQPt5jysGf/5I92wU0v8ASLioeTF4UOwr+CsoJJlmav+qpz3oUBbZk9JbrzNOeNRrGLvJZO8pr2elHLoU+w2iaG6BDA05AukUZIC3Ugkua1Jzc1Jse4hnHh9m5y/O300R5j8baSNH7zgZDnFCygKKYi+GMo5Ogr5sLI5XHlgNwi7uu5e+UGxsAwvvrtN3XQOb81F/WDNXxaQMtwbAjzdFceJL0J4hLZ7l9N9QN47YyE3jEC7XoZLWiIwe/sEbVy4WyyKt8QOJ/QxPU1IUqDeJhE08Ia6fo++0V4KQdBv+VDwk9Rdf0Za4RBIOzHFJJHpdNWipTRie55BQ+P2qDbf+rGhnwoIHuJ416ME/pHeZzoJkF3v6fYINk+nrZMIOW1aAB2egAlAF5D0FCo6+SAHulll7qrnL6vCpxOv4fx+AapPnZzP6Rt0elReja9azOFRuUKhZwjent7viX3xLQFjBVYPdgK4jl97b5K4G6FekQFAEmptLBStrZ3udrKUtWlUIA/4uDkWM22xoPPhPpp1PD5VFkDu81yx0XUFSHP5FVCphks/4/rSQOGgtCvzeoedr5gGOKYXFrYGH8QJm8FBQBlkDVmWkKl6X9vwLRzvmrHDL/eeGZpkBVlTc8h+lpoqzSyHBG0F1PZfq6Pb2tzFWkegUUq16I0ZnfW3ZJWZbVlMh1DQlD5sQo68N1qrN0mc6Th1XfAm5rNIWeSux+qWjpsfJ/w71aCT7qDr4C21OnEv3ST+ieV0BjtIgjsTs33e0juflGVeqF6EqGvhlchzU3S2/BL7p4ziTGUK0E6SAEwD23XBvv6O2r6ITUBtA8HGPZkqBGEoCM2NwG+5zDjlq23WlWHaqWB2Mx3wD2TflSXY5hoegz15xCqCJwpS51ASuRDkOpBnXWEKK1LPqZcEjrYTVDxZuSN0ZLP70aeu7DAEEYVujxCBVgLCHGo1k7t9TCPj4AoNsjAYtJzjCSpNlNLc8OkzYdzRn6kUjodhbkWT1E/7uBk6f8DmZ9xF32b6baTbdtirmzwpEmqTl74rZb70jaXoBjujCuCSp4+THpBYm3VK7sqhV36Oryr4GSyadTJi0vwVqJ0kOhUVLDBaQW1jYIA0EO1TeJcyJ98ujNHsC3Zi1cVOMkW+xMXPcWgT2Hl1ALORzWYI1d5a01Nh47EcrVWlBafBLXHJyDF1IY2/sTE+lCIUstGxRpjjC+jRfICiCbHyWJnJJBr6XEhayhKiIHPAMizwyJfu1NsCNmHNRyyRyO8XJQUjMVBer9PDl7dArKggA32frmDbGu0JV01XJ2vn/9flQV9K8+hjE6pSyvWLw5mIeSFNv6MceOgknhC0kZoGpYawZvQdH7kbof4qR64xlqOAy0xTJBeMkwRvD95OQ9tgS0KAImUOs0AdAg3vrrxTloBGsk9CamOUVohlBcysfSRgXq85dSp85XRWnorzH/aZguiQKGi97/Yfel+AcyUz31Rm1oQc/6bOkxPvXuMjFet7cjHU4FhrS/SyMV8MYx4iYR9Kz47zhPSvqGxBhRgwh/6MF8JzFWeZM0XzQa4KOVG5jh6NSD6ImAMEjlICDZvJ/oR9CwKGOELduj7DJm1yZZNTCn+rweJXDHv7UV2f6bM7dyvDut+DFZEECWV2j6GkzoVEBHXWT+93hj42+Te9IPu1hIfIGjuxpcLr1IK9wCPv+l3wt/cr8nR5V1KZrgpBIEoqw8wLTt5/ZAZEwOsKzMpx71GvjF4bjKV4wC0mqIg4bXJZHELOA11joI4MHpBWtwFVuH7fprjU2J+0YK1KucJ2Ypllnn6Hnn+jHnN9+r47Wa++k+fN7vVj9pYb4SD7tVQvxb1Bz3OvtypIQ3fB+rZaZ/f9H+G6omw7bF0unN93gT2I0R91GhklG7QqTTRlfpPcpvPrsbtAR4lUS9si/4xvZUmmHKMZNvf8pLuMfqk0sih4ZsXVtZzB3LdNoRsZ3OM55kvIq74FADEy3t6DZ7e1V/Jw5a7E2wnmT/wQ6ya5CpNZKf+aaRU0VEiZDNv51TlerAQGYyTurX3MvbcdIvZdcpmHNfKbM+NktwpIf0ozwRZqjiRR+3+9ZYIxPmtSy6VsHdCVrnWhsrI6/qV0aQzgWAB8kV1e56SFNSd1Fz7NraPAdUxKcP4pCJWisGMBlfBma2/RHb+uZrjuwLko6f2huicUbWnXVAMg+2m84gsJzew/+nrpyhzkFjBa3fBOohnNW9VLMZYSKWEuAQGWxjjrKN1t+s8aFYSCYECDNQTIQqFv/7dFrChE0+DqjiVF/6ZHfnVU5/q436k+CUtSzI94qadRY6B98mSXvcwMaIV9DmUaXzXltgMfkYQqEA10A4n10sHgbHwhtpOxOQ2HEcWoTyQK9SEJXBDsMLTR4L2oyXYc+AMb3h3C/PlmZC9Emiux7XuVVnkZ2ND6VFbmXPjaMiZomaLIDXH14GKFhkVOdDbRBOzdXzAAmklED4AodnYwPXQL6YdN9mVJ1gZHJQS75QdpNWh8cE05+ypVZvZvM+aMvRhIw5xTNHA0ZN9TAVVCMy5p9TZTS9m7Z0ejEBD0mlqhl6KpP7kCYHeB0R+qj8pih2jkk0JOCU5epfHkAiULJ/i0IA1W/eEWeoL83Rbt6WL0s6aZ2aIvUwXOrz4gHJEVEmHmMRvDFol81MJJTgllWDnRED7P3fMTL6TGApayiJEVZUkCLgJJvfyH6yiEglha72Q7UWfajteR3juvEp3Dbxjg789xw4e6QDUDC/TuYBLZFJdZx5gesriz/0nB3jJ3lnrvrMwfhNnfqjVoeopszx0bhPNEj6/3Hf4/x/Y7VFYrgg5OFajgVvC9QjkwihQmm74FCNDSPZkfc03DCoj8/kbsSPajY+HEJXBFaC1YnhltKTP9C2KWJGF5L2SXnFNVpsptWPZ8IjsVQ/tzsNG9YDzE4/iz1QU3cmCPNYqEAHgQDdKRg8HLWt8A4C9630QJHoPvmlIMiMr8jLA7QcuF7eT8TBwAMNAcFNbgCZlvfuWXPiQ8c2Rd1KwfKNTvqUBygsLekJg6XmKAmotBup5+x8aVJlEBJjb2gLssG1kbCAuDKuMVyZCTvPlC+hPL1PbHkFcjN+Ol0u0JMP3iwgGSXEHkaLg2x/jQgsaftTA5dX1/ELeV0vYZqLd/V2+8sITzfXNMZI7xwlUKuAW4HPWUOnIUBd+d8j64BjuBgJz/LQlvNF3dW1DED4dzDTx/Bl8c7xfkYRClrTPFqkSR+jykZQgHk8VaGI4kHmNV1Os+WAOWq9iIyZDi/TN7391NYCdC6/HWifmEcnq6jogFZuXlGjP+nkEWGfTApz5isizvPU7dv5nco4gzfy/LV9oKOL+wTAWYJaySmZex4EmdmE1C/JSm8slPyfqyDsde/5hV7v+YFNOwkNc5WfIbdKdQYnt+d+M6HhH8iIcsHsYk98+bpnBfxVha5zzdEDXF/t8pruop7T1hgCOv1oa14Idwof4juVTCHxuRq+v3e0EX9bsv32Da7shsGIWQNEwrdTRxlN4ZK4L26X0nAY0/50F1dYSE67l/4342RI1l5FgZ4EspbYm9mAthzUsLXRSroWLfq++hn+zHkKt9mMRck8fIK91luxmmsOHFrEOIMtU7avI/BHeK77oNRM0W3e3jCr+OGsuIF6v1rXuXRv/OPM7ap8QnUxJIp6oHYbovbwSFD+RKuapvWBAf1FSg69RVa44GwwR/7Qe6WtWCEnZTyybab6RbNzYRCwBFn6lrxgFzSed40aud92WusBRXxfPRtBRdqdnsLmkAEbjQh+udLMi2WiCU7EZJ49SNYYF7mpddrtzGqGJByG5O+CAMAKHIDW8W7VqvQRK3OlgtGQ6WN4qYusc8GqWH9Ek+OFO8hZxj84g/b5/tYb14atp8MDs+Els/hb1eKVbHXGnzcBEWizAGI1w81Omf6Zk4b4bYxqV7Qejjk724ybIgWR+r3G/51P578vWEpnEdzR+Re+ld7emmQnxPxtu6PXCcFrLiXhlVYU1sNJgSop0uch/WGNlwq07w91TdAvC5oeQbNCEd7UUL5Kx6pTEE2GlBx7sjP4u/KFU7bBal8VdtSNUdocvscEsO6fWpGZjDbaO4lH3w66EmTNGzxXk8cTGdaVLDOMWJ95Kh4SJgXYfMbA3Wg5VsGXRgxivsPgFiBsY4z4edJ/g8cioGb5LK8UrDWzvOt4vOPC5QvIR0F8Kxb0JN3/QKPBqAtg4EXC2dgB8kstBgwDdi1Ci0mveeYHuJkTufEzFLVA5UvhyUjykbpWugrERNAaQhZ5cBBsU8XQ0IWIuqdsxetWX/GLkzkCwiAeW4JureRFeTfWA7GD7mlbYkSGCJukAHkIl5HYCkykvSdYDNDiw5wc2SWsvNAhkn8e3uWkbjdHrbeIPtkh/5D1LfpC5poTWsU6gpTYOva5Z1JO+D9AEpILL5FoCXvb1ImMi7pIqcUAgXDyAp4wACXIzHYm36CsO1pwMjPCEng+ZZs2aXS5vEase6Rz+Qs/wsExlYfDuspxAtMh4S9c3/4OpileOPta072ZekOlAxgUaEbC8vZJYEC0JO81Lz7g3HF6IDnlFYmMH4j1C9CD7l1sO/s/V3RfhiL8QyY2AZMOjm33WXpp8zEcdMwQyKxLZGWEcC40MKV1o30bSUHaKtxh2OlnjPp6ESk0CTbhz2HDn1JsHSM/JCCjYMgYp04su8jNNSbJ8P5EGmwuCTKzumtgcZQvbCcWue9PZAU3fX7u/ZfjsdRJSGXNqacbNhIHMAle7jQv4AtiD4cpsb8Metu32U+nf4BZrBB/XpHEJAJl6xbczTWZhCjFQWWBmKAmofF+NWpJzmHYeuQP7Xzk+hTLOJqzrjgja4D9dSvDVJL9UF3b6kkCqRxLmJEUtN64U5m4+ccDi8gY+J2poMacGvtMNvTpDnsyBlvj7PXseDISGxbtYGjcmKTWevEISW4wT9f/EKFUbxzpRoTWJkcSimWbVdAMJ50nnDkZigSU0EApLetk0fhA4APID3EkXu2dXhANv3y4nGzxmk7y87e7OFh7XNmJrnOflxjbLylKVG74bzVAeBjrZdRR4R3HW1VS4KUypmTETjEBXZ+odhzG/Dgr6D66vUI0u7gss4vDiIWmFxZaH8c4+8UnlQ0jJ47/vETgfPspD9q5zVYueAP3SildCSGYXlF6z2jp9MA2gfhPgWPQmfdD1RKdX9SG6XUKqEw7CKwN8o1fJ5Ony9BIptWI1BwI6QQTlWRF7NzXTMx+ADHObwUsa9lnhBG6G5/IRdDxbEFZZ1d3FdEhoOkDfLCq09UhWj6KeLkZh7yKYW77tYZ0AXzNpUjkMf9y97SMFiF+tkAB0P+5O5KaZTwf2IWZUo8VC+Z8OxXLhpUT+SDHQ+IYkoJ2eXZZ5F3YWo5zyd5J3pGdCs4LvSvOo2k7THsYe1azpee9az9SnFouyDJzCXbDhWh1bZf971ZjWmbSWO5YehVE4mWYcveDA0N6C9RE2KpODB9fEW1w1tjBae50tvk48abz2deuPeYDRWKJZEPIaVUx42ZPY5Qd9WbEYPsFVE4101TUVN8tWd60FnbS2yHNjgcOcUjuMaLwPHHRQCx06AfyQsro8OJ+A7ZggiD/sWn6h7xtcDCadnuVdNOCX0ONvoAyrn6ZS3gcITZNAk/wvUBRM0T2Bflun9a0nW2HvH+xL42gDL8oV4DydZh+S0EohN1Q2r/B9TRO8ATKj/DhgEYNPrVpUd5oxiMkJiZ0KHxYXnGpXOLRAmpZrDJKIz8FH6kqFnf+AuEXee72coofHFzdFVAVFiXpoT3q85H8diT1wUViL+3x8w4rqI3ysZUp8vO2TAKT5/bCClOWknZz57lE5+MUETC53uesd1l9rybNHsj97hIOLwIOfy41oBsR6nQsMYphJFXMTyFyfoM/CRh4vyex46mJ13QXt7emYWi65dPmzRj5i1heayFppEGFR3L1G/HMetXTKky1gsP+YaeKLlbHBCjWBnybav0Ea/wgVxFUHAQy6Q3dZXlcg+ou6fv1tc6AhL+cUqWSaoH5GCTKHvJjJ3iRN3ldpBBd+QHcnwjO2rpV+e4gMUJrI5ZalJfBnsn26E/Peur9kPahXGl7AXVOwweUH0zwqLLSGv7F9iC1R8O4BA/yyW69d794ve+s+5AmbH2ZufaBSS9H/tNCj6AE+C+/6a/gayWIK3MV5xEZdwy1tmTui28zEXafOwnKpKRk0Y7XVbdDHc+qiDN+Q7Maj4XmqcwuoES64IA0phbr9d4NGt30UXJPvbACfB3K/r/4IO0v7frUrRaCKfl5XxEChWtxDIokGWCfgVk68v4yqcaq5iZUht5hJhZLx4pgEBETJl0F+v0zcxou2wsm/KN9NyXgVxgY/qpaUbqVeK2oE/rJxd3PlDl8uPJgv6Lm5D0Va7r7YqDT0rpUuqoV5GgJ+6lcKZmP4BQq1f/bbB6na2nWLy4LUejDrMtHaIEi208UZ9wb1Fg9KPZ0X9eA3rnE6Pqub4JqEfukF9kMUUQXWCdW3JJdTrDKGvkKF7MdLf81kPx+1dEswze/j9Q1wx+PVwfFRje2aQMf4Umoy/+g7Ie/KizfHVQrqWRMrklKsSYlqsq91GBq4ApVHRCvNIdCeSq5vaSt44OzSdZqepOLbwMaAqGl7Mo6H59unWv1BPAc9S1Wc2ZBspONCyMb/tRhWn+ohLKurVMSXBCaBJE4JkeFBuho0u+nfH3LKt6ZPPZAZiKrVORzA1RT1yunBjWXJTAD+a0rb0OAzt5tgTW4dGVBqAPZyecfDya0W/FDaBqPMYffU1LrcZ6wXYovnghWyLKM4M+E2/JWNihOVKojmOC7JFER9w6ckD3gaUSPzBB0Dffs+Oz3RW2boLLgnLD73yOlYdMR729NpBVn3glg6p+Qlogg5JzNolAJXi2d2fIownxKA2GVaCeCUQU/+TAxlDGAni7fPJacUmDqDuHcEMoeR0sbrfUtiZvWgjdhi0aVLWbh6PbieusoNL3oJpo1ooi69y3V6FgmVWPnYLdkUuPUNScj6IiDHJAc9kthsDJ65IJl4dwQ/CUyxvE8mJSsXm5OIRPlNpy6YubBG4SJqItl30DKD6NxmTmGRs4qrrPaTbhTlgouxRD/05IUdpTJ5WGOF8yaeieHD9zUZWgaqIQ6O+iq2ZAusYI6TzqFDSaCY/x+bpNkG6zdUKU+atBfVpD5n49fv+ts6cyxzyXyfi++5s6VQlznY04wpYHm1Puwpo19UfpFZe5EbphUm27AqYQosOCnnrvAQUf7nUb8j58e76rIImMPz7IPv+6AuedQi8ME+3WFmWBBXlsKcnORgdIQ609r0Ly1+bcAPXDEjHG3i4yqL+mWnze1MtASjjrycgqunMZFOvbAjansyN2Qx4KqEaRlwMrVdurMCHEeZBK2QlW+DsJi0gDMblzE+ztUEtz4QMH2vFrNfqdhIzL0AqtbTwzoh3MqFaVInMqMVQo49L6wfWet6Tke+5KRUKHECipeZfIu/d2Oqrm//XMo+sl5lRmoBHiUCB5yqYNqqzRQ2sXKSSBygU9o9cUUHhsyDAvk7pITPyWVBV9Ik6KHE5T44Mv+YB9txbZbFGycuaIxc/2skXeKS14blaPEMcwFdeQmTMC5eql1f8SEBY9TkaTEmDMPtMv9sCEZOcJ5AGfRAvmZ0RY6f0SrNrCPejrfBtipZA57HEvsE/164Imu1nLHG4nfhW1tRwcOFoHXhJ7MaeYdkhUy42WBr1wSA5lIa1f0LQNszV/2KRLxoCv4YjNi0xCcnfQ0RsdD7EixhwyXgAF/w94y76bCuheOVG/kiRmG8h2uj8y6rkZJYrFsvqDks+QyNCyYfZvLB5kkR4i6ktPZtJx3mDZmuzvfGVuzX+Psv/7fHU2TTtLmzAv524ue2OTqfBhHJ5gr5W3pYhdE9TV3lF7wQL/utmgnf41TW0ASL+rtQTK8lbUmHk2w6HTn+LveTRNf4pTjWCGlirc3j8BgIZbxHUm2XUhJFLYvV3avDn42BydRl+avScnjRlm+hZByKA2O3DJiyoDQTRge7L8Pp+RN+uQylEG5XFhsvff/2Snt4V361gAuJphZXAe+8wG7+TbAdvdndfsaH2MaC2Jbl6x9NKM3cCrJhUMqrx10B10/6OFxLhwNzq9i7adni5b11y2qALzILW0pGkgqoqe6dQ4/JUHaWIskV1MsdVxEkBlMth7VtS60DB1JbrgInD/o4OGr3eVDJBopgYCYi64uYJ+kPtOQiMdbV4AFRXMzlAvveLHvSu4xtDXZjV+s2VUnqOfDP6+K/rEQZm/5OqJDXV+HNLsn8NF5FsE4pVbT9fJGOjxZ0tRpRxUPBNxAldKMt2tAZbaFepirfBPG1Uly14Vjxj+MjxLh757OyBrBK+FBNMJrFqjbhkFLCSOnUeDgLGFSVAgn6IuRYc4H/e66IAMGHflAzNupLRTUpopYHLb+OsOIGAtcW8l+Chay0gA9AJhZAIUhAS0zn2ctndDWgTJWAW4AnUgsxR+UxiqHZvilZ08VSCpsze/jgqZUxnnYBBhII5KPs6aV/8Fn1Lotu9r9sNLuUfV5prLVkHOWG2HeSsrJdUcfImbr/6I68iNmLmnLu5GzWR95VwSHrWV+kxCsdXfDlSh10Ui44FZHFTPLIsdD4L79rdjLrri694YjtdvxKx1eiGvEnUOr8Sfh8NNpe/9tVS/tmoEQ+RgGj13p01M7V5QeVH+KcaHNDyjas4ria41CgxqnPaKXnnsyXH8Enqw12V45S+fW9cHZ0teHPfrsWbnRgh1QKCejfGPg6QaoZCLmzAlhuokIapCChjz6kSqMCIA5bxvYktp9t1GW3V0yJ8ZcW2GeM0NCbpk8LDfgzNoeEFTsbLSiR4m4EXxHCQq1bifTIIVqaTBdHKSJxVg1jiJ4u4I8zeCYJ/f8GsxbpkyVfCXrGamZS3hUJO2+/7fj0JVAzjRLPOAix3w7GMsWn7Kpd2Idt8Ho5gZn9C6Lk8xsWKG3Y6FAu7W3WE9vTiFbXRrmD3EpOqmnkR3coVjJxIv+Tuhzozee4g5hFp5pc6Pp/UTg9Smko3Ol1n+/PfWNKVPh/G71X2yAShALgvqGLmbGb4kHlqdiFpTcuxawaJRQySAVEFfUVRzg/Grbw++jJhjdAE5MIiAqXWw2XoUXaKn/zs+B+UeK4E26UZuNd76RX65muM1PVgeUuyiG+yt3O/P80OmWlqSkH3NWZI/ZfAuPCJHlCQtmyAwkDXEXMDAl+Y8LDEEF3wgVUZlSVzRNHIUtqyzPdnERD8RrsJ76yxHOtx1rks3XIxrV4za59prwzkmq23ZFCD2SLq/dfk+oiEXNznitbKmQhzVvBKm9hXaRjjLkuY7LWLqIvDUU4yLdVlHBHVaGljrrSpamQrG4cKLvZjrWp0RZUuBloQggXN2y+QOaeWG0bYwzpbZq6gkVUztW021YnkoFZvJBEKfEK80h0LpjsN6GEfQZhs1Ee4cX3VElIFczm9IA4mCiYsKrac+Vb4nVPXhlsZaplps5AnQWrsqiWMdoQjrTrUeYrx8iAqls/fYp14GsFZQPuyJ+aLv6dWRwyjA0HtMiBsdRkIFGPWQZPc/99045k8DroTB2YIp0CuS2j0x1NQHOTJehmheKgqRR+WBO8Hb1gPEO6Fg5QoJjOuU2IBCALwUi+moOCgaowpU82K8CkKBKzMq6d2tOfHtvz8dKSSR7FelhUNyYrDZU+4lhFPBsazbsBQHSsL0jteIXxheUZKHN8qlL6fOYMeYQAAf444NgHE3/scFxCdyOKsT4RzX8n6O0tkWdNEcFNFCB808CL7/GjyVGqISMAbbMZIgSuD8UF7/PZ07EUUrhcScc9cQGdAbk63/cTDfGgGbQdmPa371OE/kD6BPkDYwwDnsI+37gLNVlOYsz1OSXmKwUWCWT65XmxZYZ6GVYBvKxsuAcZppXgVYlsJNF4oO6t384A+kcBVQAqXS/exGNQDBlyv4usUmW9ixFDwpxSZCG9mLY6A5WB4E/sH+QtuvfMlVpCvf0QWvDQEzdVounluaHUXZP+kAVk14JnixEgQSMjJ408NuXcj0mlOC1DVFoh+KDPCj3OYLsuKei/v6s7c3n7er05onNa8xYTaEeA0a568U7m37cwyOnPhXwadyeouA6u0AtlQhr0UFoiyijPrU96rTxAvrbFc6WWRFrMd94EgFsQGL6aQFnnvgGCekfwBXrWg+h3tCa3F+V5xHxd77/apDPbyrEofEX1edM652ugYVfnbbVqZRrssGNveXQx/KS0YqwJN2fb4imjUK6MAI339kaG0ec0Ut6IKbOixxC//cKqO1bHY2Va3VhN6pAmQgN4hWzt6MEftSJ5tFow5DlGaDMuvPhhcHkbhs0QzcRxWmY5kP7iLlQycENl087tCh22w9kzFrLEayHfah99bluflbqP5Krfl+crvjt9iUxDg728PiBlMKzIOKp9x/BJzCgl1hC2lmtZTFUcwK7JFAWOZiFkl/qXWEOqe3MKTQPLoPS8t4c+JQYqkzDeaIVcxkbybpUsVGcPXOpPfkyCNn66fMHoQbWhvV92vSmohZzG2CSxeVZIvzqqLrFdVG/1n2J1CRB/iuuGMQ8fixaRu9tn083pmJil92DdwuDUShtPshcXSD5gylUL2Cy4OOhbYSvR+QrAHHFU27MmgFWe5xIJYvENV0nQ+wxXw/5DWkfO+o7Zu9T3/JW4B9I5BQKDwEG2HpX0B8epA5g7OVZSTIcr9WSQbdTTHXEUtUtxdC2AkTHQ9+3asn2e8M20vh3TPOe7nSDXjZIjBriGi4h4cqfCYgK8cNlfwpEzHml9BQv1TsHMNn35x4U616zxe3HrwqjjeUaiP1BO3pQKxO8a1Yy5mypojRR4RD1X6roEhYKJGvzBK2LyKUcXXYVLhtCJOqnhmgIrO5NxJ392mrDvrbPcEi7B4ZYgagJOwbWHEmZ7LKvmoctvI/mruXijPAIFeFkkXkFsgITX+o78g7Bh2rJx/vjsE0Q6qag5490w3Sb+8rpCV5ECxcDW/brazJdJK1XbpVf53MsQ6qEW+292KQP7DRcQh+4FLKp99UBUrKkiO3iZ1PmbPTwVWm1WnVS4aygaw10ZxhHs2MN9JMdgKM32vp+wyhdS6NbtM7wpLCq9b1VsXHPGI50m6E1tvutgI7AooSKXqDXDtt/crVDPUndz46y6blVYqsQsyltcMse/bMk4dtqIuL4UKFgUOuClwss/pSLujJX33NfQ45wTgwnSFW+Ztyh0me6hswUNb99iZJGSxADItv0lnHNWuLEIyNaq2ecUjaLYHgdLwLvra6hSzSQVWO0XXVNxzVTUPVlKtBoS4WzZ0drU1eSgvzrAAF8MgUGQZ2FQpTbBRS8OOsdVbyTqLKd7VzJ1kZvGK87hraPjloD5e+COTVsVnShZlkcqudwbVrRoVjhFva9U/gzcxWcHxQ3wW9dBeuDkdwanxtWbfiEboOVnBBpbwoUHJmxfSH10jU5zu410SoFOUIKa8PCDgl+qJPzJBvl3oOunBx7ZffkDzCK7qY4wY3Czd5HF1rqqgEuiKFiGzrvJXX8snI+LrUCg8UQTGk4x6356ml1cM61hcApCJkuB9dFWB1QIzoDnTYedajUgPINqWmM0cd1UZ3bDav1dLKLe/4r7jTWHcQ3N/701mR6tYwR3q2ckoxSP1yoCzaMjYV88+lI1NvmqRpNUXKJgfioI8oODvSMycOUC7xsmxdLQzY1o9CKoqE+xGTGryQ2XStAl1CUtovyck402wLKO0EYKeGC2ej1//J/FGDyynmVozmmRStGRzDg2EugvyDxnNm3kbaZ5vjVf4feGvFypp5ro508uJ/e8rovJjPH+tQ1ycvA4cKRXux1OeEItdPRyeO0LsEA6f0p5QQW8bey9wXYZlGejSamB6JpU+GTRkxCdNICkcuIBgbDWseOrNYIfHWuqdTUSwHDQymsggNnXSLjW86ATfUsZADjcYgkm2elf/Ahru/zX1eVjvEIn8xBozNLiogqOM98UZYL+JlHALue1wLXXIlaXk7Sy/bT6QMqge7EDp9wWGZnQxvBkULuYOJJiHEHi4T1PX70aumKyj7JECzusPZlh1QXVpzzwu/stmrt+SXbU3e6Rp4ErQlcfXlTdUV1sFAzeI3robXlh+P9EZvVZSmmzNuyEvY0co4ZJQitV2LqsRpZ9IDG3V65BjBdlvYi0aMSfW+/tGCM1gvKY8u9Rlw0TN15mAA5oRZQ9uH6F4n3TEzjkDvu5kxnTF4f9p7TJKwcX2xy+DTHcIda5LdreHy+FtH+cjKpKey32V7j6FeTwPdQSlczjPiKQcR7UFVuwGquDWcWgNNOxM70o9RmHIvOp25UWjdGFxNE6cj0BjpCyNXPCz2as1c7WpSRZYs5kijPXXSInq8SPWnFuKnOW+ZzICuygG1MnjGuyY0cZy/jK+oAdhHywDRGF+YpRxnBcAcIMExFJSP2UoEJdAWytiQ9BPiyxUqI90s/2y+zmYuci5oAoct/a7YsAxccF0wuG77XzTFpltXeCUBiosUQ/vntwFu9c81Qb6XpbPZkgTI+jPBXzOQwVEGe4zeDuws2wfbRzpWqtEJLD3KyvtDtLL4275DPzLC+Vtz7zMLwFJN6U2vOfe7VWi+PEvOwV2yvzdyV/7AWCoLfecfeTWtrF3r3v67epVZ9sd9biT3V9duCgbxOL1V0/e8TdGk6FwAiu3Z/L78i6q8wNfN8zQpyCr0WbtukhFrOa5VMoAzj0N0cfgV9Nl+dFraZh1GYurx7VGNG56aaq/2jq7kCQUk6AP+953JopMUHBbrRePP8kCqWYbhLfA2IXpBgCnmKKWscvmc9QDgaXZ1bgaiZcPT0G9zRvaqN5nezaA3oWAbOTnMsJTvncsCbovyOpXF8GGLlrpOyNbRi0hP0VvZdxEmkUDetdw+up3xZpjdEHCKXHbhpokORjvM2aUbMWtqVGFr32Zrz3Ol1+mN0ILnD2o005VnodAHpVTUbIy+ZSbw7zPc4k7FS0aH/TC3+fTyjCx+Q0VPBwaRlbjpe+0NiItmhGAsfHRnoOAAxQzPZTWrZoifG4dPnkeWL/b+bQrtrQhgtyqHwtoNmgU59b2Ob+vEnd+es2R4X0o2i9qkiHtnAsUaxA1MGrITIFKy/+zKYgaUoJZeVxpdGHZ/YgCDqiVgIqO6bA45PZIHIh9vdXcOhrfZVV7j8xPgFL8pX6Gs/NFYLMgudfjQfhQhIbvB5A27FjLTs6Q+6B4SJZqwYp6tAZRuWs/71PCSpCSDVC+ajbI0XM2B2LcEFhdz0gUeA3JXzQESjlBSn0MyDdneY4G2tOfeCGVnLDD3Sn6DBPfiPyKISaPlS/dtzFuZVutO4lHZqgFD/dglmRwerqA5NxZYsY/FQO2Uk1QjX/aosyRYiQlrBUUGXgsiq+Ta346mIase7KDYpclIYLgNpqNAZvTKJIRV7kXJp6rjgcobUzjoOghfTlvMg8ZlXdXMTma+qQNfJB8uxP+giG9ikydY+22kcsP2o44MmYcjrRFfqycvAO6ZCCAS2yT17NvAIMDuGxNj/l77o4+5uL4tZnc0RtKw/SnfcQ+m7Kf7Uk9+x0JvloW6oPV6gJhy3/N7XZzLtbh15ZoinUnDDmlCm368FiiCDVe9X4ms/tcUJzJhvrlTmuWC1xvbKpXhsnylEslPWFsGCpH1GMLBrclutfKwjT698z+yrRrHw1wWdrnj/dMuZtzKYAGd+3BuSlYofAaUhJlPeje35K2zq+LnG2ljF3hNUx0pfThxNnB95YVPAullmTO4B2G7WbEUJlLaDeA4jJ/xUT15qsQdb/7MVVHj1jYOF5p9MWCde7Kqr5y+gnfAPC7U3Eui6BuX/UFzyLk0fgvZq7xYC+DnbZkVROg965zS85tMEnFM2iDEzWdhSnZiRQ0ahnNbn5wMZpvAC8OGUFyY/jcNnd9ek9Nlj1D0Y7a0LOiY9z0f2ZYXWv6JY0MTYWWfbPiPS0OhXPA++eo8rFnMp1UDB6WH4rVCXkq4/KTgp9pO1CnuaAVf4DY7j8EhBC+iO/duGkVcSc6kp7fqSOP/5YKwQ0l3z7MwLNJW5l1oaKKkvt0TZKLZ0Wt++tfYPkvRY9d9wcipbMw+P8BLlLZlDgyRd8/muDE//V3pCtfziJsFNcUuFBsEo+XKF9WWBWlioWVa03OkbGYynDMM7xLjJ2criwIpAV8R6ZpsAeRCJpbQYKlgpKhvqsr5TdSk2YnbRShttjVl0bASW0stHS6zu8ZIYuuSwWv5HhDdXvSS7eYKfnWW4GqlHQHKmiK++DFxJMlEgfWXVzjEUQSLPl3ieyBJk8Cik2oxNuRDmx7Q3Aa6SBS6F1x9AjBIEVhXIDqFc4M3GIwIhZwn6qePa/zi9tI7z0lLq0iE9vfuWr8Bb8BEztZZWQDNNt5gKWCNtx98ED9T/yNVSKutoYCxWARCKwxK3uAKm8ST6BwHsj73fGztLSiTjK1FRALoeGbInq3WjY5vjhClQclLhtrFtb3tHcwGyiA2ZSlt0TgU13Bg2SmgCEiZNZwDFBohB1X1uDivO5+95DEieZ4ls5DNkroJvUof8moLcINFRdX/uX277RnY+0Ii4+Zxmf0t7sXMX6UDMnKQw99T2e2Ec9oEIR5xHFq3mjAiCxh4G2aPCydgZy8Kp3sQ2x+x5TC8pVM0jJv/7ahp5qTW3ugOh5sF1Fo+V3GyRfGhmFPzqmun13SqSEpBOUd2nK4WDNRmQhtFjIq/JQgA9RInrcaSjXxz8Ox3CAbVgR5Ayl3AhC543Og2MQJRwTjTV/jaNg6HIFGybHScCi3HhJ9WJOs4n+3WEQzaDcUTy8NN9wzUvbLlPDPD92sSV5G+1yJYUQnM1wg1ujtom1xIKV6jwFcm3+sWhiaLOoYdhynlh/5U++zaBISffvK3qa8Iliabprmmv6YUkJnkSB+T9SuasUfV/8m5Vea3cHR1vqK0UWY06icpfCDaBzLT26ENtr+MAWFvqVUzdyU6Ivxs5/q0m4HDwblkFl11yY4Sh8QM0Lg+viNY4FQjhmeAOHqfVYVsAgxuJlfyi2NDBcJeDVjIujbMo3TG9/94F1xbSOVJ5r5CgHnSZIen4kWZOOWkPtbuaN2nYJbTx55tob1/qMzIem2Hlj3bTBn17ti9WkUdg0dv95GO8uD78ebMiThskgmVg2Ic39D+yeC7mR89KTjs+YdgZnh/aMTXbbSwfgcDsbKqMkZrHknPGwVvQ3wOvsH2S55Zp8PVCaL4U2HU2n8d6vEUp+Ll65CqdSXY/hpHBVaEIlFfmM+ittfd0llkhMCcZEkfeQA0kLKjNzOop9nZsLFGCsGgp0+1UC9wdJ6sNmPU37QraKL2lwRcR3Yy7SYRRWk7klfyt1m+2pIA2Wrjg/9Q4F9ymdBC6VYv+pjYzGntGQglzEo0WpogAz5eaUccqi6F7kqc0zt8erexpLEHPoW3u8x+5JsIMGdc4FEU7vFgpxzKcpAbmYSMSnDrD8h4Wv3q0KAFd4Kbg8kKCHGIn8sBbK2w7LSVeKBGgYjylX4JM0hPnzo5FX4azaSDnxKirYZDQej3w4juqo21JjstO1JyDIIr5Fqx0bIDs9Gs0WOMTAj76GfPRHpMjGMg7ak84vteXv+oxHmYMB0ex662KOkns9zeXenve36XcJzGsNDSXAZa5ZuLEpIoWG6mTSjvw6mBihVlFVhjI72JQePGFo5vQxogU4YDXNJLWcBqVDYwXhbRtx/2cELG16Yc5/RfCje2DznPit/a6hp8Rfnhz7y3apFWCvJeaW9m/VnKTWzhBng499vknseo4Y7a7sCAIG3NfVznR2PsP1j1wMc3xCAcH16CSwWHCkIajoDFZb56P9DZt7Qd+aehjC/HCG9Kv7JkSbgaoV5E+jHWQc3zi7qNW5yfhR6DPQ3jUHY9LeTRqIOwGYdf1wZjOxc2ZJef7zINml0IJ2qweN1SVmVbYJ/+S3eWjPwJlfAXsYO+vmo55U4mfx9eaxbJR9So2xJqis5343AwG8KEVd/xqfdwUbiYILO8BkFMbYX1j0jl2RW+lmK5UHNv0Kvrm+/k9/9k12zpk5ySdGjzRqfC6oZ1rXIWWyaq9oysITzFiBGlad15tpYd1CArVO9pRdt1cI7ZATqFlUsIGcKBG46xHqlqXE+80Z/XVSKziQeDc/GQz53Mzdv9JobjcfQHkBndIsFpRM1qETj+ZdyvWmDPFtY3zS8N4xecnIbAF0rKCuS5ltZD+u9Tb/5oBTZlu8UF/2DVV5AWx5XYGLbVZHi+AKdG8lCSjyZf2E35b/xLbyCdEXEKjUS5XilxMXxv+CEdtxSK2WAefygoCA/JsG5DkSirPSsjFiUwOaagaCTGxlQQnt0b2ND+LjeMMh9zZBfAKmmiKbfT8WO23Yr4/yrUrTYRQCo2P4ORvqoCWyvxInewGGG/540GY5ObGpxuEakriYbBvBGVS/VfsA9yvUrSmQroNBhfrsBNrT7CFHeCbaeCsRXOScc1gp6E8Rr2Uiupb3ZNRKDQ9Qztheu/zrBUeSDEfaQmSsFw7Fd/jjZb780YvQVAY/bM345c/Tba1W7Oq84n2Jj0n6+5Gr3kXZEJ54/aSoQjivUSFCLaxHeZp+Gs40kOBGd4mqAyctfivDQl5U+x+kmDI0LUPGH6Mbvf12Wv5SZ6L0Nl033mG7TzUMoAjAKns/JPD2x259qUqQOC62We+20mJKQRjXTfhWzmQhhiUcahG4zz69whfU6vXgGDbJ6vL99oe6Rtmj/Q71O4ma5WmRbl4nHFoQsxAmZ90CW7SmofzF0l/CR9P9Vxk2y8kXBgWqg8M9IO9p7hwOGYRfFus37nGln8LxNkC03fgOp2t9Lkb5nwuKBf1p/ml2RjjD4jXtbTNEQHoP1759fDCyv58EPMqaiD5BqO0IlCkoNLNhBhZ7kAUrdNFWOv6zcN1ThDofW6ea5d4RksZ/Ra4Q/6FRoUcCoi2qJIs4/R47wjZoHe0gJ4l5IOOMua6dNUyYdVxoT3tLURI4g3OGhmfDB02OsRq6fNMlXgoyBfmmaYs5XliqeuWXI289qd3Eq7+eQs9Yur5qzyEmHqqcLrDsp9hyEXaRRgl+U4u5E0f5eRf4PpiBXipRLne95VtSHqRIYPU+8V8Q9LJCm2WEGLJJtKPOlcniY8BuVSdyOA3cFhfKEhPWf28OXNNE/H6WuXLRPzYAVt1IPUU33HuhuLeVHOQKq5OBex9lWv9rziOzbXqn7STCkl0W1O5AsnXqY+Ou2OG+CvowrDDK0nv++3P0/o9QdCItKzYCKmT6NWIoi9y4Ah8aJGF2WXWFZxzyos4NpOxKF0bceYH5hXTq2+xrsd+T4ZPUZW4o++XBdo/4/rqQfGBI7J2+eHHiAnYGY1QVZT2oz7kMXoxyFI+6l3gZE9AG4CdNR3N2kZSFvf16V/TgJkey23RGBXSfdmOTaXNXUsrHDhuQ/2LumAeWfsznBUZOB15V64vweIzJr9K399IsokeG5rtZHs9KDr2Ed58cZJFP5WfR+rfASWSKrOKYk+pBLPlaJoBwcF8sdKR7NPZFOn2UViNLPkHkbn8vv0KWJeJ1y+IVmytNtyA5X7o3Dv7dz3oKft/JLs8TMqlWD44aJbrXdmDF9Cqt8J5xspYSs300JKLLn01ZrDsCmBjcvnT1ybq69vSQ+Cw8hTG8Sf1kT8A1eA/ZfYP8rcJaSB7waMKGwd4WlqUUw7aW8HFE1eZyA4+g8AsXzk8ygkOyDBlcnZaB2Coo6H32g4omuZgCc5sqsopCI2PJkFaL7p++Ze5bzwc3FVb0CklOP5WnX444PAAWOCiEMLXmhxQ7k6sFGrLM1lF3vwki5bbXR7eAs5CckETDt0D389KcdDd1+yC3i2aNI8aAG0jNJ7kTP7e0hv85Qu5qAfP5a3lo6ER/ZJjfb/Evte2HOzRZcxBJbyRxO7jb/+/LxOs9puqyuZfPXj4XYdu96SvaaZGznYpkzwNfp+09Hkallw3EN4JJ+cRDXpd0FOZXDDr/cg3tEy7/tyjVDfJCJiz2mxOuQ72/QrEYTRNqlExNZqNw1Kk7Uf4lhXpJmK51DPCRVTRN6RCPU2+5OMY0Wv6RAFIalWFgRJ+zzqsNeI9bs96gyfOWLuJAUQWn3lSRrBRnH2l+nMqRpI3MXx2L1DE66zfy1rgB6s+tUfcZtw5BEEFJWgREPZta7jBaqkJeFzL2/CjznCy3g5aGzVfcWMcr3DI75vPGvpCPBGxbbtC4ELVBkNHFKtjZwYGMPsg9uWECZxOOB5IAdu0Y3FMYNVN+Sx6dCh1Mu5WsHqaj1sD5eRc2k2Wnwyp/s5opvI4B4keeI67cN1A3ZoCZdxHJXO5ePLKQLkU2uM+0nqrkrQwv6AcyliQnIVWw1ZTOAkO4b/ia8jhKJ99lU1/AY41k8KnLXtuuHkakZpA/ch/ABf5bTOLvFeFN6Q7nxdO75jcq/uTF+BNLdrheNHD9cFK41KcNO5PnFdTaNAVCDMZnmcFf42fqfuiqrkvhCsHIMYE0mnE23SNvR2v3KdN4AedlflDVjGlhxPg43s+jvvk8Khuz7pTNjcb/jE6Wmf1Nq1Bh4FR+ztVJt8L9PysMIyvtc4JVhS/XMdn47sRWsmCmJemQWIciULTLTlxyvz3uvg6bXOILQlhakF947xkmsGZGsmEqEXZBkHiJtzo4WTG+ZUQAhDi91O6mhDnuQdXZlDAypeNc2sQtkt1lIHuaXzQZ4C46ChKD2Ic8E3NHJLNL70voiXKlhCioJoclPmb9nqUMJdgBGhzWnhD4zHK/tFBedge46tGcbMKRF7/9eC7r519H/QI+8ToWI0qcNqlDFpC/Qye49mkSP3iURgl/o2rS/iY9B7DQDyjftwvaWCbCLA1dUZ3QXaVrpCCRA/zqM53FPe8p35pemr7C7QjrDQ4FQgc5wgz7Koe831ISsrTAe5Toqqov8AMmprFMz08zTxonVG1Ynxd7qPUOAfIYe0SyE13YsPB32rLAp0vgvlRRUbCXyJGYD+UbTmPB5KkofGZWXM1CoFlk1zacHE3NKoXtCmFWmGKpTG2ka30FRpSLZ4xjXItuuNx7tzLGCb0qxHYkJfjyCGhBtA3O4r1Ko/jpQt6bkJPI9y+aHb5NBCSXxHNLaQO0UvZBO7OUaUF+TRl/UiAoM+XtMEGvE1aOrXrIuB6MVeSVfmrLKBjPt7XjFieRr9yRzp3TEwG74+vd99bICuiVWyYZ5uBG/WpJCxmUxRgX2ZvwzbdQKM8uT01Oj6jZW7Zt6/442KYDSMTsiWOz6X3uoOQbGsmsiSBaHlZ4m934BqcRmtiOmLEsyx0lJx5madVLWspkLsAZvXv2uTGG1rr3tzlHRp058BdfEJY4t4yYPC1XM8lipe8RxDzYzl5QtVEPZA3HoyBD7sbxNiH/l0euYBuzdJYewBRnFlcTJqOXUVmSEYNACu3eXGsmo5lwuuFyWd/ccxrTTv9stB0m/qih6/SgHGH718a7c8AD0EIdFKPB5EIlGgz/ro2m3JYKacYTDIWUVdXjStnIJB6mPS6nNgirLA6LU/xX0DLxCBfo3/LVJpjX030eiKux8USJBgMtfz8p4sZ1Gn4vaeoua6InujpxYDEkec0OqkB3r1ZR6QG2+w2TwOZLqwqji0yl73gdiv0uTu+mwjaqDRhc2uStt1Ec4XLcR4d0H1d7C7mXWnjkAKxDh5vVZ7HLfNDrb++SXQEOzEs5hx778C7nrDQKYeca2yU1B7550jzNwaCKTbAZS5CmSrts1ykgweQWc3T6ksEkZB1tTQyNtfIthOf6dKG2RgoBOzblau7VQY+ozwjlbfbb8JM8rQoAUkQ8july9SwRO3sIO8PFUH2GScMmuLywpTFZjK3uubYot6Bl/Y6en+bCLAKhJ+uJ4wtS30pcZ31Ywz7hCmGACs6xR4MXNSxfW+oJZsNEwl8s76sA6eZeKVyef2UMTctqRupaY6Rd+G4EsMFgGuyRUe7f5Ik4/C7qQywD0yiCeOLrXXML/umt//UQKsywW2gGYA2KYVX+4meXIdX5NYajO/N5I6kZ+6uwAFZvP+mWolMONfUuvFeQUkHi0Hws9O0SwRoCguwrhQKx/98DiDDiC0NV+IqVPsoWNoemWvePC+MPe3GrxLBbwbvycZE12PiVssMqM4MYp3VcsHBnyK2cFkfjH/RzGz/G3E/FO01dANkuKs3LlamZDFbShvUCwluyv3PTpw9lLy3ALws4qy+gtFlWbSr2V58jUgwzTZaTsUIb8AHWHYqQ+xZXAeYA26KhmtQ6uudoXxnofPF+hXzxE0GQ79iToOxDj0MbSjPnjanL4h6HEUteVguepm2M1oPTcWE9QRGuWE57T4icM7rT2P6z8Szut7IdmFHrMI9V3FGscRWlcikA/uJ2Zu8LNMIVFlCviYwGM2OfSSyU6VhfhUxYFvFGHtJnxl4JqSFe3/y5qAWOrVhONfgikigznSLA0wZ5xeqvb+9yFKxcnyDwX6j+zLPrG+mdJZ0gs3mZiTPOAC0Rkcti0ZAqnAVFIKMy8ubrl8nTP3Y/PktYsZd+LCY43uYvD8QUIu82rtvSx62fWBcjxEtcEzu/NfmhunQ8W6vxx2nuoXxDV4mQEXFJ1Ife9fO9rnQ0bIYw7JWFLELSea2lXf8PuoamSu3Zc+iUSAk0UCx3pWG4XolEEjK0/6d3UyP4O28MftNOg1fP5slLgcq/jSWrswPvcqAJNmJOWqYhk3zh0uyeq4Gv+fZ617RvbKYv8EituX5GO5uB6eJl+O7c3imOezBjpMXaUhDZQpphA6hvnMaxjWZCtDpPfZYfmG361V0LoMfbmQLzh0IlLkmcUio4V6+ZdKdpA9JotlIzuSmr2KyN68n8pajSNql4v095hrCMbau+j51rFoENiQTTQ9abAcfz806Arv+/VLpAwPbuskKAOKXwJ1WGU9IelBtjc5EEeH9ihWdttqqSW4Vqn4zIwIsx6gJsLXkx0Pdv98iYKQk0aqOWK8SQ2FZuT+4PBNG5oApwqEOhLMpr432mPaFolwpjCmC5FbtxokJXGtokGMWG4YyDDUYVfnRL9qd1nuE4Mfdi4u/xcVn0Rb2UGS+OpxukTFesR2hDpbM87YwuM4TMaRY7k8xZ8NUXHL06aPycmgg8JELl2VPVrvzTMWJRpFuYrhQGrGzIKL23QAxKa6evkpGpOxMg6WzggPA6USfcQ+cGuyj1Xz+R9DmBETu+px34Vu0F4qgBIh+2pRmiF+wtrv1p7613CELjU8WA29cH7v+4+ohHMqq1zfKvB3MbARTTj9F2ehW4lGpNpX/mxks0ifxA1B/pS0vR84uavz7Bu7SXDQ2M63x9cCUFzMLJ+E/yiPpIRfTE0ajQSN1WkIOrx7XHHe9/nwQMPaXDSHOfAi0LJt8wauX9jwrB6UqhizhZ7cZzN20meDkTOdSXbMhb/uZz+40X66vJFuMxFHg1296/HB/rn9zvxxTDAIXlxozex+Gl+h+8ytk4gmvGQ5xz01EAb4RqTkS7/yGbFJCUepvUClAzlEWAG+JZhcLeusawW2yQyPw4t5z+9HJeozSoL/dBKr6mqoLmonewlHGtapCR4rdLzHGs807qDEcfb2NxWhpXQ3kT+4ulPw8ZMvWMrrSkXmhi0YpIkE0vOcWKuWcRsUMAKmBQGxhgi+1+gSLuPsfBe8IlM+QSL3v+NqFeCARNJyTzo0JmlWaSIthIvDD3Qqu+KVr5uPKfn6x5pIlYclXA+7o7zeX6Q3d2OYnmvfTZF7AA3pGksUmXg4l9Io3IbbtUjVLXKjxBj7TT3GXB6A1VRbmtLqnDpezdacyUpRbzZlQQkZCyuujtC5EcphmrZOzF+w1MlyzmjGEgt2gX8cVW8wQdsZqrg8f2wocQf2ZfuGqj4dTx7RZsd2UXCUMA//V5GJxNUJKR3a8zlPVJ7f71bO4Q/kvOZWKFgaqHc9K/DaCIuHqFV+t5Jx9Wrxdc4ncqyal2DPBomSkbnu0QVhY/qFg2ySOxyWI4ptOoCygIZY/j0Xj6T9qUS8xWsoyJc1es2yLml49zjHklKj4LpiDT0d2UhGyg0dR7e+JkfwCHoRPH3jLJPS0CuCiydOfa7ajjgizhYZJGYv6Q8qUdTh57N1WvhVPGArRReUw4IzKUxAz4GMO9VCs8fFu5AZEcXQ3otG3sdO8BD8/SSABf5ZsEvplD3ksAgRt7Z4yy+3KYRK0znDYuuFfNiL9FXjV39NnZh+OlMIl4wbGM/tt549OO/hnfUW9KWYK4nIF7y+sR0t3DKJhaWP9y4d8lxwkmLEM2mpNbuF3OMJ/x43IFjoT3tC4DfGSeCjtOHL3MBmY3cUeDEkVWKNXi4pCf2Afu7NAevH8PZzBkbLys5lDzuXXcahs9tseQUfBfCtgC5NUPOrfmlBWB9IsylwNlJ1Y1mbvokyGUeQpA4kXwQlmSraMPBUuVsvt/ZOlP8Tw5GyYWXh9D7xuDTYKl/2qV99iF+0PYTkGHnkUnwUFXljKImTEzKwOCh7TiE1m2nvpJNPwq5qTmNFtJdyqD6Ak5K3vZRwpi1YMRk+R/TssMOAdi+Z9Q+aehlAdwClafPH3BnZYAESisXHaX1uoYr9R0+VZuMVyhQGPGIWDFDi7e1MsHPYJYgosT5GGiKGR1SHeRCg4y57RWM8QlrRS4yG618g4FvGouYbluEETTbgNQt0O4tq6StNoWvuNv11ezvZ5mXjIp2CWelNKm3/ub/Te8X9AeldeZS24AQxrr6P5Qhf9eW+r0BiRYcpAwBAJLx1ANrVwLC88gSKCCnPQk+BWI6T7SOEZhsFwqf8Ly72YVx9HuczBYUP0FIFCxJPr+N/fDcxGQq8eJvUMpUtsWNYPN09gnv/JOuLm0nee6ELzFMhmvwoZs0xhwageVchcBsKDLKeeUARKLbZXP8NT6J+2Tj8iINNKRZR/C8h1PopusTm8iail56KaMUFgM8PTLb9R99Jt+7g46xO703I0XwY/6iSRNUo4WhEVKg/7njsgLBc9CswEyV3094z+U/bA8CTp/YVF9t0t6VcBsfCMrsOTWmh9OZBExk5bO2E5wMQqUvQ98ng5ilknssLjNT4aK7eHroM6FvfylZCuHswGeOkURXwaCeuH/1BW/+mmr3INwxd6Ip4UC/cuGhnQVmdIMeQiqOqD64V9o8mTXnpEOc4MZHc7ZvqsPZhQEDuhqs/Q/mVC8Fo4TMQ4iP1laRsIby1XQNWNhVkfNlMQdexHghFDuDhyT9oaPX5VnL7LmZpPucsItH5Y3KcC5BG9/oYBw7znxOFT6BK9f0vuLdXAayosztXPDSnqKFIslLD4Vc1Pt4/K897dDHcKF1bI4swBNs/jaGm6t0r69PDcjr9/DgKfMY6bSU2JhvIqM4FzhvQnntBAU6YaKip9d74GYtgQeh+WA8n8v9+QMtklSVlOAPwF4J+gv5ZANWXJM22yXGCrTVUVY7a5OQiGOGChVLLycstLp7JTZNeatsSQSfWIFKt4y0gLdWDTR0r7Pz5SJWM4ylLwJKXMpYFQZ7jzY6fbeTkEvVThxl7ll24VFHXUYRYGXRWqiTOI7nG+gipaz3eQyA1SoanYpwQ1pd465CYIzxrqXrgdTH0NNpDV916UVHvrUlpdGJ8k/joszaEkUktECMhZp85zNdJmhK0f52uakthkUGhIUKM/ttotXyyKzQWHMXddJzr4Dys0vcKSD8mnRui02jM63ZBIP6jSQ4qzscLT1Q+rZWkmH5NyXKfTQBM3qYdW1JdEo4pao3LPD2BGcY6CCGOxHeNNTCMsOTy0g8xza0bs2KIt8Rzm95CV4zEJB6unqI/5nLHxzWnO2WqPvi5F1QkUtryqrV1nenmzJHKUhuW/wZdTKkE7XSzb8MxHMjWgOO+U8dENX7qzmHMYVu1uKMBcGSKz6Y8F0KZEw5ScJL3hyzxCTwnn6jLnBx7oxOJClVbOg2TWcw8PznDRcSkbWYzW6d5Nf0AtuX86HQ03DPeOYOxfm1CvtNxfXH0KaLCBPycF3F0R2OJ2zwA1rIVrtTJUdNmxVYQFL5JNeE+rZk2gLOcRxxK+o64I6hH+sQ6pvNXoLfMeqdqn7K+strljva1/uY4+Cd5acjuDmm99Xof45GjisHtcFAODTCWep8kab9/euih06xmqfOaCkDAGrmia96HY9nrF+661+cFufse0nMCr+N+EnvGRhxJhopHF5dhoSrWoOi9hhEXUnxjueqBdygcdjY2CkrKcnhrWOXBumEWGDSqJFpvpMgZ5XP7YZVoup7WiZhv8rQ3Q4m2QP28z1XFuFTO3CKA/kSFsmcibHje71mP1zFm/86YQemINWSZdntybjCPGt9g7VtKT0gErTfeuPajODLqthqyh4RXd0pSJvA/qGpUmTxWf9cHn7ucvdzI7SFs5qEm/NxQFm6Tm9sHsEZ5Q85dtVoY5tiLxp3J4iiEg87F8B/Luv/zPO+4zj0Ib+hkgveWPsHGeO5djSZGhknQPh5TKdY4r91idm3nblwITyDjQ2AO79R2I60bI0g7ENUWc1ugLVmvbcu118tiQ9tj6HYJJU+5aBuapMvpsdxUxLE1oLs5SojeSochSPccbuianjGS7Ty4OYh78tyIeD6eczQ28d6nFR38kXLZ0LYrdZ62RS25zbcRE333Y/U1fxOatYKrEptA7wRG3/tJ77EMPxIA8wQoJ1WethkyGtxq3oXhf0vx2Z9WdMQJUuI7LOPBpUITulOd2SyPDWZux4GL9+UKe3e5wJIx77MvOLI3yHAgAdZM/8QOqbcmqBLNtUSfDZg5PZUEeMH7WPV/A5q2lYHUfLnXdFMEBMjnQ6O4uTMUzaxX6VTfOivzPuItdNtSRo4tATmsDKdL2ABkq/5h43KUXGoGIwdlLnAu+B1efpZDAmO522z38y5CaHkvzIPx35bFTpni7+AL8dg5Qif31u5uanpLyfaFvmYGk3fcvV/cOzgwW0165lF2xTDe9DMIOSUeALRQfAhgYm11K/36gBZpS4fTF2E3F9x8gCUIdr+/ZyqDdOTSOJbPgUAeaX01EsTsBUxVztVIqlKnGFkbjqbaqOWQQgXYOCzE7FnMHfp0rHOpQqCakwmz2bDuy076ObZnjWA2Q7PHCeJFgRb199iOlGDf8SmL+wlY1mjbLvOW45ZWcLLMwGgfp76mpERp9R7iVMO5W7AjZanSsaSQVdC8C03aGO+5LRiwNrFoSEDcXL94+GHkVMvPtBtDYMwJhjgbGYKmOc2rnjVKiefYuKZxel1IF3nAJh+sRIFuKF7J+b2lEtxrVMJoufpCjblng5ppmihnjS7WK1UUintz0XAQdTcHJruybRT4QLZnope98nlMKqkZSwUyStHJ5Hxx8fBBJZpqez3LmtacDsJUwL1fVQNxPjsV9EyQOSp1b15Dhadg/k0X92XBNXQx5fGfFoToQrMSvhe1TXZ0j4Jb/qpKmucxkaQ844DAdCR5EKwo/W5fscdpXroexCSPLu1O3p20oBENF6lrefs+hyP68m/wUmUgbRlLBO7u6sfQ/Jk3vmHuNGCZa2pgKwZzY1Ygx/RNcf/jHWPnhyLQJ/xJ6KnRqJQNvLo7dMAZIadbk7fowP7UKfWua+jTdWt755aE9nk5NrDpS0P1ZjmMBDSNbbXg5AkoDWbrbJzmr030NQTobB2vXxNYibpYykJIeTiycviluZbu87UXJy+Mq5e61JxnfNf8Kz5XIkrmsIbRUBnrPcbHzKTq2PEHZLsN6BNvNLzHJKrNS6AXtdM1V5MRPzbH6IdmWZbtcf02WbDrDp+fQYBF0/2qofc6rZzrWbNYgychktcChBAu30ikdDyIf9l9mcRiNa7Wnjq0Vo4g+SA9zFRdVMaPTkD2ZPbB36KScYIGWmpsRpr2dQUR24UUKEp5flAkZTx/M2VwfBl7pG3cxClytex0wB1y5Z3HQdqmuRalPnStyLZmLv05HEAYJONmtTPoqGU+/b5Fidx/tXs4CC54riHyav+h+PeNSmBYbVJV6lyhzsMjnRknfQbKkI3KzNkNGMabEnzTs/488Oq9xHMM6Vqfo+tOfrIC5NnFG45sMb88EOeuDj2QEbjuu8Dutt8qc3GaU171mp0fJfV9BMPw+aZFNx/ltvzWR+vZj4PglH9esUsTW5EIS/GH3qtgG/+2/8PW0EjnemjaU+29f0xiHtqh+Nn9PVh/Y2/z+4MpdnJGCos08gLwvUoSj1F/kFCEWMcroN6bla4NYaMUXFtNPxlBbY0FbsZ0HnlAO7sqYCYj1wRA4bnz1eEgIqmFglBEXtBxQNbfcEgVgYrUSlnRCbKTlwiabK7POR/knnm75PSdDHY5nEmUsgAs/ucaGNAjOxeTJbnn7cYErGq3fw+amSp265pGdnytTTOixH0yLLfYVKU5iCJVj2rAP1AZQFcA94HElwFqZc9m0wcKgwq1uDoGwnfDCHNiheCiaIcZf0W0YP9u+BRHxZYqTNNUhSBT6jg+Coyzuw8y3Dca/66Fq88f7mzbNnPBNWzJSrFHIm2PMUv5hR+7BjAVJEMBwbRzY8WttGqSTNuCOSXk+rRLw4QCdMiA0KAINUsn1F4HB2LPQ3Eydi0C/5bBC8fnGrbYErhBy1d+YN6SYe3FCD9b5my3R8RzcrJ92hvFcDgYtLsJZCCWtufsDC/U18Df6OQK+RS1NCgYBZUWLd7YwrJMPbAjQtDbqtrYkMLzqXfw1iXwj+AsFD/eZJsijXChQ8PQ65KOOUgQXol8EF+RoJ/tNiNIO6+/cxvdkdjDJI3dutv7pADpXars8v3ufL8EOeedv3CG8MOA1b8zLcfG+xp/7hIw5jYGiF1TcbZVlEO7KGd//FSMGWwRC4N8/WsSFyaCVLoL1NhfoiLW5B4g6LnlYabDhkgFfoi7+DicpHNU01HWcRGoDoz1uGDSrCQ4xrl58piTOORsrvRp3oghMjWYsnLsXQVIBqBBY+4qw8Fr35STBtDrNecocTldZecmqoF4qvfL3iE5GWbiLjUYwV6u2CWf5crWADwYB3qqI8okYHdNeIYRffnKEvFGa0yaojY43GVC+S1gjS7qArLL7cycTEGlhQ6wJ08hnEBXfIqU2h+0TihiEM7SbXizRt9gkAWP3M/8rVGc+SyhxJjvmX1FDWcjjlGNgNNQ+JzJNN1FPh0c26HRn06mXzIyCy5ri0019d0gtWWKJdmngMxd/bVGw8iVAVLAv+kLnuu+ZgTFGErJZ6DAf+KLLBMAu/a5dpYhiSiQL/OUUR25O6hS+uWFwr4yA4N0SSSYwBJCkOU1IMbsNBU8qGlevZ1xOUHKcZg5rP41HdUlChdzDayTSuZh0oJIT3hYg+/iGUnnuXcNMKjA/C5fUef7jbEAfqJ9Om7VAweX2ddOFqeMeCQ3fxfJ6smxS/ETKiIznysjVQAJgiKtbu0ZtM9eLowMlhLXXNAteA8PWKMLISu9OKVD7wGS4ESB11kG+WAkg8i1jhTtUSRXv52bDb9I15GW5BRSiJrgO9zEPcewKYBaBYXsSnTucQ5ETozwFWWhV9Zy6+zad7aRHqEBhuPitqcIc4rtpZttfHeuX7fR44LlUBPlFmAyl4L/vtNoHxJyihrElDpjerfVeoDZVIMmhnuR2D5je4D3dTkLoiwr1d2YzJSj5YvJt8gSuZRFGagcy8RP6z0CIspJ5jz5bAEzyEptmwUFItUV77FdXJlraqy8C2ohsnIB7/Vk8jDXWwTKoCV1r5c8ERQwdIDRPX8em94H9LxJ50S9aXQdNPjreFNWek4B0ERitDvEtubFEB9rueUO4URqR0RX2FUOMigmZQZstUDkVwi0fWiOY8N98oolASoOyzTnFME3pynKe9xOtbv05Y0TYMlrbuLJBcl9IdS95QzYWEo6isK9lItGEejx2p98Kka7u1WJHBuApqcJ1r0QXrfy2Ga0NFn9KCq2ZSTiCLkZ91l0a5jLlFl3p2/nRqqRtoNQvm7OlREw6nzKMx04ZaFQMlEpqjQ2jTIwUCQi3vqUuEeNzHrO3XDUvNa8uRvevXIRvUr/zeOjWELKSArHxW7nZcyTxHajuy9M5NuLoAx2+CG0LqXevxwQOmlGEIRuqxJgr8Cg6cQbXM1vhoVfDcTYQHNDhgFKwtQ0gsjBVmanlKvpEmHyNEhhU/6kSgPSmSJNFLs1td5ae3POfB+e1bCCuf8McwnJqxk2EI4N4e8H2I6BJcPW3+TmthBBFQenecNJRm4YQPYFPBHSwTAHw2627L8UhfHzaTK4KON5F2CEH7fSCq11ShYjoQ1vgCPSMdNmzUkmY/N6SzrolyA1z9uTu1mj/v9ZgqwW7vcdVdZiaH5R64jtrymyVz+B1FMS2hM3jhECZriK/3NbQaY8Z6v4dDmusqHnOMJM8rQRYCkxwuuD9MaYQsUCXyQ6ID+6C6kx+511eVkI2xfultz88metcU6D/d2q7DOmYdoQ73IN8tkfzmnJmG50jvmCp7y0zxmPe2bHk/SovRspALuluLuHfkBRxXN1zjFGTPBN6A0pKbO64hDXwOZ1CyBEo2C0K47myw3M/9xZjzieV4mKw/1VytKgnBmuUDIrzJvvKxle1/8MLK0IxcSO9uiUQjMOp86obLD8QApoGhGKSOhJHkkpHTzomsSBnTNx1VR0Huco9ycnuMIXf67YcTmPh9t9/cWvq50oFEVvV5sq70hli0LfppNmIDg2vxAH5UIZHV1ZAIaFS60OfqaeLhuqQDF8J4wDtQ6dqHYo/RGcAqJ9SChBeo17eJYbo/pxeKKfe2JtLuIf2q1BZctAHHQ3Rb0Fcf+W+PBTO/JGea8hsjPO/8Y/TXcAMSpMt8GHQfufVO/1yjssRJXDwMcuYeOPFxz7N3lS/einq83k+ABNnAGVHhOdrfhnMhHlX0Ieuh7EV/htPdhi0CX8zu2M1yzwRtCD8wJK+sYDG0QjZ8oZ9ER8M+KoPqFt8dQ4jvSquNKhDteYy3b+EpJ00OIdVwCTXsMMphnsAKWkG/bwHRa6YKERkQA43A9KDyCCdluroWqOyBDpVfp6AyHbJNIwTUHiKNZrU4VM6yNKd8Zak3rbQPLaDC9ODIgrqCOLuKHf4yP/Lq+mVSDC0fCCvyZbC03+xVJcphtThAydqdNIjqC+hxqBm+JRQZV2C8DpiCJGkDNPrUbAUar7y4Zk7Nhv4SQFxxQjLdJEwAakXPP6WEao7MiemuJ0SLORPzpY1vorXP92/VfUbeR8dl4UrLrzkvts5Zp0FahG4OgpjjUo9zdKJBYXZZBWG0xJNdoT6PRvyiGXQVNLxhDBUrkgF1FMpuz3Mju/hdLVI+/gRi+VjnTklcZP6m3YHki7QZOi8OTss/s1QKzh0loef5ZDC9l9ydEXEIm9mYuJsig2M0glKoCMI+jkWJ3wtHf6aSJHN9IvB5s2ewFm0A5IBTZ0COXErrUPGdIJKWl5dj+dAGPKoXn/EhdFDI7W5tcgXsSv/ceyuSOJOJGcmTOUKTMUahrDHhnuZpRiTgOkcVBD/Mk6O0cGcN9CyrZMrzeW26+yzzY17x2PBXCDD70K+69ELgb6DRIrKOewS/FSvm+DYZDIcenJ0X4iHEp0U/bXY3+gMdkUFZWEDLuEaee73oWUGFvRqb12CS7bujIlU4qS0lDZCWaqWEpsg473/jRhVzDg8hJ1p7alfjCpJqYAiQ1DoZJmeY99TeNrKUW90OQmWgA/MSGCY4focPXnUb6ZA8yY6+YJOFexcH3l2I36Jc9m2qgvXAITYXWbsewjrwCbC3OCucOoxVF2V7sEzWchWs4hydg32X4tLZ7wj7U+fyJVkS1IdCO1YQxHoM+uPRNa2CbywzD38Nch24CH9NFtlJjgks1isStP1dcPznX8jnhoRTSfE4A0wTPLWQvCRXTo8/Y93spIUeFlQjWp2Vm0s661DWU3OCujGMbohUgI6xcIBvKN7gmxnJrdqaw9mc0nDYbKXV3oLmUMZx6UrihAxjQKfK0gi8W8tkcovWtwkmt6qzhMd6hPTANNFzsNfd+iVaHOyMtwzJXAECd/Ga29A6u3BgaZignQZ1OgGtowpP/GxpcobJzadLAHL3i6GDB77OceRG+yf/Qry7T5gofTkcK7mW4497/cK5DSD56M3fFdRuwmWC1OnLxGRcieiO9IMC51G9VEsbuCK7WLE32WLfpshxWTo4zkwyAYnrTd4iZwjQRTPEdPAbsC4Kcqa94Vi6t1L1mFPty8xdZlhZ7e3dELJ7ncuYZSYYHbFybtsjjd7NV9Pfg9WGUBJtuybe5z5hoXAlC9pkIybj0wTQacuybf3WegYb4srLzESt6yXhEc7PGiHhE9sNovG3pFVaLmUsKMb7+6ACpSUUE5G2ZfKq8/ksZ8oJxS0Y7/C/iyUtN+vkpMt2l8za6I3isGWAVUprhAS5Zs9r6NZ6obrz1UsOC2Z25/EgAY5uiCcdaoViytkRrkVxNeKI+VlRi7MlJe6czpEtNzlT9XaaAGLVxq35iIFV30nbpEve4WnUvWU83dnzH08Eg20pjXYX5h29duG946i6REEimsaAOLxsft+n3lqkVkhcTz4Z4bg3Dx3k/tYQ9ewcA+AhNQFe9d2tZFEGkaL3bK3TAGviN59FrSePDu9FTbb+otwtJkfyQ319TuAjY0Hq6ITVytfN8uydumPVhakwSfGc9AGiMBxHfFdtbO/6037en1hh8R4/9VpYrBrP4+x0hPq6gmtleyO2dhNl1TXMrfU3TO53oHa+m4bcDb8Fts3atP+/NR5IpbN13W2km7WQ0QuX4Oz7Zj/uaTM714a/KdvsqV9lFWQCynp1dJuvsPbTpO+uncm1HNh27tjq5PJ/J+XarEtYxdHLAqBH/WU74EClQ2HYPZsC48cltejJN199TAA7uLwKLEqVRIqFRrXaJP2D7+OD1XMEJUTj+/mDlu5LiL9kecmBCuG2korQqhkD/TftvhS8NCcGznVm6GOpxkjVrrbNTR8zbGrHV2rwpgLSGLPtwXoEKevhKf+pv1QRhmUGREBLn0UKTLWbbhv3hCgMJonodGmB3fUweRTbOxDFXc8l0vJ7yGHln6gbV/jyFDpGRMwClUfD4SvIvMDobpNQPV1zyXq079hRhAStX2tKxHfOPh9dzyNBOyDL8VoQ3r42VYnN7F34hQl+tHSvpOdDB3uO0sVrn7/LprsLhJOMhLX8X6kwmRR9Xcmd7IRoJ+XcYq4Lya0RCXkA5735DeQjSpgvvFOfIhlt3Tu+pY8bJSikRTwQNIBGJQP9NV73UN4rOcisR24zAUd3YE7y759+w2YMLeTx+qRa03YDhb/J4zKUEls17cQbshPJGzx6FajcIv7pOFKeoaw+0UBB8dMEZjVIf+ap6SsIwR0Yy0KQl5EGfTiooc/xr4NBwvkP1SzC3VUCCas7rh4VLZLSNt147O+k0cZleZEVYPSWatYVYtJKOEk0l+BlKPotqqMV0lNoWUUa3BsXwdKcXmwSlUC4+8pBZE4eew9hcDPBpKCGl9gGNr8PDKFOxWdxH5upbLHDDXxP55mHvySasNEdan8U8194WJZHxi7SlHbWBBxiNilh8qn034k9GSoOucmQrmIHDv2r9Io/MJ7eu/QxxsjYzOOLEp+8YjmOQ08PUTTRoOdpsS/ow7PMzLn+Osyokl+93BTUW8UeQYHM/9ovg4lYeOXMIRnj8ZGs1I5cRc+AHWzmHOSq+xlD8jS9C/fESSApbM/+iWtiYlXBDpE7MoKhX3DGz2xZ73eIvqQbCu9tg8b3DBwNwPT1nlWaOTG679WTfGoqMZ+GMvPCOnQ8wCgkE+cNVkA3mHZQB+LrEouUKKB7MCO+nDG0dDmHCOLH+AYuLBdm6R6ezzXXgDm1eVZmdNmnNegQYfdu1c8N36CWfLysZkIpQOwTWMyp/a5kuZAanFc+z/KUOZ/1lsL+wI7eBqzO38VrjV41V66oHGSGbAUAhCbpfGe71fUiI7XZd2GFQpcMLJobgdKpy2idGJesm6GRic9jXmMS11Daj23q9D7PQxYDZ7zzN6IYDYpUqzVxq51Dv9Jv5/28x92e+ivMr3+/OeiOe3anaFC1BFveYMqhyNXcTOXXDTH8St04tlGgO/VY7fmabMuSZNgqdgXQcyg4EjmGx+vlF6uuZu4joTX132pt7ewNHDtPV63pweCCAKRp+DG2mqua85v8E2k1hYgSFdEfzG/tD8Ht1ln5ZTIXMW/jdlQQOFCk4/q30ugxYxyIns/sAFe/iKW3yaKbGHv6B7VfiacLnoQGQZMpHfbc3N1w0PQO/W7KRugVKsdP1npOQc8GojvYjFEvpd3BOXDVGf+9tVCBKfkO38fJW6NAskRPTpAx3WcnHb6MRUkPCO4k7FXGYjkvWRiptbfW5kHbIGo2jce0mvbX3gfYeOdIjnCZRTD5Bqkbt3fGEg9hxnu8JEPro9qv4w+x+npcMVkMLgxAccomYJc/0MrHCAu9zwFv5bzq3MoEGd92h9TA/lG1uzxujnW3z9BwIYAqTz9jnDzLsZOMoEoemgHfv3zDdG+vuwg+YmaOogO8v6Xq9QnebR2U7k+HUmJ2hsqy3EmFGc8mIco+TyItFaW3VF0vOUaiT5rEaDqJcs6bAjn4Qz3uocl1GYD1MQNXcu8hxfzqNo2iqM7OuaBIOUcZBihSjPzUvOno6g0CJB/9eNcO6uN7fg0SsBwditA8jecnRWFCcQYdo27+CszikSj1fJ7idnaGD+LRGHd/umLLazHg3VHubiLHe2wXEQUYBYtN/+GzR3WwZJguqbbGa0VPe+KyUjtBiKABKzoMruRP8dDoqHckOmP/SyegtshsxyNvX63LS+qrWqiiB7AQ0wdmFDu25+duU4N2yQgmDlkwuiNZu5wO6MVTq2bBsrc9qjXuT/mIzm1aFh16Aa/RyRHAC1aKGJa78ETfTcmPktMCnDs/w0sr6ZCCiJJ9AagUljiSJsXaAQnptc9UclvcC1gRsVpAUfKKa0TmZj4AVRLGYokYJmATqyOFuVNqCAr61vuLLWmp+ny9qt3koGa/12kqDu+jANoNY27b+M2vmonXn57razx6Q3ZS6C+wTSObas7teSSLcZghwt/ZOo/ZOhaJ0FrBqQjMJwI4K0/k8ndi2usFOZJ6LidtBW3YNb+nuNPuLliU2kgVyg8597fEdJoQGhg4SKIem7FtUf9bb5uhhm3uAJ8xlbrcFgxSY8w0x+kRR/UvmdGhCKec26Sj2WaNcDSif8UF8nBaBsbP28Szxq8s2p+tgc4O0I9abm/bgctuQcTE21egkLLMH+Tl3oPZr+XE7AkKtXGA0RnXYSB3/O05UbBa7dgWuy5ldlPB/ZX5buueWpGebO9Wc8cSUY/ejXCr0y+xSNCNufkwbv5B2EgmLTFcXpytSTj2LD0PkqzNE2cstzSw7wR7uIIISQrBwphmEb/xiixFh77qtkBA5ThtqgWuFLUW7SbOSVpVdG6BsfHyDeqB7PRiNhrN9E4UqgUiM7W2shGqgcLbeSo2rMo7sUtIQxyuWbUq6nXL1WHWAyxMgQNjhddhqYm680lVxJuDBq4IyVh/C5CAEmQDm702fbQhqZkV+NvRjm2eT9Awy07HuER4LvVDTMKFdhNL2Ixdzyjz363YRinmA3yV0nsoiHPJuf62ZUPkkhB9MD60mgJvt9YOm9rDFqC61NXXNEZL5nVSyrv4zPfuthPN5YmOo5b5MMjEwgrAT5E9FqxlO+Elm0sJCQ8nGdyaWIenZVC/tVXAe4/iIO/ZmrzsP1wFK0bq1BVhs65yMnynHmQCT9+KcsmCJPbHg3IJp7uHrZSREUMcjAXjU2QWGyZDEsaw7gLEWsoCyD0jUEjBphcJzfyu9ESzLi+MT2BYVhyRT/a4x/Ozy81LtNlxJYfHkOjrVMnNutubuW13I1wdBGHm08EcZTATRBYPRGHGHhfwlcqIzgcl0CuxL/LP7SRvmvtJjDMvO0tQnloQzUo6hCUfh2wAcg2zN0DgHlcLWKW3AhlN2A2luJ2YeC8F8xeMHiH+ivGbSLaLRkASIC/5eiC7MEUhHwNStH8gs7WQYTs29GurrBGi0dvRVEmiIHdYhhZyOMSBAme0c1b7e2TfO2y6mv7OdEhpeCeCfvsBmFHW1t9wki7gttMDdglwKkudTJQDu7SvALYLg7hCICX+8LEFrnHZ4JwPIPQMcLdpdfWdV9JwC0EE8gSIvBt8L2dgVdXjXSEKz80wwwBp0MxGcVH1fIGF2HYmEicswOz3P0j1x/6V3gTini87oLruo7RENWEyXhpJjLxDla4ymSoWpAACg7z8YHhgdFbnoLheHgtf2I9L3PLv4kA5qr+neRzp9a8cehf0Xarc0C71o2+IWaBldy1wbYvuW90HoTDBjgMQ0vSJyI6x/kTYFriJNW/eGyeX2M8/nj2fS7GCZZePS0hLt4z5WJh9z6+1AFUWtTr+XJlYYAgZzoesTGj4sT6oiijREUBDheRyLgnckeTTES6MFba8zY6RExB3fX8T8Y3cFtNoFINku8Qa2h+YiCm2PRcwv9wHFP14ufFetbEDBCIsIOeUr6MZMtjCVcNBWOt76LCU2vaJDy+h6u8LZiOpvk7wbJk97e78kjfu+VJ1ZzeX5mUc48udxKLcSR0U6gDDKRRGVQ8m1Igf0IWO7fye8XIaukm1JvSoVnOVlEx0Y9Pl6MN8wD0dDZ5mxpM+Yp14WOSMgBk2EoOxENrYsPA/8HVYoSBCqkh7PUm5LAynnNajm5iSrtJu7tkhVr4pDzZ0lrIPKWPEtRW+yghi4lsmD2cXE9ROBfR5gBakWEvIU4UmRVm8RLyDhy5bbixLQ1m8BdRS3X6ATuzSpXuAsrxEDMRiOe3cSGGXo8vyWx3hsosiA=="

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
