--[[
    SpectreWare | Spin A Soccer
    WindUI Edition — with auto-detect & stability improvements
]]

-- ============================================
-- 1) LOAD LIBRARY
-- ============================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ============================================
-- 2) SPECTRE THEME
-- ============================================
WindUI:AddTheme({
    Name = "SpectreTheme",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#8b5cf6"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#5b21b6"), Transparency = 0 },
    }, { Rotation = 45 }),
    Outline     = Color3.fromHex("#2e2a36"),
    Text        = Color3.fromHex("#f8fafc"),
    Placeholder = Color3.fromHex("#94a3b8"),
    Background  = Color3.fromHex("#0f0c16"),
    Button      = Color3.fromHex("#1e1a29"),
    Icon        = Color3.fromHex("#c4b5fd"),
})
WindUI:SetTheme("SpectreTheme")

-- ============================================
-- 3) CACHED SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Remotes = RS:WaitForChild("Remotes", 10)
if not Remotes then
    warn("SpectreWare: Remotes folder not found in ReplicatedStorage!")
else
    print("SpectreWare: Remotes folder found.")
end

-- ============================================
-- 4) HELPER: EquipBestCards
-- ============================================
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

-- ============================================
-- 5) SAFE REMOTE FIRE HELPER
-- ============================================
local function fireRemote(remoteName, ...)
    if not Remotes then return false end
    local remote = Remotes:FindFirstChild(remoteName)
    if not remote then return false end
    local ok, err = pcall(remote.FireServer, remote, ...)
    if not ok then
        warn("SpectreWare: Failed to fire " .. remoteName .. ": " .. tostring(err))
    end
    return ok
end

-- ============================================
-- 6) CONFIG VARIABLES
-- ============================================
local Config = {
    SmartAuto = false,
    LoopDelay = 1,
    SlotAmount = 10,
    AutoCollect = false,
    AutoClaimGems = false,
    AutoEquipBest = false,
    AutoRebirth = false,
    SelectedPacks = { ["Gold"] = true },
    AutoBuyPack = false,
    AutoOpenPack = false,
    AntiAFK = false,
    AutoSpinWheel = false,
    AutoClaimFreeWheel = false,
    AutoCraftItems = {},
    AutoCraft = false,
    AutoBuyGemItems = {},
    AutoBuyGem = false,
    SelectedCraftNames = {}, -- คอยจำรายชื่อไอเทมที่เคยแสกนเจอแล้ว เพื่อไม่ต้องเปิดร้านใหม่ทุกครั้ง
}

local function isOn(key)
    return Config.SmartAuto or Config[key]
end

-- ============================================
-- 7) UI LAYOUT FILTER HELPER
-- ============================================
local UI_IGNORE_CLASSES = {
    UIListLayout = true, UIPadding = true, UICorner = true,
    UIStroke = true, UIGridLayout = true, UITableLayout = true,
    UIPageLayout = true, UISizeConstraint = true, UIScale = true,
    UIAspectRatioConstraint = true, UITextSizeConstraint = true,
    UIFlexItem = true, UIGradient = true,
}

local function IsUILayoutObject(obj)
    return UI_IGNORE_CLASSES[obj.ClassName] ~= nil
end

-- ============================================
-- 8) DYNAMIC PACK DETECTION
--    Path: PlayerGui.PackShop.Frame.Main.ScrollingFrame.[PackName].PurchaseSection.Buy
-- ============================================
local KnownPacks = {}
local PackDropdownRef = nil

local function ScanForPacks()
    local found = {}
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pgui then return end
        local packShop = pgui:FindFirstChild("PackShop")
        if not packShop then return end
        local frame = packShop:FindFirstChild("Frame")
        if not frame then return end
        local main = frame:FindFirstChild("Main")
        if not main then return end
        local scrollFrame = main:FindFirstChild("ScrollingFrame")
        if not scrollFrame then return end

        for _, child in ipairs(scrollFrame:GetChildren()) do
            if not IsUILayoutObject(child) then
                local purchaseSection = child:FindFirstChild("PurchaseSection")
                if purchaseSection and purchaseSection:FindFirstChild("Buy") then
                    local name = child.Name
                    if name and name ~= "" then
                        found[name] = true
                    end
                end
            end
        end
    end)
    return found
end

local function UpdatePackList()
    local scanned = ScanForPacks()
    for name, _ in pairs(scanned) do
        if not KnownPacks[name] then
            KnownPacks[name] = true
        end
    end

    local sorted = {}
    for name, _ in pairs(KnownPacks) do
        table.insert(sorted, name)
    end
    table.sort(sorted)

    if PackDropdownRef then
        pcall(function()
            if PackDropdownRef.SetValues then
                PackDropdownRef:SetValues(sorted)
            elseif PackDropdownRef.Refresh then
                PackDropdownRef:Refresh(sorted)
            end
        end)
    end

    return sorted
end

-- Seed with known packs as fallback
local FallbackPacks = {
    "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Legendary",
    "Toxic", "Shadow", "Infernal", "Corrupted", "Cosmic", "Eclipse",
    "Hades", "Heaven", "Chaos", "Ordain", "Alpha", "Omega",
    "Genesis", "Abyssal", "Enigma", "Oracle", "Wither", "Bloom", "Scarlet",
}
for _, p in ipairs(FallbackPacks) do
    KnownPacks[p] = true
end

-- ============================================
-- 9) DYNAMIC GEM SHOP DETECTION
--    Path: PlayerGui.GemShop.Frame.Main.ScrollingFrame.[ItemName].BuyButton
-- ============================================
local KnownGemItems = {}
local GemDropdownRef = nil

local function ScanForGemItems()
    local found = {}
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pgui then return end
        local gemShop = pgui:FindFirstChild("GemShop")
        if not gemShop then return end
        local frame = gemShop:FindFirstChild("Frame")
        if not frame then return end
        local main = frame:FindFirstChild("Main")
        if not main then return end
        local scrollFrame = main:FindFirstChild("ScrollingFrame")
        if not scrollFrame then return end

        for _, child in ipairs(scrollFrame:GetChildren()) do
            if not IsUILayoutObject(child) then
                if child:FindFirstChild("BuyButton") then
                    local name = child.Name
                    if name and name ~= "" then
                        found[name] = true
                    end
                end
            end
        end
    end)
    return found
end

local function UpdateGemShopList()
    local scanned = ScanForGemItems()
    for name, _ in pairs(scanned) do
        if not KnownGemItems[name] then
            KnownGemItems[name] = true
        end
    end

    local sorted = {}
    for name, _ in pairs(KnownGemItems) do
        table.insert(sorted, name)
    end
    table.sort(sorted)

    if GemDropdownRef then
        pcall(function()
            if GemDropdownRef.SetValues then
                GemDropdownRef:SetValues(sorted)
            elseif GemDropdownRef.Refresh then
                GemDropdownRef:Refresh(sorted)
            end
        end)
    end

    return sorted
end

-- Seed with known gem items as fallback
local FallbackGemItems = {
    "AutoEquipBest", "AutoSkip", "ExtraBankSlots", "Inventory500",
}
for _, g in ipairs(FallbackGemItems) do
    KnownGemItems[g] = true
end

-- ============================================================
-- 9.5 DYNAMIC CRAFT SHOP DETECTION (Real-time, v3.5 - Proper Mapping)
-- Path: PlayerGui.CraftShop.**.ScrollingFrame.<AnyFrame>.TextLabel(ItemName)
-- ============================================================
local KnownCraftItems  = {}
local CraftNameMap     = {}   -- [displayName] = internal frame.Name
local CraftDropdownRef = nil
local CraftScrollRef   = nil
local CraftConnections = {}
local PGuiConnections  = {}

-- 🧹 Blacklist names at the frame level
local CRAFT_NAME_BLACKLIST = {
    Start=true, ["End"]=true, Padding=true, Template=true,
    Header=true, Footer=true, Title=true, Divider=true,
    Spacer=true, Background=true, CraftButton=true, Button=true,
}

-- 🏷️ Keywords that suggest a TextLabel is a price/count instead of a name
local PRICE_KEYWORDS = { "price","cost","amount","coin","gem","cash","qty","count","x%d" }

local function looksLikePrice(s)
    if not s or s == "" then return true end
    if s:match("^%s*[%d,%.]+%s*$") then return true end      -- Plain numbers
    if s:match("^%s*x%s*%d") then return true end            -- x10, x100
    local low = s:lower()
    for _, kw in ipairs(PRICE_KEYWORDS) do
        if low:find(kw) then return true end
    end
    -- Also filter standard non-item words
    local bad = {"craft","buy","owned","locked","max","level"}
    for _, b in ipairs(bad) do if low:find(b) then return true end end
    return false
end

-- 🔍 Extract the human-readable name from within an item frame
local function ExtractCraftName(frame)
    if not frame or not frame:IsA("GuiObject") then return nil end
    
    -- 1) ลองใช้ชื่อของ Frame เลยถ้ามันดูไม่ใช่ชื่อระบบ (เช่น "Immortal Chalice", "Golden Boot")
    local fName = frame.Name
    if fName and fName ~= "" and not CRAFT_NAME_BLACKLIST[fName] and not looksLikePrice(fName) then
        if not fName:match("^Frame") and not fName:match("^Slot") and not fName:match("^Item") then
            return fName
        end
    end

    -- 2) ลองหาจาก TextLabel ที่เป็นชื่อไอเทม (มักจะอยู่ใน PurchaseSection หรือเป็นลูกตรงๆ)
    local preferred = { "ItemName","Title","Name","Label","DisplayName","TrophyName" }
    for _, key in ipairs(preferred) do
        local lbl = frame:FindFirstChild(key, true)
        if lbl and lbl:IsA("TextLabel") and lbl.Text and lbl.Text ~= "" 
           and not looksLikePrice(lbl.Text) then
            return lbl.Text
        end
    end
    
    -- 3) fallback: เลือก TextLabel ที่ยาวและเด่นที่สุด (ไม่ใช่ราคา)
    local best, bestLen = nil, 0
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and #d.Text > 1 and not looksLikePrice(d.Text) then
            if #d.Text > bestLen then
                best, bestLen = d.Text, #d.Text
            end
        end
    end
    return best
end

local function isValidCraftEntry(child)
    if not child or not child:IsA("GuiObject") then return false end
    if IsUILayoutObject(child) then return false end
    
    local name = child.Name
    if CRAFT_NAME_BLACKLIST[name] then return false end
    
    -- จากโครงสร้างล่าสุด: ต้องมี PurchaseSection และข้างในมีปุ่ม Craft หรือ Buy
    local purchase = child:FindFirstChild("PurchaseSection")
    if purchase then
        if purchase:FindFirstChild("CraftButton") or purchase:FindFirstChild("BuyButton") or purchase:FindFirstChild("Buy") then
            return true
        end
    end
    
    -- Fallback: มี TextLabel และไม่ใช่ขยะ
    local lbl = child:FindFirstChildOfClass("TextLabel", true)
    if lbl and not looksLikePrice(lbl.Text) then
        return true
    end
    
    return false
end

local function PushCraftItem(displayName, internalName)
    if not displayName or displayName == "" then return false end
    if KnownCraftItems[displayName] then 
        -- Update mapping if it changed
        CraftNameMap[displayName] = internalName or displayName
        return false 
    end
    KnownCraftItems[displayName] = true
    CraftNameMap[displayName] = internalName or displayName
    return true
end

local function RefreshCraftDropdown()
    local sorted = {}
    for name, _ in pairs(KnownCraftItems) do
        table.insert(sorted, name)
    end
    table.sort(sorted)
    if CraftDropdownRef then
        pcall(function()
            if CraftDropdownRef.SetValues then
                CraftDropdownRef:SetValues(sorted)
            elseif CraftDropdownRef.Refresh then
                CraftDropdownRef:Refresh(sorted)
            end
        end)
    end
    return sorted
end

local function FindCraftScroll()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui"); if not pgui then return nil end
    local craftShop = pgui:FindFirstChild("CraftShop");   if not craftShop then return nil end
    local best, bestCount = nil, -1
    for _, d in ipairs(craftShop:GetDescendants()) do
        if d:IsA("ScrollingFrame") then
            local c = #d:GetChildren()
            if c > bestCount then best, bestCount = d, c end
        end
    end
    return best
end

local function ScanForCraftItems()
    local found = {}
    pcall(function()
        local scroll = FindCraftScroll()
        if not scroll then return end
        CraftScrollRef = scroll
        for _, child in ipairs(scroll:GetChildren()) do
            if isValidCraftEntry(child) then
                local realName = ExtractCraftName(child)
                if realName and realName ~= "" then
                    found[realName] = child.Name -- [DisplayName] = InternalName
                end
            end
        end
    end)
    return found
end

local function UpdateCraftList(silent)
    local scanned = ScanForCraftItems()
    local addedNames = {}
    for displayName, internalName in pairs(scanned) do
        if PushCraftItem(displayName, internalName) then
            table.insert(addedNames, displayName)
            -- บันทึกรายชื่อใหม่ลงใน Config เพื่อให้คราวหน้าโหลดขึ้นมาได้ทันที
            if not table.find(Config.SelectedCraftNames, displayName) then
                table.insert(Config.SelectedCraftNames, displayName)
            end
        end
    end
    local list = RefreshCraftDropdown()
    if (not silent) and #addedNames > 0 then
        pcall(function()
            WindUI:Notify({
                Title="Craft Shop",
                Content="🆕 New: "..table.concat(addedNames,", "),
                Duration=3,
            })
        end)
    end
    return list
end

local function DisconnectAll(list)
    for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
    table.clear(list)
end

-- 🪄 ฟังก์ชัน "แอบเปิดร้าน" เพื่อบังคับให้ไอเทมโหลดออกมา
local function ForceInitializeShop()
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local craftShop = pgui:FindFirstChild("CraftShop")
        if craftShop and craftShop:IsA("ScreenGui") then
            local oldEnabled = craftShop.Enabled
            craftShop.Enabled = true
            task.wait(0.1)
            craftShop.Enabled = oldEnabled
        end
    end)
end

local function BindCraftScrollListener()
    local scroll = FindCraftScroll()
    if not scroll then return false end
    CraftScrollRef = scroll
    DisconnectAll(CraftConnections)

    table.insert(CraftConnections, scroll.ChildAdded:Connect(function(child)
        task.spawn(function()
            -- ⏳ Patiently wait for TextLabels to populate
            for attempt = 1, 20 do
                task.wait(0.2)
                if isValidCraftEntry(child) then
                    local realName = ExtractCraftName(child)
                    if realName and realName ~= "" then
                        if PushCraftItem(realName, child.Name) then
                            -- บันทึกรายชื่อใหม่ลงใน Config
                            if not table.find(Config.SelectedCraftNames, realName) then
                                table.insert(Config.SelectedCraftNames, realName)
                            end
                            RefreshCraftDropdown()
                            pcall(function()
                                WindUI:Notify({
                                    Title="Craft Shop",
                                    Content="🆕 Detected: "..realName,
                                    Duration=2,
                                })
                            end)
                        end
                        return
                    end
                end
            end
        end)
    end))

    table.insert(CraftConnections, scroll.DescendantAdded:Connect(function(desc)
        if desc:IsA("TextLabel") then
            task.wait(0.3)
            UpdateCraftList(true)
        end
    end))

    table.insert(CraftConnections, scroll.AncestryChanged:Connect(function(_, parent)
        if not parent then
            CraftScrollRef = nil
            task.wait(0.5)
            BindCraftScrollListener()
        end
    end))

    UpdateCraftList(true)
    return true
end

task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui", 15); if not pgui then return end
    DisconnectAll(PGuiConnections)

    local function tryBind()
        ForceInitializeShop()      -- บังคับโหลดไอเทม 1 ครั้งตอนเริ่ม
        UpdateCraftList(true)
        BindCraftScrollListener()
    end
    tryBind()

    table.insert(PGuiConnections, pgui.DescendantAdded:Connect(function(desc)
        if not desc then return end
        if desc.Name == "CraftShop"
           or (desc:IsA("ScrollingFrame") and desc:FindFirstAncestor("CraftShop")) then
            task.wait(0.5)
            tryBind()
        end
    end))

    -- 🔁 Heartbeat
    task.spawn(function()
        while true do
            task.wait(10)
            if not CraftScrollRef or not CraftScrollRef.Parent then
                BindCraftScrollListener()
            else
                UpdateCraftList(true)
            end
        end
    end)
end)

-- 🌱 Seed fallback + Load from Config
local FallbackCraftItems = {
    "Golden Boot", "Champions League", "Ballon d'Or", "Eternal Crown", "Immortal Chalice",
}
for _, c in ipairs(FallbackCraftItems) do
    KnownCraftItems[c] = true
    CraftNameMap[c]    = c
end

-- ดึงไอเทมที่เคยแสกนเจอจาก Config มาใส่เพิ่มทันทีที่โหลดสคริปต์
task.spawn(function()
    task.wait(2) -- รอให้ ConfigManager โหลดเสร็จก่อน
    if Config.SelectedCraftNames then
        for _, name in ipairs(Config.SelectedCraftNames) do
            if not KnownCraftItems[name] then
                KnownCraftItems[name] = true
                CraftNameMap[name]    = name -- สมมติว่า internal-display ตรงกันสำหรับของเซฟ
            end
        end
        RefreshCraftDropdown()
    end
end)

-- ============================================
-- 10) CREATE WINDOW
-- ============================================
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
            ColorSequenceKeypoint.new(1, Color3.fromHex("#5b21b6")),
        }),
    },
})

pcall(function()
    Window:EditOpenButton({
        Title = "SpectreWare",
        Icon = "sparkles",
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#8b5cf6")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#5b21b6")),
        }),
    })
end)

-- ============================================
-- 11) TABS
-- ============================================
local Tabs = {
    Home     = Window:Tab({ Title = "Dashboard",      Icon = "layout-dashboard" }),
    Farm     = Window:Tab({ Title = "Automation",      Icon = "zap" }),
    Spin     = Window:Tab({ Title = "Spin Wheel",      Icon = "refresh-cw" }),
    Craft    = Window:Tab({ Title = "Craft Shop",      Icon = "hammer" }),
    GemShop  = Window:Tab({ Title = "Gem Shop",        Icon = "gem" }),
    Packs    = Window:Tab({ Title = "Packs & Crates",  Icon = "package-open" }),
    Sell     = Window:Tab({ Title = "Auto Sell",       Icon = "trash-2" }),
    Misc     = Window:Tab({ Title = "Local Player",    Icon = "user-cog" }),
    Settings = Window:Tab({ Title = "Settings",        Icon = "settings" }),
}

-- ============================================
-- 12) DASHBOARD TAB
-- ============================================
local HomeSec = Tabs.Home:Section({ Title = "Welcome to SpectreWare", Opened = true })

HomeSec:Paragraph({
    Title = "Welcome to SpectreWare",
    Desc  = "Spin A Soccer automation suite.\nIf you encounter any bugs, contact us on Discord.",
})

local QuickSec = Tabs.Home:Section({ Title = "Quick Start", Opened = true })

QuickSec:Toggle({
    Flag     = "Tgl_SmartAuto",
    Title    = "⚡ Smart Auto (All-in-One)",
    Desc     = "Automatically Collect Slots, Claim Gems, Buy & Open Packs, Equip cards, and Rebirth in one click.",
    Default  = false,
    Callback = function(state)
        Config.SmartAuto = state
        if state then
            WindUI:Notify({ Title = "Smart Auto", Content = "All-in-One automation enabled!", Duration = 3 })
        end
    end,
})

-- ============================================
-- 13) AUTOMATION TAB
-- ============================================
local FarmCoreSec = Tabs.Farm:Section({ Title = "Core Automation", Opened = true })

FarmCoreSec:Toggle({
    Flag = "Tgl_AutoCollect", Title = "Auto Collect Slots",
    Desc = "Continuously collect spins from slots.",
    Default = false, Callback = function(s) Config.AutoCollect = s end,
})
FarmCoreSec:Toggle({
    Flag = "Tgl_AutoClaimGems", Title = "Auto Claim Gems",
    Desc = "Automatically collect gems from the index.",
    Default = false, Callback = function(s) Config.AutoClaimGems = s end,
})
FarmCoreSec:Toggle({
    Flag = "Tgl_AutoEquipBest", Title = "Auto Equip Best",
    Desc = "Always equip the highest stat cards.",
    Default = false, Callback = function(s) Config.AutoEquipBest = s end,
})
FarmCoreSec:Toggle({
    Flag = "Tgl_AutoRebirth", Title = "Auto Rebirth",
    Desc = "Instantly rebirth when requirements are met.",
    Default = false, Callback = function(s) Config.AutoRebirth = s end,
})

local FarmPerfSec = Tabs.Farm:Section({ Title = "Performance Settings", Opened = true })

FarmPerfSec:Slider({
    Flag = "Sld_LoopDelay", Title = "Automation Loop Delay",
    Desc = "Speed of background tasks (Lower = Faster).",
    Step = 0.5, Value = { Min = 0.5, Max = 5, Default = 1 },
    Callback = function(v) Config.LoopDelay = v end,
})
FarmPerfSec:Slider({
    Flag = "Sld_SlotAmount", Title = "Slots Target Amount",
    Desc = "Number of slots to cycle through when collecting.",
    Step = 1, Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(v) Config.SlotAmount = v end,
})

local FarmActionSec = Tabs.Farm:Section({ Title = "Quick Actions", Opened = false })

FarmActionSec:Button({
    Title = "Collect Slots Once", Desc = "Manually trigger slot collection.",
    Callback = function()
        for i = 1, Config.SlotAmount do
            fireRemote("CollectSlot", i)
            task.wait(0.1)
        end
        WindUI:Notify({ Title = "Action", Content = "Collected Slots Manually", Duration = 2 })
    end,
})
FarmActionSec:Button({
    Title = "Claim Gems Once", Desc = "Manually claim all index gems.",
    Callback = function()
        fireRemote("ClaimAllIndexGems")
        WindUI:Notify({ Title = "Action", Content = "Claimed All Gems", Duration = 2 })
    end,
})
FarmActionSec:Button({
    Title = "Equip Best Cards", Desc = "Manually equip your strongest team.",
    Callback = function()
        EquipBestCards()
        WindUI:Notify({ Title = "Action", Content = "Equipped Best Cards", Duration = 2 })
    end,
})
FarmActionSec:Button({
    Title = "Rebirth Instantly", Desc = "Force rebirth if you have enough cash.",
    Callback = function()
        fireRemote("Rebirth")
        WindUI:Notify({ Title = "Action", Content = "Attempted Rebirth", Duration = 2 })
    end,
})

-- ============================================
-- 14) SPIN WHEEL TAB
-- ============================================
local SpinAutoSec = Tabs.Spin:Section({ Title = "Spin Wheel Automation", Opened = true })

SpinAutoSec:Toggle({
    Flag = "Tgl_AutoSpinWheel", Title = "Auto Spin Wheel",
    Desc = "Continuously spin the wheel.",
    Default = false, Callback = function(s) Config.AutoSpinWheel = s end,
})
SpinAutoSec:Toggle({
    Flag = "Tgl_AutoClaimFreeWheel", Title = "Auto Claim Free Wheel",
    Desc = "Automatically claim free wheel spins.",
    Default = false, Callback = function(s) Config.AutoClaimFreeWheel = s end,
})

local SpinManualSec = Tabs.Spin:Section({ Title = "Manual Actions", Opened = false })

SpinManualSec:Button({
    Title = "Spin Wheel Once", Desc = "Manually spin the wheel.",
    Callback = function() fireRemote("SpinWheel", "spin") end,
})
SpinManualSec:Button({
    Title = "Claim Free Spin Once", Desc = "Manually claim free wheel spin.",
    Callback = function() fireRemote("SpinWheel", "claim_free") end,
})

-- ============================================
-- 15) CRAFT SHOP TAB (Auto-Detecting)
-- ============================================
local CraftAutoSec = Tabs.Craft:Section({ Title = "Auto Crafting", Opened = true })

CraftAutoSec:Paragraph({
    Title = "Auto-Detect Enabled",
    Desc  = "Craft Shop items are scanned automatically every 15 seconds. New items will appear here!",
})

local initialCraftItems = UpdateCraftList()

CraftDropdownRef = CraftAutoSec:Dropdown({
    Flag     = "Drop_SelectCraftItems",
    Title    = "Select Items to Auto-Craft",
    Desc     = "Choose which items to craft automatically.",
    Values   = initialCraftItems,
    Value    = {},
    Multi    = true,
    Callback = function(selected)
        -- Reset all
        for k, _ in pairs(Config.AutoCraftItems) do
            Config.AutoCraftItems[k] = false
        end
        -- Enable selected
        if type(selected) == "table" then
            for _, name in ipairs(selected) do
                Config.AutoCraftItems[name] = true
            end
        elseif type(selected) == "string" then
            Config.AutoCraftItems[selected] = true
        end
    end,
})

CraftAutoSec:Toggle({
    Flag = "Tgl_AutoCraft", Title = "Auto Craft Selected Items",
    Desc = "Continuously craft the selected items.",
    Default = false,
    Callback = function(s)
        Config.AutoCraft = s
        if s then
            local count = 0
            for _, on in pairs(Config.AutoCraftItems) do if on then count += 1 end end
            WindUI:Notify({ Title = "Auto Craft", Content = "Enabled — crafting " .. tostring(count) .. " selected item(s) each loop.", Duration = 3 })
        end
    end,
})

local CraftManualSec = Tabs.Craft:Section({ Title = "Manual Actions", Opened = false })

CraftManualSec:Button({
    Title = "Craft All Selected Once",
    Desc  = "Manually craft each selected item once.",
    Callback = function()
        local crafted = 0
        for itemName, on in pairs(Config.AutoCraftItems) do
            if on then
                local internalName = CraftNameMap[itemName] or itemName
                if fireRemote("CraftTrophy", internalName) then crafted += 1 end
            end
        end
        WindUI:Notify({ Title = "Craft Shop", Content = "Attempted to craft " .. tostring(crafted) .. " items.", Duration = 2 })
    end,
})
CraftManualSec:Button({
    Title = "Force Rescan Craft Shop",
    Desc  = "Manually trigger a Craft Shop scan right now.",
    Callback = function()
        local items = UpdateCraftList()
        WindUI:Notify({ Title = "Craft Shop", Content = "Found " .. tostring(#items) .. " items.", Duration = 2 })
    end,
})

-- ============================================
-- 16) GEM SHOP TAB (Auto-Detecting)
-- ============================================
local GemAutoSec = Tabs.GemShop:Section({ Title = "Auto Gem Shop", Opened = true })

GemAutoSec:Paragraph({
    Title = "Auto-Detect Enabled",
    Desc  = "Gem Shop items are scanned automatically every 15 seconds. Open the Gem Shop once to detect all items!",
})

local initialGemItems = UpdateGemShopList()

GemDropdownRef = GemAutoSec:Dropdown({
    Flag     = "Drop_SelectGemItems",
    Title    = "Select Items to Auto-Buy",
    Desc     = "Choose which Gem Shop items to purchase automatically.",
    Values   = initialGemItems,
    Value    = {},
    Multi    = true,
    Callback = function(selected)
        -- Reset all
        for k, _ in pairs(Config.AutoBuyGemItems) do
            Config.AutoBuyGemItems[k] = false
        end
        -- Enable selected
        if type(selected) == "table" then
            for _, name in ipairs(selected) do
                Config.AutoBuyGemItems[name] = true
            end
        elseif type(selected) == "string" then
            Config.AutoBuyGemItems[selected] = true
        end
    end,
})

GemAutoSec:Toggle({
    Flag = "Tgl_AutoBuyGem", Title = "Auto Buy Selected Gem Items",
    Desc = "Continuously purchase the selected Gem Shop items.",
    Default = false,
    Callback = function(s)
        Config.AutoBuyGem = s
        if s then
            local count = 0
            for _, on in pairs(Config.AutoBuyGemItems) do if on then count += 1 end end
            WindUI:Notify({ Title = "Auto Buy Gems", Content = "Enabled — buying " .. tostring(count) .. " selected item(s) each loop.", Duration = 3 })
        end
    end,
})

local GemManualSec = Tabs.GemShop:Section({ Title = "Manual Actions", Opened = false })

GemManualSec:Button({
    Title = "Buy All Selected Once",
    Desc  = "Manually buy each selected Gem Shop item once.",
    Callback = function()
        local bought = 0
        for itemName, on in pairs(Config.AutoBuyGemItems) do
            if on then
                if fireRemote("BuyGemShopItem", string.lower(itemName)) then bought += 1 end
            end
        end
        WindUI:Notify({ Title = "Gem Shop", Content = "Attempted to buy " .. tostring(bought) .. " items.", Duration = 2 })
    end,
})
GemManualSec:Button({
    Title = "Force Rescan Gem Shop",
    Desc  = "Manually trigger a Gem Shop scan right now.",
    Callback = function()
        local items = UpdateGemShopList()
        WindUI:Notify({ Title = "Gem Shop", Content = "Found " .. tostring(#items) .. " items.", Duration = 2 })
    end,
})

-- ============================================
-- 17) PACKS & CRATES TAB (Auto-Detecting)
-- ============================================
local PackConfigSec = Tabs.Packs:Section({ Title = "Packs Configuration", Opened = true })

PackConfigSec:Paragraph({
    Title = "Auto-Detect Enabled",
    Desc  = "New packs are scanned automatically every 15 seconds from the PackShop GUI. You no longer need to update the list manually!",
})

local initialPacks = UpdatePackList()

PackDropdownRef = PackConfigSec:Dropdown({
    Flag     = "Drop_SelectPacks",
    Title    = "Select Target Packs",
    Desc     = "Choose which packs to buy and open.",
    Values   = initialPacks,
    Value    = { "Gold" },
    Multi    = true,
    Callback = function(selected)
        local newSelections = {}
        if type(selected) == "table" then
            for _, pack in ipairs(selected) do newSelections[pack] = true end
        elseif type(selected) == "string" then
            newSelections[selected] = true
        end
        Config.SelectedPacks = newSelections
    end,
})

PackConfigSec:Toggle({
    Flag = "Tgl_AutoBuyPack", Title = "Auto Buy Selected Packs",
    Desc = "Continuously spend cash on chosen packs.",
    Default = false,
    Callback = function(s)
        Config.AutoBuyPack = s
        if s then
            local count = 0
            for _, on in pairs(Config.SelectedPacks) do if on then count += 1 end end
            WindUI:Notify({ Title = "Auto Buy Packs", Content = "Enabled — buying " .. tostring(count) .. " selected pack(s) each loop.", Duration = 3 })
        end
    end,
})
PackConfigSec:Toggle({
    Flag = "Tgl_AutoOpenPack", Title = "Auto Open Selected Packs",
    Desc = "Continuously open purchased packs.",
    Default = false, Callback = function(s) Config.AutoOpenPack = s end,
})

local PackManualSec = Tabs.Packs:Section({ Title = "Manual Management", Opened = false })

PackManualSec:Button({
    Title = "Buy Selected Packs Once",
    Desc  = "One-time purchase of all selected packs.",
    Callback = function()
        local bought = 0
        for pack, on in pairs(Config.SelectedPacks) do
            if on then
                if fireRemote("BuyPack", pack) then bought += 1 end
            end
        end
        WindUI:Notify({ Title = "Packs", Content = "Bought " .. tostring(bought) .. " selected packs.", Duration = 2 })
    end,
})
PackManualSec:Button({
    Title = "Open Selected Packs Once",
    Desc  = "One-time opening of all selected packs.",
    Callback = function()
        local opened = 0
        for pack, on in pairs(Config.SelectedPacks) do
            if on then
                if fireRemote("OpenPack", pack) then opened += 1 end
            end
        end
        WindUI:Notify({ Title = "Packs", Content = "Opened " .. tostring(opened) .. " selected packs.", Duration = 2 })
    end,
})
PackManualSec:Button({
    Title = "Force Rescan Packs",
    Desc  = "Manually trigger a pack scan right now.",
    Callback = function()
        local packs = UpdatePackList()
        WindUI:Notify({ Title = "Packs", Content = "Found " .. tostring(#packs) .. " packs.", Duration = 2 })
    end,
})

-- Background pack, gem shop + craft shop scanner (every 15 seconds)
task.spawn(function()
    task.wait(5)
    while true do
        pcall(function() UpdatePackList() end)
        pcall(function() UpdateGemShopList() end)
        pcall(function() UpdateCraftList() end)
        task.wait(15)
    end
end)

-- ============================================
-- 18) AUTO SELL TAB
-- ============================================
local SellSec = Tabs.Sell:Section({ Title = "Auto Sell Filter", Opened = true })

SellSec:Paragraph({
    Title = "How Auto Sell Works",
    Desc  = "Enable rarities you want to instantly sell when obtained to keep your inventory clean.",
})

local SellRarities = {
    "Bronze", "Silver", "Gold", "Legendary", "Mythic",
    "Azure Zenith", "Crimson Zenith", "Divine", "Primordial",
    "Oblivion", "Eternity",
}

for _, rarity in ipairs(SellRarities) do
    SellSec:Toggle({
        Flag     = "Tgl_AutoSell_" .. string.gsub(rarity, "%W", ""),
        Title    = "Sell " .. rarity .. " Cards",
        Default  = false,
        Callback = function(state) fireRemote("UpdateAutoSell", rarity, state) end,
    })
end

-- ============================================
-- 19) LOCAL PLAYER TAB
-- ============================================
local MiscSec = Tabs.Misc:Section({ Title = "Player Modifications", Opened = true })

MiscSec:Toggle({
    Flag = "Tgl_AntiAFK", Title = "Anti-AFK",
    Desc = "Prevents getting kicked for being idle (20 mins by Roblox).",
    Default = false,
    Callback = function(state)
        Config.AntiAFK = state
        if state then
            pcall(function()
                if not getgenv().AntiAFKConnection then
                    getgenv().AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                        if Config.AntiAFK then
                            local VirtualUser = game:GetService("VirtualUser")
                            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                            task.wait(1)
                            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        end
                    end)
                end
            end)
        end
    end,
})
MiscSec:Slider({
    Flag = "Sld_WalkSpeed", Title = "WalkSpeed Override",
    Desc = "Change your character's run speed.",
    Step = 1, Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(v)
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end
        end)
    end,
})
MiscSec:Slider({
    Flag = "Sld_JumpPower", Title = "JumpPower Override",
    Desc = "Change your character's jump height.",
    Step = 1, Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(v)
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end
        end)
    end,
})

-- ============================================
-- 20) SETTINGS TAB
-- ============================================
local UISec = Tabs.Settings:Section({ Title = "UI Options", Opened = true })

UISec:Keybind({
    Flag = "Keybind_ToggleMenu", Title = "Toggle Menu Key",
    Desc = "Hide or show the UI.",
    Value = "LeftControl",
    Callback = function(k)
        if Window.SetToggleKey then
            Window:SetToggleKey(Enum.KeyCode[k] or Enum.KeyCode.LeftControl)
        end
    end,
})

local AvailableThemes = {}
for themeName, _ in pairs(WindUI.Themes) do
    table.insert(AvailableThemes, themeName)
end
if not table.find(AvailableThemes, "SpectreTheme") then
    table.insert(AvailableThemes, "SpectreTheme")
end

UISec:Dropdown({
    Flag     = "Drop_Theme",
    Title    = "Select Interface Theme",
    Desc     = "Change the color palette of the menu.",
    Values   = AvailableThemes,
    Value    = "SpectreTheme",
    Callback = function(themeName)
        pcall(function() WindUI:SetTheme(themeName) end)
    end,
})

-- ============================================
-- 21) BACKGROUND AUTOMATION LOOP
-- ============================================
task.spawn(function()
    while true do
        task.wait(Config.LoopDelay)

        -- 1. Collect Slots
        if isOn("AutoCollect") then
            for i = 1, Config.SlotAmount do
                if not isOn("AutoCollect") then break end
                fireRemote("CollectSlot", i)
                task.wait(0.1)
            end
        end

        -- 2. Claim Gems
        if isOn("AutoClaimGems") then
            fireRemote("ClaimAllIndexGems")
        end

        -- 3. Buy Packs
        if isOn("AutoBuyPack") then
            for pack, on in pairs(Config.SelectedPacks) do
                if on then fireRemote("BuyPack", pack) end
            end
        end

        -- 4. Open Packs
        if isOn("AutoOpenPack") then
            for pack, on in pairs(Config.SelectedPacks) do
                if on then fireRemote("OpenPack", pack) end
            end
        end

        -- 5. Equip Best
        if isOn("AutoEquipBest") then
            EquipBestCards()
        end

        -- 6. Rebirth
        if isOn("AutoRebirth") then
            fireRemote("Rebirth")
        end

        -- 7. Spin Wheel
        if isOn("AutoSpinWheel") then
            fireRemote("SpinWheel", "spin")
        end

        -- 8. Claim Free Wheel
        if isOn("AutoClaimFreeWheel") then
            fireRemote("SpinWheel", "claim_free")
        end

        -- 9. Auto Craft
        if isOn("AutoCraft") then
            for itemName, isCrafting in pairs(Config.AutoCraftItems) do
                if isCrafting then
                    local internalName = CraftNameMap[itemName] or itemName
                    fireRemote("CraftTrophy", internalName)
                end
            end
        end

        -- 10. Auto Buy Gem Shop Items (dynamic list)
        if isOn("AutoBuyGem") then
            for itemName, on in pairs(Config.AutoBuyGemItems) do
                if on then
                    fireRemote("BuyGemShopItem", string.lower(itemName))
                end
            end
        end
    end
end)

-- ============================================
-- 22) FINAL SETUP
-- ============================================
Tabs.Home:Select()

WindUI:Notify({ Title = "SpectreWare Loaded", Content = "Injected successfully with SpectreTheme!", Duration = 5 })

-- Auto Save/Load
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
