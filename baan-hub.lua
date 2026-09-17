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

local PAYLOAD_KEY = "mBl/iQ2uK/BPE8xVldaj5udROtMpnKZphZU3M6sFjuA="
local PAYLOAD_IV = "5/qZavwelD1gHSrXO5/YoQ=="
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
