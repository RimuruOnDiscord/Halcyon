-------------------------------
-- Client-Side Variables
-------------------------------
local infstam = false
local delay = 3
local autoGenRunning = false
local run = false

-------------------------------
-- Functions
-------------------------------
local function autogen(state)
    run = state
    
    local debounce = {}

    while run do
        task.wait()
        for _, v in pairs(game.Workspace.Map.Ingame.Map:GetChildren()) do
            if v.Name == "Generator" then
                
                if not debounce[v] then
                    debounce[v] = true
                    v:WaitForChild("Remotes"):WaitForChild("RE"):FireServer()
                    task.delay(delay, function() debounce[v] = nil end)
                end
            end
        end
    end
end

local function unlockclientcharacters()
    local clone = game.Players.LocalPlayer.PlayerData.Equipped.Skins:Clone()
    clone.Parent = game.Players.LocalPlayer.PlayerData.Purchased.Killers
    for i, v in pairs(clone:GetChildren()) do
        v.Parent = game.Players.LocalPlayer.PlayerData.Purchased.Killers
    end
    local clone2 = game.Players.LocalPlayer.PlayerData.Equipped.Skins:Clone()
    clone2.Parent = game.Players.LocalPlayer.PlayerData.Purchased.Survivors
    for i, v in pairs(clone2:GetChildren()) do
        v.Parent = game.Players.LocalPlayer.PlayerData.Purchased.Survivors
    end
end

local function InfiniteStamina(state)
    infstam = state
    local stamscript = require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)
    while infstam do
        stamscript.StaminaLossDisabled = true
        task.wait(1)
    end
    stamscript.StaminaLossDisabled = nil
end

local function solvegen()
    for i, v in pairs(game.Workspace:WaitForChild("Map").Ingame:WaitForChild("Map"):GetChildren()) do
        if v.Name == "Generator" then
            v:WaitForChild("Remotes"):WaitForChild("RE"):FireServer()
        end
    end
end

-------------------------------
-- ESP / Visuals Functions & Variables
-------------------------------
local toolhighlightActive = false
local isHighlightActive = false
local isSurvivorUtilEspActive = false
local isSurvivorHighlightActive = false
local isKillerHighlightActive = false

-- List of Survivor Utility names
local survivorutil = {
    "007n7",
    "BuildermanSentry",
    "BuildermanDispenser",
    "Pizza",
    "BuildermanSentryEffectRange"
}

local function highlighttools(state)
    toolhighlightActive = state
    print("highlighttools state:", state)
    
    local function applyHighlight(tool)
        if toolhighlightActive then
            local existinghighlight = tool:FindFirstChild("ToolHighlight")
            if not existinghighlight then
                local toolhighlight = Instance.new("Highlight")
                toolhighlight.Name = "ToolHighlight"
                toolhighlight.Parent = tool
                toolhighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                if tool.Name == "Medkit" then
                    toolhighlight.FillColor = Color3.fromRGB(0, 255, 0)
                elseif tool.Name == "BloxyCola" then
                    toolhighlight.FillColor = Color3.fromRGB(88, 57, 39)
                end
                print("Added tool highlight to:", tool.Name)
            end
        else
            local existinghighlight = tool:FindFirstChild("ToolHighlight")
            if existinghighlight then
                existinghighlight:Destroy()
                print("Removed tool highlight from:", tool.Name)
            end
        end
    end
    
    for _, v in pairs(game.Workspace:WaitForChild("Map").Ingame:GetChildren()) do
        if v:IsA("Tool") then
            applyHighlight(v)
        end
    end
    
    game.Workspace:WaitForChild("Map").Ingame.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            applyHighlight(child)
        end
    end)
end

local function toggleHighlightGen(state)
    isHighlightActive = state 
    print("toggleHighlightGen state:", state)
    
    local function applyGeneratorHighlight(generator)
        if generator.Name == "Generator" then
            local existingHighlight = generator:FindFirstChild("GeneratorHighlight")
            local progress = generator:FindFirstChild("Progress")
            
            if isHighlightActive then
                if not existingHighlight then
                    local genhighlight = Instance.new("Highlight")
                    genhighlight.Parent = generator
                    genhighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    genhighlight.Name = "GeneratorHighlight"
                    print("Added generator highlight to:", generator.Name)
                end
            else
                if existingHighlight then
                    existingHighlight:Destroy()
                    print("Removed generator highlight from:", generator.Name)
                end
                return
            end

            if progress then
                if progress.Value == 100 then
                    local highlight = generator:FindFirstChild("GeneratorHighlight")
                    if highlight then
                        highlight:Destroy()
                        print("Generator complete, removed highlight from:", generator.Name)
                    end
                    return
                end

                progress:GetPropertyChangedSignal("Value"):Connect(function()
                    if progress.Value == 100 then
                        local highlight = generator:FindFirstChild("GeneratorHighlight")
                        if highlight then
                            highlight:Destroy()
                            print("Generator reached 100, removed highlight from:", generator.Name)
                        end
                    elseif isHighlightActive and not generator:FindFirstChild("GeneratorHighlight") then
                        local genhighlight = Instance.new("Highlight")
                        genhighlight.Parent = generator
                        genhighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        genhighlight.Name = "GeneratorHighlight"
                        print("Re-added generator highlight to:", generator.Name)
                    end
                end)
            end
        end
    end

    for _, v in pairs(game.Workspace:WaitForChild("Map").Ingame:WaitForChild("Map"):GetChildren()) do
        applyGeneratorHighlight(v)
    end

    game.Workspace:WaitForChild("Map").Ingame:WaitForChild("Map").ChildAdded:Connect(function(child)
        applyGeneratorHighlight(child)
    end)
end

local function survivorutilesp(state)
    isSurvivorUtilEspActive = state
    print("survivorutilesp state:", state)
    
    local function applySurvivorUtilHighlight(model)
        local existingHighlight = model:FindFirstChild("SurvivorUtilHighlight")
        if isSurvivorUtilEspActive then
            if not existingHighlight then
                for _, util in pairs(survivorutil) do
                    if model.Name == util then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "SurvivorUtilHighlight"
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.Parent = model
                        print("Added Survivor Utility highlight to:", model.Name)
                    end
                end
            end
        else
            if existingHighlight then
                existingHighlight:Destroy()
                print("Removed Survivor Utility highlight from:", model.Name)
            end
        end
    end
    
    for _, v in pairs(game.Workspace:WaitForChild("Map").Ingame:GetChildren()) do
        if v:IsA("Model") or v:IsA("Part") then
            applySurvivorUtilHighlight(v)
        end
    end
    
    game.Workspace:WaitForChild("Map").Ingame.ChildAdded:Connect(function(child)
        if child:IsA("Model") or child:IsA("Part") then
            applySurvivorUtilHighlight(child)
        end
    end)
end

local function survivorHighlighter(state)
    isSurvivorHighlightActive = state
    print("survivorHighlighter state:", state)

    local function applySurvivorHighlight(model)
        if model:IsA("Model") and model:FindFirstChild("Head") then
            local existingBillboard = model.Head:FindFirstChild("billboard")
            local existingHighlight = model:FindFirstChild("HiThere")
            
            if isSurvivorHighlightActive then
                if not existingBillboard then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "billboard"
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = model.Head
                    
                    local textLabel = Instance.new("TextLabel", billboard)
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.Text = model.Name
                    textLabel.TextColor3 = Color3.new(1, 1, 1)
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                    textLabel.BackgroundTransparency = 1
                    print("Added survivor billboard to:", model.Name)
                end

                if not existingHighlight then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "HiThere"
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.Parent = model
                    print("Added survivor highlight to:", model.Name)
                end
            else
                if existingBillboard then
                    existingBillboard:Destroy()
                    print("Removed survivor billboard from:", model.Name)
                end
                if existingHighlight then
                    existingHighlight:Destroy()
                    print("Removed survivor highlight from:", model.Name)
                end
            end
        end
    end

    for _, v in pairs(game.Workspace.Players.Survivors:GetChildren()) do
        applySurvivorHighlight(v)
    end

    game.Workspace.Players.Survivors.ChildAdded:Connect(function(child)
        applySurvivorHighlight(child)
    end)
end

local function killerHighlighter(state)
    isKillerHighlightActive = state
    print("killerHighlighter state:", state)

    local function applyKillerHighlight(model)
        if model:IsA("Model") and model:FindFirstChild("Head") then
            local existingBillboard = model.Head:FindFirstChild("billboard")
            local existingHighlight = model:FindFirstChild("HiThere")
            
            if isKillerHighlightActive then
                if not existingBillboard then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "billboard"
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = model.Head
                    
                    local textLabel = Instance.new("TextLabel", billboard)
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.Text = model.Name
                    textLabel.TextColor3 = Color3.new(1, 0, 0)
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                    textLabel.BackgroundTransparency = 1
                    print("Added killer billboard to:", model.Name)
                end

                if not existingHighlight then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "HiThere"
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.Parent = model
                    print("Added killer highlight to:", model.Name)
                end
            else
                if existingBillboard then
                    existingBillboard:Destroy()
                    print("Removed killer billboard from:", model.Name)
                end
                if existingHighlight then
                    existingHighlight:Destroy()
                    print("Removed killer highlight from:", model.Name)
                end
            end
        end
    end

    for _, v in pairs(game.Workspace.Players.Killers:GetChildren()) do
        applyKillerHighlight(v)
    end

    game.Workspace.Players.Killers.ChildAdded:Connect(function(child)
        applyKillerHighlight(child)
    end)
end

-------------------------------
-- Load Fluent Renewed & Addons
-------------------------------
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-------------------------------
-- Create Main Window
-------------------------------
local Window = Library:CreateWindow{
    Title = "Halcyon",
    SubTitle = "Forsaken",
    TabWidth = 180,
    Transparency = false,
    Size = UDim2.fromOffset(800, 530),
    Resize = true,
    MinSize = Vector2.new(480, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
}

-------------------------------
-- TAB: VISUALS
-------------------------------
local TabVisuals = Window:CreateTab{
    Title = "Visuals",
    Icon = "phosphor-eye-bold"
}

local SectionESP = TabVisuals:CreateSection("ESP")

-- Global toggle for overall visuals
local visualsEnabled = false

-- Individual toggles for each ESP category.
SectionESP:CreateToggle("Survivors", {
    Title = "Survivors ESP",
    Default = true,
    Description = "Toggle Survivor ESP (billboards & highlights).",
    Callback = function(state)
        print("[Toggle] Survivors changed =>", state)
            survivorHighlighter(state)
    end
})

SectionESP:CreateToggle("Killer", {
    Title = "Killer ESP",
    Default = true,
    Description = "Toggle Killer ESP (billboards & highlights).",
    Callback = function(state)
        print("[Toggle] Killer changed =>", state)
            killerHighlighter(state)
    end
})

SectionESP:CreateToggle("Tools", {
    Title = "Tool ESP",
    Default = true,
    Description = "Toggle Tool highlights.",
    Callback = function(state)
        print("[Toggle] Tools changed =>", state)
            highlighttools(state)
    end
})

SectionESP:CreateToggle("Generators", {
    Title = "Generator ESP",
    Default = true,
    Description = "Toggle Generator highlights.",
    Callback = function(state)
        print("[Toggle] Generators changed =>", state)
            toggleHighlightGen(state)
    end
})

SectionESP:CreateToggle("Survivor Utilities", {
    Title = "Survivor Utility ESP",
    Default = true,
    Description = "Toggle Survivor Utility highlights.",
    Callback = function(state)
        print("[Toggle] Survivor Utilities changed =>", state)
            survivorutilesp(state)
    end
})

-- Helper function to update visuals based on each toggle's current value.
-- (This is called if the overall Visuals toggle is enabled.)
function updateVisuals()
    local survivorsState = Library.Options.Survivors.Value
    local killerState = Library.Options.Killer.Value
    local toolsState = Library.Options.Tools.Value
    local generatorsState = Library.Options.Generators.Value
    local survivorUtilState = Library.Options["Survivor Utilities"].Value

    print("\n[updateVisuals] Updating visuals:")
    print("Survivors:", survivorsState, "Killer:", killerState, "Tools:", toolsState, "Generators:", generatorsState, "Survivor Utilities:", survivorUtilState)

    survivorHighlighter(survivorsState)
    killerHighlighter(killerState)
    highlighttools(toolsState)
    toggleHighlightGen(generatorsState)
    survivorutilesp(survivorUtilState)
end

-------------------------------
-- TAB: UTILITY / ASSIST
-------------------------------
local TabUtility = Window:CreateTab{
    Title = "Utility",
    Icon = "phosphor-lightning-bold"
}

local SectionAimbot = TabUtility:CreateSection("Aimbot")
SectionAimbot:CreateDropdown("AimbotMode", {
    Title = "Aimbot Mode",
    Values = {"Chance", "Shed", "Guest1337", "c00lkid", "1x1x1x1", "Jason"},
    Multi = false,
    Default = "Chance",
    Description = "Select the aimbot mode to use."
})
SectionAimbot:CreateToggle("EnableAimbot", {
    Title = "Enable Aimbot",
    Default = false,
    Description = "Toggle the aimbot functionality."
})

local SectionAssists = TabUtility:CreateSection("Assist Options")
SectionAssists:CreateToggle("InfiniteStamina", {
    Title = "Infinite Stamina",
    Default = false,
    Description = "Toggle infinite stamina.",
    Callback = InfiniteStamina
})

-------------------------------
-- TAB: AUTOMATION
-------------------------------
local TabAutomation = Window:CreateTab{
    Title = "Automation",
    Icon = "phosphor-play-bold"
}

local SectionAutoGenerator = TabAutomation:CreateSection("Auto-Generator")
SectionAutoGenerator:CreateSlider("AutoGeneratorDelay", {
    Title = "Delay (sec)",
    Description = "Adjust the delay for auto-generation (4 to 10 seconds).",
    Default = 3,
    Min = 3,
    Max = 10,
    Rounding = 1,
    Callback  = function(value)
    delay = value
    end
})
SectionAutoGenerator:CreateToggle("EnableAutoGen", {
    Title = "Enable Auto-Generator",
    Default = false,
    Description = "Toggle auto-solve for generators.",
    Callback = function(state)
        print("[Toggle] EnableAutoGen changed =>", state)
        if state then
            autogen(true)
        else
            autogen(false)
        end
    end
})

local SectionPopup = TabAutomation:CreateSection("Popup Solver")
SectionPopup:CreateToggle("PopupSolver", {
    Title = "Enable Popup Solver",
    Default = false,
    Description = "Toggle the popup solver for 1x1x1x1."
})

-------------------------------
-- TAB: MISC
-------------------------------
local TabMisc = Window:CreateTab{
    Title = "Misc",
    Icon = "ellipsis"
}

local SectionMiscOptions = TabMisc:CreateSection("Client")
SectionMiscOptions:CreateButton{
    Title = "Unlock All Characters",
    Description = "This visually unlocks all characters.",
    Callback = function()
        Window:Dialog{
            Title = "Important",
            Content = "This feature is client-sided and will not appear on other people's end.",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        unlockclientcharacters()
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function() end
                }
            }
        }
    end
}

local SectionMovementModifiers = TabMisc:CreateSection("Player Movement Modifiers")
SectionMovementModifiers:CreateSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Adjust the character's walk speed.",
    Default = 16,
    Min = 16,
    Max = 120,
    Rounding = 0
})
SectionMovementModifiers:CreateSlider("JumpPower", {
    Title = "Jump Power",
    Description = "Adjust the character's jump power.",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0
})

-------------------------------
-- SETUP: SAVE & INTERFACE MANAGER
-------------------------------
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Window)
SaveManager:BuildConfigSection(Window)

Window:SelectTab(1)

Library:Notify{
    Title = "Halcyon - Forsaken",
    Content = "Successfully Authenticated.",
    Duration = 6
}

SaveManager:LoadAutoloadConfig()
