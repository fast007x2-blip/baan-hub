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

local PAYLOAD_KEY = "ARsgJyLsVGU3g+MVFB/goaIE4VWxhEG6DrklKAgsi10="
local PAYLOAD_IV = "DzpKzm9BqinHdU7fe1qwPA=="
local PAYLOAD_CT = "kh9BDO0z+DUGbQxU7qWdLlmQ8UsFSEmfmRhZJp8iG5OSQXyIUwOZSO+JfQvlTsp5ZfOAazuhFnkt77DTHAaHp2PXVSBm6hcqkmlNl9ECPyH1A3N29nG3R97lutZ3M9JcFPR4NwNNZBLoyV+6OjtymdwFcUAeG4uaUQPynzVh5OW+44bn6n4kUPivmWe3nvlHcSvUSZrIbhY2j2DHxQVc1k71XNDkgV5N/ur3pZBg24hp+OuaA94ZW6PCWkn6BblgBmMKwUXrwrSep3O6CMRLJzBsd64SvIpBFkd92juhWCA8pVHmo8fTFMNIfXice0wlpStmuBqty+pCpw8QlnupC+X/mcxrCDjbMGtaYgdTlGVRmYf45wa7XFaVScij++aHTouyE2aXQLxaceJhTfZjp2odVZm9HLJDOj7nBgtVYV1qhaUQfo47uSZwVlg2F5LsQHCxWfOS9PWE8kzsexxf+87mwdscsHTMxTjTAJvl+uKa4T7iZMlUsZ4gc2ztYCUHikmlVRJ4YK8PXoztr14VlqtHWXc6J6mCn6Zbsw8e8anMg/iFayXbDq5tZhbhX9OQuGzBSNQ1i8fAybNlH5zaAr+Mln/gR1iWfiE7+NANhW6TSGnsthxMKIl696zFte7W6dN27fXaRfk3NY5zVE9lu0BKsW74vhWJtsKInjPQl1oZd3fMlyJ+LDz25nIegMMMkGxFobvaruowhxyXBuary3pskHH/aVehzWl1RhE6OL+yM7zYGq4LK98YhBRnlAwF4HT9TwpqOyuzbDXUFc1w2OO+If3T8DGKLmkQl9fueSgs/Jae20WEo80l2V5Tc34uMZ0POk7eALDfxD5/WrRq1GosG5rgw6VUawYd3GY9ZENcFKzth2yvgcuzBDwvZaaNPmN/RhwRhF0nfUTeWEQrjS1dvqMGTprSQQ0UwP38tj/8/X1FKJ25xNwQT1pWQB11BMYlbDHBVyTaxLIv31GYvHR2464EkfCI6RlepD1hd3Cl66LAqy2SjvWsjxoY2Tqw1CB/ZfeDNW7OAq1V+dl+CWB0RTZXU4Zx7CZGrQXfqNh5UkbwVv5JVigO6+yB94Rf5houKxIqjqCRXS/8m67ghogvAVVZSwYO5g56M6RY/NQImDb22f2LC4uOGchTv+BewjfURqxwMDNg+m5QfzNOgEuZX7vfO4oGdfJGDGm1WtCqERqU0M/mnmqjplTLhjt5Pn/v4dAq7cEw7NGUtB0tXGVAho5iWmHjbVYHhcglQ4DCtQBGUMn7F26KjyjrgMFcSv6psyou4pEvrqU3N4P94CpX3oPF+3BaNmqcRTKR2RDdyIzpPAOHuRh4mRomCkVkkwo1ozgoIs108WhHKYyd/iawwPiKmHVTlZmm8Z3QS1kVFRt/obMyWd9x2i2RONBlvaG/+fejbRC5GovXvpfFe7JYIUNuWhOXrzbECprS4faZ1vwms1OHNHTPA77F4g+oGswTtWVe2XCFxXveDHyEZ+YXInSbHuc5Y2EPqY395egWmnS7UMNUx/OWy2GgGcHl8JuG5sMGKB1oCGqMaldLw9HgOwcmyZ7RRCBoydQmWPVPDyi+YOVS7bUMuu+MWpCekxIuq8o4cBvYGKtAoiQGIB+ZbaGtJIzEwKmOIwPP8fC+ixc9iJvgfBOMjkHKpNw5yCF+JMw0ZzOkij+7QMNKotg+9wKwg507EGFYw0kaW44wF2eLCZZ+jP/v48mWrmAogFckqpJLUZc8h3HHVrA5ktg5V8zBmcGwKEQqlFS4p8XmhigTHJQIgsxZWPGzEZ9JsYGn40R0fuyBO491LzSNGKrXN3ip8F2BGKk+Z3dzn6g5OnwLHl+tnK3y4N7/Zt+fCv3OFSG58+jMG//kquQia9cfo9xiJ4uxDXpLvsB0t+eb0gipSTM3GNY/uu/LICk6kllq+FRvtL96d9Q5cN08GOdINZQkboKg19D4kCzYvblAxkfaLzz/JqT1ybM2bH7tDJuL/Y4cmu6aPUiK2CL83M9b/lkAf+yWFTByLyXwdAfEXcYZdSkM6SoWvupG5NC7YYko1Jxc/DnpAGRPUi4k8lzUB18lq7VN3V8fKe1NFDdjXCeMfGFJw4jUg1AoLHuLWy9n9CYYY2+FYe670Sxs+tC5JK3vURhYeMKtp5BHNCxsnH9P1WO8u/ZlYViieYbPfW9JljUWDNJHF+yAf5PO69+GA9w4g23NKI3rxvfunKUu9fTasRZOJJTZmASNjJBVrtGwoaoM5wCgtu4jMlmyD/5HnpFjnbuCrwDl3MIfTmnb2Pp2JDy4mVYNSW5hZhmXf9GLUfbG2SBSjCYohMXUGCf4suLZhkVLQ2TYzAclR7yqA/NwcZoZRKdIraZYBAcTiZlNndNxg9WdFsnRNu1VqykfgtayleJl5eL4tmLk0hK99RvuUwsozaovA++Uy9R7jsy0dihIKA+rL0F4tDNscOA57l/M/VseYTUQgjd1ipBwjg9NefIjYHTdc6SnZoQoj9LwvGkHJVAfI4klXSqQgSZFBgE5ZXUXi4if+p9N5ZsG2GWMhTn0TEWBwgvPWO+hEqoddQLXaw7/2AofQh/wsnW3iqv5sABR38n8G0MJPru/QCEv5G76domNJzDJduQINn0bLAhlT4MSLgjKUkQsb4LGq45QLHGwo0unuR9TN91Q3dlICSqPEcVD1TFYas6b8SNSAvdkAS6UUPbKVUVfYAG0s/02hd6EYqAq2OtH1E7scxHkBu9nHTNmJz9VREy6cWg9pvspceNJJytl8NaWgqgXLL8o428htfgy7ftYAegREDYkUNlfUyhB6EYz5JHV6zIwpRXuXLq9YDpU1xRwkg3oOCFj1eMeMP1N6vRt4Rs6My08182+SYi6bsP1Os0Vly0cw2lH/nCVgFL1DhjK/uFw8PFVpncsRyn7H6Qwm1Kk/YpnQiVV7E7/DZVlStSQSlQ2COoNVSfa1K4f4kFvhvVq+BLhzbW0zlPH+L3WdduYjsI0eDnEv8iUGAKbvs9TboQdFs7rTCN9bDSq9CEzSwNVRVdeuHxVnz44W9/eRfVj/zomhsIj2CxB9omlNlYCgM7L5np+1XM6KDMYBjBx7k17+DtkrUv6Te9BNE2bwTU/4e9Se3v1GOZrm3mq+0AMmIQwIZNsS5q/cPF3zM2VJ0c53OES6U7FMDKBSMFqtb1J1h4B5MF79w+xecBbutK1+qFGBlmVzfoad9nY3U+aN2IJJz90XA482MGytEstRJyKuGGA7m1bgD+y4dejf7V5RB5J9Bh36Zr0RFnY13apPzJFqUc9o2iCiDLzgtd1vaSRvj6tlKRxJEzVmhdOBpWa25ro6epEqPgGxG2pSsBijcqOkrG6FRi/CluPz6lD9tdKgP4O0DhudcJp2joU62wUdcLM6JOzB5Z9Jwv9PrBfKbQf+5zkyCqTe1X9fzGGdMK8ubdCmh2idYp7jYH4hJXWo4EdoCtCXIL2JNc+Va43tvNMJBhma7wi4OT7iNyhlK86Jh5EY8DkkiOCbo88VZXAU87OtIwoUOnJK9Bz0huOXuCPfjy1gS/pNm01dj1Jz7u+dpP1xPy73RnBMtid5Rn4SXUb+QcT7bqDTzMacYVPZnIJnnsB/6CdMiyZlQSfMpHI5Em3HyU3ww2bFm1s4+qHZ6CGIDBdksuHrIsg31DhzYQE9uRn7WKH01MgfCJaVVw3/CCG7PlafHZmPp7DSgB6B3diA+DsVMtY8jhXQvTxKrmYqMJKDjpo7g1TtbNEqaLmNXp5EIHTCCI1SDGjyimD0Sa/Qq25DN1CepS45P0dcbbi1OSBgAzovQEkXyCWc7ei5ad1h+lNL7XUD1ZWlmAzBqScgmByFA3zYur3wIVEmT7vz4Xc42ewyKHrGIEb5bMXMCUdU+bd5ybl+X5/VBiMt7jybwRuom6WU9XtSViwk63EdUKqTpPDouYD/Hvit4OBNTsDx7nyQKXqrFp3ldy8ybQx42i/aRmRvlV2QQYAVujOvnT8wx2VE/TwovaGsmgmnincU/NXPwuGMS9wDgNLj51ZNINZ/bW6C9aR0dt/u8RArs+GeQF7iRWGB3tfTOuw59J0pfB/TdQxQ5FmbltJ8EmkRps53ph5ME5ReakUT3Durhi4I+2xaUHB0C1sZpIJJYzCt4UNNsLuwDcVPmu+1DE3T22NSpQfwDWS5BPyw8xli+MdtqosXwUA6iqrsXv0dpgSnQ7nikbtQNP4uBvQrSQo+rFKctiDvQwtZn+ob2MHBKnJTA97bBYwjVbvRbH2v0FyN2sLHpk9N9088ZB+q9jD9Eit5T2xp0F6LPunTkpmlqc6bKklyttqk0vPf92SQuFhoYyMXkm4qsS+M8tShl2y5oTuM6Wi+FbG0HeVUnFLNtnuQoFtDaP8bxRZmC2mxMWadTTbnRNozEuiz5KdX7kZHi6edrgbrnzrpvDgPy5mLo8OSGqPQNYgH9j6jDssHeCaYv4votV7LNCQIcMim/DPSJ+ebne8+qV5dGkftmSczt/pvC9EA66DhXL9yEUtUiqSZ5u7xqpC5q9Jbk06mcPLSWxXRBi6BwJx0w828JLuAuELV/Z6KGjO9EZ1gUlN8l0NKela5YFxRTbmJ01FCG9zNPPpBTxlXcZtVxUAQjh3gbKzaPBYkjebBN3y934k/CX2ss0goRIj4S6i5TNKGStsJqykx94Xw5Z074eimfXGuNpEggyBGCQ4aRdmWvbfUpYfUWNJVVVZjioA2Fkp6/G+BXRLOkpL3wyfjPlNf1ht8Rdt8Esu9h+U+W5D71rR0i4n/brf5kxmfHvLAEDaTha/Q1ByQHLFREjtpA1v3DSoVlGque9SyNsi12SielpplvDgMbEPTd1MuWQAtqFjHm9SyjdCmoB5AIUMjdvs3DjsU/WFedgbxKK5nHEgv0G/LYXUWCyy2vjRoZgszEL8eC00LNRqlEXEimGpdtClyO6oLSvDFdQVA/sXLQRvBWoHPXtwpcUCZ3bnqy9z73c5t7DiJHdyq7Hchh6RXoQn2Z0/lKONlEICQqyakNTSiojF1rSEBAKPvzZKZ7T9YNA7Wcc9ZItW1hZKqlNFhbO+WYSU+Djx1dD5uvi4KjyOmImJDPDmjiBtnoR69RquG/NL/5mBRdhVpz1TBxG6aBRoZwFSEfbLKEUL5k44hQTb06G9DvqxdnKr06kHXCRAeyU5+e81+2kOuPAs+m03rH7Ab9zp7xpBqtSxm7WdUyZbzTOzyHKqGx2KGTiFTF7h6QDP1ZfljgQqXvdoP2y+/QJJi8FAmTgKBwY8KqZcijOFNKkwTlLKCFuZk9GdWbKTBiCQ5cBYCnGinz98Z/E1K+YtplEFrv8HKTCU2FbxqBgaSlM/SzVFpAjPGVYd0fFxgmf9jj02slLBsC9Gsz0zikAcgq3/8EHVL4DU57BsOuN0mcwbq/Tae3nkiMQXfs8tThiM8sPgRITgpIwAaMCQubIuwu1KjqaCY0UKs9a7dfe7N3sf4alGJ5hSmqnmNK7sRoj3Z75F7Tl3T7fg6+RA58Yvk+TFijw9NpLi1a2YwD23cEOno6jQw2Xm7VUHQ0saG+QL24LyYMd4t7JK8OhnhxBXRym7aBKWtwjdR0Ie9C/1CAO7YPNrd+gIH25DXfI8QS+TDL3IfR4l2akz72eykanIMJyTmE4RFgXPxAvM5GIrAbM8ZksKXsrLKKO/KHPyaEJpOpb9sKdRGcjGqvgq4cUorSIgKrnP7Ch1ax4fc6S2euHdo3Xfs5g4Y4C5+EM/fY3R2b0p335xvXyzqlsDFuswUTSPFzYaFdRZas9swEgLWqM2x+crKFf06C4wDg3qsfU3N8XVEav/CRZaAxC9SE5o0SGpLeKBIWU8ET5huH46IO3eEJ043qPChwiIjRJk0Bskprbk3Qvbao03PdVUbDufMnvdgZCIi0BlZaS+Sq0YBDGY9YCKTEpthMqbafkwCTOr1VXYN/fhA8+RUwehFnfyGOzb3b4AoXiV4ttLWi8ZWk3FvtpKlQQJX9J7tHOqocIoBQyM8lz9KJUPiZluMlmPaNa0w1rN/SOQSoZSwdU89h00l4ZOtshnQ1tF6e56M7KpPQxe1jnL76k8g6MZRNCfNLXF1uGsecEf4NgsOqpVN7xOwulOIlqC51qTfR3RSiWobraSaVxOlA9mZp2JEVSqwbN3D1NUMu00MdwcNlR5Lc5NnLgD3SbWrq69R5m6zBiPQQm7Lby3I6tAG7Zm3EZS5uNdjTQREEUyfE0vR1cITiBVEFzocCQ1W0c9Q7GvfXshhsbJjc/U4WxZ60w5mA79IvwNNJuOeD0b7tG3uApdCHOiQezshethzbHQSNx+ZiEH25tMxECMv7YsjjkXsdcQxiL4s60SMvIOw8mzgj9OEofmzfD6z/CBiHEXJlHwX0U9lWHlBL9E/CudRC+GRmwG2m5ZkLYBxQvV/f6+UZOHoqY9Ph/MFQQT7fCrAzcz7GIwPz3GPKzGHVWe1bIAajfymraSuMQ5vpyLZHWSj3qeXVa5gzGQWeYAi/yVI8Zcg3khMHQIOnPH4jrpWyziXM3qLJp/NBVrvIYGFyTCquefs7koxIOkjqTJmX5EbI9ytKWdATUVuTWZCQNiJOPeGe/5Cm2qLG+tt3FkjbWGn2RRYbsQecTIInSI3Tv3Y9pCK1evkjR82CTOvSrWJSzK262w8VzxRBLP5TwxcqWXs26nFRpRZNhLa6wKXD+aT4nOb90lsvOozCxQjjEVP7OLpT2DLkemraR47Yvk1dbmYX6IYOf1bQfCtXD8yVKpWbKom35jkIVGOw8ZPugqDwMJ9GhaMMvHdl7P6V4zklQ3sG504pyQj5a9OZ8zYQxyCoocbaQg2J2K0XB4PlsXEr+vpqdirKDcxZfFpFjqLIYK1aoBrbgfOMzT6O5avWkTyqvGxRovOFPKq6j4bFSxUvKNEcQ1FEEKEgkNqXn5KDYd17Fq1cuPxZOPThlh3O4dH2PexgJmzCk1aDTp2KgQsjGKufp1jAKWMaBCTSZkkLIBAUTB3L1vukEAsPPnSRVuaSHTu41lHydkgAAzWAfDRqtoFfzRm3up8eAfJGBoUFBqERQB0HoGefydnVIu8eO4palTWsZM143JkT1FAkswLj20tMJ7FAleTnt1thx+/4zNDACwtwSkKi/sh2j+CI0u43fUX5U8NZ8tc3IAi9yaOCeMYSoiklOOQGahn4EHsu6ldt66t/exUQZO/9Z3pV500fGN+oOuTGY6BWbvWsJsmPLAkeC5DbTM7fJ6svhQDCREaMgTKm6ATWDhqXpJxgLyVaQZXA+o9MxDrNbjr5Gy2GEs7q9yaKNYYeK3BTS5XahB4Lb5EqzSEJZqRWr2Neqf7qIBDQnKNgqjop0ndQwbWFbvYVtJZgMp41mXA1ZRAgJ2wHeEtPRkf6uHNwPkA7N/bY+dRJ0H5tWvK5uiTrKs4C5Vlm13w5cIREyuU4laXzUvDhBxgF+B521wvbsz3rRyKLJbhNhF1v4DuO+/S7hmnmeukhKbU6/gf1HziC0RgXgwnG/IU/akepgV2avjal3yOLce7VMgkbONI0mGrGLNEeJz/lobNb8Q4xBK1Rfihn/e5fjy2EgHiGLOZm58sekbCgBif4eDQC9jpADGsqe2Ljy3f8+wkDQwQawglcTNfE+Kx5luV4nYHYRJEtJzMxV2+zOTUTPtfKLTsDdrUFXzNEIYvvIYLoZgv900BNfNlZKA1vzj3PZBV9eOXJ4bduhYYouuXOR0wGxmatdU3R79M/qJpvvSeHLhsYcUWTgBbfOfa60HsPlCDhaKw31uabmizo8I1RuJERKnFH2/sc6I8rlw1/JE1Fvivlk26A9i0+xxOrQu6+3osL/yZYZbPGvLeXsXftkXoHR8gB2JJjUjaWw1R+cJiyNfpYquJogAMb7N2H5Zhwv1/eTCCoEIaKhBjW/0arajiuNpf4rJkEoR2aPUcozJJezcid7tSpcC7WOS9gerAooH5hee7i4HeUoDyBkMAEBQCApWzzYq2hfcUztD20GUr2fLBGIomXMcbluubHrFVXa4vnZJmhw2VKJVoB4DiN9JQQCKuw0qXv2TKWR0AI4bBRzIi8EAWzFzUnZPXex6IUt2eDE+SxWMB4NmyVDSCL/IiHHIdsysC9SE6tdaHU5KHSvSkH837h+8EJv6jgYDV4bhwNkTOc/k+fLmY4vOJsU7CHAplowS7vmF0kl6URHb/1lnhInzBVk3NCor4PDk6Xjm9rD0vsTU3YN74hbbICIpE8RshHPfiVXik23NCwQ3qDaffHbPkUflHlp/l6OrpdAhSc/DiEaOn3tU2NE+F8x/dpMUcV1np8hNrAmrF9PDqEq/MrFhjQH+Hxcjo2zqZjVuaaELy9PfkpZv1FmLGmG04EwXU6j3p2Yf5HxZCnY4r7W1PKyXkTfoQ8LUbxnepDj5H1V5gvKyXk+dgi5mb+pxUKWasHHMEu7qqloBopjMSLU/HDY/j30gj001uBBMjNn2UJ+r4/nEkGB5HS6sUCGPBWUe1SBxw4i/LpGavBAcJdw9DCGRi2QMcoQbWiXKOyZdHkE8b76P6FdQu6jrBNs2gzmvjRUj+OIekCGZRCIe6yMBRPvp1LQG0HKBRwgNaaS5+K35Ul10ahZZ0ttmcpvzuHXgP97nU/fmBTh/Ss9JJlROfYLX7qVv5N7ReypgQMZUc+7ixL0nPuf3MxXHydRgPHtUKJav+wykMb3milC10k4hfslfDuE5ydXhEjHUdhvcfcvszUziVhjvWpERd9mkcXikeOwgxVlRm0wI29kF3XIrG8TjFTscX9RncGt1zhxSNy5R0LFij4TJY1YHalh73NmlKkg5NWiWW0Rxat4sGs8tmBmrk9V0zMDKFq6vat1t6fMK7prKnvmkcfcyCo/NztiAAPa7ojipTsn1eCWvwI+fUGqbJU3YJU6fh4LXCczXJ4gHp42wC6Z9m1svmCmGM3Dk5Tjcjrl9XA+xKt1ULk2n192zwlRull+dSA5VRTY6FgjhalXHZzX0T6bw6JceXa5pmg6bLzdDK6KEOWqLkuYvAHJU6Qk+Ny13B7brPeoYLMMoCXaVWBu/4x+ls1Mg4ZoE8nH/ovVTANKMas4gl22Yl4L21/0zhYSZe785Xa+PWRY5C87KR3Gbkq9g/KB2uwGxpDtRkZvnvt2rRjDF2jA2RQkuKoNJ/AN2gOJH69yeiOLH5AGZ16SVxNFsHNfUkoweCPIRnwh2KN3QJezs9mb5zxDFSel6GSK76QaNKgrO7XVpnfg82Izt8Fr9jU/HVgd+CY2odRyHvGWDaFxqQMLLdICQvTkDLkeeZGQSOsP8MXee1lVIDpjSMDounuxdwmsIZjgJHe9QJpklmgpWCZg1MEFO5BHdmJu3dmqpv0WTrrc/KcHfGzlDQdkARBZVApe2MmYIyqi4sxAxbSnAcn/sjG0RsO0kxgVuoZTH2zTNT4R2vvwboPBNuK3qn+IgclUPm0xXDnratzk51hQZJBiwSNvKNilergJbruJhCjBhlafnEEnmdORWrAmResK1zSKzCQpynjwqh6qGd0Lp+xyQqjhH4mC5Ett6s7dnpV5nfn1p0IVa5w77emjJFu6C6fpQbpN0abzpKghoq8/8oCEf2vnj7fP7ewCgn2kvbzDeoiZ8kX3QypLgjwgayuMrw0dkbowFHM5I0M9nXKMcxiKCxbFSJHFSggWqNizutbWQ+wHclNztfaKqyspvdXuIVyozvo1DUTFB1UhVlcXAGDQ+VdqJ7S15cB00m/X0QEJuBFjf72Btt1aSi+H5YfdgL2HWSdGkgexEfsOs+N1ktG6ktapq+4MSbMWArXp6CBYpfvz20opO9GRAW2zT66R1ooKYmGGgCmm16CwoRv3lIsXtekw9YqYPo0AStQYwKUy+HqvMC6epKrlu1NjeXd5R3mDEnAcl/XoW/7IHk6SGUsgC+ZrNC5MFqmAR2djX5KGG/+quGfKABl/NLkkXV2nqIF62ev73SKHc+BDHo56GTlz73opIP4pYZs4pB939rjsuAQCHZJXw9zYZ2+PYG5/uN0rz8V4skUKmpem3VRz2bbC4Oxcj7cWqiQ53AduYrmM8Nn8YFlHwxAWS9YBwO7/bWWRXr/f/GRGsapxbcSs7DqrKjogqpXAy1E7vuLM8DWeQWIQfCp2uCBHTfALUsNCpMEyHp0bYl2T+DYrpwRMuh8HRWAzYweysMmdtR1eHbqXdwelEN3Bd2F7j5LDuvDbW+pJhb6vuSy/nBWmcInzulQTYR6lisvY+uNs7Kw0BpAFXCNoPpHmSGXfkq50xveOuw1NmKUsCza6x6Dpw5rn5MXOVcVgzTMbS4jtXe/A/rtFSgA/qTtpZF/+JvRNQ7HOkY4BpOxIrfqu8E5GxywHvw7wExshtd+b9Jj0CqNEagonhgDsLMd6ZRvy8cdiRNqwtXd5isVtDA/e6uriBN03MA+Tm1IN8SCnnBEhWypFfUjEi6A/YFdDQt9WT9GSREWENTeVZwjdk2I14zWK1kMK8xAAyN9QWFZIPugJm0ll1Jym3iGZsUxyk3e0Yw1mO22j/wkIkdzBGbo9ln61RpxPHRgf18FajfNhJ1EMjRtE/Sh+kXbGxY+hF9sbdRqCw+Ow8clyMTbITGqMHlIpmz2Nz6GK/8Lp9ZIYNYkbU7QZbXs3sasjauquVxGVRgeHhFNFx2Bq0dvBERNhtCeiWblcKOV982hZXxs2SoYyB0tA9TZboAuCjqakVCMpiEEba27rKEvu/WBnpR2+paCYHGwOibi2RCxfsgsbLHUv3ad4H695jX/p5bEkyRrDBAJ8MgxCnLiglTdvveJEtO5CZ0Gg+uhwS6wYsnCRJtMfLEEOQvEhLVXPQjBxi7EgkJU1RQZji9mT+Gj0ub8pMeYrY3a14UWtKO6je5zQSiJrMZgkEA6LfxGnY5W6w+rBSJCA62abQmdvjTlzjiTZV23gF2Zfm7Rsbf00z5hg06I2mgWWc3ZIpfClY638hpKRVkYvEHfJ4ufj0gfRsnHvsBwy6Z7tMaKCS9VhSC0snFymSWd5X1w8fG607VRRVonPPNdKSD+vciwTiqnljja+t3G59vxXgonkB8X3M4buVhB0Z1FRYNZ1pdZZWyME9kNhsg5MrFHH/Fbnk/rsqGMyfTT84qANzn3oiiC4nNuSKDjHXTWF0u/hEKNbIp89/ATYIp01Nv7nxzx5Wio3THyOnRpOJGZgvby/J/r8cYvLBLmytbh1xCYu4d1FE2a6QWvi8/GuC7GM5tSp93izDm53zgQYFduzHo03elcEmq9zP75ICLYyl5uLZl3e1QTI1dj+AUTuK72R40oOI5CD713ZwDd3kbUCdJQ9Zzr9DnsxHAZZm0b2cDtA9bVEa/sX6U5oDlxfwb1oCOPSyn652Y5my5AmmvrDwi+3Ri7ngRs776VReCHCGf//IOZxEmZoOkc+S4cLeEPV/PVUELfNl4jDwys+scy19Qy6pMgSPtkQ9tx/sErZDzvBcxhK90gDJ7i++KsVBJws6a0CxBg+9JE27+WsOfTftzJ5catkdpfl7fufgyg9Jz7U157A9grRwfPwKe8evVcqY+OafEA2z4wUjC16XZ7WejrwoBklcqvIy0c3Nxe1gtlSS7Bg8tpWrb/Vvcm209qGNnFh3K6RQwYj4S93Az5eaDXzE5pi0hdP2nrjE4JBNBCIZdpuC86bo/3OlLVIzDQI12deARqByhT8bnUpEsZuGUGUafRGSrHmYi9kGr/+p03ecs4R9/NJG4PEwxXCF044As8AYeM8RuGNU9ioxnljrhLVemEfvf00amebKUbdtFVzqpejo2yo0DeEi+jjvrPdUF8Rs3e/BukssTzlrYhqmaWm4rvQC0QtTnTgbbEbAYl83oINFYegVnEMwKoSk5xgB4dUjXRJE1MVRYijAX2ujXJUMOSwd8yv6z2D29ii09zH0mBXJrRZVhSj0AI/uWou/aqxQF9tusDBWm+2Sf9gwL+JhX8SHZe7wG7ot4tpJI4lPyQpy/6o/T2W/Ekn/cIuLxyND1vuRdizwFbQgcAGJrDxNyV9NUNfErFOYhDITINGW3oen6gVXuVkP43gQi2pRQRhyNMYaE1mqh8+9aKUlA8DOVx7wAjmj/16EErUZdgRaxQ5WEMLbiOaat9FJv/kYKHiqxIJQdg4SnITQvDq9YiJqlV7HOxxYRJQjrNpWyFV9ukp6XfMYCL8b9l+IR6hXXSvxMh4YwDkMQvzfh1WjCYEVkQFtGJZXMZP7LOyngVcBqwyX5iYYsfm59V9l/sj+B9Z2Lj+024ng2eruXsnES7o19Okxt92BV2FNbdWA18Lu9gli0vkdIM2yo88+aSwc+Nb3iHtrZ69M4yUwYiqCoWlIDXcrcOv1zpDHeXz0Fkw1KAAXqBEOoQjT9+E1VmLkFlCPfDcVIsYlNEjHTJGYwOIwF8cUyrj5MaSaDUQlcfo/HVLiQknM6wYmTOkX0GQ55fCkbN6+rebuQyydrF9ho56GSGaQGU8itqSpm7gLFhdN0eiB9ZM7sL4Wrcpy7/hLNSCkEKV3hjez6VNq7TRjGA5NBXO5KskbvGEso16/nZTTM3Hs3hgOCpmRBie2j5SKM3ahN0MMXAWvAnbE1EhEDVRVFTmySZb1M5lNb4+TvpMg8ZznX4p7H71WoTu3zt+fhsajCWEeDMJYLcYso0lKSNZeQEUNustIjYoSMtVVgP5ZNpWPaCQ4EeUV4rKjGSr5UsJp9kNCgd8HF4MnB/S8IvG72kP4KMWm1BTZSF5F5XAoHKfJ9gtpmKirScHwSuPScfzJ598LwGJ0zBBJhiBx098yePYl7cBLxuBlzPJmT7uzNOapAQ5R/tCldnxN/tAr+yT+zBZpDiSjpr+mt/f1DM5McUGdTq9OiMK4vNNDHgVhephDIWtI4ZP46c0B9hSNWLAci4ye7PCtDm/WGvKpxDZnI+OzHIXA2jWOiRbjLr35jaJvLRIjjc9fEXTgaIQV2mNIp0e83vRUjPgv6RXK+MehPqOAIYWELcElQxR6DTk8CipqcjKIlG99yauZ+2aqsI90dEtb0p7r14cyh8HV75cSnjZ+IwjsJUJ6SF1zfcjzVdpigMDTww9IF3JqIVsllbXlXOy/5GbnGl3X74LueRlxbTMLuLV9l7BZdDavwrKbpZjGwJmNaVC4wptSobVw5tBU+EEBqn10WlnxbQ2TnfxiFc0SlXto2Wj5XxbXkwMmACqR1xdVWY4qWAaIozaisZP6FQ0krTu9sBY9ZzpmsXI7UKdPuc/uth1Q5Ymm8LoBy2hQPRgO2eY/n8utpfaL5Rvvu68UweLCYxY+0BQIlip/Zs/TANVHwCu6EHnYG35jAcnvkKroSt7K/vE4XHenc+00f8UWOagcViOC5dK+XOMNFhSFH2Gj7SWptvO3HrSi6MoqQ2Bdkad9CRcg6GjrOiDoXBRMab3U2MC591mmKOCYloezchMiOjFbJ7pBZ9ZHqULr/YjtnMA6YbNQIDzk6AUz7VhosmfpOQZGVeD1phwhzYT8ETA3sboGs7hW5exh19S9818Nb5RR72njC39CpAEWb4jw2sbxwXa6+j1bprIoDBuJPyW7mNFyVP7gpSarRoVeLHE+cVvAYR5oIIP1AVKzRdFy3Dbqju48MHWi0BsYEEkgSCn2UYGheHNAHaTFZ9uEYdlJyqZ5IXxRDPN9sX4XRS3qoCxwUbTqu84Ngnv5JSSY9KCcsOrGV64FvtUm9TFY5gL6UNC9/4mAMQBun/I4ja3tncBOgAnYJ4LDavtzxdL0Ja8xt0Cx6mF+pYbUwgmt6LmvL2v1infJUrWm/dns8pPVhOGxyRHqKlBFFSNtqiU+s4/uodfj7vglDOrUP7pmzjtOC20dGrAN/6vxof3iuhhGNz0evifHLK6Fp35Ev6F+BjJFR0GwNc22K3v6i5EVOuAqLuSWEAPBAqtxGnzdltlNcT4wc550sg7EvlX0H0BrMSREbbf/GfbV6x8mYEKZuz6mVri4RFTG3MvIvO2vzFpP+c1mC+RyyQ7qUWHJePSE6brNsjFvF6Xhb7rKhOKyOH+Og/zJtlcQkmZYFxfAjYFAtmOBuwQ64e80/g0VTVB8tqXk7jE2ECar2EcdExSaWjFmNmzLn7yPjmT3+OEBHYsRoReK0u3KarSmVfrPW/PbZp1sZosUA00MQefLJjCELV1BJEq5Ee6IdwMN1v2A0/bNNgvs39+BH+OXCHdiBU25o7L8v1Bm1lKqS5nkvBEi4p1Ft06MoSZCYFlHLeCgdXvowzLZ8Rd5C2WkJJHQobn333D3juFDNm/11VEPyt78ZqapKBhrHxK24c3b9NupQtjL9ZNmVZeyychvmox6H8qqP5nbb80JUfCH8798bwGAJWoLqax8CWWggVmiBHVBeEeOXU345T5njIyPGaq3eXB6hIBHxMometSc8yFTstGtwmcD8RTjZszuIg1wI3C4atzGVVoT/SDnE/NDtNVNxpiRP6Gl+sB4NJKK5p+wT368aUSgtl7vW3qoRd8bTg3Et7AoKj4p2tnKTQOEjJuMcaIc7rOGPVxHtuRHEHIx/JD9ystEzy0lTosZSPx0kErA2AL4vOsGZPSBOdONZBv0N7ynb/L4f/pXgmbHiNpQuhst0UnI7GW3FGzzvZ0609jB0GfRyOYtLBOdQpUnE/Qi1aEXFoVuo4fZx8VBLIZEU73wYNL3Lpv3yGKUgPWGIsYNjFDA3m9b5Ou1Cb3BOveI6S7vKrhmYnteQDa45CswuntQh1Y9ZhiIN+66BCsW8jTunaPunRMs3AmmlKFnj/1rDR3wOSVQb32HHqE1VEAHn85V6biEsndgDp2bC5bN+6IGu2isFU3HYHaLDKw4ODkme4rR6sTAGLXIhsHJQia7MSY0BNvmKgYE1BwYH4ZpXYAgf9CO2S7n6P79GuoUKX1yHjjJ6P2jnPK0ZWr0qEqpzGhyPn5/g90nZbrhlEm2Er+ImrYWRasSTrhLOko3mv8Hn8xhtjJ32sOsqTnrJV9jRnk+P2pUu1ZIFRQny0GQlrj16IPO5pLvHLV7+Dy/shrN+91FeGxu38VUlcMlr3Jf1WUC/NAcAvUZjt8uz1uhDnRHHDWDPwwIot3J8CwAVbPI+3xfPISePbu/PYFTG1N/gmd0iPuoqtjigAR+hqp8mw/jf0Er51KiObcJghNykT+8loM4GSpGNbAzE1QiK/zT/2kZmaMky/u7/R4d8dp62PVw3Oc1+KIWzqmtfkx66Sxe38wUh7n2yMPpNdJdK2lS6qTf0GsBlzFub/rESevRdGtT1MvIWntmm4V1vECbTBTsrBKEe8ryrM323hByGNf9UF6wEMu+F8kCBcIDCrthwKCGPdkPBhCiWPizagaYK0o9/OVwUUcDzI3al04w6dwCSogts6V9mpRUQ/JRrXH0ekGrW4idlY6T1SaUAudxu7BA6sHWeS6p0dGzzWVJhcussM2NFW3mc0tqTwNw1HWe7d7HKjVUKOtfzjHt9N/UNjudeylaxOKnIZhnLWdsFEQA9++RCepHEKSJhEnKFFZJd+2oD9ONuxr37uoHP7XVOUsEhw3csmeIrrNefrI4CS3W6vd6L+INgQVVQpNB/p+s20/HXbND8Y/vvAOr/FDgmw4TS5aEwZU+AP2QFwjBs7yuU/ga9VlYYzqb+F/WzIDlmUnk6rr6CuT8WohnlsdLFRvJ8xxlfIanQoK9IIlkbkQWcd7xeNjqZdYs/wMUh+/LCwGF7sG5TIa4MgSZHpDRPQgJII3F7vX/KIzrn+vZTHioWQFe3X5CPnblMqLLZlD26bx08s0pL2bY3GGYM3dIeEWfMZq7MXa9eNPNciDcHuIVxJtDtiWj2xw0BGppenn/AXrkvxAiqPZfaqiQqzMaUDF7XwepOb5ScY+COOP6Nyg1axKqYHctQ8ZN60CgSwtqec2ID3KVfmWYx4Z0qLywHvgourxFd3TleSX6YEJp49UNa93kQLFsEjsS86OU+GXBXz1Z5kmGENiROUHImvFCJVu0hx76hyIj7Z8s7CNti4jtKZAobjYLlkJ8Uy8663qxp6HmFxpOQEfeFymT3dBAdugxueO+ELj0u/p09wifFk+f6s+KnuRm6sEQIKPN1PMPWSuoeisyptrxY5RFTP4X0tyuu+2bfL4RUTddIX+jAJ+hNo34qTjx7uqy+VfQ/RX5xlXxNqmfC/CjucXyzh8tuW72WSoYO5LYigMSlOjKhmGpdPESlLoJj2kYEm/D72d2xJwoxSf56o1+xRpCLkAUmwb9z6fzWsb2fE+cPTdLyixvVYBIEkYSxAmRGRXzn+/GljyydAeIf5bjAU57EwpBdJ3mu/NEYje3jEmW53V0eBrF/LBNHw2fEU38HjfbRht/d/eZVkpvzcXcK829W9k5Zxua4tyQhJCD9/BhNsVtqRc67Opwqwq00eR7qdeD4ht75z8EgKhdgXvPYi3vR4LQkIAqWefaDDeUKIdTIIGEOckkSmHBXnthVPJV+MOeOO5wp+aTWkFchJhnHuihMMe6rJrNVMgH/PBplDepTz/96K9ZOq8znOHvX7Luy/eb4kTQLYeR3QbOj8hf2/Dv6OPQHllfjTa/C6JsJlrxA73YfjkzwNSLjekhL+xV36orJKvX8HT+s8opmDVDEulhdDjzqm9TbMt998AUrkAAjrKwinTJDMQ4aviiTA44GkGP5wWk7UXbByYvy8CEroUPBQKdgxboUR/MJsPUKWL4uEt5ICb12fL8LvZDYCIx0E4Dyjn7zLa7Qvjn09+H3TDfc1RtTDYCk1fGLQ+AcO6bLRIdkgqzW2ZfqB6NaQgdMqttXAvYsQGQOwTkhYqRtX9OVj62ke/AFc+0Ont5QbP5ekAeBRvRJisNLPi78xhWW01cpsGCKg3JBCu4Uw5Ubb6I0NRCb4iRywCjAjSwzwRQHpWvVQvVHIG8DyuT6ZuS8M5gecIZAKM9UbtbKdxB+JwEXn5stSPNj1KW8E7dmyACh1lYy6vH1B9XfhuM+Eh1DDsLJvsJMcOBpxLdmaiH6zQv5IqkFqmCIlEiZorw9oos+rscHw8+3Wi/S0/r22r0nSb9qJ5F/DZBW4fa/CjHHFLO7q+GgYRA1wZUJDpF66QDoRAHzIKXT2kFSBMgefiABmKCBTB62NPGHByGg5JX0Bfm5hUubbsCyk08dEhgy12H/UCXqdp5DMhs+cneSPgHlhyY+dhD8U6TZxJNPyQhlHkGsixqO1ZDFUv1w3riJXeQRmbvCy8bVKHKIOLP9tGrImZvnKa+sMVPYE2QJ++7wDlQGKNPKxgR5EMhkyQayIGaWb/wBYWqTEw8THK7EkyhimrpTWNY6kSw1ZY4Ro86aB7jT//TPYaRlROC0EEzrgBTYYsuVQdeuhlVUCsC/+FWrW3SDFyAe2BP8bkKlTSbkmmVcXoHrr85l/Pw4OwGWxQmi2DnHpzAMMOQVjAtQF4OA7DbsVXYnYtWXN4WS9sCXfSS+MpTZrucWIG8nh5+TGN6sZV1tBI2vBl7mKKuYDNmtE2DZb+FOy5ZJ8ObGK1WPYXgK62l4FAHhIhlEHxx+ye3Wum+z2H+voMmhMLIgati5hHa1xpfsf74UUiLzcE7yVGbiLIhffIyVe47G4QxWXKoFW+QEZmksCCMy+TLy4AYYQxgCBWlSkDka2CGPICBNCwXrqWdw/ck18mctjusqhp/qOssAmgj1y4QI0CnvgHqzaDh2nVSBXcKoPzfaB3f05k63jr/Oi0r6SmKqF6bh9JrnJFJGXj3IbrGqQ9NZB4fbcO/mCihvnI3dR9ekTYxWW9FgpguVrVLCGmjzSmSI0EnhIlDkCPMAnoxJrFrU2hA7G92IDaJrYYhN4tV0IwnLYBwLX/0dqy1fF7NF0I9NcDdk2xgPpqvV+d1uJgqoD1SsFlfKjs7IHyK16rd7otB49R6LEkbhJFlipG0qhizHNb3Jx895AWM1fo0UDJ2rh74CHGU61FsM+mnb4bVyKsLrAD7CaoJCzq/egSa+gOaFDbIrWsWWgkPH5QV6B4ygdBOCC1IyaM6AY605hVZU2HmY/JVdac4Ah5SwVhR26ug9uxZqiRlFcQWWODQsjuI+DL6gHFq0b9wNh+xw0ygWZkB/9WClwAQb2OxlkzhYl9mihUdGtyyC5mIsIJJ9tWZvB0YJIR3f9z7mI/+g5rUMxT92fJicHu6ODcNMPyyE8OAoodbmL+fwanYCssW86sFUb9hSKL33V8ykQc4i2yCOLEZ5EllrCNMsn2biClB0saexcgzc8NT1VaMeVT5BTmI5AvTczWq1qQLrfgHKdO6fkQ95HA2HbSXFM0qX1prMswmUHAecR4agtbCa0cZvCXmlS3rmJ27BL5fZ+ALtP6pgTz9MHsuOJYE1U+/Z35clfkUvDNg1k3E0n/CvbjDX4cutHKR3wTL5wjf5kh/gl6ikOn4cYvjVTBXpmkmF3Gc9MJG/fWR7h6OnqGh7hXO7Iq6dUCDIL/SNDJvALBw8+f3spKp0Mv2gIFZPW3z7U0cqs8TuXRtG2U1yOvgF/+fm+j5mh6BsWFDIeuXUmPhL5hEcsqdYH4LEfpvQqgy3VNpVBn1Id9jGVg8naSzxTgLGRPi22KsQ/yGmwAkGokZ+tpfzZEY9Ynvrfro1BKHqR7ODXLjq7LDrtK+Viybyx7NgazhZMTsouKZ/6i4TXtfRX03pOmGdbbk02ZxQ/ZQY5VfgrgPS/ZtYw8crP2CxKNlzBXVp6Cb89rbSKgBODHAQPrKAEOaC741pr6SiMh7Sd6TiRHJDRBFY3vekz/kMBl+iroTPm0bOi7petVc/8fTaFHjSM/1xV2CgyulHATNgKtoboQAqdqQVotEOTN7Q8MCF0phZmq8f+BOERMF7zAdF1zT9XHDrFtDiD4rygGjuf6e3BxypA7+D2vqKsIfk+0i0NGRCHF34rwyety8DlWgmVpLJXN0rw32EUxaP/uY/HgsuckrbbvTvbEUL4nneibHP+5Rj5GEJZGNJLjYCe522KtN63sg9VQDMKAUaNxRu9FK42354RrJtOWB7CQvHtDPaa9rGMkSIqPZJS6AmRDlOb3oSyzlwsfvlPlXyvxfFNTOfycS3P3yhjYu3swpwat0b+EUwHoTCDRyAQVc6CNYqUjgy7gMNvFVD0YyekV8Mz0ddvB34Z416NHC+KF+RfDy2J8XTr0Wn7uHxzv7qXv4D2Wyooa+5r8H3/BzK0cCxiXf2S+tsf4QO7VP7w7wFix0xO2He2tQVLkxEZWt108n7SCjlp61PHkXU3l4LKEpteSgORKjhHNM5s1cFiJvB9ZP9PPFR2xgqAmqIhRS4ZpHp+fpMMw+xMjoRsOEXuazLECkw5tpxOjNDOgEO/eQWekxQ1Bdli2BLTsy3iuPbZjeDV1BeMI8SIog09e04qwBwC1tYv3cZoxq/QDPJPA1jLuGvmqRjRrbIkcklL2ANrfOqmc9grLsR29J4jh5ZpYzBm1K8h8FKHArEaL7ReE7P7VcOC6jdYlKBdbBj7MnZjTyYo4H/P3PaGMt6NuQOueTmkdQhNrtvwPJVHtNr02hlbtfkPdlCxOWmXbLvM3n3U3wmzGW6MgJ6rZdqDo7LRkV6cPFtfb+l1CW8rzzpw294mOUuGXxzd0FC45/pS1m/2V70axLyRV5UzjBxZylEi0bkXAFOjK3NH9Rb4qgeYVNCvV9mHOPCSm2Uat/zTFP+/uisjPeHfc+Gz9nal55wLnXdjxeneGO8ityHdY82drws41wVEXDpMqXJ7aRFFQcdiuSZdH3YzEkY8S7i7A5IO+w+Efwq83xjP17wcHFitZ6Duhxr4ggj4HhXnnM6X0OUNy1M+ZTyrp1ZshuEXcpq3dex+lZ9V2mn7Iy2kC6tiZo58RHCT7WWkONzeR/XW/CwhcCG9OIvzqxpJk0qK0r4CDv6Gz+wZWlkMCP0nrk4s+SwndcFr2YbfBRZgKwZEWJrcsAqvCCEWLjDnVVXlhWntibosdIVa44RYu/3d7d+WVkvb/a+vrCZ4FgbfQun7ekgaP8z9MLGI9y+Xm3dFmfO0GZPX8D66xqMRgu+8/XbFPMRm3Y+b+T5SDbuA4zkEwasSNhusQDfOj6y7Sbk3E52aYFHXuhByRZA6EsEGfZagjo7oAo9kvet7/0Dxs5Z/XGFsdSTJn4RKJ5rld7ADtRMi/a30shiuEzZx07+lGLOcpoxaM0kPM52vWkVBlVDEMp9xA9hGbGEIOkQ3CSyDhAfhbeCYi+LNUPmON2SQeH/tER3q2GGJ+vtfKMoP6JWsqcbCxa6KwCP2v9p5x/2S64152gCboWiH9aF07Chvpz9I74id7A3UVe9mp1dlQ8NcRAk2Lhb4/wUDUhzPqKu9MsbZJkAk5sEWRlc3QOmx/UEyX+FdwLohXUozM7hMK9zmJeyrQiElzSDcPMMt8UeRsm1ghbIM+AQSfaMjdqncYxtXme2grpYGMVnFSuwTCctYQRIOjIRSVbBc5uGqZWE/4FxZHOG35ieTccyZVJBIpeZWXiC7U11kIUSbmgMkEZIGvHrWeEn/0vdZ1WJC1C/wjXq/bQRdUGg/uknyIFzXX1MQ7SCK0lalDiCfylgNH/Z8y3rkrVTO8QiLr7ioxVuy15A1dSDsYJbZjIt+BKydyF4Gh+xHSp7flMiwphZ3jaVPL8G+bdAVKp+QNj9LJE5p4Tc9puCHrVRBuJFLnmEORjjkMHFk3dCPNqNM3jjudHwyHS9MY5UfqQG6ya69lhF0n6SNz34U8J3wc3iXksu8gZPnHvBZG8z8voD3xontSGPB0J5J1LMD6NzgbYlS4VYAmXthcV+BPIrt5v4FF3HFkCodtFdwFOUIPu5f1iq/QZ/POhkRUBJj/ABSsuPnQvC/HBNGaHtnGwXsLQgYoLVGVJ2IJ1aDEkpRToOnLPaYbNng6vCmDLE7LHeS68XWIQHFU8lg6ZkCZfBt9CqrvkChpI7n7GN+JpyATS/YolRU73lcztuDYWSi5OF+1X4Xe0AkgfDjl9tdbT14sb8hrN8l3eVODGBw3y5eWsZSOvBuRRhZ/fSUbEUqjOaVzeHY05v8L0gJ4QdXaJb7QEf9kpXVLX9EMhsqfaUPP+JEhrE3CgVn9kiuX1phZJi8u8PyAIM+BRTETrEjrWkZgFDNll+sb7SuGe0UFZ24rHVEQ5pVjqJ0cRGK44BtL6K068u4sZkg68z7hLuiP2KeaBG7keWBMR/J448r7+F6LF3W8vsymj7kHBdI3aLv/UUWxwIsszs2tT4caKcEHNeUcNFuSgcqGUeohREvNJK8+7HB/2bmjidZ+gYqNpDM45Gdi6rWaxUmm1vuNzRIHKp4ta9m/+ZHoupA8uwgL5Z5yBvsWWhNOb+FWnlttcbZbaHI0xr3WXpW42ZU0LMMUSqWkkr12iu0B+Ijyqgs44cB4wTaRqE2K1Vtk4tf+977dmnBpAYYC+BCsYBxJHn/5lVlZhDyl/S5Yz6DVhNNdj2ml2xpu/2LI+/qGO649tCCkSzLDL04G8upK3KU9zt08cgeGeOVYpHhZqsnU7Lpz4GSHpitPRakDusqWwjVyTOyLAn6ZGv2LtvN19gWLiaTlw7Yc0hkHHXIeY6K241IzirHcIxJ8gkEmujkwYb02I6W027yAcEKph2BHdX4bFtQSHwU491jHN9x5WhMgpOOqS0SUWM9gGPuU+Elwgpu9PpAFc7/x1NL77sL0rU2jKNN1M7fzpa7syZDf9dyQXtiV1PlKZ1y6KusbxzxWhnLR4Gt89O8cab0JrW6CjCNkhIdDka51IXB7p4XqRXXb/nQh7LrDbfc6YdpPK0nlsbh7RendPQX4fAIuBkz1KaA12lwj/PyS0Ct5h733ZmYHd5Z3FcdcBabu63oZ3pHKXuG35XgZCy6IBzbtrcvJkaeInvcJCAEspY4mkuQuC73Z6J3Vvzcs2qvyAX67eF0211as1lgbu8mnYhzckBCy3xD7+Pp4KjAHbVe77uLxktSKVz1+baPq+9XogyCs0JBx11vbNah3gT4tqDVd1WMVHQjhDRAdYZhaDwCqjX0TOYEmLkdBJFkOv1ed6SkMi0/LArFOsoRkZSx8/KPobRa5EEnfqFDudRxO0LmotGtWwNt5xqtCbN9PPzU79IR/XEcVxYZ/hDGJnsebO5cEGp8pNsJWkKYuIp8SBi0AT3FjSTstcGanSq19FnmGTv/y01xXBSuJYSg85huO/fAzI1uraQH7usxDkf++KLNaKobWu7ikxhCRB+UWSQ/o1vOXvVWFsg0Wbirorr2SgPoALzRsU50e1Ts/xLhPaBmNmi+Kx+lgUf3q89CpUHbf7R4fM9yrYBRpRRlJx1t1dIpm82C1nfgajoN8jnun24PGr0riFgjTmRi8USxxHbhCJPsJWZPRuFT/yIsHFKSRienXfxqDIeme+61DE/dbZWn2QIaAGagVcQWof+gERgkoJq5clA5q03i5dH30hrg5Lt+wnZ/zIh1uzDzrpHmgs5YJhP7JP50tQuH4VFLDnExqaogvZ7VcWTSMd52I2Q2IKX9fReZYIgXQryQX1SGuMUq0tweCPgIlIj9xtgwzvHci13/BuJZQ3sDDANTg9q8AwunAQ9PZ4EcTYi3AxIbzpWE11fhaWAriP/cuPcywfAqRWEnlhk8OlZKGaQaWBD+BcB49mZYodwIsEV1hIbYiTuieIu2WKolny14AxXbMfzBVpKVEkunQXZj2CWrsM8H79iLhjCPg/S8CUVcEYDu99T6O+emWqVwZ7thEzEWqVddFVuJvEX2h2LL/D48oZc1x7ZgKiOxteUfWNZ6s+0UXkX/tzfdnqZiP9zMoJbnWfWVUFqNzt4bVueTN0oQs+9yfuAJqmg3yCKWnUrTm0iiLvbRZjRdUtpBo4HJ0VzMJffXcWwws974Bs96422aRszTahMGMe6NxPG00nvrTwps1ULN5vnYrApUODJ3qTinaXsJoeLVVChdMhL4sULPtfm1LQ/vR/pwCHxwXeYfTaiYzvuTRDgGwflyxKmpqX3QZfjd6b36cATeL3WXUYcyC2QYI/ztJv9cc/D+ec8vJCAj8THG6yi5G5OvNVOZOQtivQDgfeUCrZ2cQdBUhhXLIsLFOnBXIJuIwN/yEuynyLbQYeq8kIllWTZ0zL3ubkF5xdRGnlHytUB6Q+R8EUDYhdkptZxK0yQYwwovyKQeTF5SvzDuymIEcr4EeepImz+TP8ysDd/ZiIZv9qS3mhfcjHdETohgaX5GQJWO35OSdq9YGCKsSiG71kAEBGiEg8PRI3hkPlfmjYM0QvGNXDLoLYp1lEl33wiZ8QdRUR94DZyX1JPwoTwDdsXIYhAgKrJRQ10/YQinYkjg465hUvbEuYojT7SQiv7p+DWogPQMuTiEl2XMt1hfM8HTUGUo+Um5byiy0Z2oY4VMofbo1y10WUsY7WHH/HNxVgSXR+0XMv2lx7b/jsBsCJX+S/NMoeQ8/sMxwFEy2Ef+ThqcByo/AhJt+inyrFBUhZEHMnvcLT8nuooCXR5VqCDT78E98jLGCn6/AgeGOkngWyhstbp4glB8+/mVBYIzAG0hxNZvdyqF8kfeyJf4x6Xgn3BuSqxG4Ur0m7Q9BE5yUEmr9WDy5cCSMsQqLd7d4hDAiLMhOMUdYkEQCn/bQnvs3YHiKft5z/E+67QYHl03MxAMuDyN2UkRiK2dEPSxgTnidJ5+TrrXdmVIFnb3L9vd25A2WEEV1CUJ02SVgfkabskAwbqZk0jG7WBSUDKI9UQ6d0DWmLdWAqmqV1N/l4B+TXoKaNtjpHQ5EJhTkxTvG0PvgBPwEznnLqI88+JSyxZZLE/2W4eGW+afh1ST2bsRgOx8mXrhiWPC8A8tl0ieUllL/79Q1xoMUbmliMHNAyPgi3frGkseAIaTlEE5OlNWoHMGqwXzDOjSi4BsvZN1aqRtbt8nRST4EpI7JYMle3HvqXDXsWbd/YuVPt5Ppui/sQVNwEDdrAIDX6kAPOLjgDjY9XfDS7WinuIk9AL8edupPszapdXOjpZNQykiF46Wxt47JleealbR4vIoSBsobvW7wyAXot/G915+oNLwF9gqcNJ1uo+k0ZPko9yeKWaop4JPVeBBP+pU2NylhQd49m0SGmWJuhN21QeoGN2EEZxrkrYZ4n0lwfNYoFqyxVWIct3mW2WdxOGZdKvk0p5jgbD+uWsGMEdVKAnDZbUZer6hLPEL0vMQuKmRBIA2RoAo0ZsT7ymJgP0ruuUb9m+8cs7RZD7s4gfEQQGhEdY05mcwoC3CBY5ui9b1rAganwqGx08JeuwuzD1hyNZkrXYwY/IZvsLaHXzstnZX19emIYvMVd5p7EahmgCGVv6w5nIjJSSBp6nwv6wuT3zz6EddyKDtRd69jcmvtdtla2ry/TtYBdvhcZoQSasrgT3T28DBYiC+Irfet6sEjQMzMdKGF5lTzDBRCIaWxGHL0WYzrNBtxXujBJ7WKrZlS+kuNQjpAg9z6FrHVk2ldn6D+V4m8Ks60b+SOTs4rlAxG6crDmM9OQ1AUgtBu3udZb0vgDujQ0QUh4WoJf9pe0xfvwNTkRSx67TRWXfGmg1QyPu5NBjDzs3CLqk6T9MC0qHO+VPA8cAg3zbiiExfCydjGv8SINqHhgynHZZjcTgyuNiKhMI/pBfUbTO6VJpm3yj4XEHfLse+VDNYX6UqdYPyDeY++zxwqBdd5K4WrzAwLqiYlqqVVae9kY16LGlPp+GeddFSyHEOwBo+/gB9OQKoWui/kZ6lemZftV8Hltv2B9+/SdzgBhZ+azhMX5M89t45JKOl7p+/wOOKl5vY9Fc9XAx6hjQ0UnM2qu+uAiVJeYdRQPcU6xZ7DLjZOHA8oyAqfkMD2KsuFzTqbLDZZX70hCcVbObS1jwZLZpx9A3rO5covZYSU2D4RqKq0wyowD1BRm4JL9mV4vj9+5pp4G5LGieUolZEvx+RojVLAhiMRcqz39cG4wz2g2xbjazQhZB9eskdbqQdtEhyPMUpLcFdT/trahKb1glb8NTddwuy+Zt3ei//X6nfXrScaZiIKDh7qhnaHmOmZ2uTYDqmx7cs+AyRpDo91k5+FZRtEpmtlSMoD2LlAX/D4ET5Y73lypjs2syx2qO1vzWRUSVm9HJ9z7Vk8bUPrsufFMZWjDK87TZNvKihyt63aAYEUjT3WrIrAAyWE3iAOfviJec0iTA06ppMF3tW+oFc67ATOpM8N9Z9bQ+abA9ww+/9xmhU8FWkQ/5WqxjKU4iUphAKuErz//TgU/IJMqWQu+3j3pmMmBKcXfBiSEmq+maVecVGKaH4hnSTMS8JSbqpTPgmpnxN9HcUc2gjjSdUQZbHNyZEfgDyYc/Pm5mgrcxyOQzSG/GlO34sdx3ohYg78bOs+tzEDdwMTA00PYuj8LduT6IH6uKXgJA01yy3xPUmXmz62mu++SsvQSmLMuPPTtjH+AapjhdICVQJYdHaXxZ683wHE54MibH9M7nBQPWusyRxFwZgKXMM5JNB8TIuHIJnJgn0ybnoBL3sSBsnOzp+3W9C3/LfVLIWp0hTkSfeVnsi0R4PUpm7Mk0zKG4/dgQ85D5MBubbQ7duDVuM2cKFgBQLmuFQfqTKoRt3aK0A0R0rvsDL5Jx+eT/a+AthpWMQs6NhRMTtGqcSNGJ6nvhh9w0nYLVY7vF0bl0etyxuC2bg1qgB7Tm6jvDs7DWe0EcFCkNuO2MAb+JwEkyAXpk8mQnzFBM3z5mCYPj0txqtZ3VKHmmA7Q18mShB1/bdr+EQrpYAwh2JMKu1WKrqeV0f7OsCxXvbDIZpv3YvOysGQSr9IzlKGpUI0pFKyusYa78/50Hy4iPhg0vhC0Q0me12C02gQdS6bLNJ5wkN2evgFI4OlTCY0OfKUJBJIaY+IwtsZ6KuYTUXQmez+u1v+TFGnT055b0yQH6XAA6+cCg1gbkq4OsVZfo95ZW7fBH7o7XEzd2SmRT9cc90ZL/Kx2QtOnqARtRQZDAjbZxxTLudEy3wq6MFA0OVpFhsCYfg+BsDjEKpKLowfUeJTYhuuUiTofA8QSU+FLJlHZ+KImtHsjaRbXP3Bf5f99BtY0ncBtVLj0zLR0f0Yc88koLlXPBm9MJJu6uEC1pkHa8PAgHzHjERFj+xaDoWEsG48VKImxKj4COdUggRwbz59lKQrhnqlh06vJMVf3dZJWs3TX/aCr8q5uL8JWZqV5U+qQIuBC4CVG5b1IxIWI21UHn8RLIi2Uo032m7nJpR0hsAcbV69Yy4ANuDvt1SsTZ6r1dnQxdTFWie0BQwC8Jh82DOjowBLaOAp5Clr0DV7TisUjMcuGMdHVyonNtzQ2B1LcGg5Vn67ULI+BYstW2VilRBB7PofLtE/eWjQfKMxYhTrxlq+qJnmNPD3rCzmLWl1I9QhzGwMxnPs9XerSiucOBHjSCYNZrZbbUy2x1YQjJWfPmThw5Jywi+4EWtQY7uhO1Jb8504lhEJA1NE6vDbSiyO0kDRRODMGSgpMJ9VGwYfNE02CfPZKDdISXw862PqK/vnP70zda0Z/pq0zgOX+9h1z6Tlaj7OswKXmUk7rf69usf+X9UqYAQcDCavF51lZoCZlNfrDWbG0ou54iI+Rf2dTUeNMKzdW+ZLJekVkaJTzHtCQ3aaM5kW3/malaH51k1W4xAG3vq31Oil9HxQH7JlzBzlVD0ee12rvPcefpmOFR9Iz5AH4JPafyS7Cn9ycz1P6b0SXWQU4cRBw+sq/1rCy2cBE8Mh2aqTWKv2wHHcYKkFSZvKhNPg3/i+8Z9dl9+4SBOhxILTRYaM9FmKZR6G+A/jgPAFafzik6+nkGnzzk9nACmI8I7mro3t1KcXGhe9vANR2JO4abK8jS4GjslWdB2MXv1eP7bekQQgrb0neXtdId17B+j52/Uq/LYtUalbxaAGQgghuwHZMnmvs9tL3z0wgN4q4F9mukOg+P3ejDe03nHffo8q0DLgpWyzgmQctHzSMQHTir386H5Oh+AghzGVKrsZF4xjnoiKXLLdlXNDrheN1bzePHkIFq6rUq84UBqnQFXC99gdvMSXSBqumCFB8pSveUPozFIxK0DLEEj7RfKMmyvBRfMtiLEwO/c95BYDkzp/X1BlNTAYMrRyLO0l5bqvOQJ2T3xBoiL1xpGqYHpmQHALXLZThDWss0sgxdcdNJR3uQiCbqFQVjoOQHuXWobHGIrjvlTJkPAL0gmzuCfcQnC6BAjyYc3ahhKPGazA5igx10gS17ri7vUrugF8G5ydknaTVKf29XEa6UKJdhUNAvzLkuD4gsczaV6bRv9EF0gIUFEdrqgTyy/6B8SfMs7lMd5eLz4YGIFxBUJBdRPWXDavcwkOST8mZRy4Ve7Jve9BReePZKIU0J9iHu+72QeROGQ1mFRBJuUXRQ2P0l/By4YsbrfXmrMV+/W03e0veE8il5LSijdjCcAyrmJLP/lUf/QqBdvAcNcu/XcAEHmpdJbIeFSEobVh3ZV51xqZ+mtzr10Q34giIBV5vSPNqMHYmNQGhlGMhjyoQqHOJ2U6AE1swUTSQ0gjRK3md9Qbv22B0XEUT0SiZDYB8OkJpClMDPi9l32v3x25DChfC1NviIS/vLY1FFjn8A8fTxrqg6w4Bvi2Q+I49mu8j6LIagdRA4A3eb/zhp54OPMLr/Ux2eZ0ocYTOQQSu9gpPWoZoHEfHHc9RutzXSqCPVIrFHkh61BnTZ+LHIcWfz/B7mlA1E/V5TLhIadgpDqZzwnuyALeY3FaYcoNhQ/GZodBrOfun9Iap1KkwYsQAJfa6z9TFAAflHXKEko5DnhfNXqVxVMby6GjJiSrqXgwgoAuHYM9AIFUE2G7NtaAoN+H3VMPKjVGVMPrtZ7uREVeXMZdZok+6MOjYeTsuApOtt3Ig3VSCzeFH+IewY4ZLv3q9J/KvDoTGgUBMTIOOYZsdJP5wwrmp7RaJtcUaN+cOJrLIJzOcBR1kRO10XqVavtv9+M/2LkiWGLegJP8q0EgThbPbyqUE1N202J+A3R6B7Fbsi84XIa4ZqjW+aN+HSi0spOCDS8OnJzeruzlopICpjMIekIGybDKRF55z7LTcrXaaOkmbm1v+aPkoDLzHGDpjnjhcHbHteYP5lg+S9DRp82icqcyGdq8NjtY0dvw51m1QlQx5thNkZCC9FCqBf6XiR2LiZ9/jU6csy6VHng/1jNEhFNN52cNx8fqVF/v2yeUs7sz6/t2fpr4QiyDkDVXL0VBFQ6gkIcChzQs0WskV9X4kXyY2Lz0kblS/gpoNKEWnBMnFHZcA08re56k6DrfMWm3V9ZsEDUjaRUFjyZURJyhZNvMIxVB8tLqLH2hYPrWq9HJQZ6yRXzNQsUA+RZ2zZHnUyZYaG2a2bVHRQbsKcNSGegDzxrOxRzilAgVdPkydXpsNICgb1eI+MNHCkZQ+rLT6kZ91vF6qKufBruWmu51EdGX6Ae7oY4RbYaSm83qtmdphCdrqsRN1g8yBy9dOUPDKe4FlgL7fOZj9x4Xf6NRlMQ1DX64g/z74fbXmnMkpDRVip+y9XGpGDYEKJHSQAcfE6F+2U16dzU991I3TIbH1I3acoNesaI69x9uG4wT08bA0eposcNz9DFg3aGrhOrA5caXB4aSqk6kfW4k4JWnHeWDLWgLQN7BGBaXur+ZHtms+Z5r2zasSH50Wwlz8HcQiHeZDg38LmFY9o1PUEapePIEObCsb8iX7RBsW0KI1bJ5nCofqDftX0//NN8+5Emm782xhsXogQJ2XB0er4iriEEjtODFBGiGHebt348NYjvuWjZ1VR5Nq5ia/7l5EL9i3EaA5yTRV6S2tgfHUltivYgXNJOGlsJeMkCT9ZU55P9Sp3DyHym6+J4CqsbPdV7q+yljMYbSHPIi+oAXSQNcddVT7cb4I42bP9u5S0zi5XiB/sUuMJHtYxFBYNUOEZIAL5GTMv3vsVHtGJl6PwPwgAXnp0WT2Pg+qRc3ftncWUJsiNxuW+UZokXQQpI1p/AzJcYvS9xliLfRApOSq6Ym9PRSbbCXRU7vcWhFi7VD6QKZL28II5ta5pO2ibP5q47XVLxWNvC1p/xLglXvV+nsJ/qSoVv/Iksgwxgmi5Li+aIE5ecb4MBrjzpOQtkK3ZN0w1IB/weQVQDq9vcYaZJhcpr0cUg2IaVvzjeFayPTm7QO8Zyac7qP6U+DKQuqkIH+QJzByrk/AqSYE1Hv54nmYOK+MENSigBVU/UVEyWjISF+ef4G6lnOlL8AZ9CT4xO9GycFSFflnGDi5eAD0LgDNeKC0hd7yVvWFE2NXLlEjVDoIZpLNWHJnz+zRSloD8eC4g8vsFVzjDpFfFo8FZQdC3FX4bXMsD86rVS8H2/ffSLpMiGBML8wjqLMnMRT8lVzJJt79c2QD7rKL4+9Hgh9ilCrQRKi2e7lBO+Gg4myQ99OoFkuqVqHQcy4WCzF5vwkVkGPBDqQKOGWCHgWnr28QAsdbop3oFDiMu9JSCIwHiSO/IOX0YnCxxRzNTbvMxn28eCFLugKitByw0krZaYSocz2oSU8r1jpf5MGTCtpKE9bJih3d6YaU6btGtMUVIcaeqR8F0h0kopgGwzuUJja912qLcin+RaOwtEcselcHTf9Z43P+AeEbR82gixJeyPvd89BIpRF3TCRC/ymrDGaeYS8vfXBXSfj7NBPWA7KtKMM5K5IYpf8jafb3XMxY/BiJtvvbmD5zACMF6FJmIOeH3k6cJxgSVxjqnEs8X5uJewJC5uZqVlWGOS8coq0cYnld0ri2NvDNnhrDuFk2+qLA5riPLrXiCix5cSOBKGfRDjpi7FFdMMcEWRwW0j7Bmnjf6Hs8niQ6y1aMa/klAh96veZ/7BmAYuAJ2QMpu7XiIysrO0GBllDFNNom77ouNstbpAemb6wNmbSmvgVE8jJrlfo2G6050N+vuzA+wTnBfIgIMpGkbpHrSJS6eGLJXVToVzbcKYjOJuH7iiFkaTmUR/0ryCiyci36qwz82qJ2MmPFw2JcTsf/e0dySnTnMzD6FYf4p2T1n4YqGtP5eh8zeonrW98b8Gmf2yzS1gP/IraG3dP815IKuOhzMjayVS3Pq175rMtgmFy3u5zJxpoqUWEOc6o9O0Y3gjq84ZPbNE/QmBMoP43iJItwsf/jXBattxRXCll2idVRCiADqRnj6Iotph4p1spulwBuamEjKo51AYJFjaP8uNJlPFU15I/YxLu5+GIyMKjI8LOMYJ9FGHIpLJMbpOadtrivGC1tGrsTyBPIf1xr4ZvaR0/ztmLVOKjK/M+vwMukPjFeEhMTggwPy0n1IIfd1o3O3L0wtdaOHC2ThHtyHCTFGdGXY3Wnt4oZFCzA1zfDOdtfQyaJR9xWGN7QfH4tiXdIdvugD33VFHBs/P9PNVub4bMmCavoxJYcqb7Cc3tfRqTQ9XprEe2O6l7YmV3K3OY8YSv0snIc2vdTia475hOPsXJg3Z5eKbJPxegC67ndjoHJnsTyJXpMGkbzFBYGfDMqoiWMv/sxqS/FQ22bs4GMC42/VF3sr+zskYuCeGVBZSGZB+q0Ww5vhsSSgx+D9Es4z/TJaMXCPm7yOxqfb9VdkKAAhBmj5ae6VN1qh7ghyrvUZ2B2M8/Dq/WJLzhCiw+FI//4AsPlzoAKZGro8d20ZEZIYfdpkXm7Qw9OveS1oqx/Q38oP7RQdmQT3IEWmcTz2ThwlDJ7/1b3oxFV+Dkbhv/SmJIzCzFUVccMH1gaSGxQzRpj6FT3Rb43QJAvC9QwDkbjIooEmkubX3P76ZCNj1BEsCEhmkdZtrRYd1F/REy2KQze0de6Gqs+cSHOshsemAygztUm5pDRHVaBwMmIZ+utcmIJ3+nY2QjTt1WQFY+YM3VRVa90U6I0l5+z6XAUDXqQFZJ6O/gTM5CsrQMKlIrIA7eQ41Jf7zMvtj/7HU/K+UKigVFiGCyu+VUbuBHnFWlvctidgSWJs+BQx1mROw01VBYZHCZPBt6gc1BGIv5Gv/nB+HH6AuKegfZHOGIRRKAFUItQJnNsvGF7SpgHgj+RTslImVONS4SLNIvf/wqgFYxQfqzdDFV3tw0WTxntprUQnZWGTFKTTdvSATplQ7fuaNd0bdLH9P62wXp3y/g74Y6nftS754zO9SJoHcIuPnylEOiS+oSVODs7t5/Zf+J/WuybUYnbSrfC8DTD1EddFZELnY/eJGtkn4HMxW1xz1arUysFNbFM3cCZ6SlKZr3YCY2xTKUwIwQuWGD+gJXntjHknKtSIfacZ1IhvdZnINKzXzhhZbPuCxaOwA34pw4PWK+NJQ/f35IhzaCrnZ9TUov3MNyVRzbZkzQMxLQM/vNGqkW0Sw7vtCRNvLe6GtgzGQmYQM0pDUiquqV2KRMtfUNfgc7JFaq5r3Xtze5poQSiM89SV4GT/xYT94rGxvwrhjT+9JV4Fn6gE1ND6Tyo209WqAnmkH+G8y9Xd28Eqke1SB/oq9CPScW//ig2uEw2jvIqnSHy1OVjPgKaTD2M7s3BG1pwK50hqesSNWghVo4nSWgaKdAT1Am3KWxUVnzIfNgrlEvbcWWsbcH1sPmzTnUK5XvwphZ24ZW81ZVQnO2q2hndBdas+LiActDBa7lYgUbIJxoIXixk3lsqCQOR4qNRNFT9wF6M6Jy76pl/BSpD0CQctTkk0IZVIWuyvhn07hn+qVwGD4Ra30EOmoGXp4cojmzTGT+5nqDXkV7xRUiaxLUxtWGJzKTGH6t2cqul3qeodVActDEgN9AKpZgqaiD8V4Cre76iUQaBpRkm/nc5FcsTOHP//z4h9asnFv0anO2NZ5cQKBjV5yx36uVlcQPlYnf+Wk/qVmyW121gTMR436qr2wMqKnWSnuvZsWJ9s8SPT4+9HZqtQQS0pjmY4gXNUW38EBG5bvgJXFU7hVG2/wRHWizhhvU7f/JQ+cTk83YH6uFQwHMBy8SsZsdyN8Shezzw6XQRV75YmxxzRsiw4ZZ6y4lW8bLXVzjrr/1LvSMiFsWI/oUl7mecobH6gnyJM+z7+K3xP+fTq6j5fA+ywYF14hJbwhAYKxwKUbrBtUDYYW6AQV4wdNwW8uZKskfRjCE4A2q2XQO/TOW+eaTQU9bSYJm31JreGFTnKCqlwuMUcaNK3Xg+Ph7YCy8WPKTWq2LqXtVggEEWVfm1EQ7/26z4/238mcEry/0Cc1BGIDrLod6kaSaBihHf0gzoecbGCz4RhUFaLWo02W+ejSREH+Tmn6Gk+Y2po5mxBPrhRJaMRNrvUN7KLFjl3fWElFsq+cnyoX/+COxR2YkjcwtqPGubJY08aadwxeSEVQcRsFQs46xlRyEZG0xCnNRuAMSdu/q7cwuSg1FIHjZgwEqVuk3DYBRKkBEaYzoMdzHzmL15hXZk4p1JCvXF1l6UdB+WTI1RLFqavcv/UAf4JoVgawZbWtjLrdGYXSvXSTqPCJuJieeVep7/ShUi0qT13QZ0rBlbj3c10KZvELN6MGZyJwjFPkIJ4ncuWwKT8EoGbS6BPXYXgjfiegUMImbPsZpw/obJogC+FO+E07+FefBozpDLE2TTuRzZC8elli5ioKwD66fOtdfT3ILkOY9P9siymOGj178GWfHgumeIFxrjEsaX4gTRPBPWkWD7ZlZymxFPBTT0z62sH24IuaVUnw0VHrvJReRpjOBrDOEODVf1X+3XAfoRC8LcNWqWq/VTS78Vs2m62s/dvq3lNK6WKvCcE21OTrXpNYtW7zA/SC2qBaxDR0J1qykJ38rKqe9+2AbLdq2jjbQ4ebkBafa2ZOLeB8sDyqWGhtHWacYMXV/P4U8HtBhxrb8srexsaWXRRqRfQ9LHYlYvWPgyioVjoAyCk/8e/J4ghCNkqTRmCQbqGkXE2M5YEFPBtMjhnSA0rlrlYbj3ZvveoOZa8/DDQJM8QEx7Jp32nV4GPL1pIe4qnKd3Xo0G2BTG9uvwob68NKXLZAEeUpSrQmoQKl5ESpjtP2w9yUPa0WYi5s2gCVQTKYiSGf6aH6AyLDFEV2OazTq4ixVVl9ayBh7J7CZHS7Ts51HHIKguRSOV7xST07kn7R2nSdgebve1eBE2E+4IlaAd1NR/69ukonS8nNZUiYa2cjwyPH8M9WfL3BaTf+EbLVrUyEHgaDAttb9zBfXRndwSMjXii/Zwb2OEvTbAASlFbCrsxIPQQumjuNcxNrpH9waq+I0qGRDXjOHaAzO4E1PZukDh7nFyAOY+KKHjDpEKUhLjVahAzzy5221U2aWB4BJJVieS5f2uZvYgob0BGX4LrCCxZ+4bZpPzaCEWzjFKLovH4MNMm5zbuUSK/aghyQlZT1eIyHSCoBl6+0AaWgVp+jA5bi3wBUjoBajM8ODjKlPmLjr1gQJIcmlXO4wDGT5ZD8yy6olrh9i2UOPjTjevfd+Q7FrbXaTPfjm2xsjR7gLnd/h9q55BhGmfTs8KaJE09t3oKmhUhy0H1waR2zwgjpr+C1+muRZYEMhOQdVwXGpO/42cVQByttY/u6snIUFa7z3ensUHEEE33TDPj6CPc7j7XC14tbFAPguroa+KRRo7O4joQCzjQHYawMupAybN55ek/+RIi09Jjmqcky2WSApriLxBaFHFfzD6qawheorwcTY1I/0zbhzoDHou2wlvek/QAkcKEscxRo5CKt7Vt4qb+uqwO3jysLw7bHxYVjU3niOAn0MMC5U2drDDCsaqS/ypHg3UOUd7RP17BrCX7QGjmQ67RLmVYIQYqMrewJ/W1BftYqV/mHQymMsUh4R1n9zaCJG87XCamFjzUUwecWt9E5UkP5aRDuWNpONsAw5DDT52zExX6Ss/KaF+7GYbEMDF0f/k6ym4kBQwCf5qbh+gTqGV0Ro/sfIP5G41w5MTr0gz8916uqffC5hDHuLVkHqLGhGu8ZWxO919F59Y658ge5fDCQSXQ6q+dw97RcK6psgvmDIY+7QMrNLqfLdyc6BL6a7oOSRTk8InINk6ZvDOiHa4WCewdU0J3Pj6gFPLLccPkg8nIjkj+Od2QCE66uDKGxRM9nVhfeztjmXPYlG949EXA5ZTVsTd5mC0E6ACefMhCHv41nByE40zwh6aKJHje/UNEWbENmVi3bUcC+7dddQwf3ZeUyay8uoIjgHhXT8dotJLbA8knaP9pZ/J1gxCEoAoo8K1wFmE82zDoLTXY9VfGVCl0YkXfEtEPBOtyZsZkXZvDfREj5zvtIsD8Mw6259L5UVqba7v2XPHUbWxBJE3TtvWIQjUGkKc8ZGgA32B/sSxW6PdInIo0J5moG0Gft//KhZJD6srrMsF8n27QDqs3ilsWDvslAJkxJ4EX/fn0MZXGGMfltLN7s0+PP8HClaDY/SEjIK7MnQ7mmdM+p5zqnLkVag6MKMjZkqvMHRqTo7hjxTuH9dhMgYf6xxPT0NES8wDJgaiBsiSfsK/mPBCLxsGcb8vfz8mTbjtqhVBPK2zd3xPHjM+Ejf/VQf1WZn6ZcO+9BpyLH4tlKRGkNRG77Eav26p1PzjSwKzJCzVzkHPLxgwrqlYiWDxqRS0V0gPF0/MKAqySVuUgnlE2qsFWiWjXUUGjOu32C253zjU/dXRDPN7cVraXwq504tA1AOlpIzB0a0HVv2oK9nafkSdV8zjIO4gnia998d64mcyqLLkj3+hxQ99wsLrxunR5380JVqJnLBIw5Im6isWxtxqoRkPd0i3Tn9pMVQGZinuO1k+LYtinKrikGjnOyHKhjeoTrBn0cDx2t1x5y+AWTaMYudJNprVCCRDVaC+WN4ncx/SJBA+ElTcsadRnzkXAfw2P6JkU6Y7LUAiKY6RWSkwUguhgRM2OYNj6ll7vWQ8LAFY4Uxn33hYu11CLnnipK9rZl6h2pup+AGcUNq8Gb0pY6J8rnZT2W+fQAKb53Y+3L5+uSf0MsyENPoGIRgAjONN5eRc1Iy+EE5/XxYf3h0BrzDoPicVri6bHwTF97K9ZSJrXcxiMKNvJjPKkfsk5s8lSB45TYD93gzkihJ83JYGFY24vA6E3yPPJlHO3GaCxYf1lISucb+0CmvjVlG7pK9nZAroaxzT3RhYPUqSPca274gq8/d1G4O1kXrKvKSURhf7KI7QUThvM6M3mNgsDAf3Jtd6On5f2yczp8r0uVIntQtij7eH0KyD/oej4ematfs82n4SnSqiXPL6S2HGZBPb/oj9hzNy5CKd0SEW3Ey2371deF3JHZeMOg01sYUFYIMPM6K8hTvAO5vGEfCJmJZj76flfUjHw/f8aFnxbis45IDsHVVHkEqpditAWlShcoZu3cZe+dMStKqB3xoctz+9rjfHjj76Qkg9NmaXTF4RbKsUxnv2tLUgFaob62g/yb/ODpW+joN0GtT798TMyJVG8kIPOLmMyQEgeEvK6bP8UbF1hP1RWqbKXpi2lasPFn/meuCyRJ5oPqmw60o9Zl596f0fyegC1bM93mULBZ5eydiwtY/occpXdYl19NolEZ9Y+4tch/Rhtp6wmBz3r1eZGJfjNpZZhNdzx3h9upI8MoBRrBsDU/h0nXbUgj39HBT7mXhDQtBiIHRPv+nAK1rpCVAjrLM8YUHpSM3sQ1Ee0bPKAT4Ua7wmvFIsZeZ4g+8QCBe28Ou3q6mpxLSEKtSEIGqZ1LWhK5E9vlWfoUs9qt7j1E+CanZ1/jKKR/O2fIqwbyLc8W6g57idAmF7E8ov4rGnbhbumeqAZbspyvEdTVeN8oLF9HiS8Y25uojZELGf5p9gzgxkfNb7O+qhEHmRul/uKBos6dfwc7EdT5bknThYjSSX7pFPBgdiCTZ9bzpHLeSQXtP+qzDpkx+q61DyX8rkcpUwaLnHppejkKESARY0KrEWjmDhEO87an0nzNAEdZ0MhDzZcBTtnta4/II5aUtjtcH3UIUdOL8eDUCa34IoNCZoKj2cQuSGk9dUoT/0Yl01i1pFAe/6H95x0BXtfIADJ2uMptkAn6hqHVm0FOKTjKc45mQUWBHRqgo6H/r1Dsyupye/kg8ey7RJ4hnh1/qu+J/A/TjBX+luqVdkMktwm2EuMi/dQRufISSHoWeBYT6PCVsimqBTuPZfV6xxfSpdLDy55OoZ1HiyfhBOyzMd0Fy0/USNbidyiIf69s0BXLIAaLSEAVMaIc4FYQ=="

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
