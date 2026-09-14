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
local KEY_TTL = 24 * 60 * 60 -- seconds a validated key stays activated (24 hours)
local DEV_KEYS = { "BAANHUB-TEST" }

local PAYLOAD_KEY = "MFrUe7XFmWNdfqn0/iDOvg57n/CGz8H0JItfq9eNfas="
local PAYLOAD_IV = "jYn7VntVg88npHU+4OV/cg=="
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
