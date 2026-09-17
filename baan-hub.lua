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

local PAYLOAD_KEY = "Ci+7yx/hnJWN6D0aW6rkLcjCXBsei2EhoHxvwvauUfU="
local PAYLOAD_IV = "1xL3fa5HuMI6hpPFGcUClg=="
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
