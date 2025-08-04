local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()



-- UI Setup
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Wyvern.ag",
	Footer = "@velocityontop",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Lobby", "door-open"),
    Ingame = Window:AddTab("Match", "swords"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local function setupCapsuleUI()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    local LocalPlayer = Players.LocalPlayer
    local ItemsInventory = LocalPlayer:WaitForChild("ItemsInventory")
    local GiftPass = ReplicatedStorage:WaitForChild("GiftPass")
    local UseEvent = ReplicatedStorage:WaitForChild("PlayMode").Events:WaitForChild("Use")

    local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Bundles")

    local ValidItems = {}

    -- Only include items that are in both GiftPass and the player's inventory
    for _, item in ipairs(ItemsInventory:GetChildren()) do
        if GiftPass:FindFirstChild(item.Name) then
            table.insert(ValidItems, item.Name)
        end
    end

    -- Display message and skip buttons if none found
    if #ValidItems == 0 then
        LeftGroupBox2:AddLabel("No bundles found in your inventory.", true)
        return
    end

    -- UI setup
    local SelectedItem = ValidItems[1]
    local AmountToUse = 1

    -- Dropdown to select item
    LeftGroupBox2:AddDropdown("SelectItem", {
        Text = "Choose Bundle",
        Values = ValidItems,
        Default = ValidItems[1],
        Callback = function(value)
            SelectedItem = value
        end
    })

    -- Amount input
    LeftGroupBox2:AddInput("AmountToUse", {
        Text = "Amount",
        Default = "1",
        Numeric = true,
        Finished = true,
        Callback = function(value)
            AmountToUse = tonumber(value) or 1
        end
    })

    -- Normal Use Button
    LeftGroupBox2:AddButton({
        Text = "Use Selected Item",
        Func = function()
            if not SelectedItem or AmountToUse <= 0 then
                Library:Notify({
                    Title = "Error",
                    Description = "Invalid item or amount.",
                    Time = 3
                })
                return
            end

            UseEvent:InvokeServer(SelectedItem, AmountToUse)

            Library:Notify({
                Title = "Success",
                Description = "Used " .. AmountToUse .. "x " .. SelectedItem,
                Time = 3
            })
        end,
        Tooltip = "Uses the selected capsule or bundle by specified amount."
    })

    -- Obtain Button (negative use)
    LeftGroupBox2:AddButton({
        Text = "Obtain Selected Item",
        Func = function()
            if not SelectedItem or AmountToUse <= 0 then
                Library:Notify({
                    Title = "Error",
                    Description = "Invalid item or amount.",
                    Time = 3
                })
                return
            end

            UseEvent:InvokeServer(SelectedItem, -AmountToUse)

            Library:Notify({
                Title = "Success",
                Description = "Obtained " .. AmountToUse .. "x " .. SelectedItem,
                Time = 3
            })
        end,
        Tooltip = "Gives you the selected capsule or bundle."
    })
end

setupCapsuleUI()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ItemsInventory = LocalPlayer:WaitForChild("ItemsInventory")
local GiftPass = ReplicatedStorage:WaitForChild("GiftPass")
local GiftEvent = ReplicatedStorage:WaitForChild("PlayMode").Events:WaitForChild("Gift")

local giftboxiguess = Tabs.Main:AddRightGroupbox("Auto-Gift")

-- Get giftable items from inventory
local ValidItems = {}
for _, item in ipairs(ItemsInventory:GetChildren()) do
    if GiftPass:FindFirstChild(item.Name) then
        table.insert(ValidItems, item.Name)
    end
end

if #ValidItems == 0 then
    giftboxiguess:AddLabel("❌ No giftable items.")
    return
end

-- UI State
local SelectedItem = ValidItems[1]
local TargetPlayer = ""
local IsLooping = false

giftboxiguess:AddDropdown("Gift Item", {
    Text = "Select Item",
    Values = ValidItems,
    Default = ValidItems[1],
    Callback = function(value)
        SelectedItem = value
    end
})

giftboxiguess:AddInput("Target Username", {
    Default = "",
    Placeholder = "Enter player username",
    Callback = function(value)
        TargetPlayer = value
    end
})

giftboxiguess:AddToggle("Auto-Gift Toggle", {
    Text = "Auto-Gift Enabled",
    Default = false,
    Callback = function(state)
        IsLooping = state

        if IsLooping then
            task.spawn(function()
                while IsLooping and task.wait(0.5) do
                    if TargetPlayer ~= "" and SelectedItem then
                        local args = {
                            "Gift",
                            {
                                TargetPlayer,
                                SelectedItem
                            }
                        }

                        GiftEvent:InvokeServer(unpack(args))
                    end
                end
            end)
        end
    end
})


-- UI Settings tab
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind"
})
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
