local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RimuruOnDiscord/Halcyon/refs/heads/main/test.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService      = game:GetService("RunService")
local RepStorage      = game:GetService("ReplicatedStorage")
local EggsFolder = RepStorage:WaitForChild("Assets"):WaitForChild("Eggs")
local hatchRemote = RepStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("Event")
local Module = require(game:GetService("ReplicatedStorage").Client.Effects.HatchEgg)
local originalPlay = Module.Play
local eggs = EggsFolder:GetChildren()
local Window = Library:Window{
Logo = `rbxassetid://74593959334913`,
TabWidth = 160,
Size = UDim2.fromOffset(750, 540),
Resize = true,
Acrylic = false,
Theme = "Dark",
MinimizeKey = Enum.KeyCode.RightShift

}

local Tabs = {
Hatching = Window:Tab{ Title = "Eggs", Icon = "phosphor-egg-bold"},
SettingsTab = Window:Tab{ Title = "Settings", Icon = "phosphor-gear-six-bold"},
}

local hatchSec = Tabs.Hatching:Section("Hatching")

local eggDropdown = hatchSec:Dropdown("SelectEgg", {
    Title       = "Egg Type",
    Description = "Choose an egg to hatch.",
    Values      = {},
    Multi       = false,
    Searchable = true,
    Default     = nil,
    Displayer   = function(egg) return egg.Name end,
})

eggDropdown:SetValues(eggs)
if not table.find(eggs, eggDropdown.Value) and #eggs > 0 then
    eggDropdown:SetValue(eggs[1])
end

local autoHatchToggle = hatchSec:Toggle("AutoHatch", {
    Title   = "Auto Hatch",
    Default = false,
})

local hatchAmountSlider = hatchSec:Slider("HatchAmount", {
    Title       = "Amount to hatch",
    Description = "How many to hatch each time (1–6)",
    Default     = 1,
    Min         = 1,
    Max         = 6,
    Rounding    = 0,
})

task.spawn(function()
    while true do
        if autoHatchToggle.Value and eggDropdown.Value then
            hatchRemote:FireServer(
                "HatchEgg",
                eggDropdown.Value.Name,
                hatchAmountSlider.Value
            )
        end
        task.wait(0.5)
    end
end)

local usefulSec = Tabs.Hatching:Section("Tweaks")

local skipAnimToggle = usefulSec:Toggle("SkipHatchAnimation", {
    Title   = "Skip Hatch Animation",
    Default = false,
})

Module.Play = function(self, result)
    if skipAnimToggle.Value and result and result.Pets then

        local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui")
        gui.Hatching.Visible = false
        gui.HUD.Visible     = true
        self._hatching      = false
    else

        originalPlay(self, result)
    end
end

-- Settings & Save Manager
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("nooo")
SaveManager:SetFolder("nooo/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.SettingsTab)
SaveManager:BuildConfigSection(Tabs.SettingsTab)

-- Finalize
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
