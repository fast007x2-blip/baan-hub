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

local PAYLOAD_KEY = "eDA9Jmw72Ug6HhWRRCzM1rsGXMpjJjIfJafRTRadJvM="
local PAYLOAD_IV = "sDPGpJEADPyg+d3LShDFKQ=="
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
