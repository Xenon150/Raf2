-- ══════════════════════════════════════════════════════════
--  XENON RELOAD GUARD
-- ══════════════════════════════════════════════════════════
if getgenv().XenonLoaded then
    if getgenv().XenonScreenGui then getgenv().XenonScreenGui:Destroy() end
    if getgenv().MobileButton   then getgenv().MobileButton:Destroy()   end
end
getgenv().XenonLoaded = true

-- ══════════════════════════════════════════════════════════
--  СЕРВИСЫ
-- ══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Events      = ReplicatedStorage:WaitForChild("Events")

-- ══════════════════════════════════════════════════════════
--  НАСТРОЙКИ И БАЗА
-- ══════════════════════════════════════════════════════════
local UnlocksModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Unlocks"))
local ShopData = UnlocksModule.the_interwebs

local Settings = {
    AutoClick   = false,
    AutoBuy     = false,
    AutoCollect = false,
    AutoRent    = false,
    AutoSeeds   = false,
    ZeroCD      = false,
    CrystalTP   = false,
    AntiAFK     = true
}

local PERMANENT_BLACKLIST = {
    ["Anti Time Cube"] = true,
    ["Time Cube"]      = true,
    ["Floppa Food"]    = true
}

-- ══════════════════════════════════════════════════════════
--  УНИВЕРСАЛЬНЫЕ ФУНКЦИИ
-- ══════════════════════════════════════════════════════════
local suffixes = { K=1e3, M=1e6, B=1e9, T=1e12, Q=1e15 }
local function parseValue(text)
    if not text or text == "" then return 0 end
    text = text:gsub(",","")
    local num, suf = text:match("%$([%d%.]+)([KMBTQkmbtq]?)")
    if num then return (tonumber(num) or 0) * (suffixes[suf:upper()] or 1) end
    num = text:match("([%d%.]+)")
    if num then return tonumber(num) or 0 end
    return 0
end

local function getWallet()
    local money, gold = 0, 0
    pcall(function()
        local left = PlayerGui:FindFirstChild("HUD") and PlayerGui.HUD:FindFirstChild("Left")
        if left then
            if left:FindFirstChild("Money Label") and left["Money Label"].Visible then
                money = parseValue(left["Money Label"].Text)
            end
            if left:FindFirstChild("Gold Label") and left["Gold Label"].Visible then
                gold = parseValue(left["Gold Label"].Text)
            end
        end
    end)
    return money, gold
end

local function safeTouch(targetObj)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not targetObj or not targetObj.Parent then return end
        if firetouchinterest then
            local touchPart = nil
            if targetObj:IsA("BasePart") and targetObj:FindFirstChildWhichIsA("TouchTransmitter") then
                touchPart = targetObj
            else
                for _, desc in ipairs(targetObj:GetDescendants()) do
                    if desc:IsA("TouchTransmitter") then touchPart = desc.Parent; break end
                end
            end
            if touchPart and touchPart:IsDescendantOf(workspace) and touchPart:FindFirstChildWhichIsA("TouchTransmitter") then
                firetouchinterest(touchPart, root, 0)
                task.wait()
                if touchPart and touchPart:IsDescendantOf(workspace) then
                    firetouchinterest(touchPart, root, 1)
                end
            end
        end
    end)
end

local function isValidDrop(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("BasePart") then return false end
    if obj.Name == "Baseplate" or obj.Name == "Grass" then return false end
    if obj.Parent:FindFirstChild("Humanoid") then return false end
    return true
end

-- ══════════════════════════════════════════════════════════
--  ANTI-AFK
-- ══════════════════════════════════════════════════════════
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- ══════════════════════════════════════════════════════════
--  KEY SYSTEM
-- ══════════════════════════════════════════════════════════
local VALID_KEY   = "Jkfq12lvwfwg51vdc"
local GETKEY_LINK = "https://discord.gg/9Fyh42Hs"
local hasAccess   = false

if not hasAccess then
    local gui = Instance.new("ScreenGui")
    gui.Name           = "XenonKeyUI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn   = false
    gui.Parent         = game.CoreGui

    local blur = Instance.new("BlurEffect")
    blur.Size   = 0
    blur.Parent = game.Lighting
    TweenService:Create(blur, TweenInfo.new(0.4), {Size = 20}):Play()

    local bg = Instance.new("Frame")
    bg.Size                  = UDim2.new(1,0,1,0)
    bg.BackgroundColor3      = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 1
    bg.Parent                = gui
    TweenService:Create(bg, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()

    local main = Instance.new("Frame")
    main.Size             = UDim2.new(0,0,0,0)
    main.Position         = UDim2.new(0.5,0,0.5,0)
    main.AnchorPoint      = Vector2.new(0.5,0.5)
    main.BackgroundColor3 = Color3.fromRGB(15,15,15)
    main.Parent           = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
    TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0,340,0,220)
    }):Play()

    local title = Instance.new("TextLabel", main)
    title.Size                = UDim2.new(1,0,0,50)
    title.BackgroundTransparency = 1
    title.Text                = "XENON"
    title.Font                = Enum.Font.GothamBlack
    title.TextSize             = 20
    title.TextColor3           = Color3.fromRGB(255,255,255)

    local input = Instance.new("TextBox", main)
    input.Size             = UDim2.new(0.8,0,0,40)
    input.Position         = UDim2.new(0.1,0,0.45,0)
    input.BackgroundColor3 = Color3.fromRGB(25,25,25)
    input.PlaceholderText  = "Enter key..."
    input.Text             = ""
    input.Font             = Enum.Font.Gotham
    input.TextSize          = 14
    input.TextColor3        = Color3.new(1,1,1)
    Instance.new("UICorner", input).CornerRadius = UDim.new(0,10)

    local unlock = Instance.new("TextButton", main)
    unlock.Size             = UDim2.new(0.8,0,0,35)
    unlock.Position         = UDim2.new(0.1,0,0.68,0)
    unlock.Text             = "Unlock"
    unlock.Font             = Enum.Font.GothamBold
    unlock.TextSize          = 14
    unlock.TextColor3        = Color3.new(1,1,1)
    unlock.BackgroundColor3  = Color3.fromRGB(0,160,255)
    Instance.new("UICorner", unlock).CornerRadius = UDim.new(0,10)

    local getkey = Instance.new("TextButton", main)
    getkey.Size             = UDim2.new(0.8,0,0,28)
    getkey.Position         = UDim2.new(0.1,0,0.85,0)
    getkey.Text             = "Get Key"
    getkey.Font             = Enum.Font.Gotham
    getkey.TextSize          = 12
    getkey.TextColor3        = Color3.fromRGB(200,200,200)
    getkey.BackgroundColor3  = Color3.fromRGB(30,30,30)
    Instance.new("UICorner", getkey).CornerRadius = UDim.new(0,10)

    local status = Instance.new("TextLabel", main)
    status.Size                  = UDim2.new(1,0,0,18)
    status.Position              = UDim2.new(0,0,1,-18)
    status.BackgroundTransparency = 1
    status.Text                  = ""
    status.Font                  = Enum.Font.Gotham
    status.TextSize               = 12
    status.TextColor3             = Color3.fromRGB(255,80,80)

    getkey.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GETKEY_LINK)
            status.Text      = "Link copied!"
            status.TextColor3 = Color3.fromRGB(100,255,100)
        else
            status.Text = "Clipboard not supported"
        end
    end)

    local unlocked = false
    unlock.MouseButton1Click:Connect(function()
        if input.Text == VALID_KEY then
            status.Text      = "Access granted"
            status.TextColor3 = Color3.fromRGB(100,255,100)
            unlocked = true
            TweenService:Create(main, TweenInfo.new(0.3), {Size = UDim2.new(0,0,0,0)}):Play()
            task.wait(0.3)
            gui:Destroy()
            blur:Destroy()
        else
            status.Text = "Invalid key"
        end
    end)

    repeat task.wait() until unlocked
end

-- ══════════════════════════════════════════════════════════
--  XENON UI
-- ══════════════════════════════════════════════════════════
local XenonLib     = loadstring(game:HttpGet("https://raw.githubusercontent.com/Xenon150/Xenon-GUI/refs/heads/main/GUI.lua"))()
local Notification = XenonLib:CreateNotification()
local Logging      = XenonLib:CreateLogger()

local isMobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local autoScale = isMobile and XenonLib.Scales.Mobile or XenonLib.Scales.Default

local window = XenonLib:CreateWindow({
    Logo             = XenonLib.GlobalLogo,
    Name             = "Xenon",
    Content          = "Raf2",
    Size             = autoScale,
    ConfigFolder     = "FloppaHubConfigs",
    Enable3DRenderer = false,
    Keybind          = "K"
})

getgenv().XenonScreenGui = XenonLib.ScreenGui

if isMobile then
    task.wait(0.2)
    window:SetSize(XenonLib.Scales.Mobile)
end

pcall(function()
    for _, v in pairs(XenonLib.ScreenGui:GetDescendants()) do
        if v:IsA("Frame") and v:FindFirstChild("pencil-square") then v.Visible = false end
        if v:IsA("TextLabel") and v.Text == "pencil-square" then
            local p = v.Parent; if p then p.Visible = false end
        end
    end
end)

if isMobile then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name         = "XenonMobileButton"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent       = game:GetService("CoreGui")

    local btn = Instance.new("TextButton")
    btn.Size                  = UDim2.new(0,60,0,60)
    btn.Position              = UDim2.new(0.5,-30,0.9,-30)
    btn.BackgroundColor3      = Color3.fromRGB(30,30,30)
    btn.BackgroundTransparency = 0.3
    btn.Text                  = "Menu"
    btn.TextColor3            = Color3.fromRGB(255,255,255)
    btn.TextSize               = 20
    btn.Font                  = Enum.Font.SourceSansBold
    btn.BorderSizePixel        = 0
    btn.Parent                = mobileGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,30)

    local dragToggle, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true; dragStart = input.Position; startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragToggle and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    btn.MouseButton1Click:Connect(function() window:ToggleInterface() end)
    getgenv().MobileButton = mobileGui
end

-- ══════════════════════════════════════════════════════════
--  ОЧИСТКА СТАРЫХ СОЕДИНЕНИЙ
-- ══════════════════════════════════════════════════════════
if getgenv().XenonConnections then
    for _, c in pairs(getgenv().XenonConnections) do pcall(function() c:Disconnect() end) end
end
getgenv().XenonConnections = {}

-- ══════════════════════════════════════════════════════════
--  WATERMARK
-- ══════════════════════════════════════════════════════════
local Watermark = window:Watermark()
local UITogg = Watermark:AddBlock("cube-vertexes", "Xenon")
UITogg:Input(function() window:ToggleInterface() end)
Watermark:AddBlock(
    isMobile and "smartphone-portrait" or "teletype",
    isMobile and "Mobile" or "PC"
)

-- ══════════════════════════════════════════════════════════
--  ВКЛАДКА: MAIN FARM
-- ══════════════════════════════════════════════════════════
local MainTab     = window:AddTab({ Icon = "home", Name = "Main Farm" })
local FarmSection = MainTab:AddSection({ Name = "AUTOMATION" })

local toggleAutoClick = FarmSection:AddLabel("Auto Click Floppa"):AddToggle({
    Default = false, Flag = "AutoClick",
    Callback = function(v) Settings.AutoClick = v end
})

local toggleAutoCollect = FarmSection:AddLabel("Auto Collect Drops"):AddToggle({
    Default = false, Flag = "AutoCollect",
    Callback = function(v) Settings.AutoCollect = v end
})

local toggleAutoBuy = FarmSection:AddLabel("Smart Auto Buy"):AddToggle({
    Default = false, Flag = "AutoBuy",
    Callback = function(v) Settings.AutoBuy = v end
})

local toggleAutoRent = FarmSection:AddLabel("Auto Rent (Roommate)"):AddToggle({
    Default = false, Flag = "AutoRent",
    Callback = function(v) Settings.AutoRent = v end
})

local toggleAutoSeeds = FarmSection:AddLabel("Auto Collect Seeds"):AddToggle({
    Default = false, Flag = "AutoSeeds",
    Callback = function(v) Settings.AutoSeeds = v end
})

-- ОПТИМИЗИРОВАННЫЙ ZERO CD ТОГГЛ
local zeroCDConnection = nil
local toggleZeroCD = FarmSection:AddLabel("0-Second Prompts"):AddToggle({
    Default = false, Flag = "ZeroCD",
    Callback = function(v)
        Settings.ZeroCD = v
        if v then
            task.spawn(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.HoldDuration > 0 then 
                        obj.HoldDuration = 0 
                    end
                end
            end)

            zeroCDConnection = workspace.DescendantAdded:Connect(function(obj)
                if Settings.ZeroCD and obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = 0
                end
            end)
            table.insert(getgenv().XenonConnections, zeroCDConnection)
        else
            if zeroCDConnection then
                zeroCDConnection:Disconnect()
                zeroCDConnection = nil
            end
        end
    end
})

local toggleCrystalTP = FarmSection:AddLabel("Auto Crystal Collect"):AddToggle({
    Default = false, Flag = "CrystalTP",
    Callback = function(v) Settings.CrystalTP = v end
})

-- ══════════════════════════════════════════════════════════
--  ВКЛАДКА: PLAYER
-- ══════════════════════════════════════════════════════════
local PlayerTab   = window:AddTab({ Icon = "person-running", Name = "Player" })
local MoveSection = PlayerTab:AddSection({ Name = "MOVEMENT" })

local forcedSpeed = 16
local forcedJump  = 50

local statsConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.WalkSpeed ~= forcedSpeed then hum.WalkSpeed = forcedSpeed end
        if hum.JumpPower  ~= forcedJump  then
            hum.UseJumpPower = true; hum.JumpPower = forcedJump
        end
    end)
end)
table.insert(getgenv().XenonConnections, statsConn)

MoveSection:AddLabel("Walk Speed"):AddSlider({
    Default = 16, Min = 16, Max = 300, Step = 1, Flag = "WalkSpeed",
    Callback = function(v) forcedSpeed = v end
})

MoveSection:AddLabel("Jump Power"):AddSlider({
    Default = 50, Min = 50, Max = 500, Step = 5, Flag = "JumpPower",
    Callback = function(v) forcedJump = v end
})

local noclipEnabled = false
local noclipConn    = nil
MoveSection:AddLabel("Noclip"):AddToggle({
    Default = false, Flag = "Noclip",
    Callback = function(v)
        noclipEnabled = v
        if v then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclipEnabled then return end
                pcall(function()
                    local char = LocalPlayer.Character; if not char then return end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end)
            end)
            table.insert(getgenv().XenonConnections, noclipConn)
        else
            if noclipConn then pcall(function() noclipConn:Disconnect() end); noclipConn = nil end
            pcall(function()
                local char = LocalPlayer.Character; if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end)
        end
    end
})

local ijConn = nil
MoveSection:AddLabel("Infinite Jump"):AddToggle({
    Default = false, Flag = "InfJump",
    Callback = function(v)
        if v then
            ijConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                pcall(function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end)
            table.insert(getgenv().XenonConnections, ijConn)
        else
            if ijConn then pcall(function() ijConn:Disconnect() end); ijConn = nil end
        end
    end
})

local flyEnabled = false
local flyConn    = nil
local flyBV, flyBG

MoveSection:AddLabel("Fly"):AddToggle({
    Default = false, Flag = "Fly",
    Callback = function(v)
        flyEnabled = v
        if v then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if not root or not hum then return end
                hum.PlatformStand = true
                flyBV = Instance.new("BodyVelocity", root)
                flyBV.Velocity = Vector3.zero
                flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
                flyBG = Instance.new("BodyGyro", root)
                flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
                flyBG.D = 100
                local UIS    = game:GetService("UserInputService")
                local Camera = workspace.CurrentCamera
                flyConn = RunService.Heartbeat:Connect(function()
                    if not flyEnabled then return end
                    local cf  = Camera.CFrame
                    local vel = Vector3.zero
                    local spd = 50
                    if UIS:IsKeyDown(Enum.KeyCode.W)         then vel = vel + cf.LookVector  * spd end
                    if UIS:IsKeyDown(Enum.KeyCode.S)         then vel = vel - cf.LookVector  * spd end
                    if UIS:IsKeyDown(Enum.KeyCode.A)         then vel = vel - cf.RightVector * spd end
                    if UIS:IsKeyDown(Enum.KeyCode.D)         then vel = vel + cf.RightVector * spd end
                    if UIS:IsKeyDown(Enum.KeyCode.Space)     then vel = vel + Vector3.new(0,spd,0)  end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0,spd,0)  end
                    if flyBV and flyBV.Parent then flyBV.Velocity = vel end
                    if flyBG and flyBG.Parent then flyBG.CFrame   = cf  end
                end)
                table.insert(getgenv().XenonConnections, flyConn)
            end)
        else
            if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
            pcall(function()
                if flyBV and flyBV.Parent then flyBV:Destroy() end
                if flyBG and flyBG.Parent then flyBG:Destroy() end
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end)
        end
    end
})

MoveSection:AddButton({
    Name = "Reset Stats", Icon = "arrow-rotate-left",
    Callback = function()
        forcedSpeed = 16; forcedJump = 50
        Logging.new("arrow-rotate-left", "Stats reset", 3)
    end
})

-- ══════════════════════════════════════════════════════════
--  ВКЛАДКА: SETTINGS
-- ══════════════════════════════════════════════════════════
local SettingsTab     = window:AddTab({ Icon = "gear", Name = "Settings" })
local SettingsSection = SettingsTab:AddSection({ Name = "GENERAL" })

local toggleAntiAFK = SettingsSection:AddLabel("Anti-AFK"):AddToggle({
    Default = true, Flag = "AntiAFK",
    Callback = function(v)
        Settings.AntiAFK = v
        Logging.new("shield", "Anti-AFK: " .. (v and "ON" or "OFF"), 3)
    end
})

-- ══════════════════════════════════════════════════════════
--  ВКЛАДКА: CONFIG
-- ══════════════════════════════════════════════════════════
local CONFIG_FOLDER = "FloppaHubConfigs"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function getCurrentData()
    return {
        AutoClick   = Settings.AutoClick,
        AutoBuy     = Settings.AutoBuy,
        AutoCollect = Settings.AutoCollect,
        AutoRent    = Settings.AutoRent,
        AutoSeeds   = Settings.AutoSeeds,
        ZeroCD      = Settings.ZeroCD,
        CrystalTP   = Settings.CrystalTP,
        AntiAFK     = Settings.AntiAFK,
    }
end

local function applyData(data, toggles)
    if not data then return end
    local map = {
        AutoClick = toggles.toggleAutoClick, AutoBuy = toggles.toggleAutoBuy,
        AutoCollect = toggles.toggleAutoCollect, AutoRent = toggles.toggleAutoRent,
        AutoSeeds = toggles.toggleAutoSeeds, ZeroCD = toggles.toggleZeroCD,
        CrystalTP = toggles.toggleCrystalTP, AntiAFK = toggles.toggleAntiAFK,
    }
    for key, toggle in pairs(map) do
        if data[key] ~= nil then toggle:SetValue(data[key]) end
    end
end

local function saveConfig(name)
    if not name or name == "" then Logging.new("triangle-exclamation", "Enter config name", 3); return end
    ensureFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(getCurrentData()) end)
    if ok then writefile(CONFIG_FOLDER .. "/" .. name .. ".json", encoded); Logging.new("folder", "Saved: " .. name, 3) end
end

local function getConfigList()
    ensureFolder()
    local list = {}
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if not ok then return list end
    for _, path in pairs(files) do
        local name = string.match(path, "([^/\\]+)%.json$")
        if name then table.insert(list, name) end
    end
    return list
end

local CfgTab     = window:AddTab({ Icon = "folder", Name = "Config" })
local CfgSection = CfgTab:AddSection({ Name = "SAVE / LOAD" })

local configNameInput = CfgSection:AddLabel("Config Name"):AddTextInput({
    Default = "", Placeholder = "Enter name...", Size = 120, Flag = "ConfigName", Callback = function() end
})

CfgSection:AddButton({
    Name = "Save Config", Icon = "arrow-down-to-line",
    Callback = function() saveConfig(configNameInput:GetValue()) end
})

local CfgListSection = CfgTab:AddSection({ Name = "CONFIGS" })

local configDropdown = CfgListSection:AddLabel("Select Config"):AddDropdown({
    Default = nil, Values = getConfigList(), AutoUpdate = true, Size = 120, Flag = "ConfigSelect", Callback = function() end
})

CfgListSection:AddButton({
    Name = "Load Selected", Icon = "arrow-right-from-portrait-rectangle",
    Callback = function()
        local name = configDropdown:GetValue()
        if not name or name == "" then Logging.new("triangle-exclamation", "Select a config", 3); return end
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if not isfile(path) then Logging.new("triangle-exclamation", "File not found", 3); return end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok or not data then Logging.new("triangle-exclamation", "Load error", 3); return end
        applyData(data, {
            toggleAutoClick = toggleAutoClick, toggleAutoBuy = toggleAutoBuy,
            toggleAutoCollect = toggleAutoCollect, toggleAutoRent = toggleAutoRent,
            toggleAutoSeeds = toggleAutoSeeds, toggleZeroCD = toggleZeroCD,
            toggleCrystalTP = toggleCrystalTP, toggleAntiAFK = toggleAntiAFK,
        })
        Logging.new("folder", "Loaded: " .. name, 3)
    end
})

CfgListSection:AddButton({
    Name = "Delete Selected", Icon = "trash-can",
    Callback = function()
        local name = configDropdown:GetValue()
        if not name or name == "" then Logging.new("triangle-exclamation", "Select a config", 3); return end
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path); configDropdown:SetValues(getConfigList()); configDropdown:SetValue(nil)
            Logging.new("trash-can", "Deleted: " .. name, 3)
        end
    end
})

CfgListSection:AddButton({
    Name = "Refresh List", Icon = "arrow-rotate-right",
    Callback = function()
        configDropdown:SetValues(getConfigList())
        Logging.new("arrow-rotate-right", "List refreshed", 2)
    end
})

window.UserSettings:AddLabel("Menu Keybind"):AddKeybind({
    Default = "K",
    Callback = function(v) window.Keybind = v; Logging.new("ps4-touchpad", "Keybind: " .. tostring(v), 5) end,
})

window.UserSettings:AddLabel("Menu Scale"):AddDropdown({
    Default = isMobile and "Mobile" or "Default",
    Values  = {"Default", "Large", "Mobile", "Small"},
    Callback = function(v) window:SetSize(XenonLib.Scales[v]); Logging.new("crop", "Scale: " .. tostring(v), 5) end,
})

-- ══════════════════════════════════════════════════════════
--  ИГРОВЫЕ ЦИКЛЫ
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoClick then
            pcall(function()
                local cd = workspace:FindFirstChild("Floppa") and workspace.Floppa:FindFirstChild("ClickDetector")
                if cd then fireclickdetector(cd) end
            end)
        end
        if Settings.AutoRent then
            pcall(function()
                local collectEvent = Events:FindFirstChild("Collect Rent")
                local raiseEvent   = Events:FindFirstChild("Raise Rent")
                if collectEvent then collectEvent:FireServer() end
                if raiseEvent   then raiseEvent:FireServer()   end
            end)
        end
        -- ЗДЕСЬ БЫЛ СТАРЫЙ ZERO CD - УДАЛЕН ДЛЯ ОПТИМИЗАЦИИ
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Settings.AutoSeeds then
            pcall(function()
                local seedsFolder = workspace:FindFirstChild("Seeds"); if not seedsFolder then return end
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
                local originalCFrame = root.CFrame
                local collectedAny   = false
                for _, seed in ipairs(seedsFolder:GetChildren()) do
                    if not Settings.AutoSeeds then break end
                    if seed.Name == "Seed" and seed:IsA("BasePart") then
                        local prompt = seed:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt and prompt.Enabled then
                            root.CFrame = seed.CFrame + Vector3.new(0,2,0); task.wait(0.2)
                            if fireproximityprompt then fireproximityprompt(prompt)
                            else prompt.HoldDuration = 0; prompt:InputHoldBegin(); task.wait(0.1); prompt:InputHoldEnd() end
                            task.wait(0.1); collectedAny = true
                        end
                    end
                end
                if collectedAny and root then root.CFrame = originalCFrame end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Settings.CrystalTP then
            pcall(function()
                local unlocks       = workspace:FindFirstChild("Unlocks")
                local wormhole      = unlocks and unlocks:FindFirstChild("Wormhole Machine")
                local crystalFolder = wormhole and (wormhole:FindFirstChild("Crystal") or wormhole:FindFirstChild("Crystals"))
                if not crystalFolder then return end
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
                local originalCFrame = root.CFrame; local collectedAny = false
                for _, obj in ipairs(crystalFolder:GetChildren()) do
                    if not Settings.CrystalTP then break end
                    local part   = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if not part then continue end
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    root.CFrame = part.CFrame + Vector3.new(0,2,0); task.wait(0.2)
                    if prompt and prompt.Enabled then
                        if fireproximityprompt then fireproximityprompt(prompt)
                        else prompt.HoldDuration = 0; prompt:InputHoldBegin(); task.wait(0.1); prompt:InputHoldEnd() end
                    else safeTouch(part) end
                    task.wait(0.1); collectedAny = true
                end
                if collectedAny and root then root.CFrame = originalCFrame end
            end)
        end
    end
end)

local dropConn = workspace.DescendantAdded:Connect(function(obj)
    if Settings.AutoCollect then task.wait(0.1); if isValidDrop(obj) then safeTouch(obj) end end
end)
table.insert(getgenv().XenonConnections, dropConn)

task.spawn(function()
    while task.wait(3) do
        if Settings.AutoCollect then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:FindFirstChildWhichIsA("TouchTransmitter") then
                        if isValidDrop(obj) then safeTouch(obj); task.wait(0.01) end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not Settings.AutoBuy then continue end
        local unlocksFolder = workspace:FindFirstChild("Unlocks"); if not unlocksFolder then continue end
        local money, gold = getWallet()
        local toBuy = {}
        for itemName, itemData in pairs(ShopData) do
            if PERMANENT_BLACKLIST[itemName] then continue end
            if not unlocksFolder:FindFirstChild(itemName) then
                local canUnlock = true
                if itemData.Requirement then
                    if not unlocksFolder:FindFirstChild(itemData.Requirement.Unlock) then canUnlock = false end
                end
                if canUnlock then
                    local isGold = itemData.Gold or false
                    local price  = itemData.Price or 0
                    if (isGold and gold >= price) or (not isGold and money >= price) then
                        table.insert(toBuy, { name = itemName, price = price })
                    end
                end
            end
        end
        table.sort(toBuy, function(a, b) return a.price < b.price end)
        for _, upgrade in ipairs(toBuy) do
            if not Settings.AutoBuy then break end
            local unlockEvent = Events:FindFirstChild("Unlock")
            if unlockEvent then unlockEvent:FireServer(upgrade.name, "the_interwebs") end
            task.wait(0.1)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--  УВЕДОМЛЕНИЕ О ЗАПУСКЕ
-- ══════════════════════════════════════════════════════════
Notification.new({
    Title    = "Xenon",
    Content  = "Loaded | " .. (isMobile and "Mobile (button added)" or "PC — press K"),
    Duration = 5,
})
