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

local PAYLOAD_KEY = "t8Mh8xGhTyfW0TwLICXWc8+nuBHrTa3XyrasXroptFc="
local PAYLOAD_IV = "6/jw3DjzQeAVNUNqjOAHRA=="
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
