--{
----------------------------------------------------
-- 🔓 CLEAN MULTI-GAME LOADER (NO WEBHOOK / NO LOGS)
----------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- ⚙️ CONFIGURATION
----------------------------------------------------

-- Game → script link mapping
local Scripts = {
    [95841983169718] = "https://raw.githubusercontent.com/demonone23/Roblox-scripts/refs/heads/main/CoreFactory.lua",  -- Core Factory
    [123456789]      = "LINK_GAME_2",
    [987654321]      = "LINK_GAME_3",
}

----------------------------------------------------
-- 🚀 LOAD THE CORRECT SCRIPT
----------------------------------------------------

local link = Scripts[game.PlaceId]

if link then
    local success, code = pcall(function()
        return game:HttpGet(link)
    end)

    if success then
        loadstring(code)()
    else
        warn("Failed to load script for this game.")
    end
else
    warn("No script assigned for PlaceId: " .. tostring(game.PlaceId))
end
