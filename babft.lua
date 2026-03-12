local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- === CONFIG VARIABLES ===
local Config = {
    AutoFarm = false,
    FlightHeight = 65,
    MinFlightTime = 15,
    TweenUpTime = 0.6,
    TweenAlignTime = 1.0,
    TweenDropTime = 0.8,
    TweenSpeed = 300,
    AntiAFK = false
}

-- === SYSTEM VARIABLES ===
local isFarming = false
local currentTween = nil
local noclipConnection = nil
local antiFallPart = nil

-- === CORE FUNCTIONS ===

local function GetChestTrigger()
    local stages = Workspace:FindFirstChild("BoatStages")
    if stages then
        local normal = stages:FindFirstChild("NormalStages")
        if normal then
            local theEnd = normal:FindFirstChild("TheEnd")
            if theEnd then
                local chest = theEnd:FindFirstChild("GoldenChest")
                if chest then
                    return chest:FindFirstChild("Trigger")
                end
            end
        end
    end
    return nil
end

local function CreateFloatPlatform(char)
    if antiFallPart then antiFallPart:Destroy() end
    antiFallPart = Instance.new("Part")
    antiFallPart.Size = Vector3.new(5, 1, 5)
    antiFallPart.Transparency = 1
    antiFallPart.Anchored = true
    antiFallPart.CanCollide = true
    antiFallPart.Parent = Workspace

    task.spawn(function()
        while Config.AutoFarm and char:FindFirstChild("HumanoidRootPart") and antiFallPart do
            antiFallPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
            task.wait()
        end
        if antiFallPart then antiFallPart:Destroy() end
    end)
end

local function EnableNoclip(char)
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if not Config.AutoFarm then
            if noclipConnection then noclipConnection:Disconnect() end
            return
        end
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function StartAutoFarm()
    task.spawn(function()
        while Config.AutoFarm do
            local char = LocalPlayer.Character
            if not char then task.wait(1) continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if not hrp or not hum or hum.Health <= 0 then
                task.wait(1)
                continue
            end

            local chestTrigger = GetChestTrigger()
            if not chestTrigger then
                task.wait(3)
                continue
            end

            isFarming = true
            EnableNoclip(char)
            CreateFloatPlatform(char)

            local function SafeTween(targetCFrame, tInfo)
                if not Config.AutoFarm or hum.Health <= 0 then return false end
                currentTween = TweenService:Create(hrp, tInfo, {CFrame = targetCFrame})
                currentTween:Play()
                currentTween.Completed:Wait()
                return Config.AutoFarm and hum.Health > 0
            end

            local targetPos = chestTrigger.Position
            
            -- 1. Up
            if not SafeTween(CFrame.new(hrp.Position.X, Config.FlightHeight, hrp.Position.Z), TweenInfo.new(Config.TweenUpTime, Enum.EasingStyle.Linear)) then break end

            -- 2. Align
            if not SafeTween(CFrame.new(targetPos.X, Config.FlightHeight, hrp.Position.Z), TweenInfo.new(Config.TweenAlignTime, Enum.EasingStyle.Linear)) then break end

            -- 3. Fly to chest
            local overChestPos = CFrame.new(targetPos.X, Config.FlightHeight, targetPos.Z)
            local distance = (hrp.Position - overChestPos.Position).Magnitude
            local timeToTween = math.max(Config.MinFlightTime, distance / Config.TweenSpeed)
            
            if not SafeTween(overChestPos, TweenInfo.new(timeToTween, Enum.EasingStyle.Linear)) then break end

            -- 4. Drop
            if antiFallPart then antiFallPart:Destroy() end
            if not SafeTween(CFrame.new(targetPos.X, targetPos.Y + 1, targetPos.Z), TweenInfo.new(Config.TweenDropTime, Enum.EasingStyle.Linear)) then break end

            -- Touch
            if firetouchinterest then
                firetouchinterest(hrp, chestTrigger, 0)
                task.wait(0.1)
                firetouchinterest(hrp, chestTrigger, 1)
            end

            if noclipConnection then noclipConnection:Disconnect() end

            -- Wait for respawn
            local waitTimer = 0
            while waitTimer < 30 and Config.AutoFarm do
                task.wait(1)
                waitTimer = waitTimer + 1
                local newChar = LocalPlayer.Character
                if newChar and newChar ~= char and newChar:FindFirstChild("HumanoidRootPart") then
                    if newChar:FindFirstChild("Humanoid") and newChar.Humanoid.Health > 0 then break end
                end
            end
            task.wait(2)
            isFarming = false
        end
    end)
end

local function StopAutoFarm()
    Config.AutoFarm = false
    isFarming = false
    if currentTween then currentTween:Cancel() end
    if noclipConnection then noclipConnection:Disconnect() end
    if antiFallPart then antiFallPart:Destroy() end
end

-- === SPECTRE THEME ===
WindUI:AddTheme({
    Name = "SpectreTheme",
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#8b5cf6"), Transparency = 0 }, -- Violet 500
        ["100"] = { Color = Color3.fromHex("#5b21b6"), Transparency = 0 } -- Violet 800
    }, { Rotation = 45 }),
    Outline = Color3.fromHex("#2e2a36"),
    Text = Color3.fromHex("#f8fafc"),
    Placeholder = Color3.fromHex("#94a3b8"),
    Background = Color3.fromHex("#0f0c16"), 
    Button = Color3.fromHex("#1e1a29"),
    Icon = Color3.fromHex("#c4b5fd"),
})
WindUI:SetTheme("SpectreTheme")

-- === WIND UI SETUP ===
local Window = WindUI:CreateWindow({
    Title = "SpectreWare | BABFT",
    Icon = "ship",
    Author = "Tiger",
    Folder = "SpectreBABFT",
    Size = UDim2.fromOffset(500, 420),
    Transparent = true,
    Theme = "SpectreTheme",
    SideBarWidth = 160,
    OpenButton = {
        Title = "SpectreWare",
        Icon = "sparkles",
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 1,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#8b5cf6")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#5b21b6"))
        })
    }
})

pcall(function()
    Window:EditOpenButton({
        Title = "SpectreWare",
        Icon = "sparkles",
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#8b5cf6")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#5b21b6"))
        })
    })
end)

local Tabs = {
    Home = Window:Tab({ Title = "Main", Icon = "house" }),
    Farm = Window:Tab({ Title = "Config", Icon = "wrench" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- == HOME TAB ==
local HomeSec = Tabs.Home:Section({ Title = "Welcome to SpectreWare", Opened = true })
HomeSec:Paragraph({
    Title = "SpectreWare | BABFT",
    Desc = "Advanced automatic gold farming for Build A Boat For Treasure. Enjoy the luxury of automated wealth."
})

HomeSec:Toggle({
    Flag = "Tgl_AutoFarm",
    Title = "⚡ Start Auto Farm",
    Desc = "Start the tween farming loop.",
    Default = false,
    Callback = function(state)
        Config.AutoFarm = state
        if state then StartAutoFarm() else StopAutoFarm() end
    end
})

-- == FARM TAB ==
local FarmSec = Tabs.Farm:Section({ Title = "Farm Settings", Opened = true })

FarmSec:Slider({ 
    Flag = "Sld_TweenSpeed",
    Title = "Tween Speed", 
    Desc = "Speed of flight (Safety cap applies).",
    Step = 10, 
    Value = {Min = 100, Max = 500, Default = 300}, 
    Callback = function(v) Config.TweenSpeed = v end 
})

FarmSec:Slider({ 
    Flag = "Sld_FlightHeight",
    Title = "Flight Height", 
    Desc = "Height during flight (65 is recommended).",
    Step = 5, 
    Value = {Min = 40, Max = 150, Default = 65}, 
    Callback = function(v) Config.FlightHeight = v end 
})

-- == SETTINGS TAB ==
local MiscSec = Tabs.Settings:Section({ Title = "Misc Features", Opened = true })

MiscSec:Toggle({
    Flag = "Tgl_AntiAFK",
    Title = "Anti-AFK",
    Desc = "Prevent idle kick.",
    Default = false,
    Callback = function(state)
        Config.AntiAFK = state
        if state then
            pcall(function()
                if not getgenv().AntiAFKConnection then
                    getgenv().AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                        if Config.AntiAFK then
                            local VirtualUser = game:GetService("VirtualUser")
                            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                            task.wait(1)
                            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        end
                    end)
                end
            end)
        end
    end
})

local UISec = Tabs.Settings:Section({ Title = "UI Options", Opened = true })
UISec:Keybind({ 
    Flag = "Key_ToggleMenu",
    Title = "Toggle UI Key", 
    Value = "LeftControl", 
    Callback = function(k) 
        if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[k] or Enum.KeyCode.LeftControl) end 
    end 
})

local AvailableThemes = {}
for themeName, _ in pairs(WindUI.Themes) do table.insert(AvailableThemes, themeName) end
if not table.find(AvailableThemes, "SpectreTheme") then table.insert(AvailableThemes, "SpectreTheme") end

UISec:Dropdown({
    Flag = "Drop_Theme",
    Title = "UI Theme",
    Desc = "Change the visual style of the interface.",
    Values = AvailableThemes,
    Value = "SpectreTheme",
    Callback = function(t) pcall(function() WindUI:SetTheme(t) end) end
})

Window:SelectTab(1)
WindUI:Notify({ Title = "SpectreWare", Content = "Loaded BABFT Farm!", Duration = 3 })

-- === System Settings (Auto Save/Load) ===
local ConfigManager = Window.ConfigManager
if ConfigManager then
    pcall(function()
        Window.CurrentConfig = ConfigManager:CreateConfig("SpectreBABFTConfig")
        Window.CurrentConfig:Load()
        task.spawn(function()
            while task.wait(3) do
                pcall(function() if Window.CurrentConfig then Window.CurrentConfig:Save() end end)
            end
        end)
    end)
end
