--// Load Fluent Renewed & Addons
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

--// Create Main Window
local Window = Library:CreateWindow{
    Title = "Halcyon",
    SubTitle = "Volleyball Legends",
    TabWidth = 180,
    Transparency = false,
    Size = UDim2.fromOffset(800, 530),
    Resize = true,
    MinSize = Vector2.new(480, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
}

--------------------------------------------------------------------------------
-- TAB 1: GAMEPLAY (Formerly "Hitbox & Visuals")
--------------------------------------------------------------------------------
local TabGameplay = Window:CreateTab{
    Title = "Enhancements",
    Icon = "wand-sparkles"
}

TabGameplay:CreateSection("Hitbox Settings")
TabGameplay:CreateToggle("HitboxExpansion", {
    Title = "Expand Ball Hitbox",
    Description = "Increases the ball's collision area for easier contact.",
    Default = false
})
TabGameplay:CreateSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Adjust how large the collision area becomes.",
    Default = 1,
    Min = 1,
    Max = 15,
    Rounding = 1
})

TabGameplay:CreateSection("Visuals")
TabGameplay:CreateToggle("ShowHitboxOverlay", {
    Title = "Show Hitbox Overlay",
    Description = "Visualize the expanded collision area in-game.",
    Default = false
})

-- Hitbox logic (unchanged)
local partConnections = {}

local function findBallModel()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant:FindFirstChild("OnHit") then
            return descendant
        end
    end
    return nil
end

local function findBallMesh(ballModel)
    for _, child in ipairs(ballModel:GetChildren()) do
        if child:IsA("MeshPart") then
            return child
        end
    end
    return nil
end

local function updateHitboxSystem()
    local ballModel = findBallModel()
    if not ballModel then return end
    local defaultPart = findBallMesh(ballModel)
    if not defaultPart then return end

    local hitboxPart = ballModel:FindFirstChild("CustomHitbox")
    if not hitboxPart then
        hitboxPart = Instance.new("Part")
        hitboxPart.Name = "CustomHitbox"
        hitboxPart.Shape = Enum.PartType.Ball
        hitboxPart.Material = Enum.Material.ForceField
        hitboxPart.Color = Color3.fromRGB(0, 0, 255)
        hitboxPart.Anchored = true
        hitboxPart.Massless = true
        hitboxPart.CanCollide = false
        hitboxPart.Parent = ballModel
    end

    local expansionEnabled = Library.Options.HitboxExpansion.Value
    local sizeMultiplier   = Library.Options.HitboxSize.Value or 1
    local overlayEnabled   = Library.Options.ShowHitboxOverlay.Value

    if expansionEnabled then
        hitboxPart.Size = defaultPart.Size * sizeMultiplier
        hitboxPart.Transparency = overlayEnabled and 0.5 or 1
    else
        hitboxPart.Size = defaultPart.Size
        hitboxPart.Transparency = 1
    end

    if partConnections[defaultPart] then
        partConnections[defaultPart]:Disconnect()
        partConnections[defaultPart] = nil
    end

    partConnections[defaultPart] = defaultPart:GetPropertyChangedSignal("CFrame"):Connect(function()
        hitboxPart.CFrame = defaultPart.CFrame
    end)
end

Library.Options.HitboxExpansion:OnChanged(updateHitboxSystem)
Library.Options.HitboxSize:OnChanged(updateHitboxSystem)
Library.Options.ShowHitboxOverlay:OnChanged(updateHitboxSystem)

workspace.DescendantAdded:Connect(function(newObj)
    if newObj:IsA("Model") and newObj:FindFirstChild("OnHit") then
        task.wait(0.1)
        updateHitboxSystem()
    end
end)

task.spawn(function()
    while task.wait(1) do
        updateHitboxSystem()
    end
end)

updateHitboxSystem()


local TabStats = Window:CreateTab{
    Title = "Stat Modifiers",
    Icon = "phosphor-sliders-bold"
}

TabStats:CreateSection("Game Multipliers")

-- Single toggle that enables/disables all stat modifiers
TabStats:CreateToggle("EnableStatModifiers", {
    Title = "Enable Stat Modifiers",
    Default = false
})

-- List of attributes we need to handle
local AttributeNames = {
    "GameDiveSpeedMultiplier",
    "GameSpikePowerMultiplier",
    "GameTiltPowerMultiplier",
    "GameSpeedMultiplier",
    "GameSetPowerMultiplier",
    "GameServePowerMultiplier",
    "GameJumpPowerMultiplier",
    "GameBumpPowerMultiplier",
    "GameBlockPowerMultiplier"
}

-- Store original values so we can revert them later
local OriginalValues = {}

-- On script load, capture the player's original attribute values
for _, attrName in ipairs(AttributeNames) do
    local original = game.Players.LocalPlayer:GetAttribute(attrName)
    if original == nil then
        -- If the attribute doesn't exist yet, assume 1 as default
        original = 1
    end
    OriginalValues[attrName] = original
end

-- We'll create a slider for each attribute
-- and store references so we can update them easily.
local Sliders = {}

for _, attrName in ipairs(AttributeNames) do
    -- For UI display, create a short label (e.g., removing "Game" prefix)
    local label = attrName:gsub("Game", "") -- e.g. "DiveSpeedMultiplier"
    TabStats:CreateSlider(attrName, {
        Title = label,
        Description = "Adjust " .. label,
        Default = OriginalValues[attrName],
        Min = 0,
        Max = 10,
        Rounding = 2
    })
    Sliders[attrName] = Library.Options[attrName]
end

-- Helper to apply or revert attribute values
local function applyStatModifiers(enable)
    for attrName, sliderRef in pairs(Sliders) do
        if enable then
            -- Set the player's attribute to the slider's value
            game.Players.LocalPlayer:SetAttribute(attrName, sliderRef.Value)
        else
            -- Revert to the original value
            game.Players.LocalPlayer:SetAttribute(attrName, OriginalValues[attrName])
        end
    end
end

-- Listen for changes to each slider
for attrName, sliderRef in pairs(Sliders) do
    sliderRef:OnChanged(function(newValue)
        -- Only apply if the main toggle is on
        if Library.Options.EnableStatModifiers.Value then
            game.Players.LocalPlayer:SetAttribute(attrName, newValue)
        end
    end)
end

-- Listen for changes to the main toggle
Library.Options.EnableStatModifiers:OnChanged(function(enabled)
    applyStatModifiers(enabled)
end)

local TabOffense = Window:CreateTab{
    Title = "Assistance",
    Icon = "phosphor-crosshair-bold"
}

TabOffense:CreateSection("Serving Options")

TabOffense:CreateSlider("ServePower", {
    Title = "Serve Power",
    Description = "Adjust the serve strength multiplier.",
    Default = 1,
    Min = 0,
    Max = 6,
    Rounding = 1
})

local Keybind = TabOffense:AddKeybind("Keybind", {
    Title = "Serve KeyBind",
    Mode = "Always", -- Always, Toggle, Hold
    Default = "C",
    Callback = function()
        local servePower = Library.Options.ServePower.Value or 1
        local ohVector31 = Vector3.new(0, servePower, 0)
        local ohNumber2 = 1
        game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(ohVector31, ohNumber2)
    end
})

TabOffense:CreateSection("Shot Automation")

TabOffense:CreateToggle("AutoServe", {
    Title = "Auto Serve",
    Description = "Automatically serve the ball when possible.",
    Default = false
})
TabOffense:CreateToggle("AutoSpike", {
    Title = "Auto Spike",
    Description = "Automatically spike the ball when possible.",
    Default = false
})
TabOffense:CreateToggle("AutoBlock", {
    Title = "Auto Block",
    Description = "Automatically block incoming shots at the net.",
    Default = false
})
TabOffense:CreateToggle("AutoSet", {
    Title = "Auto Set",
    Description = "Automatically set incoming shots.",
    Default = false
})
TabOffense:CreateToggle("AutoBump", {
    Title = "Auto Bump",
    Description = "Automatically perform a bump when needed.",
    Default = false
})

-- AutoSpike logic (unchanged)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local localPlayer = Players.LocalPlayer
local ws = workspace
local mouse = localPlayer:GetMouse()

local spikeAnimation = Instance.new("Animation")
spikeAnimation.AnimationId = "rbxassetid://109794030888371"

local function isPointInsidePart(point, part)
    local relativePos = part.CFrame:PointToObjectSpace(point)
    local halfSize = part.Size * 0.5
    return math.abs(relativePos.X) <= halfSize.X 
       and math.abs(relativePos.Y) <= halfSize.Y 
       and math.abs(relativePos.Z) <= halfSize.Z
end

local function findBallModel()
    for _, model in ipairs(ws:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("OnHit") then
            return model
        end
    end
    return nil
end

local function spikeBall()
    local ballModel = findBallModel()
    if not ballModel then
        return
    end

    local customHitbox = ballModel:FindFirstChild("CustomHitbox")
    if not customHitbox then
        return
    end

    local character = localPlayer.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not (hrp and humanoid) then
        return
    end

    local state = humanoid:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
        return
    end

    if not isPointInsidePart(hrp.Position, customHitbox) then
        return
    end

    if math.abs(hrp.Velocity.Y) > 4.5 then
        return
    end

    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
    print("AutoSpike: Simulated left click at:", mouse.X, mouse.Y)

    local animTrack = humanoid:LoadAnimation(spikeAnimation)
    animTrack:Play()
end

task.spawn(function()
    while task.wait(0.04) do
        if Library.Options.AutoSpike and Library.Options.AutoSpike.Value then
            spikeBall()
        end
    end
end)


--------------------------------------------------------------------------------
-- TAB 3: MOVEMENT (Formerly "Movement & Rotation")
--------------------------------------------------------------------------------
local TabMovement = Window:CreateTab{
    Title = "Movement",
    Icon = "phosphor-compass-bold"
}

TabMovement:CreateSection("Aerial Controls")
TabMovement:CreateToggle("AerialRotation", {
    Title = "Aerial Rotation (Shiftlock)",
    Description = "Allows rotating your camera freely while airborne.",
    Default = false
})

local camera = workspace.CurrentCamera

task.spawn(function()
    while task.wait() do
        if Library.Options.AerialRotation.Value then
            local character = localPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if humanoid and hrp then
                    local state = humanoid:GetState()
                    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
                        local camLook = camera.CFrame.LookVector
                        local horizontalLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + horizontalLook)
                    end
                end
            end
        end
    end
end)

local TabSpin = Window:CreateTab{
    Title = "Auto Spin",
    Icon = "phosphor-repeat-bold"
}

TabSpin:CreateSection("Auto Spin Controls")

TabSpin:CreateSlider("SpinLimit", {
    Title = "Spin Count Limit",
    Description = "Number of spins before stopping (0 = infinite).",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 0
})

TabSpin:CreateDropdown("SpinType", {
    Title = "Spin Type",
    Values = {"Normal Spin","Lucky Spin"},
    Multi = false,
    Default = "Normal Spin",
    Description = "Choose what spin type you want to use."
})

TabSpin:CreateDropdown("SpinStyle", {
    Title = "Select Rarity",
    Values = {"Common", "Rare", "Legendary","Godly","Secret"},
    Multi = false,
    Default = 1,
    Description = "Choose how your spin behaves."
})

TabSpin:CreateDropdown("SpinStyle", {
    Title = "Select Spin Style",
    Values = {"None","Hinoto", "Legendary", "Slow Mo"},
    Multi = false,
    Default = "None",
    Description = "Choose what rarity for you to stop."
})

TabSpin:CreateToggle("InfiniteSpinToggle", {
    Title = "Enable Data Rollback",
    Default = false,
    Description = "Rolls your data back after spinning."
})

TabSpin:CreateToggle("AutoSpinToggle", {
    Title = "Enable Auto Spin",
    Default = false,
    Description = "Automatically spin for style."
})

--------------------------------------------------------------------------------
-- TAB 5: IDENTITY (Formerly "Profile Spoofer")
--------------------------------------------------------------------------------
local TabIdentity = Window:CreateTab{
    Title = "Profile Spoofer",
    Icon = "phosphor-question-bold"
}

TabIdentity:CreateSection("Local Player Data")
TabIdentity:CreateInput("NameSpoof", {
    Title = "Player Name",
    Default = "",
    Placeholder = game.Players.LocalPlayer.Name,
    Callback = function(newValue)
        print("Name spoofed to:", newValue)
    end
})
TabIdentity:CreateInput("StyleSpoof", {
    Title = "Style",
    Default = "",
    Placeholder = game:GetService("Players").LocalPlayer.PlayerGui.Interface.Lobby.Styles.TopPanel.DisplayName.Text,
    Callback = function(newValue)
        print("Style name spoofed to:", newValue)
    end
})
TabIdentity:CreateInput("LevelSpoof", {
    Title = "Level",
    Default = "",
    Placeholder = string.sub(game:GetService("Players").LocalPlayer.PlayerGui.Interface.Stats.LeftSidePanel.PlayerLevelButton.Amount.Text, 5),
    Callback = function(newValue)
        print("Level spoofed to:", newValue)
    end
})
TabIdentity:CreateInput("YenSpoof", {
    Title = "Yen",
    Default = "",
    Placeholder = game:GetService("Players").LocalPlayer.PlayerGui.Interface.Stats.LeftSidePanel.YenAmountButton.Amount.Text,
    Callback = function(newValue)
        print("Yen spoofed to:", newValue)
    end
})
TabIdentity:CreateInput("BackNumberSpoof", {
    Title = "Back Jersey No.",
    Default = "",
    Placeholder = "Enter a number...",
    Callback = function(newValue)
        print("Back jersey number spoofed to:", newValue)
    end
})
TabIdentity:CreateInput("FrontNumberSpoof", {
    Title = "Front Jersey No.",
    Default = "",
    Placeholder = "Enter a number...",
    Callback = function(newValue)
        print("Front jersey number spoofed to:", newValue)
    end
})
TabIdentity:CreateToggle("EnableSpoofing", {
    Title = "Enable Spoofing",
    Default = false,
    Description = "Globally enable or disable all spoofed values."
})


--------------------------------------------------------------------------------
-- TAB 7: SETTINGS
--------------------------------------------------------------------------------
local TabSettings = Window:CreateTab{
    Title = "Settings",
    Icon = "phosphor-gear-six-bold"
}

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(TabSettings)
SaveManager:BuildConfigSection(TabSettings)

-- Select the first tab upon loading
Window:SelectTab(1)

-- Notify user that UI has loaded
Library:Notify{
    Title = "Halcyon - Volleyball Legends",
    Content = "Successfully Authenticated.",
    Duration = 6
}

SaveManager:LoadAutoloadConfig()
