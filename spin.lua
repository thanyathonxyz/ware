local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Player = game:GetService("Players").LocalPlayer
local PlayerName = Player and Player.DisplayName or "Player"

local Window = Rayfield:CreateWindow({
   Name = "SpectreWare | Spin A Soccer Card",
   Icon = 0,
   LoadingTitle = "SpectreWare Loading...",
   LoadingSubtitle = "by Tiger",
   Theme = "Default", 
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SpectreWare",
      FileName = "Rayfield_Config_V2"
   },
   KeybindOptions = {
      Keybind = "LeftControl",
      UIBuild = false,
      UIBuildText = "Toggle UI"
   },
   ToggleUIKeybind = Enum.KeyCode.LeftControl
})

local HomeTab = Window:CreateTab("Home", "home")
local FarmTab = Window:CreateTab("Farm", "leaf")
local PacksTab = Window:CreateTab("Packs", "package")

local Options = {
    LoopDelay = 1,
    SlotAmount = 10,
    SmartAuto = false,
    AutoCollect = false,
    AutoClaimGems = false,
    AutoEquipBest = false,
    AutoRebirth = false,
    AutoBuyPack = false,
    AutoOpenPack = false,
    SelectedPacks = {"Gold"}
}

local function isOn(key)
    return Options.SmartAuto or Options[key]
end

local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
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

local function claimGems() pcall(function() Remotes:WaitForChild("ClaimAllIndexGems"):FireServer() end) end
local function doRebirth() pcall(function() Remotes:WaitForChild("Rebirth"):FireServer() end) end
local function buyPack(pack) pcall(function() Remotes:WaitForChild("BuyPack"):FireServer(pack) end) end
local function openPack(pack) pcall(function() Remotes:WaitForChild("OpenPack"):FireServer(pack) end) end

-- ============================================================
-- TAB: HOME
-- ============================================================
HomeTab:CreateParagraph({
    Title = "Welcome, " .. PlayerName .. "!.👋", 
    Content = ""
})

HomeTab:CreateToggle({
   Name = "Smart Auto (All-in-One)",
   CurrentValue = false,
   Flag = "SmartAuto",
   Save = true,
   Callback = function(Value)
        Options.SmartAuto = Value
        if Value then 
            Rayfield:Notify({Title = "Smart Auto Activated", Content = "The system is running completely automated.", Duration = 3}) 
        end
   end,
})

-- ============================================================
-- TAB: FARM
-- ============================================================
FarmTab:CreateSection("Settings")

FarmTab:CreateSlider({
   Name = "Loop Delay (Seconds)",
   Range = {0.5, 5},
   Increment = 0.5,
   Suffix = "s",
   CurrentValue = 1,
   Flag = "LoopDelay",
   Save = true,
   Callback = function(Value) Options.LoopDelay = Value end,
})

FarmTab:CreateSlider({
   Name = "Slot Amount",
   Range = {1, 50},
   Increment = 1,
   Suffix = " slots",
   CurrentValue = 10,
   Flag = "SlotAmount",
   Save = true,
   Callback = function(Value) Options.SlotAmount = Value end,
})

FarmTab:CreateSection("Action Toggles")
FarmTab:CreateToggle({ Name = "Auto Collect Slots", CurrentValue = false, Flag = "AutoCollect", Save = true, Callback = function(Value) Options.AutoCollect = Value end})
FarmTab:CreateToggle({ Name = "Auto Claim Gems", CurrentValue = false, Flag = "AutoClaimGems", Save = true, Callback = function(Value) Options.AutoClaimGems = Value end})
FarmTab:CreateToggle({ Name = "Auto Equip Best", CurrentValue = false, Flag = "AutoEquipBest", Save = true, Callback = function(Value) Options.AutoEquipBest = Value end})
FarmTab:CreateToggle({ Name = "Auto Rebirth", CurrentValue = false, Flag = "AutoRebirth", Save = true, Callback = function(Value) Options.AutoRebirth = Value end})

FarmTab:CreateSection("Manual Actions")
FarmTab:CreateButton({ Name = "Collect Slots (Once)", Callback = function()
    for i = 1, Options.SlotAmount do RS.Remotes.CollectSlot:FireServer(i) task.wait(0.1) end
    Rayfield:Notify({Title = "Success", Content = "Collected items from slots.", Duration = 2})
end})
FarmTab:CreateButton({ Name = "Claim Gems (Once)", Callback = function() claimGems() Rayfield:Notify({Title = "Success", Content = "Claimed gems.", Duration = 2}) end})
FarmTab:CreateButton({ Name = "Equip Best (Once)", Callback = function() EquipBestCards() Rayfield:Notify({Title = "Success", Content = "Equipped best cards.", Duration = 2}) end})
FarmTab:CreateButton({ Name = "Rebirth (Once)", Callback = function() doRebirth() Rayfield:Notify({Title = "Success", Content = "Rebirth requested.", Duration = 2}) end})


-- ============================================================
-- TAB: PACKS
-- ============================================================
PacksTab:CreateSection("Pack Selection")

PacksTab:CreateDropdown({
   Name = "Select Packs (Multi-Select)",
   Options = {"Bronze", "Silver", "Gold", "Platinum", "Diamond", "Legendary", "Toxic", "Shadow", "Infernal", "Corrupted", "Cosmic", "Eclipse", "Hades", "Heaven"},
   CurrentOption = {"Gold"},
   MultipleOptions = true,
   Flag = "PackDropdown",
   Save = true,
   Callback = function(OptionsArray)
        Options.SelectedPacks = OptionsArray
   end,
})

PacksTab:CreateSection("Pack Toggles")
PacksTab:CreateToggle({ Name = "Auto Buy Pack", CurrentValue = false, Flag = "AutoBuyPack", Save = true, Callback = function(Value) Options.AutoBuyPack = Value end})
PacksTab:CreateToggle({ Name = "Auto Open Pack", CurrentValue = false, Flag = "AutoOpenPack", Save = true, Callback = function(Value) Options.AutoOpenPack = Value end})

PacksTab:CreateSection("Manual Packs")
PacksTab:CreateButton({ Name = "Buy Selected (Once)", Callback = function()
    for _, pack in ipairs(Options.SelectedPacks) do buyPack(pack) end
    Rayfield:Notify({Title = "Package", Content = "Bought selected packages!", Duration = 2})
end})

PacksTab:CreateButton({ Name = "Open Selected (Once)", Callback = function()
    for _, pack in ipairs(Options.SelectedPacks) do openPack(pack) end
    Rayfield:Notify({Title = "Package", Content = "Opened selected packages!", Duration = 2})
end})

-- ============================================================
-- CORE LOOP (Background Worker)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(Options.LoopDelay)

        -- 1. Slots
        if isOn("AutoCollect") then
            for i = 1, Options.SlotAmount do
                if not isOn("AutoCollect") then break end
                RS.Remotes.CollectSlot:FireServer(i)
                task.wait(0.1)
            end
        end

        -- 2. Gems
        if isOn("AutoClaimGems") then claimGems() end
        
        -- 3. Buy/Open
        if isOn("AutoBuyPack") then
            for _, pack in ipairs(Options.SelectedPacks) do buyPack(pack) end
        end
        if isOn("AutoOpenPack") then
            for _, pack in ipairs(Options.SelectedPacks) do openPack(pack) end
        end
        
        -- 4. Equip & Rebirth
        if isOn("AutoEquipBest") then EquipBestCards() end
        if isOn("AutoRebirth") then doRebirth() end
    end
end)

Rayfield:LoadConfiguration()
