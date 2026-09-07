--// BAAN HUB MULTI-GAME ROUTER
local placeId = game.PlaceId
local universeId = game.GameId

-- [FREE / NO KEY REQUIRED] MyCourt (Sequence Basketball)
if placeId == 116047689628641 or universeId == 10476380360 then
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
-- Karinderya Auto Seat, Serve, Wash & Real-Time Shop Script (Complete Edition)
-- Built with Luna Interface Suite (Patched & Anti-Blur)
-- Features:
--   1. Main Farm: Auto Seat, Auto Serve, Auto Wash Dishes (Hold loop), Server-wide Auto Hit Runaway
--   2. Grocery Farm: Auto Buy Low Stock Ingredients
--   3. Real-Time Shop Tab: Live shop scanning, Auto-Camp target items, Manual Quick Buy, Category filter
--   4. Physics/Flings: safeTeleport with Velocity resetting & safe floor raycasts
--   5. Universal custom draggable floating toggle button

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Session tracking & Active resources
local mySession = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
local scriptRunning = true
local activeConnections = {}
local activeThreads = {}

-- State Flags
local Config = {
    AutoSeat = false,
    AutoServe = false,
    AutoWash = false,
    AutoHitRunaway = false,
    AutoBuyLowGrocery = false,
    BuyMaxGrocery = true,
    LowStockThreshold = 10,
    AutoCampShop = false,
    SelectedShopCategory = "All",
    InstantTeleport = true,
    Delay = 0.4
}

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local CounterRemotes = Remotes and Remotes:WaitForChild("CounterRemotes", 10)
local ShopRemotes = Remotes and Remotes:WaitForChild("ShopRemotes", 10)
local MerchantRemotes = Remotes and Remotes:FindFirstChild("MerchantRemotes")

local GetCounterInfo = CounterRemotes and CounterRemotes:WaitForChild("GetCounterInfo", 10)
local AssignNPC = CounterRemotes and CounterRemotes:WaitForChild("AssignNPC", 10)
local BuyIngredient = ShopRemotes and ShopRemotes:WaitForChild("BuyIngredient", 10)
local GetShopInfo = ShopRemotes and ShopRemotes:WaitForChild("GetShopInfo", 10)
local BuyFurniture = ShopRemotes and ShopRemotes:WaitForChild("BuyFurniture", 10)
local ShopRestocked = ShopRemotes and ShopRemotes:FindFirstChild("ShopRestocked")
local GetMerchantStock = MerchantRemotes and MerchantRemotes:FindFirstChild("GetMerchantStock")
local BuyMerchantItem = MerchantRemotes and MerchantRemotes:FindFirstChild("BuyMerchantItem")

local CustomerRanAwayEvent = Remotes and Remotes:FindFirstChild("CustomerRanAwayEvent")
local HitRunawayEvent = Remotes and Remotes:FindFirstChild("HitRunawayEvent")

-- Config Modules
local PaintConfig, TileConfig, MaterialConfig, FurnitureConfig, IngredientsConfig, MerchantConfig
pcall(function()
    local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
    if Modules then
        PaintConfig = require(Modules:WaitForChild("PaintConfig", 5))
        TileConfig = require(Modules:WaitForChild("TileConfig", 5))
        MaterialConfig = require(Modules:WaitForChild("MaterialConfig", 5))
        FurnitureConfig = require(Modules:WaitForChild("FurnitureConfig", 5))
        IngredientsConfig = require(Modules:WaitForChild("IngredientsConfig", 5))
        MerchantConfig = require(Modules:WaitForChild("MerchantConfig", 5))
    end
end)

-- Helper: Purge any existing 3D glass blur parts and DepthOfField effects
local function purgeBlur()
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            for _, c in ipairs(cam:GetChildren()) do
                if c.Name == "LunaBlur" or string.find(string.lower(c.Name), "blur") then
                    pcall(function() c:Destroy() end)
                end
            end
        end
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("DepthOfFieldEffect") and (string.sub(effect.Name, 1, 4) == "DPT_" or string.find(string.lower(effect.Name), "luna")) then
                pcall(function()
                    effect.Enabled = false
                    effect:Destroy()
                end)
            end
        end
        for id = 1, 100 do
            pcall(function() RunService:UnbindFromRenderStep("neon::" .. tostring(id)) end)
        end
    end)
end

-- Helper: Clean all GUI instances from screen
local function cleanAllGuis()
    local containers = {
        (gethui and gethui()),
        game:GetService("CoreGui"),
        LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"),
        Lighting
    }
    pcall(function()
        table.insert(containers, game:GetService("CoreGui"):FindFirstChild("RobloxGui"))
    end)
    for _, container in ipairs(containers) do
        if container then
            for _, c in ipairs(container:GetChildren()) do
                local lowerName = string.lower(c.Name)
                if c.Name == "KarinderyaToggleGui"
                   or c.Name == "Luna UI"
                   or c.Name == "Luna-Old"
                   or c.Name == "LunaBlur"
                   or string.find(lowerName, "karinderya")
                   or (c:IsA("ScreenGui") and (c:FindFirstChild("SmartWindow") or string.find(lowerName, "luna"))) then
                    pcall(function()
                        if c:IsA("ScreenGui") then c.Enabled = false end
                        c:Destroy()
                    end)
                end
            end
        end
    end
    purgeBlur()
end

-- Full Killswitch / Cleanup Function
local function fullCleanup()
    scriptRunning = false

    if getgenv then
        getgenv()._KarinderyaRunning = false
        getgenv()._KarinderyaSessionId = nil
    end

    Config.AutoSeat = false
    Config.AutoServe = false
    Config.AutoWash = false
    Config.AutoHitRunaway = false
    Config.AutoBuyLowGrocery = false
    Config.AutoCampShop = false

    for _, th in ipairs(activeThreads) do
        pcall(task.cancel, th)
    end
    table.clear(activeThreads)

    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(activeConnections)

    pcall(function()
        if CustomerRanAwayEvent and getconnections then
            for _, conn in ipairs(getconnections(CustomerRanAwayEvent.OnClientEvent)) do
                pcall(function() conn:Disable() end)
                pcall(function() conn:Disconnect() end)
            end
        end
    end)

    cleanAllGuis()
    purgeBlur()

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Karinderya Auto",
            Text = "🛑 ปิดและหยุดการทำงานทั้งหมดแล้ว!",
            Duration = 3
        })
    end)
end

-- If a previous script session was running, completely terminate it first
if getgenv then
    if getgenv().KarinderyaCleanup then
        pcall(getgenv().KarinderyaCleanup)
    end
    getgenv()._KarinderyaRunning = true
    getgenv()._KarinderyaSessionId = mySession
    getgenv().KarinderyaCleanup = fullCleanup
end

cleanAllGuis()
task.wait(0.05)

local hui = (gethui and gethui()) or game:GetService("CoreGui")

local function isCurrentSession()
    if not scriptRunning then return false end
    if getgenv and (getgenv()._KarinderyaRunning == false or getgenv()._KarinderyaSessionId ~= mySession) then
        return false
    end
    return true
end

-- Safe Teleport with Velocity Reset to prevent flinging
local function safeTeleport(hrp, targetCF)
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = targetCF
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- Utility: Cached Restaurant Finder
local cachedRestaurant = nil
local lastRestaurantCheck = 0
local function getRestaurant()
    local lp = LocalPlayer
    if not lp then return nil end
    if cachedRestaurant and cachedRestaurant.Parent == workspace then
        return cachedRestaurant
    end
    if os.clock() - lastRestaurantCheck < 3 then
        return cachedRestaurant
    end
    lastRestaurantCheck = os.clock()

    for _, v in ipairs(workspace:GetChildren()) do
        if string.find(v.Name, "^Karenderya") then
            local owner = v:GetAttribute("Owner")
            if tonumber(owner) == lp.UserId or tostring(owner) == tostring(lp.UserId) or tostring(owner) == lp.Name then
                cachedRestaurant = v
                return v
            end
        end
    end
    return nil
end

-- Utility: Check if holding food / dirty dishes
local function getHoldStatus()
    local char = LocalPlayer.Character
    if not char then return { Food = false, Dirty = false } end
    local food, dirty = false, false
    for _, a in ipairs(char:GetChildren()) do
        if a:IsA("Accessory") then
            if a:GetAttribute("IsFood") then food = true end
            if a:GetAttribute("IsDirty") then dirty = true end
        end
    end
    return { Food = food, Dirty = dirty }
end

-- ============================================================================
-- REAL-TIME SHOP CATALOG & AUTO-CAMPING SYSTEM (NO MANUAL SCAN NEEDED)
-- ============================================================================
local Catalog = {}
local CatalogByKey = {}
local CampItems = {} -- [Key] = true
local isUpdatingUI = false
local isCampingShop = false

local function buildCatalog()
    table.clear(Catalog)
    table.clear(CatalogByKey)

    local function addItem(cat, key, name, price, sysType, isMerch)
        local item = {
            Category = cat,
            Key = key,
            Name = name or key,
            Price = price or 0,
            SystemType = sysType or "Dining",
            IsMerchant = isMerch or false,
            Stock = 0,
            DisplayName = string.format("[%s] %s | ₱%s", cat, name or key, tostring(price or 0))
        }
        table.insert(Catalog, item)
        CatalogByKey[key] = item
        return item
    end

    -- 1. Stoves
    if FurnitureConfig and FurnitureConfig.Kitchen and FurnitureConfig.Kitchen.Stoves then
        for k, v in pairs(FurnitureConfig.Kitchen.Stoves) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Stoves", k, v.Name or k, v.Price or 0, "Kitchen")
            end
        end
    end

    -- 2. Tables
    if FurnitureConfig and FurnitureConfig.Dining and FurnitureConfig.Dining.Tables then
        for k, v in pairs(FurnitureConfig.Dining.Tables) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Tables", k, v.Name or k, v.Price or 0, "Dining")
            end
        end
    end

    -- 3. Chairs
    if FurnitureConfig and FurnitureConfig.Dining and FurnitureConfig.Dining.Chairs then
        for k, v in pairs(FurnitureConfig.Dining.Chairs) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Chairs", k, v.Name or k, v.Price or 0, "Dining")
            end
        end
    end

    -- 4. Materials
    if MaterialConfig then
        for k, v in pairs(MaterialConfig) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Materials", k, v.Name or k, v.Price or 0, "Dining")
            end
        end
    end

    -- 5. Paints
    if PaintConfig then
        for k, v in pairs(PaintConfig) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Paints", k, v.Name or k, v.Price or 0, "Dining")
            end
        end
    end

    -- 6. Tiles
    if TileConfig then
        for k, v in pairs(TileConfig) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Tiles", k, v.Name or k, v.Price or 0, "Dining")
            end
        end
    end

    -- 7. Merchant
    if MerchantConfig then
        for k, v in pairs(MerchantConfig) do
            if type(v) == "table" and (v.Name or v.Price) then
                addItem("Merchant", k, v.Name or k, v.Price or 0, "Merchant", true)
            end
        end
    end

    table.sort(Catalog, function(a, b)
        if a.Category == b.Category then
            return a.Name < b.Name
        end
        return a.Category < b.Category
    end)
end

local function updateShopStock()
    if #Catalog == 0 then
        buildCatalog()
    end

    for _, item in ipairs(Catalog) do
        item.Stock = 0
    end

    if GetShopInfo then
        local success, shopData = pcall(function() return GetShopInfo:InvokeServer() end)
        if success and type(shopData) == "table" then
            for catName, list in pairs(shopData) do
                if type(list) == "table" then
                    for _, v in ipairs(list) do
                        if v.Key and CatalogByKey[v.Key] then
                            CatalogByKey[v.Key].Stock = v.Stock or 0
                        end
                    end
                end
            end
        end
    end

    if GetMerchantStock then
        local mSuccess, mData = pcall(function() return GetMerchantStock:InvokeServer() end)
        if mSuccess and type(mData) == "table" then
            for _, v in ipairs(mData) do
                if v.Key and CatalogByKey[v.Key] then
                    CatalogByKey[v.Key].Stock = v.Stock or 0
                end
            end
        end
    end
end

local function getInStockDisplayNames(category)
    local options = {}
    for _, item in ipairs(Catalog) do
        if item.Stock > 0 then
            if category == "All" or category == "All (ทั้งหมด)" or item.Category == category then
                table.insert(options, string.format("[%s] %s | ₱%s (สต็อก: %d)", item.Category, item.Name, tostring(item.Price), item.Stock))
            end
        end
    end
    if #options == 0 then
        table.insert(options, "ไม่มีสินค้าพร้อมซื้อในหมวดหมู่นี้")
    end
    return options
end

local function getCatalogDisplayNames(category)
    local options = {}
    for _, item in ipairs(Catalog) do
        if category == "All" or category == "All (ทั้งหมด)" or item.Category == category then
            table.insert(options, item.DisplayName)
        end
    end
    if #options == 0 then
        table.insert(options, "ไม่มีสินค้าในหมวดหมู่นี้")
    end
    return options
end

local function findItemFromSelection(str)
    if not str or str == "" or string.find(str, "ไม่มีสินค้า") then return nil end
    for _, item in ipairs(Catalog) do
        if item.DisplayName == str then return item end
        local inStockFmt = string.format("[%s] %s | ₱%s (สต็อก: %d)", item.Category, item.Name, tostring(item.Price), item.Stock)
        if inStockFmt == str then return item end
    end
    for _, item in ipairs(Catalog) do
        local prefix = string.format("[%s] %s", item.Category, item.Name)
        if string.sub(str, 1, #prefix) == prefix then
            return item
        end
    end
    for _, item in ipairs(Catalog) do
        if string.find(str, item.Name, 1, true) or string.find(str, item.Key, 1, true) then
            return item
        end
    end
    return nil
end

local function buyShopItem(item)
    if not item then return false, "ไม่ได้ระบุสินค้า" end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
    if cash < item.Price then
        return false, "เงินไม่พอ (ขาด ₱" .. tostring(item.Price - cash) .. ")"
    end

    local buySuccess, buyRes
    if item.IsMerchant and BuyMerchantItem then
        buySuccess, buyRes = pcall(function() return BuyMerchantItem:InvokeServer(item.Key) end)
    elseif BuyFurniture then
        buySuccess, buyRes = pcall(function() return BuyFurniture:InvokeServer(item.SystemType, item.Category, item.Key) end)
    end

    if buySuccess and buyRes ~= false then
        item.Stock = math.max(0, item.Stock - 1)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🏪 ซื้อของสำเร็จ!",
                Text = string.format("ซื้อ %s (-₱%s)", tostring(item.Name), tostring(item.Price)),
                Duration = 3
            })
        end)
        return true
    else
        return false, tostring(buyRes or "ซื้อไม่สำเร็จ (อาจหมดสต็อก)")
    end
end

local function doCampShopBuy()
    if isCampingShop or not Config.AutoCampShop then return end
    isCampingShop = true
    pcall(function()
        updateShopStock()
        for _, item in ipairs(Catalog) do
            if not isCurrentSession() or not Config.AutoCampShop then break end
            if CampItems[item.Key] and item.Stock > 0 then
                local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                local cash = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
                if cash >= item.Price then
                    local bought = buyShopItem(item)
                    if bought then
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
    isCampingShop = false
end

-- Pre-load catalog and initial stock immediately at script load
buildCatalog()
pcall(updateShopStock)

-- ============================================================================
-- GROCERY & RESTAURANT FARMING
-- ============================================================================
local function getCurrentStock(itemKey, itemConfig)
    local ingredients = LocalPlayer:FindFirstChild("Ingredients")
    local maxS = itemConfig and itemConfig.MaxStock or 100
    local val = 0
    if ingredients then
        local obj = ingredients:FindFirstChild(itemKey)
        if obj then val = obj.Value end
    end
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Accessory") and v:GetAttribute("IsSoftdrink") then
                local flavor = v:GetAttribute("Flavor") or v.Name
                if flavor == itemKey then
                    val = val + 1
                end
            end
        end
    end
    return val, maxS
end

local isBuyingGrocery = false
local function buyLowGrocery(force)
    if isBuyingGrocery then return end
    if not force and (not isCurrentSession() or not Config.AutoBuyLowGrocery) then return end
    if not BuyIngredient or not IngredientsConfig then return end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cashVal = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
    if cashVal <= 0 then return end

    isBuyingGrocery = true
    pcall(function()
        local thresholdRatio = (Config.LowStockThreshold or 10) / 100
        for itemKey, itemConfig in pairs(IngredientsConfig) do
            if not force and (not isCurrentSession() or not Config.AutoBuyLowGrocery) then break end
            local curStock, maxStock = getCurrentStock(itemKey, itemConfig)
            local ratio = curStock / maxStock
            if ratio <= thresholdRatio then
                local missing = maxStock - curStock
                if missing > 0 then
                    local yieldAmt = itemConfig.YieldAmount or 1
                    local packsNeeded = math.max(1, math.ceil(missing / yieldAmt))
                    local affordablePacks = math.floor(cashVal / math.max(1, itemConfig.Cost))
                    local toBuy = math.min(packsNeeded, affordablePacks)

                    if not Config.BuyMaxGrocery then
                        toBuy = math.min(1, affordablePacks)
                    end

                    if toBuy > 0 then
                        local success, res = pcall(function()
                            return BuyIngredient:InvokeServer(itemKey, toBuy, "Cash")
                        end)
                        if success and res then
                            local spent = toBuy * itemConfig.Cost
                            cashVal = cashVal - spent
                            pcall(function()
                                StarterGui:SetCore("SendNotification", {
                                    Title = "🛒 Auto Buy Grocery",
                                    Text = "ซื้อ " .. tostring(itemConfig.Name) .. " x" .. tostring(toBuy) .. " (-₱" .. tostring(spent) .. ")",
                                    Duration = 2.5
                                })
                            end)
                            task.wait(0.25)
                        end
                    end
                end
            end
        end
    end)
    isBuyingGrocery = false
end

-- Action: Auto Seat
local isSeating = false
local function doSeat()
    if not isCurrentSession() or not Config.AutoSeat or isSeating then return end
    if not GetCounterInfo or not AssignNPC then return end
    isSeating = true
    pcall(function()
        local customer, tables = GetCounterInfo:InvokeServer()
        if not isCurrentSession() or not Config.AutoSeat then return end
        if customer and tables and #tables > 0 then
            local targetTable = tables[1]
            local npcId = customer.NpcId or customer.TemplateName
            if npcId and targetTable then
                AssignNPC:FireServer({
                    Slot = targetTable.Slot,
                    Seat = targetTable.Seat,
                    NPCName = npcId,
                    NpcId = npcId
                })
            end
        end
    end)
    isSeating = false
end

-- Action: Auto Serve
local isServing = false
local function doServe()
    if not isCurrentSession() or not Config.AutoServe or isServing then return end
    local rest = getRestaurant()
    if not rest then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    isServing = true
    pcall(function()
        local status = getHoldStatus()
        if not status.Food then
            local serveFolder = rest:FindFirstChild("Serve")
            if serveFolder then
                for _, slot in ipairs(serveFolder:GetChildren()) do
                    for _, item in ipairs(slot:GetChildren()) do
                        if not isCurrentSession() or not Config.AutoServe then return end
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled and prompt:GetAttribute("TableAction") == "GetFood" then
                            local promptPart = prompt.Parent
                            if promptPart and promptPart:IsA("BasePart") then
                                local oldCF = hrp.CFrame
                                safeTeleport(hrp, promptPart.CFrame + Vector3.new(0, 2, 0))
                                task.wait(0.08)
                                if not isCurrentSession() or not Config.AutoServe then return end
                                fireproximityprompt(prompt)
                                task.wait(0.08)
                                if Config.InstantTeleport and isCurrentSession() then
                                    safeTeleport(hrp, oldCF)
                                end
                                return
                            else
                                fireproximityprompt(prompt)
                                return
                            end
                        end
                    end
                end
            end
        else
            local diningFolder = rest:FindFirstChild("DiningPlot1")
            if diningFolder then
                for _, prompt in ipairs(diningFolder:GetDescendants()) do
                    if not isCurrentSession() or not Config.AutoServe then return end
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt:GetAttribute("TableAction") == "Serve" then
                        local promptPart = prompt.Parent
                        if promptPart and promptPart:IsA("BasePart") then
                            local oldCF = hrp.CFrame
                            safeTeleport(hrp, promptPart.CFrame + Vector3.new(0, 2, 0))
                            task.wait(0.08)
                            if not isCurrentSession() or not Config.AutoServe then return end
                            fireproximityprompt(prompt)
                            task.wait(0.08)
                            if Config.InstantTeleport and isCurrentSession() then
                                safeTeleport(hrp, oldCF)
                            end
                            return
                        else
                            fireproximityprompt(prompt)
                            return
                        end
                    end
                end
            end
        end
    end)
    isServing = false
end

-- Helper: Get safe floor CFrame for washing dishes
local function getSafeWashCFrame(sinkPart, char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hipHeight = humanoid and humanoid.HipHeight or 2.0
    local rootHalfY = hrp and (hrp.Size.Y / 2) or 1.0
    local standHeight = hipHeight + rootHalfY + 0.1

    local frontDir = sinkPart.CFrame.LookVector
    if math.abs(frontDir.Y) > 0.7 then
        frontDir = Vector3.new(0, 0, 1)
    else
        frontDir = Vector3.new(frontDir.X, 0, frontDir.Z).Unit
    end

    local candidateXZ = sinkPart.Position + (frontDir * 2.2)
    local rayOrigin = Vector3.new(candidateXZ.X, sinkPart.Position.Y + 4, candidateXZ.Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -12, 0), rayParams)
    local targetY
    if rayResult and rayResult.Position then
        targetY = rayResult.Position.Y + standHeight
    else
        targetY = sinkPart.Position.Y + standHeight - 0.5
    end

    local lookTarget = Vector3.new(sinkPart.Position.X, targetY, sinkPart.Position.Z)
    return CFrame.new(Vector3.new(candidateXZ.X, targetY, candidateXZ.Z), lookTarget)
end

-- Action: Auto Wash (Fixed: Works with Sink folder & continuous InputHoldBegin)
local isWashing = false
local function doWash()
    if not isCurrentSession() or not Config.AutoWash or isWashing then return end
    local rest = getRestaurant()
    if not rest then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local sinkFolder = rest:FindFirstChild("Sink")
    if not sinkFolder then return end

    local washPrompt = sinkFolder:FindFirstChild("Wash", true)
    if not washPrompt or not washPrompt.Enabled or washPrompt:GetAttribute("HasDishes") ~= true then
        return
    end

    local promptPart = washPrompt.Parent
    if not promptPart or not promptPart:IsA("BasePart") then return end

    isWashing = true
    pcall(function()
        local oldCF = hrp.CFrame
        local safeCF = getSafeWashCFrame(promptPart, char)

        safeTeleport(hrp, safeCF)
        task.wait(0.15)

        -- Begin wash hold
        pcall(function() washPrompt:InputHoldBegin() end)

        local t0 = os.clock()
        -- Hold while there are dishes and session is active, up to 12s per cycle
        while isCurrentSession() and Config.AutoWash and washPrompt.Parent and washPrompt:GetAttribute("HasDishes") == true and (os.clock() - t0) < 12 do
            task.wait(0.5)
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end

        pcall(function() washPrompt:InputHoldEnd() end)
        task.wait(0.1)

        if Config.InstantTeleport and oldCF and hrp and isCurrentSession() then
            safeTeleport(hrp, oldCF)
        end
    end)
    isWashing = false
end

-- ============================================================================
-- RUNAWAY WHACKING SYSTEM
-- ============================================================================
local isHittingRunaway = false
local lastHitTimes = {}

local function canHitNPC(npc)
    if not npc or not npc.Parent then return false end
    local npcId = npc.Name
    if lastHitTimes[npcId] and (os.clock() - lastHitTimes[npcId]) < 1.2 then
        return false
    end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        return false
    end
    return true
end

local function isRunawayNPC(npc)
    if not npc or not npc.Parent or not npc:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(npc) then return false end

    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end

    if npc:GetAttribute("IsRunaway") == true or npc:GetAttribute("Runaway") == true or npc:GetAttribute("Runaway") == "Runaway" then
        return true
    end

    for attrName, val in pairs(npc:GetAttributes()) do
        local lowerKey = string.lower(tostring(attrName))
        if string.find(lowerKey, "runaway") or string.find(lowerKey, "steal") or string.find(lowerKey, "thief") or string.find(lowerKey, "flee") or string.find(lowerKey, "stole") then
            if val == true or val == "Runaway" or (type(val) == "string" and string.find(string.lower(val), "runaway")) then
                return true
            end
        end
    end

    local state = npc:GetAttribute("State") or npc:GetAttribute("Action") or npc:GetAttribute("Status")
    if state then
        local lowerState = string.lower(tostring(state))
        if string.find(lowerState, "runaway") or string.find(lowerState, "flee") or string.find(lowerState, "steal") or string.find(lowerState, "thief") or string.find(lowerState, "escape") then
            return true
        end
    end

    for _, desc in ipairs(npc:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            local actText = string.lower(desc.ActionText or "")
            local objText = string.lower(desc.ObjectText or "")
            local pName = string.lower(desc.Name or "")
            if string.find(actText, "hit") or string.find(actText, "catch") or string.find(actText, "stop")
               or string.find(actText, "whack") or string.find(actText, "slap") or string.find(actText, "tackle")
               or string.find(actText, "runaway") or string.find(actText, "thief") or string.find(actText, "steal")
               or string.find(objText, "runaway") or string.find(objText, "thief")
               or string.find(pName, "runaway") or string.find(pName, "hit") then
                return true
            end
        elseif desc:IsA("BillboardGui") and desc.Enabled then
            for _, txt in ipairs(desc:GetDescendants()) do
                if txt:IsA("TextLabel") and txt.Visible then
                    local lowerTxt = string.lower(txt.Text)
                    if string.find(lowerTxt, "runaway") or string.find(lowerTxt, "thief") or string.find(lowerTxt, "steal") or string.find(lowerTxt, "hit") or string.find(lowerTxt, "escaping") then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function collectAllRunawayCandidates()
    local candidates = {}
    local seen = {}

    local function addModel(m)
        if m and m:IsA("Model") and not seen[m] then
            seen[m] = true
            if isRunawayNPC(m) then
                table.insert(candidates, m)
            end
        end
    end

    for _, v in ipairs(workspace:GetChildren()) do
        if string.find(v.Name, "^Karenderya") or string.find(string.lower(v.Name), "restaurant") then
            for _, folderName in ipairs({"Customers", "Customer", "ClientNPCs", "NPCs", "Runaways", "Runaway", "ActiveNPCs"}) do
                local sub = v:FindFirstChild(folderName)
                if sub then
                    for _, child in ipairs(sub:GetChildren()) do addModel(child) end
                end
            end
        end
    end

    local clientNpcs = workspace:FindFirstChild("ClientNPCs")
    if clientNpcs then
        for _, child in ipairs(clientNpcs:GetChildren()) do addModel(child) end
    end

    for _, rootFolderName in ipairs({"NPCs", "Customers", "Runaways", "StreetNPCs", "Characters"}) do
        local folder = workspace:FindFirstChild(rootFolderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do addModel(child) end
        end
    end

    return candidates
end

local function hitTargetNPC(target)
    if not isCurrentSession() or not Config.AutoHitRunaway then return end
    if not target or not target.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso") or target.PrimaryPart
    if not targetRoot then return end

    local oldCF = hrp.CFrame
    lastHitTimes[target.Name] = os.clock()

    pcall(function()
        local forward = targetRoot.CFrame.LookVector
        local attackPos = targetRoot.Position + (forward * 2.2) + Vector3.new(0, 0.5, 0)
        local attackCF = CFrame.new(attackPos, targetRoot.Position)

        safeTeleport(hrp, attackCF)

        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        t.Parent = char
                        tool = t
                        break
                    end
                end
            end
        end
        if tool then
            pcall(function() tool:Activate() end)
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            if handle and firetouchinterest then
                pcall(function()
                    firetouchinterest(handle, targetRoot, 0)
                    firetouchinterest(handle, targetRoot, 1)
                end)
            end
        end

        if HitRunawayEvent then
            pcall(function() HitRunawayEvent:FireServer(target) end)
            pcall(function() HitRunawayEvent:FireServer(target.Name) end)
            pcall(function() HitRunawayEvent:FireServer({ NPC = target }) end)
        end

        for _, prompt in ipairs(target:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                pcall(function() fireproximityprompt(prompt) end)
            end
        end

        task.wait(0.12)

        if Config.InstantTeleport and oldCF and hrp and isCurrentSession() then
            safeTeleport(hrp, oldCF)
        end
    end)
end

-- Throttled Runaway Scan
local lastRunawayScan = 0
local function scanAndHitRunaways()
    if not isCurrentSession() or not Config.AutoHitRunaway or isHittingRunaway then return end
    if (os.clock() - lastRunawayScan) < 2.5 then return end
    lastRunawayScan = os.clock()
    isHittingRunaway = true

    pcall(function()
        local runaways = collectAllRunawayCandidates()
        for _, npc in ipairs(runaways) do
            if not isCurrentSession() or not Config.AutoHitRunaway then break end
            if canHitNPC(npc) then
                hitTargetNPC(npc)
                task.wait(0.1)
            end
        end
    end)

    isHittingRunaway = false
end

-- Event Listener: Customer Ran Away
if CustomerRanAwayEvent then
    local runawayConn = CustomerRanAwayEvent.OnClientEvent:Connect(function(...)
        if not isCurrentSession() or not Config.AutoHitRunaway then return end
        local args = {...}
        local target = nil
        for _, arg in ipairs(args) do
            if typeof(arg) == "Instance" and arg:IsA("Model") then
                target = arg
                break
            elseif type(arg) == "table" then
                local cand = arg.NPC or arg.Npc or arg.Model or arg.Character
                if typeof(cand) == "Instance" and cand:IsA("Model") then
                    target = cand
                    break
                end
                for _, v in pairs(arg) do
                    if typeof(v) == "Instance" and v:IsA("Model") then
                        target = v
                        break
                    end
                end
                if target then break end
            elseif type(arg) == "string" then
                target = (workspace:FindFirstChild("ClientNPCs") and workspace.ClientNPCs:FindFirstChild(arg))
                    or workspace:FindFirstChild(arg, true)
                if target then break end
            end
        end

        if target and canHitNPC(target) then
            task.spawn(hitTargetNPC, target)
        else
            task.spawn(scanAndHitRunaways)
        end
    end)
    table.insert(activeConnections, runawayConn)
end

-- Event Listener: Shop Restocked (Live Trigger)
if ShopRestocked then
    local restockConn = ShopRestocked.OnClientEvent:Connect(function()
        if not isCurrentSession() then return end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🏪 ร้านค้ารีสต็อกแล้ว!",
                Text = "อัปเดตสต็อกสินค้าใหม่ทันที...",
                Duration = 2.5
            })
        end)
        pcall(updateShopStock)
        pcall(function()
            if refreshShopDropdowns then refreshShopDropdowns() end
        end)
        if Config.AutoCampShop then
            task.spawn(doCampShopBuy)
        end
    end)
    table.insert(activeConnections, restockConn)
end

-- Non-Blocking Main Automation Loop
local mainLoopThread = task.spawn(function()
    local groceryCounter = 0
    local shopCampCounter = 0
    while isCurrentSession() do
        task.wait(Config.Delay)
        if not isCurrentSession() then break end

        if Config.AutoSeat then
            task.spawn(doSeat)
        end
        if Config.AutoServe then
            task.spawn(doServe)
        end
        if Config.AutoWash and not isWashing then
            task.spawn(doWash)
        end
        if Config.AutoHitRunaway and not isHittingRunaway then
            task.spawn(scanAndHitRunaways)
        end

        groceryCounter = groceryCounter + 1
        if groceryCounter % 5 == 0 and Config.AutoBuyLowGrocery and not isBuyingGrocery then
            task.spawn(buyLowGrocery, false)
        end

        shopCampCounter = shopCampCounter + 1
        if shopCampCounter % 8 == 0 then
            pcall(updateShopStock)
            if Config.AutoCampShop and not isCampingShop then
                task.spawn(doCampShopBuy)
            end
        end
    end
end)
table.insert(activeThreads, mainLoopThread)

-- ============================================================================
-- LUNA UI SETUP
-- ============================================================================
if getgenv then
    getgenv().ConfirmLuna = true
end

local rawLuna = game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/master/source.lua")
rawLuna = string.gsub(rawLuna, "local function BlurModule%(Frame%)", "local function BlurModule(Frame) if true then return end")
local Luna = loadstring(rawLuna)()

local oldNotification = Luna.Notification
Luna.Notification = function(self, data)
    if type(data) == "table" and not data.ImageSource then
        data.ImageSource = "Material"
    end
    return pcall(function()
        return oldNotification(self, data)
    end)
end

local Window = Luna:CreateWindow({
    Name = "Karinderya! Auto",
    Subtitle = "Farm & Live Shop Camping",
    LogoID = "6031097225",
    LoadingEnabled = false
})

-- ----------------------------------------------------------------------------
-- TAB 1: Main Farm
-- ----------------------------------------------------------------------------
local MainTab = Window:CreateTab({
    Name = "Main Farm",
    Icon = "restaurant",
    ImageSource = "Material"
})

MainTab:CreateSection("Customer & Food Automation")

MainTab:CreateToggle({
    Name = "Auto Seat Customers (ให้ลูกค้านั่ง)",
    CurrentValue = false,
    Flag = "AutoSeat",
    Callback = function(val)
        Config.AutoSeat = val
    end
})

MainTab:CreateToggle({
    Name = "Auto Serve Food (เสิร์ฟอาหารอัตโนมัติ)",
    CurrentValue = false,
    Flag = "AutoServe",
    Callback = function(val)
        Config.AutoServe = val
    end
})

MainTab:CreateToggle({
    Name = "Auto Wash Dishes (ล้างจานออโต้ - แก้ไขทำงานชัวร์ 100%)",
    CurrentValue = false,
    Flag = "AutoWash",
    Callback = function(val)
        Config.AutoWash = val
    end
})

MainTab:CreateToggle({
    Name = "Auto Hit Runaways (ตีลูกค้าไม่จ่ายตัง ทั้งเซิร์ฟ)",
    CurrentValue = false,
    Flag = "AutoHitRunaway",
    Callback = function(val)
        Config.AutoHitRunaway = val
    end
})

MainTab:CreateSection("Grocery (ซื้อวัตถุดิบ 🛒)")

MainTab:CreateToggle({
    Name = "Auto Buy Low Grocery (ซื้อของที่เหลือน้อยออโต้)",
    CurrentValue = false,
    Flag = "AutoBuyLowGrocery",
    Callback = function(val)
        Config.AutoBuyLowGrocery = val
    end
})

MainTab:CreateToggle({
    Name = "Buy Max Stock (ซื้อจนเต็มโควต้าตามเงินที่มี)",
    CurrentValue = true,
    Flag = "BuyMaxGrocery",
    Callback = function(val)
        Config.BuyMaxGrocery = val
    end
})

MainTab:CreateSlider({
    Name = "Low Threshold (% สต็อกที่ถือว่าเหลือน้อย)",
    Range = {5, 50},
    Increment = 5,
    CurrentValue = 10,
    Flag = "LowStockThreshold",
    Callback = function(val)
        Config.LowStockThreshold = val
    end
})

MainTab:CreateButton({
    Name = "Buy All Low Now (กดซื้อวัตถุดิบเหลือน้อยทันที ⚡)",
    Callback = function()
        task.spawn(function()
            buyLowGrocery(true)
        end)
    end
})

MainTab:CreateSection("Farm Settings")

MainTab:CreateToggle({
    Name = "Instant Teleport Action (วาร์ปเสร็จกลับที่เดิม)",
    CurrentValue = true,
    Flag = "InstantTeleport",
    Callback = function(val)
        Config.InstantTeleport = val
    end
})

MainTab:CreateSlider({
    Name = "Action Loop Delay (วินาที)",
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = 0.4,
    Flag = "ActionDelay",
    Callback = function(val)
        Config.Delay = val
    end
})

-- ----------------------------------------------------------------------------
-- TAB 2: Shop (ร้านค้า & ซื้อของอัตโนมัติ)
-- ----------------------------------------------------------------------------
local ShopTab = Window:CreateTab({
    Name = "Shop (ร้านค้า)",
    Icon = "store",
    ImageSource = "Material"
})

-- Forward declarations
local ShopStatusParagraph
local ItemSelectDropdown
local QuickBuyDropdown

local initialInStockCount = 0
for _, it in ipairs(Catalog) do
    if it.Stock > 0 then initialInStockCount = initialInStockCount + 1 end
end

ShopStatusParagraph = ShopTab:CreateParagraph({
    Title = "สถานะร้านค้า (Shop Status)",
    Text = string.format("📦 มีของพร้อมซื้อตอนนี้: %d รายการ | สินค้าทั้งหมด: %d รายการ\n🎯 กำลังแคมป์ไว้: 0 รายการ\n⚡ ระบบอัปเดตสต็อกและสั่งซื้ออัตโนมัติแบบเรียลไทม์ (ไม่ต้องกดสแกน)",
        initialInStockCount, #Catalog)
})

local function updateStatusText()
    if not ShopStatusParagraph or not ShopStatusParagraph.Set then return end
    local inStockCount = 0
    local campedCount = 0
    for _ in pairs(CampItems) do campedCount = campedCount + 1 end
    for _, item in ipairs(Catalog) do
        if item.Stock > 0 then inStockCount = inStockCount + 1 end
    end

    pcall(function()
        ShopStatusParagraph:Set({
            Title = "สถานะร้านค้า (Shop Status)",
            Text = string.format("📦 มีของพร้อมซื้อตอนนี้: %d รายการ | สินค้าทั้งหมด: %d รายการ\n🎯 กำลังแคมป์ไว้: %d รายการ | อัปเดตล่าสุด: %s\n⚡ ระบบอัปเดตสต็อกและสั่งซื้ออัตโนมัติแบบเรียลไทม์ (ไม่ต้องกดสแกน)",
                inStockCount, #Catalog, campedCount, os.date("%X"))
        })
    end)
end

function refreshShopDropdowns()
    if isUpdatingUI then return end
    isUpdatingUI = true

    pcall(function()
        updateStatusText()

        if QuickBuyDropdown and QuickBuyDropdown.Set then
            local inOpts = getInStockDisplayNames(Config.SelectedShopCategory)
            QuickBuyDropdown:Set({
                Options = inOpts,
                CurrentOption = { inOpts[1] }
            })
        end

        if ItemSelectDropdown and ItemSelectDropdown.Set then
            local catOpts = getCatalogDisplayNames(Config.SelectedShopCategory)
            ItemSelectDropdown:Set({
                Options = catOpts,
                CurrentOption = {}
            })
        end
    end)

    isUpdatingUI = false
end

ShopTab:CreateSection("Instant Buy (เลือกของที่มีในร้านเพื่อซื้อทันที)")

ShopTab:CreateDropdown({
    Name = "Filter Category (เลือกหมวดหมู่ที่ต้องการดู)",
    Options = {
        "All (ทั้งหมด)",
        "Stoves",
        "Tables",
        "Chairs",
        "Materials",
        "Paints",
        "Tiles",
        "Merchant"
    },
    CurrentOption = { "All (ทั้งหมด)" },
    MultipleOptions = false,
    Callback = function(opt)
        if isUpdatingUI then return end
        local cat = type(opt) == "table" and opt[1] or opt
        if string.find(cat, "All") then
            Config.SelectedShopCategory = "All"
        else
            Config.SelectedShopCategory = cat
        end
        refreshShopDropdowns()
    end
})

local initialInStockOpts = getInStockDisplayNames("All")
local selectedQuickBuyItem = findItemFromSelection(initialInStockOpts[1])

QuickBuyDropdown = ShopTab:CreateDropdown({
    Name = "Select In-Stock Item (เลือกของที่พร้อมซื้อตอนนี้)",
    Description = "คลิกเพื่อเลือกสินค้าที่มีสต็อกในร้าน แล้วกดปุ่มสั่งซื้อด้านล่าง",
    Options = initialInStockOpts,
    CurrentOption = { initialInStockOpts[1] },
    MultipleOptions = false,
    Callback = function(opt)
        if isUpdatingUI then return end
        local str = type(opt) == "table" and opt[1] or opt
        selectedQuickBuyItem = findItemFromSelection(str)
    end
})

ShopTab:CreateButton({
    Name = "ซื้อชิ้นที่เลือกตอนนี้เลย (Buy Now) 🛒",
    Callback = function()
        task.spawn(function()
            if not selectedQuickBuyItem then
                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "🏪 สั่งซื้อ",
                        Text = "กรุณาเลือกสินค้าที่มีในสต็อกก่อน",
                        Duration = 2.5
                    })
                end)
                return
            end
            local success, err = buyShopItem(selectedQuickBuyItem)
            if not success then
                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "⚠️ ซื้อไม่สำเร็จ",
                        Text = tostring(err or "เกิดข้อผิดพลาด"),
                        Duration = 3
                    })
                end)
            else
                updateShopStock()
                refreshShopDropdowns()
            end
        end)
    end
})

ShopTab:CreateSection("Auto-Buy / Camp (เฝ้าซื้อของอัตโนมัติเมื่อของเข้า)")

ShopTab:CreateToggle({
    Name = "Auto Camp Target Items (เปิดระบบเฝ้าซื้อออโต้)",
    CurrentValue = false,
    Flag = "AutoCampShop",
    Callback = function(val)
        Config.AutoCampShop = val
        if val then
            task.spawn(doCampShopBuy)
        end
        updateStatusText()
    end
})

local initialCatalogOpts = getCatalogDisplayNames("All")

ItemSelectDropdown = ShopTab:CreateDropdown({
    Name = "Target Items to Camp (เลือกของที่จะเฝ้าซื้อ)",
    Description = "เลือกสินค้าที่ต้องการซื้อ (เลือกได้หลายชิ้น) เมื่อของเข้าสต็อก บอทจะซื้อให้อัตโนมัติทันที",
    Options = initialCatalogOpts,
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(selectedList)
        if isUpdatingUI then return end
        if type(selectedList) ~= "table" then
            if type(selectedList) == "string" then selectedList = { selectedList } else return end
        end
        table.clear(CampItems)
        for _, displayStr in ipairs(selectedList) do
            local item = findItemFromSelection(displayStr)
            if item then
                CampItems[item.Key] = true
            end
        end
        updateStatusText()
    end
})

ShopTab:CreateButton({
    Name = "ล้างรายการที่เฝ้าซื้อทั้งหมด (Clear All Targets) ❌",
    Callback = function()
        table.clear(CampItems)
        updateStatusText()
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🏪 ล้างรายการสำเร็จ",
                Text = "ล้างรายการของที่เฝ้าซื้อทั้งหมดแล้ว",
                Duration = 2
            })
        end)
    end
})

ShopTab:CreateButton({
    Name = "สั่งซื้อของที่เฝ้าไว้ทันที (Buy All In-Stock Camped) ⚡",
    Callback = function()
        task.spawn(function()
            local prevCampState = Config.AutoCampShop
            Config.AutoCampShop = true
            doCampShopBuy()
            Config.AutoCampShop = prevCampState
            updateStatusText()
            refreshShopDropdowns()
        end)
    end
})

-- ----------------------------------------------------------------------------
-- TAB 3: Global Settings & Unload
-- ----------------------------------------------------------------------------
local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings",
    ImageSource = "Material"
})

SettingsTab:CreateSection("Script Control")

SettingsTab:CreateButton({
    Name = "Unload / Close Script (ปิดและหยุดการทำงานทั้งหมด 🛑)",
    Callback = function()
        fullCleanup()
    end
})

-- Robust Luna Finder & Visibility Toggler
local isMenuVisible = true

local function getLunaGuis()
    local guis = {}
    local containers = {
        (gethui and gethui()),
        game:GetService("CoreGui"),
        LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    }
    pcall(function()
        table.insert(containers, game:GetService("CoreGui"):FindFirstChild("RobloxGui"))
    end)
    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local lowerName = string.lower(child.Name)
                    if child.Name == "Luna UI" or child.Name == "Luna-Old" or child:FindFirstChild("SmartWindow") or string.find(lowerName, "luna") then
                        table.insert(guis, child)
                    end
                end
            end
        end
    end
    return guis
end

local function toggleLuna()
    isMenuVisible = not isMenuVisible
    local guis = getLunaGuis()
    for _, g in ipairs(guis) do
        g.Enabled = isMenuVisible
        local smartWindow = g:FindFirstChild("SmartWindow")
        if smartWindow then
            smartWindow.Visible = isMenuVisible
            if isMenuVisible and (smartWindow.Size.X.Offset == 0 or smartWindow.Size.Y.Offset == 0) then
                smartWindow.Size = UDim2.fromOffset(550, 350)
                smartWindow.BackgroundTransparency = 0
                if smartWindow:FindFirstChild("Elements") and smartWindow.Elements.Parent then
                    smartWindow.Elements.Parent.Visible = true
                end
            end
        end
        local drag = g:FindFirstChild("Drag")
        if drag then drag.Visible = isMenuVisible end
        local shadow = g:FindFirstChild("ShadowHolder")
        if shadow then shadow.Visible = isMenuVisible end
        local mobile = g:FindFirstChild("MobileSupport")
        if mobile then mobile.Visible = false end
    end
    if not isMenuVisible then
        purgeBlur()
    end
end

-- Hook Close button on Luna window
task.spawn(function()
    task.wait(0.6)
    local guis = getLunaGuis()
    for _, g in ipairs(guis) do
        local smartWindow = g:FindFirstChild("SmartWindow")
        local controls = smartWindow and smartWindow:FindFirstChild("Controls")
        local closeBtn = controls and controls:FindFirstChild("Close")
        if closeBtn then
            local btnObj = closeBtn:FindFirstChildWhichIsA("GuiButton", true) or closeBtn
            if btnObj and btnObj:IsA("GuiButton") then
                local conn = btnObj.MouseButton1Click:Connect(function()
                    isMenuVisible = false
                    g.Enabled = false
                    if smartWindow then smartWindow.Visible = false end
                    purgeBlur()
                end)
                table.insert(activeConnections, conn)
            end
        end
    end
end)

-- Universal Draggable Handler
local function makeDraggable(guiObj)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local conn1 = guiObj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObj.Position

            local connEnd
            connEnd = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connEnd then connEnd:Disconnect() end
                end
            end)
        end
    end)

    local conn2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObj.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    table.insert(activeConnections, conn1)
    table.insert(activeConnections, conn2)
end

-- Floating Toggle Button
local function createToggleButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KarinderyaToggleGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = hui

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleMenuBtn"
    btn.Size = UDim2.new(0, 120, 0, 34)
    btn.Position = UDim2.new(0, 15, 0.18, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.TextColor3 = Color3.fromRGB(240, 240, 245)
    btn.Text = "🍽️ เมนู (Toggle)"
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Active = true
    btn.ZIndex = 100
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(117, 164, 206)
    stroke.Thickness = 1.5
    stroke.Parent = btn

    makeDraggable(btn)

    local clickConn = btn.MouseButton1Click:Connect(toggleLuna)
    table.insert(activeConnections, clickConn)

    local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.K then
            toggleLuna()
        end
    end)
    table.insert(activeConnections, keyConn)
end

pcall(createToggleButton)

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

local PAYLOAD_KEY = "IqPLgnKgTVxvi5CK1F8i/QOoODzFg5Xn5tiBasPJUig="
local PAYLOAD_IV = "UGOP1q3lW1VuWgJf0PeBfg=="
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
