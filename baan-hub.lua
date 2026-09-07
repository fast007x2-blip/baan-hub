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

local PAYLOAD_KEY = "ErHLMuB0zQoFxu7e7TB4tw9+e0JAdfhtO4JbYNtq6mM="
local PAYLOAD_IV = "UPFOAMbwzpS2I7KsQh5dnw=="
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
