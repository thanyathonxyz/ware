local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ===== SPECTRE THEME =====
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

local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes", 10)

-- === HELPER: EquipBestCards ===
local cachedSlotController = nil
local function EquipBestCards()
    if not cachedSlotController then
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("ModuleScript") and v.Name == "SlotController" then
                cachedSlotController = v
                break
            end
        end
    end
    if cachedSlotController then
        pcall(function() require(cachedSlotController).equipBestCards() end)
    end
end

-- === CONFIG VARIABLES ===
local Config = {
    SmartAuto = false,
    LoopDelay = 1,
    SlotAmount = 10,
    AutoCollect = false,
    AutoClaimGems = false,
    AutoEquipBest = false,
    AutoRebirth = false,
    SelectedPacks = {["Gold"] = true},
    AutoBuyPack = false,
    AutoOpenPack = false,
    AntiAFK = false
}

-- Check if individual feature or SmartAuto is enabled
local function isOn(key)
    return Config.SmartAuto or Config[key]
end

-- === WIND UI SETUP ===
local Window = WindUI:CreateWindow({
    Title = "SpectreWare | Spin A Soccer",
    Icon = "sparkles", 
    Author = "Tiger",
    Folder = "SpectreSpinAS_Config",
    Size = UDim2.fromOffset(600, 480),
    Transparent = true,
    Theme = "SpectreTheme",
    SideBarWidth = 180,
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
    Home = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Farm = Window:Tab({ Title = "Automation", Icon = "zap" }),
    Packs = Window:Tab({ Title = "Packs & Crates", Icon = "package-open" }),
    Sell = Window:Tab({ Title = "Auto Sell", Icon = "trash-2" }),
    Misc = Window:Tab({ Title = "Local Player", Icon = "user-cog" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- == HOME TAB ==
local HomeSec = Tabs.Home:Section({ Title = "Welcome to SpectreWare", Opened = true })

HomeSec:Paragraph({
    Title = "Welcome to SpectreWare",
    Desc = "If you encounter any bugs or problems, you can contact us on Discord."
})

local SmartAutoSec = Tabs.Home:Section({ Title = "Quick Start", Opened = true })

SmartAutoSec:Toggle({
    Flag = "Tgl_SmartAuto",
    Title = "⚡ Smart Auto (All-in-One)",
    Desc = "Automatically Collect Slots, Claim Gems, Buy & Open Packs, Equip cards, and Rebirth in one click.",
    Default = false,
    Callback = function(state) 
        Config.SmartAuto = state 
        if state then
            WindUI:Notify({ Title = "Smart Auto", Content = "All-in-One automation enabled!", Duration = 3 })
        end
    end
})

-- == FARM TAB ==
local FarmSec = Tabs.Farm:Section({ Title = "Core Automation", Opened = true })

FarmSec:Toggle({ 
    Flag = "Tgl_AutoCollect", 
    Title = "Auto Collect Slots", 
    Desc = "Continuously collect spins from slots.",
    Default = false, 
    Callback = function(s) Config.AutoCollect = s end 
})
FarmSec:Toggle({ 
    Flag = "Tgl_AutoClaimGems", 
    Title = "Auto Claim Gems", 
    Desc = "Automatically collect gems from the index.",
    Default = false, 
    Callback = function(s) Config.AutoClaimGems = s end 
})
FarmSec:Toggle({ 
    Flag = "Tgl_AutoEquipBest", 
    Title = "Auto Equip Best", 
    Desc = "Always equip the highest stat cards actively.",
    Default = false, 
    Callback = function(s) Config.AutoEquipBest = s end 
})
FarmSec:Toggle({ 
    Flag = "Tgl_AutoRebirth", 
    Title = "Auto Rebirth", 
    Desc = "Instantly rebirth when requirements are met.",
    Default = false, 
    Callback = function(s) Config.AutoRebirth = s end 
})

local DelaySec = Tabs.Farm:Section({ Title = "Performance Settings", Opened = true })
DelaySec:Slider({ 
    Flag = "Sld_LoopDelay", 
    Title = "Automation Loop Delay", 
    Desc = "Speed of the background tasks (Lower = Faster).",
    Step = 0.5, 
    Value = {Min = 0.5, Max = 5, Default = 1}, 
    Callback = function(v) Config.LoopDelay = v end 
})
DelaySec:Slider({ 
    Flag = "Sld_SlotAmount", 
    Title = "Slots Target Amount", 
    Desc = "Number of slots to cycle through when collecting.",
    Step = 1, 
    Value = {Min = 1, Max = 50, Default = 10}, 
    Callback = function(v) Config.SlotAmount = v end 
})

local ActionSec = Tabs.Farm:Section({ Title = "Quick Actions", Opened = false })
ActionSec:Button({ 
    Title = "Collect Slots Once", 
    Desc = "Manually trigger slot collection.",
    Callback = function()
        for i = 1, Config.SlotAmount do
            if Remotes and Remotes:FindFirstChild("CollectSlot") then
                pcall(function() Remotes.CollectSlot:FireServer(i) end)
            end
            task.wait(0.1)
        end
        WindUI:Notify({ Title = "Action", Content = "Collected Slots Manually", Duration = 2 })
    end 
})
ActionSec:Button({ 
    Title = "Claim Gems Once", 
    Desc = "Manually claim all index gems.",
    Callback = function() 
        if Remotes and Remotes:FindFirstChild("ClaimAllIndexGems") then
            pcall(function() Remotes.ClaimAllIndexGems:FireServer() end) 
            WindUI:Notify({ Title = "Action", Content = "Claimed All Gems", Duration = 2 })
        end
    end 
})
ActionSec:Button({ 
    Title = "Equip Best Cards", 
    Desc = "Manually equip your strongest team.",
    Callback = function() 
        EquipBestCards() 
        WindUI:Notify({ Title = "Action", Content = "Equipped Best Cards", Duration = 2 })
    end 
})
ActionSec:Button({ 
    Title = "Rebirth Instantly", 
    Desc = "Force rebirth if you have enough cash.",
    Callback = function() 
        if Remotes and Remotes:FindFirstChild("Rebirth") then
            pcall(function() Remotes.Rebirth:FireServer() end) 
            WindUI:Notify({ Title = "Action", Content = "Attempted Rebirth", Duration = 2 })
        end
    end 
})

-- == PACKS TAB ==
local PackSec = Tabs.Packs:Section({ Title = "Packs Configuration", Opened = true })

PackSec:Dropdown({
    Flag = "Drop_SelectPacks",
    Title = "Select Target Packs",
    Desc = "Choose which packs to buy and open.",
    Values = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Legendary", "Toxic", "Shadow", "Infernal", "Corrupted", "Cosmic", "Eclipse", "Hades", "Heaven"},
    Value = {"Gold"},
    Multi = true,
    Callback = function(selected)
        local newSelections = {}
        if type(selected) == "table" then
            for _, pack in ipairs(selected) do
                newSelections[pack] = true
            end
        elseif type(selected) == "string" then
            newSelections[selected] = true
        end
        Config.SelectedPacks = newSelections
    end
})

PackSec:Toggle({ 
    Flag = "Tgl_AutoBuyPack", 
    Title = "Auto Buy Selected Packs", 
    Desc = "Continuously spend cash on chosen packs.",
    Default = false, 
    Callback = function(s) Config.AutoBuyPack = s end 
})
PackSec:Toggle({ 
    Flag = "Tgl_AutoOpenPack", 
    Title = "Auto Open Selected Packs", 
    Desc = "Continuously open purchased packs.",
    Default = false, 
    Callback = function(s) Config.AutoOpenPack = s end 
})

local PackManualSec = Tabs.Packs:Section({ Title = "Manual Management", Opened = false })
PackManualSec:Button({ 
    Title = "Buy Selected Packs Once", 
    Callback = function()
        local bought = 0
        for pack, on in pairs(Config.SelectedPacks) do
            if on and Remotes and Remotes:FindFirstChild("BuyPack") then 
                pcall(function() Remotes.BuyPack:FireServer(pack) end) 
                bought += 1
            end
        end
        WindUI:Notify({ Title = "Packs", Content = "Bought " .. tostring(bought) .. " selected packs.", Duration = 2 })
    end 
})
PackManualSec:Button({ 
    Title = "Open Selected Packs Once", 
    Callback = function()
        local opened = 0
        for pack, on in pairs(Config.SelectedPacks) do
            if on and Remotes and Remotes:FindFirstChild("OpenPack") then 
                pcall(function() Remotes.OpenPack:FireServer(pack) end) 
                opened += 1
            end
        end
        WindUI:Notify({ Title = "Packs", Content = "Opened " .. tostring(opened) .. " selected packs.", Duration = 2 })
    end 
})

-- == SELL TAB ==
local SellSec = Tabs.Sell:Section({ Title = "Auto Sell Filter", Opened = true })

SellSec:Paragraph({
    Title = "How auto sell works",
    Desc = "Enable the rarities you want to instantly sell when obtained to keep your inventory clean."
})

local SellRarities = {
    "Bronze", "Silver", "Gold", "Legendary", "Mythic", 
    "Azure Zenith", "Crimson Zenith", "Divine", "Primordial", 
    "Oblivion", "Eternity"
}

for _, rarity in ipairs(SellRarities) do
    SellSec:Toggle({
        Flag = "Tgl_AutoSell_" .. string.gsub(rarity, " ", ""),
        Title = "Sell " .. rarity .. " Cards",
        Default = false,
        Callback = function(state)
            if Remotes and Remotes:FindFirstChild("UpdateAutoSell") then
                pcall(function()
                    Remotes.UpdateAutoSell:FireServer(rarity, state)
                end)
            end
        end
    })
end

-- == BACKGROUND LOOP ==
task.spawn(function()
    while true do
        task.wait(Config.LoopDelay)

        -- 1. Collect Slots
        if isOn("AutoCollect") then
            for i = 1, Config.SlotAmount do
                if not isOn("AutoCollect") then break end
                if Remotes and Remotes:FindFirstChild("CollectSlot") then
                    pcall(function() Remotes.CollectSlot:FireServer(i) end)
                end
                task.wait(0.1)
            end
        end

        -- 2. Claim Gems
        if isOn("AutoClaimGems") and Remotes and Remotes:FindFirstChild("ClaimAllIndexGems") then
            pcall(function() Remotes.ClaimAllIndexGems:FireServer() end)
        end

        -- 3. Buy Packs
        if isOn("AutoBuyPack") and Remotes and Remotes:FindFirstChild("BuyPack") then
            for pack, on in pairs(Config.SelectedPacks) do
                if on then pcall(function() Remotes.BuyPack:FireServer(pack) end) end
            end
        end

        -- 4. Open Packs
        if isOn("AutoOpenPack") and Remotes and Remotes:FindFirstChild("OpenPack") then
            for pack, on in pairs(Config.SelectedPacks) do
                if on then pcall(function() Remotes.OpenPack:FireServer(pack) end) end
            end
        end

        -- 5. Equip Best
        if isOn("AutoEquipBest") then
            EquipBestCards()
        end

        -- 6. Rebirth
        if isOn("AutoRebirth") and Remotes and Remotes:FindFirstChild("Rebirth") then
            pcall(function() Remotes.Rebirth:FireServer() end)
        end
    end
end)

-- == MISC TAB ==
local MiscSec = Tabs.Misc:Section({ Title = "Player Modifications", Opened = true })

MiscSec:Toggle({
    Flag = "Tgl_AntiAFK",
    Title = "Anti-AFK",
    Desc = "Prevents getting kicked for being idle (20 mins by Roblox).",
    Default = false,
    Callback = function(state)
        Config.AntiAFK = state
        if state then
            pcall(function()
                if not getgenv().AntiAFKConnection then
                    local LocalPlayer = game:GetService("Players").LocalPlayer
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

MiscSec:Slider({ 
    Flag = "Sld_WalkSpeed",
    Title = "WalkSpeed Override", 
    Desc = "Change your character's run speed.",
    Step = 1, 
    Value = {Min = 16, Max = 150, Default = 16}, 
    Callback = function(v) 
        pcall(function() game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v end) 
    end 
})

MiscSec:Slider({ 
    Flag = "Sld_JumpPower",
    Title = "JumpPower Override", 
    Desc = "Change your character's jump height.",
    Step = 1, 
    Value = {Min = 50, Max = 500, Default = 50}, 
    Callback = function(v) 
        pcall(function() game.Players.LocalPlayer.Character.Humanoid.JumpPower = v end) 
    end 
})

-- == SETTINGS TAB ==
local UISec = Tabs.Settings:Section({ Title = "UI Options", Opened = true })

UISec:Keybind({ 
    Flag = "Keybind_ToggleMenu",
    Title = "Toggle Menu Key", 
    Desc = "Hide or show the UI.",
    Value = "LeftControl", 
    Callback = function(k) 
        if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[k] or Enum.KeyCode.LeftControl) end 
    end 
})



local AvailableThemes = {}
for themeName, _ in pairs(WindUI.Themes) do
    table.insert(AvailableThemes, themeName)
end
if not table.find(AvailableThemes, "SpectreTheme") then
    table.insert(AvailableThemes, "SpectreTheme")
end

UISec:Dropdown({
    Flag = "Drop_Theme",
    Title = "Select Interface Theme",
    Desc = "Change the color palette of the menu.",
    Values = AvailableThemes,
    Value = "SpectreTheme",
    Callback = function(themeName)
        pcall(function() WindUI:SetTheme(themeName) end)
    end
})

Tabs.Home:Select()
WindUI:Notify({ Title = "SpectreWare Loaded", Content = "Injected successfully with SpectreTheme!", Duration = 5 })

-- ===== System Settings (Auto Save/Load) =====

local ConfigManager = Window.ConfigManager
if ConfigManager then
    pcall(function()
        Window.CurrentConfig = ConfigManager:CreateConfig("SpectreSpinAS_Config")
        Window.CurrentConfig:Load()

        task.spawn(function()
            while task.wait(3) do
                pcall(function()
                    if Window.CurrentConfig then
                        Window.CurrentConfig:Save()
                    end
                end)
            end
        end)
    end)
end
