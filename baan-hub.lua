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

local PAYLOAD_KEY = "LNcNK+ajDVRfSW+1o0jBLAsv033fiO6hJr0C77MQKU8="
local PAYLOAD_IV = "K65006IObUv8VXzJjjeMJQ=="
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
