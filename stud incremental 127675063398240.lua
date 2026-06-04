local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "stud incremental",
    LoadingTitle = "stud incremental Script",
    LoadingSubtitle = "by demonalt",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Collect stud options from workspace.Studs
local studOptions = {}
local studsFolder = workspace:FindFirstChild("Studs")
if studsFolder then
    for _, part in ipairs(studsFolder:GetChildren()) do
        table.insert(studOptions, part.Name)
    end
end
if #studOptions == 0 then
    studOptions = {"Stud"}
end

local selectedStud = studOptions[1]
local currencyWait = 0.1
local xpWait = 0.1
local pointsWait = 0.1
local blocksWait = 0.1
local currencyWorkers = 1
local xpWorkers = 1
local pointsWorkers = 1
local blocksWorkers = 1
local currencyActive = false
local xpActive = false
local pointsActive = false
local blocksActive = false
local fuserActive = false
local tokensWait = 0.1
local tokensWorkers = 1
local tokensActive = false

-- ===================== MAIN TAB =====================

MainTab:CreateSection("Currency")

MainTab:CreateDropdown({
    Name = "Select Stud",
    Options = studOptions,
    CurrentOption = {selectedStud},
    MultipleOptions = false,
    Flag = "StudDropdown",
    Callback = function(option)
        selectedStud = type(option) == "table" and option[1] or option
    end,
})

MainTab:CreateSlider({
    Name = "Currency Wait (seconds)",
    Range = {0.05, 5},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "CurrencyWait",
    Callback = function(value)
        currencyWait = value
    end,
})

MainTab:CreateSlider({
    Name = "Currency Workers",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "CurrencyWorkers",
    Callback = function(value)
        currencyWorkers = value
    end,
})

MainTab:CreateToggle({
    Name = "Gain Currency",
    CurrentValue = false,
    Flag = "CurrencyToggle",
    Callback = function(state)
        currencyActive = state
        if state then
            for i = 1, currencyWorkers do
                task.spawn(function()
                    while currencyActive do
                        pcall(function()
                            game:GetService("ReplicatedStorage").Area1.CurrencyGain:FireServer(selectedStud)
                        end)
                        task.wait(currencyWait)
                    end
                end)
            end
        end
    end,
})

MainTab:CreateSection("XP")

MainTab:CreateSlider({
    Name = "XP Wait (seconds)",
    Range = {0.05, 5},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "XPWait",
    Callback = function(value)
        xpWait = value
    end,
})

MainTab:CreateSlider({
    Name = "XP Workers",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "XPWorkers",
    Callback = function(value)
        xpWorkers = value
    end,
})

MainTab:CreateToggle({
    Name = "AddXP",
    CurrentValue = false,
    Flag = "XPToggle",
    Callback = function(state)
        xpActive = state
        if state then
            for i = 1, xpWorkers do
                task.spawn(function()
                    while xpActive do
                        pcall(function()
                            game:GetService("ReplicatedStorage").AddXpEvent:FireServer()
                        end)
                        task.wait(xpWait)
                    end
                end)
            end
        end
    end,
})

MainTab:CreateSection("Points")

MainTab:CreateSlider({
    Name = "Points Wait (seconds)",
    Range = {0.05, 5},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "PointsWait",
    Callback = function(value)
        pointsWait = value
    end,
})

MainTab:CreateSlider({
    Name = "Points Workers",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "PointsWorkers",
    Callback = function(value)
        pointsWorkers = value
    end,
})

MainTab:CreateToggle({
    Name = "Gain Points",
    CurrentValue = false,
    Flag = "PointsToggle",
    Callback = function(state)
        pointsActive = state
        if state then
            for i = 1, pointsWorkers do
                task.spawn(function()
                    while pointsActive do
                        pcall(function()
                            game:GetService("ReplicatedStorage").Area2.PointsGain:FireServer(1)
                        end)
                        task.wait(pointsWait)
                    end
                end)
            end
        end
    end,
})

MainTab:CreateSection("Blocks")

MainTab:CreateSlider({
    Name = "Blocks Wait (seconds)",
    Range = {0.05, 5},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "BlocksWait",
    Callback = function(value)
        blocksWait = value
    end,
})

MainTab:CreateSlider({
    Name = "Blocks Workers",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "BlocksWorkers",
    Callback = function(value)
        blocksWorkers = value
    end,
})

MainTab:CreateToggle({
    Name = "Gain Blocks",
    CurrentValue = false,
    Flag = "BlocksToggle",
    Callback = function(state)
        blocksActive = state
        if state then
            for i = 1, blocksWorkers do
                task.spawn(function()
                    while blocksActive do
                        pcall(function()
                            game:GetService("ReplicatedStorage").Area3.BlocksGain:FireServer()
                        end)
                        task.wait(blocksWait)
                    end
                end)
            end
        end
    end,
})

MainTab:CreateSection("Tokens")

local tokenData = {
    ["WHEAT_V7_ALPHA_99"]      = "Pot2",
    ["CARROT_X2_BETA_21"]      = "Pot3",
    ["STRAWBERRY_Z5_GAMMA_44"] = "Pot2",
    ["BLUEBERRY_Q9_DELTA_12"]  = "Pot3",
    ["BLOSSOM_K3_OMEGA_88"]    = "Pot2",
}
local tokenNames = {
    "WHEAT_V7_ALPHA_99",
    "CARROT_X2_BETA_21",
    "STRAWBERRY_Z5_GAMMA_44",
    "BLUEBERRY_Q9_DELTA_12",
    "BLOSSOM_K3_OMEGA_88",
}
local selectedToken = tokenNames[1]

MainTab:CreateDropdown({
    Name = "Select Token",
    Options = tokenNames,
    CurrentOption = {selectedToken},
    MultipleOptions = false,
    Flag = "TokenDropdown",
    Callback = function(option)
        selectedToken = type(option) == "table" and option[1] or option
    end,
})

MainTab:CreateSlider({
    Name = "Tokens Wait (seconds)",
    Range = {0.05, 5},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "TokensWait",
    Callback = function(value)
        tokensWait = value
    end,
})

MainTab:CreateSlider({
    Name = "Tokens Workers",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "TokensWorkers",
    Callback = function(value)
        tokensWorkers = value
    end,
})

MainTab:CreateToggle({
    Name = "Gain Tokens",
    CurrentValue = false,
    Flag = "TokensToggle",
    Callback = function(state)
        tokensActive = state
        if state then
            for i = 1, tokensWorkers do
                task.spawn(function()
                    while tokensActive do
                        pcall(function()
                            game:GetService("ReplicatedStorage").Area5.TokenGain:FireServer(selectedToken, tokenData[selectedToken])
                        end)
                        task.wait(tokensWait)
                    end
                end)
            end
        end
    end,
})

MainTab:CreateSection("Fuser")

MainTab:CreateToggle({
    Name = "Auto Click Fuser",
    CurrentValue = false,
    Flag = "FuserToggle",
    Callback = function(state)
        fuserActive = state
        if state then
            task.spawn(function()
                while fuserActive do
                    pcall(function()
                        fireclickdetector(workspace.map.Areas.area4.Fuser.Btn.ClickDetector)
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end,
})

-- ===================== MISC TAB =====================

MiscTab:CreateSection("Titles")

MiscTab:CreateButton({
    Name = "Unlock All Titles",
    Callback = function()
        local titlesFolder = game:GetService("Players").LocalPlayer:FindFirstChild("TitlesUnlock")
        if titlesFolder then
            for _, v in ipairs(titlesFolder:GetDescendants()) do
                if v:IsA("BoolValue") then
                    v.Value = true
                end
            end
            Rayfield:Notify({
                Title = "Unlock All Titles",
                Content = "All titles unlocked!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

MiscTab:CreateSection("Gamepass")

MiscTab:CreateButton({
    Name = "Purchase All Gamepass",
    Callback = function()
        local bundleOwned = game:GetService("Players").LocalPlayer.GamepassMultipliers:FindFirstChild("BundleOwned")
        if bundleOwned then
            bundleOwned.Value = true
            Rayfield:Notify({
                Title = "Purchase All Gamepass",
                Content = "BundleOwned set to true!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

-- ===================== LOADED =====================

Rayfield:Notify({
    Title = "Gamepass",
    Content = "Script loaded successfully!",
    Duration = 4,
    Image = 4483362458,
})
