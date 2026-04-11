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

if not Remotes then
    warn("SpectreWare: Remotes folder not found in ReplicatedStorage!")
else
    print("SpectreWare: Remotes folder found.")
end

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
    AntiAFK = false,
    AutoSpinWheel = false,
    AutoClaimFreeWheel = false,
    AutoCraftItems = {},
    AutoBuyGemItems = {}
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
    Spin = Window:Tab({ Title = "Spin Wheel", Icon = "refresh-cw" }),
    Craft = Window:Tab({ Title = "Craft Shop", Icon = "hammer" }),
    GemShop = Window:Tab({ Title = "Gem Shop", Icon = "gem" }),
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

-- == SPIN TAB ==
local SpinSec = Tabs.Spin:Section({ Title = "Spin Wheel Automation", Opened = true })

SpinSec:Toggle({ 
    Flag = "Tgl_AutoSpinWheel", 
    Title = "Auto Spin Wheel", 
    Desc = "Continuously spin the wheel.",
    Default = false, 
    Callback = function(s) Config.AutoSpinWheel = s end 
})

SpinSec:Toggle({ 
    Flag = "Tgl_AutoClaimFreeWheel", 
    Title = "Auto Claim Free Wheel", 
    Desc = "Automatically claim free wheel spins.",
    Default = false, 
    Callback = function(s) Config.AutoClaimFreeWheel = s end 
})

local SpinManualSec = Tabs.Spin:Section({ Title = "Manual Actions", Opened = true })

SpinManualSec:Button({ 
    Title = "Spin Wheel Once", 
    Desc = "Manually spin the wheel.",
    Callback = function() 
        pcall(function()
            local args = { "spin" }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpinWheel"):FireServer(unpack(args))
        end)
    end 
})

SpinManualSec:Button({ 
    Title = "Claim Free Spin Once", 
    Desc = "Manually claim free wheel spin.",
    Callback = function() 
        pcall(function()
            local args = { "claim_free" }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpinWheel"):FireServer(unpack(args))
        end)
    end 
})

-- == CRAFT SHOP TAB ==
local CraftSec = Tabs.Craft:Section({ Title = "Auto Crafting", Opened = true })

CraftSec:Paragraph({
    Title = "Crafting Automation",
    Desc = "Automatically craft your desired items. New shop items will be detected automatically in the background."
})

local CraftableItemsList = {"Golden Boot", "Champions League", "Ballon d'Or", "Eternal Crown"}

for _, itemName in ipairs(CraftableItemsList) do
    CraftSec:Toggle({
        Flag = "Tgl_Craft_" .. string.gsub(itemName, " ", ""),
        Title = "Auto Craft: " .. itemName,
        Desc = "Automatically crafts " .. itemName .. " when possible.",
        Default = false,
        Callback = function(state)
            Config.AutoCraftItems[itemName] = state
        end
    })
end

local CraftManualSec = Tabs.Craft:Section({ Title = "Manual Actions", Opened = false })

for _, itemName in ipairs(CraftableItemsList) do
    CraftManualSec:Button({
        Title = "Craft " .. itemName .. " Once",
        Desc = "Manually craft one " .. itemName .. ".",
        Callback = function()
            if Remotes and Remotes:FindFirstChild("CraftTrophy") then
                pcall(function() Remotes.CraftTrophy:FireServer(itemName) end)
                WindUI:Notify({ Title = "Crafting", Content = "Attempted to craft: " .. itemName, Duration = 2 })
            end
        end
    })
end

-- Silent Background Scanner for new items
task.spawn(function()
    while true do
        task.wait(10) -- Scan every 10 seconds
        pcall(function()
            local scrollFrame = game:GetService("Players").LocalPlayer.PlayerGui.CraftShop.Frame.Items.ScrollingFrame
            for _, item in ipairs(scrollFrame:GetChildren()) do
                if item:IsA("Frame") and item:FindFirstChild("PurchaseSection") then
                    if not table.find(CraftableItemsList, item.Name) then
                        table.insert(CraftableItemsList, item.Name)
                        -- New item found, the background loop will now handle it if it's in Config.AutoCraftItems
                    end
                end
            end
        end)
    end
end)

-- == GEM SHOP TAB ==
local GemSec = Tabs.GemShop:Section({ Title = "Auto Gem Shop", Opened = true })

GemSec:Paragraph({
    Title = "Gem Shop Automation",
    Desc = "Automatically purchase your desired items using Gems from the Gem Shop."
})

local GemShopItemsList = {
    {Id = "AutoEquipBest", Display = "Auto Equip Best"},
    {Id = "AutoSkip", Display = "Auto Skip"},
    {Id = "ExtraBankSlots", Display = "Extra Bank Slots"},
    {Id = "Inventory500", Display = "Inventory +500"}
}

for _, item in ipairs(GemShopItemsList) do
    GemSec:Toggle({
        Flag = "Tgl_Gem_" .. item.Id,
        Title = "Auto Buy: " .. item.Display,
        Desc = "Automatically buy " .. item.Display .. " when it is affordable.",
        Default = false,
        Callback = function(state)
            Config.AutoBuyGemItems[item.Id] = state
        end
    })
end

GemSec:Toggle({
    Flag = "Tgl_Gem_LuckyItem",
    Title = "Auto Buy: Today's Lucky Item",
    Desc = "Automatically checks the rotating lucky item in the shop and buys it.",
    Default = false,
    Callback = function(state)
        Config.AutoBuyGemItems["LuckyItem"] = state
    end
})

local GemManualSec = Tabs.GemShop:Section({ Title = "Manual Actions", Opened = false })

for _, item in ipairs(GemShopItemsList) do
    GemManualSec:Button({
        Title = "Buy " .. item.Display .. " Once",
        Desc = "Manually buy one " .. item.Display .. ".",
        Callback = function()
            print("SpectreWare: Attempting to buy " .. item.Id)
            local targetRemote = Remotes:FindFirstChild("BuyGemShopItem")
            if targetRemote then
                local success, err = pcall(function()
                    targetRemote:FireServer(item.Id)
                end)
                if success then
                    print("SpectreWare: Successfully fired BuyGemShopItem for " .. item.Id)
                    WindUI:Notify({ Title = "Gem Shop", Content = "Attempted to buy: " .. item.Display, Duration = 2 })
                else
                    warn("SpectreWare: Error firing remote: " .. tostring(err))
                end
            else
                warn("SpectreWare: BuyGemShopItem remote not found in Remotes folder!")
                WindUI:Notify({ Title = "Error", Content = "BuyGemShopItem remote not found!", Duration = 3 })
            end
        end
    })
end

GemManualSec:Button({
    Title = "Buy Today's Lucky Item Once",
    Desc = "Reads the current lucky item name from the GUI and buys it.",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("BuyGemShopItem") then
            local fired = false
            pcall(function()
                local pgui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 2)
                local itemName = pgui.GemShop.Frame.Main.ScrollingFrame.LuckyItem.Item.Title.Text
                if itemName and itemName ~= "" then
                    Remotes.BuyGemShopItem:FireServer(itemName)
                    WindUI:Notify({ Title = "Gem Shop", Content = "Attempted to buy Lucky Item: " .. itemName, Duration = 2 })
                    fired = true
                end
            end)
            
            if not fired then
                WindUI:Notify({ Title = "Gem Shop Error", Content = "Could not find the UI elements! Please open the Gem Shop manually first so the game loads the item names.", Duration = 4 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "BuyGemShopItem remote not found!", Duration = 3 })
        end
    end
})

-- == PACKS TAB ==
local PackSec = Tabs.Packs:Section({ Title = "Packs Configuration", Opened = true })

local FullPackList = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Legendary", "Toxic", "Shadow", "Infernal", "Corrupted", "Cosmic", "Eclipse", "Hades", "Heaven", "Chaos", "Ordain", "Alpha", "Omega", "Genesis", "Abyssal", "Enigma","Oracle","Wither","Bloom"}

PackSec:Dropdown({
    Flag = "Drop_SelectPacks",
    Title = "Select Target Packs",
    Desc = "Choose which packs to buy and open.",
    Values = FullPackList,
    Value = {"Gold"},
    Multi = true,
    Callback = function(selected)
        local newSelections = {}
        if type(selected) == "table" then
            for _, pack in ipairs(selected) do newSelections[pack] = true end
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

        -- 7. Spin Wheel
        if isOn("AutoSpinWheel") then
            pcall(function()
                local args = { "spin" }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpinWheel"):FireServer(unpack(args))
            end)
        end

        -- 8. Claim Free Wheel
        if isOn("AutoClaimFreeWheel") then
            pcall(function()
                local args = { "claim_free" }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpinWheel"):FireServer(unpack(args))
            end)
        end

        -- 9. Auto Craft via Remote
        if Remotes and Remotes:FindFirstChild("CraftTrophy") then
            for itemName, isCrafting in pairs(Config.AutoCraftItems) do
                if isCrafting then
                    pcall(function()
                        Remotes.CraftTrophy:FireServer(itemName)
                    end)
                end
            end
        end

        -- 10. Auto Buy Gem Shop Items
        if Remotes and Remotes:FindFirstChild("BuyGemShopItem") then
            -- 10.1 Static Items
            local gemItems = {
                {Id = "AutoEquipBest", Display = "Auto Equip Best"},
                {Id = "AutoSkip", Display = "Auto Skip"},
                {Id = "ExtraBankSlots", Display = "Extra Bank Slots"},
                {Id = "Inventory500", Display = "Inventory +500"}
            }
            for _, item in ipairs(gemItems) do
                if Config.AutoBuyGemItems[item.Id] then
                    pcall(function()
                        Remotes.BuyGemShopItem:FireServer(item.Id)
                    end)
                end
            end

            -- 10.2 Dynamic Lucky Item
            if Config.AutoBuyGemItems["LuckyItem"] then
                pcall(function()
                    local targetText = game:GetService("Players").LocalPlayer.PlayerGui.GemShop.Frame.Main.ScrollingFrame.LuckyItem.Item.Title.Text
                    if targetText and targetText ~= "" then
                        Remotes.BuyGemShopItem:FireServer(targetText)
                    end
                end)
            end
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
