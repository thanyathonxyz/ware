-- ============================================================
-- Be a Streamer | Script Hub (Smart v3.1 - Clean Edition)
-- Powered by Rayfield + Lucide Icons
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local UserInput         = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

-- Window uses Lucide icon "video" as topbar icon
local Window = Rayfield:CreateWindow({
    Name             = "Be a Streamer  |  Script Hub",
    Icon             = "video",                 -- Lucide icon
    LoadingTitle     = "Be a Streamer Hub",
    LoadingSubtitle  = "by SpectreWare  •  Lastest Version",
    Theme            = "DarkBlue",              -- clean dark purple
    ShowText         = "SpectreWare Hub",
    ConfigurationSaving = {
        Enabled     = true,
        FolderName  = "SpectreWare",
        FileName    = "Config_EN_v3"
    },
    Discord    = { Enabled = false, Invite = "noinvite", RememberJoins = true },
    KeySystem  = false,
})

-- Tabs with Lucide icons (strings) — no emojis in labels
local MainTab     = Window:CreateTab("Main",        "rocket")
local AutoTab     = Window:CreateTab("Automation",  "settings-2")
local PlayerTab   = Window:CreateTab("Player",      "user")
local TPTab       = Window:CreateTab("Teleport",    "map-pin")
local VisualTab   = Window:CreateTab("Visuals",     "eye")
local ServerTab   = Window:CreateTab("Server",      "server")
local SettingsTab = Window:CreateTab("Settings",    "sliders-horizontal")

-- ============================================================
-- Config & State
-- ============================================================
local CONFIG = {
    onlyMyPlot    = true,
    actionName    = "collectRevenue",
    interval      = 1.0,
    claimCooldown = 3.0,
}

local State = {
    autoRevenue   = false,
    autoMail      = false,
    autoFollowers = false,
    smartMode     = true,
    instantPrompt = false,
    infiniteJump  = false,
    noClip        = false,
    fullbright    = false,
    antiAFK       = true,
}

local lastClaim = setmetatable({}, { __mode = "k" })

-- ============================================================
-- Helpers
-- ============================================================
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP() return getChar():FindFirstChild("HumanoidRootPart") end
local function getHum() return getChar():FindFirstChildOfClass("Humanoid") end

local function getMyPlot()
    local plots = workspace:FindFirstChild("Plots"); if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local ov = plot:FindFirstChild("Owner") or plot:FindFirstChild("owner")
        if ov and ov:IsA("ObjectValue") and ov.Value == LP then return plot end
        local a = plot:GetAttribute("Owner")
        if a == LP.UserId or a == LP.Name then return plot end
    end
end

local function isReallyFull(root)
    if not root then return false end
    for _, k in ipairs({"Progress","Fill","Revenue","Amount","IsFull","Completed","Ready"}) do
        local v = root:GetAttribute(k)
        if (type(v)=="boolean" and v) or (type(v)=="number" and v>=1) then return true end
    end
    for _, c in ipairs(root:GetDescendants()) do
        if c:IsA("TextLabel") or c:IsA("TextButton") then
            local t = (c.Text or ""):lower()
            if t ~= "" then
                if t:find("completed") or t:find("finished") or t:find("ready")
                   or t:find("full") or t:find("100%%") or t:find("take share") or t:find("claim") then
                    return true
                end
                local a,b = t:match("(%d+)%s*/%s*(%d+)")
                if a and b then a,b = tonumber(a),tonumber(b)
                    if a and b and b>0 and a>=b then return true end
                end
            end
        end
    end
    return false
end

local function findRoot(prompt)
    local r = prompt.Parent
    while r and r.Parent and not (r:IsA("Model") and r.Name ~= "ActivePurchases") and r ~= workspace do
        r = r.Parent
    end
    return r
end

local function autoClaimPrompts()
    local plot = getMyPlot(); if not plot then return end
    local now = tick()
    for _, v in ipairs(plot:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v.RequiresLineOfSight   = false
            v.MaxActivationDistance = 999999
            v.HoldDuration          = 0
            local act = (v.ActionText or ""):lower()
            if act:find("take") or act:find("claim") or act:find("collect") or act:find("share") then
                if now - (lastClaim[v] or 0) >= CONFIG.claimCooldown then
                    local ok = not State.smartMode or isReallyFull(findRoot(v))
                    if ok then
                        lastClaim[v] = now
                        pcall(function()
                            if fireproximityprompt then fireproximityprompt(v)
                            else v:InputHoldBegin(); task.wait(); v:InputHoldEnd() end
                        end)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Unified Loops
-- ============================================================
task.spawn(function()
    while task.wait(CONFIG.interval) do
        if State.autoRevenue then pcall(autoClaimPrompts) end
    end
end)

task.spawn(function()
    local evt = ReplicatedStorage:WaitForChild("GetMailBox", 10)
    while task.wait(1) do
        if State.autoMail and evt then pcall(function() evt:FireServer() end) end
    end
end)

task.spawn(function()
    local evt = ReplicatedStorage:WaitForChild("StreamingEvent", 10)
    while task.wait(0.5) do
        if State.autoFollowers and evt then pcall(function() evt:FireServer("Responded") end) end
    end
end)

-- ============================================================
-- MAIN TAB
-- ============================================================
MainTab:CreateSection("Revenue")

MainTab:CreateToggle({
    Name = "Auto Collect Revenue",
    CurrentValue = false, Flag = "ToggleRevenue",
    Callback = function(v) State.autoRevenue = v end,
})

MainTab:CreateToggle({
    Name = "Smart Claim Mode",
    CurrentValue = true, Flag = "ToggleSmart",
    Callback = function(v) State.smartMode = v end,
})

MainTab:CreateSlider({
    Name = "Check Interval", Range = {0.5,5}, Increment = 0.5, Suffix = "s",
    CurrentValue = 1.0, Flag = "SliderInterval",
    Callback = function(v) CONFIG.interval = v end,
})

MainTab:CreateSlider({
    Name = "Claim Cooldown", Range = {1,10}, Increment = 0.5, Suffix = "s",
    CurrentValue = 3.0, Flag = "SliderCooldown",
    Callback = function(v) CONFIG.claimCooldown = v end,
})

MainTab:CreateDivider()
MainTab:CreateSection("Social")

MainTab:CreateToggle({
    Name = "Auto Get Mail",
    CurrentValue = false, Flag = "ToggleMail",
    Callback = function(v) State.autoMail = v end,
})

MainTab:CreateToggle({
    Name = "Auto Respond to Followers",
    CurrentValue = false, Flag = "ToggleFollowers",
    Callback = function(v) State.autoFollowers = v end,
})

-- ============================================================
-- AUTOMATION TAB
-- ============================================================
AutoTab:CreateSection("Interactions")

AutoTab:CreateToggle({
    Name = "Instant Proximity Prompts",
    CurrentValue = false, Flag = "ToggleInstant",
    Callback = function(v)
        State.instantPrompt = v
        if v then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then d.HoldDuration = 0 end
            end
        end
    end,
})

game.DescendantAdded:Connect(function(v)
    if State.instantPrompt and v:IsA("ProximityPrompt") then v.HoldDuration = 0 end
end)

-- ============================================================
-- PLAYER TAB
-- ============================================================
PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = {16,300}, Increment = 1,
    CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v) local h=getHum(); if h then h.WalkSpeed=v end end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power", Range = {50,500}, Increment = 5,
    CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v)
        local h = getHum()
        if h then h.UseJumpPower = true; h.JumpPower = v end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false, Flag = "InfJump",
    Callback = function(v) State.infiniteJump = v end,
})

UserInput.JumpRequest:Connect(function()
    if State.infiniteJump then
        local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PlayerTab:CreateToggle({
    Name = "No-Clip",
    CurrentValue = false, Flag = "NoClip",
    Callback = function(v) State.noClip = v end,
})

RunService.Stepped:Connect(function()
    if State.noClip then
        local c = LP.Character
        if c then for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end end
    end
end)

PlayerTab:CreateDivider()
PlayerTab:CreateSection("Character")

PlayerTab:CreateButton({
    Name = "Reset Character",
    Callback = function() local h=getHum(); if h then h.Health=0 end end,
})

-- ============================================================
-- TELEPORT TAB
-- ============================================================
TPTab:CreateSection("Locations")

TPTab:CreateButton({
    Name = "Teleport to My Plot",
    Callback = function()
        local hrp, plot = getHRP(), getMyPlot()
        if hrp and plot and plot.PrimaryPart then
            hrp.CFrame = plot.PrimaryPart.CFrame + Vector3.new(0,5,0)
        end
    end,
})

TPTab:CreateButton({
    Name = "Teleport to Mailbox",
    Callback = function()
        local hrp, plot = getHRP(), getMyPlot()
        if hrp and plot then
            local mb = plot:FindFirstChild("Mailbox", true)
            if mb and mb:IsA("BasePart") then
                hrp.CFrame = mb.CFrame + Vector3.new(0,3,0)
            end
        end
    end,
})

TPTab:CreateDivider()
TPTab:CreateSection("Players")

local playerDropdown
playerDropdown = TPTab:CreateDropdown({
    Name = "Teleport to Player",
    Options = {}, CurrentOption = {}, MultipleOptions = false,
    Flag = "TPPlayer",
    Callback = function(opt)
        local name = type(opt)=="table" and opt[1] or opt
        local t = Players:FindFirstChild(name)
        local hrp = getHRP()
        if t and t.Character and hrp then hrp.CFrame = t.Character:GetPivot() end
    end,
})

TPTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local list = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(list, p.Name) end
        end
        if playerDropdown and playerDropdown.Refresh then
            playerDropdown:Refresh(list, false)
        end
    end,
})

-- ============================================================
-- VISUAL TAB
-- ============================================================
VisualTab:CreateSection("Lighting")

local orig = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient,
}

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false, Flag = "Fullbright",
    Callback = function(v)
        State.fullbright = v
        if v then
            Lighting.Brightness = 2; Lighting.ClockTime = 14
            Lighting.FogEnd = 1e9; Lighting.Ambient = Color3.fromRGB(178,178,178)
        else for k,val in pairs(orig) do Lighting[k]=val end end
    end,
})

VisualTab:CreateDivider()
VisualTab:CreateSection("Performance")

VisualTab:CreateButton({
    Name = "Apply FPS Boost",
    Callback = function()
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.Plastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = 1
    end,
})

-- ============================================================
-- SERVER TAB
-- ============================================================
ServerTab:CreateSection("Connection")

ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function() TeleportService:Teleport(game.PlaceId, LP) end,
})

ServerTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            ))
        end)
        if ok and data and data.data then
            for _,s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP); break
                end
            end
        end
    end,
})

ServerTab:CreateButton({
    Name = "Copy Job ID",
    Callback = function()
        if setclipboard then setclipboard(game.JobId) end
        Rayfield:Notify({ Title="Copied", Content="Job ID copied", Duration=3, Image="clipboard-check" })
    end,
})

ServerTab:CreateDivider()
ServerTab:CreateSection("Utility")

ServerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true, Flag = "AntiAFK",
    Callback = function(v) State.antiAFK = v end,
})

LP.Idled:Connect(function()
    if State.antiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ============================================================
-- SETTINGS TAB
-- ============================================================
SettingsTab:CreateSection("Interface")

SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Default","AmberGlow","Amethyst","Bloom","DarkBlue","Green","Light","Ocean","Serenity"},
    CurrentOption = {"Amethyst"}, MultipleOptions = false,
    Flag = "Theme",
    Callback = function(opt)
        local name = type(opt)=="table" and opt[1] or opt
        if Window.ModifyTheme then Window.ModifyTheme(name) end
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "K", HoldToInteract = false, Flag = "ToggleUIKey",
    Callback = function() Rayfield:Toggle() end,
})

SettingsTab:CreateDivider()

SettingsTab:CreateButton({
    Name = "Destroy Script",
    Callback = function() Rayfield:Destroy() end,
})

-- ============================================================
-- Ready
-- ============================================================
Rayfield:Notify({
    Title    = "Script Loaded",
    Content  = "SpectreWare!",
    Duration = 5,
    Image    = "check-circle",   -- Lucide icon for clean look
})
