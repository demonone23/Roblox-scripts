-- DRM inf item script.lua
-- LocalScript - StarterPlayerScripts

-- ── Anti-AFK ──────────────────────────────────────────────────
local VU = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
	VU:CaptureController()
	VU:ClickButton2(Vector2.new(0, 0))
end)

-- ── Rayfield ──────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()


-- ── Services ──────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local player  = Players.LocalPlayer

-- ── Remotes ───────────────────────────────────────────────────
local Rem        = RS:WaitForChild("Remotes")
local rSacrifice = Rem:WaitForChild("SacrificeItem")
local rUseItem   = Rem:WaitForChild("UseItem")
local rOpenCrate = Rem:WaitForChild("OpenCrate")
local rRoll      = Rem:WaitForChild("Roll")
local rClick     = Rem:WaitForChild("Click")
local rGlyph     = Rem:WaitForChild("RollGlyph")
local rYatzy     = Rem:WaitForChild("YatzyRoll")
local rCoinFlip  = Rem:WaitForChild("CoinFlip")
local rRollQuirk = Rem:WaitForChild("RollQuirk")
local rSetTitle    = Rem:WaitForChild("SetTitle")
local rRedeemCode  = Rem:WaitForChild("RedeemCode")
local rClaimMastery = Rem:WaitForChild("ClaimMastery")
local rBallLanded   = Rem:WaitForChild("BallLanded")

-- ── Data ──────────────────────────────────────────────────────
local ALL_ITEMS = {
	"Apple", "Avocado", "Banana", "Blueberries", "Burger", "Carrot", "Cherries",
	"Cookie", "Fried Chicken", "Grapes", "Lemon", "Orange", "Pear", "Pineapple",
	"Pizza", "Strawberry",
	"Amethyst Clover", "Clover", "Diamond Clover", "Ruby Clover",
	"Lucky Vial", "Fortune Vial", "XP Vial", "Stats Vial", "Runic Vial",
	"Dice", "Super Dice", "Ultra Dice", "Inverted Dice",
	"Fortune Rift", "Power Rift", "Echo Rift", "Rapid Rift", "Lucky Rift",
	"Gravity Coil", "Speed Coil", "Super Coil", "Regen Coil", "Fusion Coil",
	"Cursor", "Golden Cursor",
	"Hourglass", "Lucky Block", "Divine Heart", "Holy Heart",
	"Mini Chest", "Mini Chest II", "Mini Chest III", "Mini Chest IV",
	"Quest Reroll",
}

local ALL_CRATES = {
	"Basic Crate", "Golden Crate", "Rainbow Crate", "Galaxy Crate", "Abyss Crate",
}

local RUNE_NAMES = {
	"Hype Rune", "Celebration Rune",
	"Basic Rune", "Roller Rune", "Qualities Rune", "Ancient Rune",
}

local RUNE_POS = {
	["Hype Rune"]        = Vector3.new(  21, 38, 104),
	["Celebration Rune"] = Vector3.new( -33, 38, 102),
	["Basic Rune"]       = Vector3.new(   2, 10,   1),
	["Roller Rune"]      = Vector3.new(-239, 10,   4),
	["Qualities Rune"]   = Vector3.new(-557, 10, -66),
	["Ancient Rune"]     = Vector3.new(-927, 10,   8),
}

-- ── State ─────────────────────────────────────────────────────
local selItem    = ALL_ITEMS[1]
local selCrate   = ALL_CRATES[1]
local selRune    = RUNE_NAMES[1]
local useCount   = 100
local useWorkers = 1
local useDelay   = 0.15
local crateAmt        = 1000000
local crateOpenOn     = false
local crateOpenPool   = {}
local crateOpenRps    = 20
local crateOpenWorkers = 4
local useOn      = false
local usePool    = {}

local diceDelay  = 0.2
local diceOn     = false
local diceTh     = nil

local clickDelay = 0.05
local clickOn    = false
local clickTh    = nil

local glyphDelay = 0.05
local glyphOn    = false
local glyphTh    = nil

local yatzyDelay = 0.2
local yatzyOn    = false
local yatzyTh    = nil

local coinDelay  = 0.2
local coinOn     = false
local coinTh     = nil

local quirkDelay = 0.2
local quirkOn    = false
local quirkTh    = nil

local tpMins     = 5
local tpOn       = false
local tpTh       = nil

local pointsOn   = false
local pointsTh   = nil

local titleName     = "Starter"
local titleColor    = Color3.new(0.792, 1, 0.620)
local rainbowOn     = false
local rainbowThread = nil
local rainbowSpeed  = 0.005

-- ── Helpers ───────────────────────────────────────────────────
local function fmtNum(n)
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9  then return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6  then return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3  then return string.format("%.2fK", n / 1e3)
	else                  return string.format("%.0f",  n)
	end
end

-- ── NaN → inf patcher ─────────────────────────────────────────
local function isNaN(n) return n ~= n end

task.spawn(function()
	local data  = player:WaitForChild("Data",  10)
	if not data then return end
	local items = data:WaitForChild("Items", 10)
	if not items then return end
	while true do
		task.wait(0.1)
		for _, obj in ipairs(items:GetChildren()) do
			if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and obj.Value ~= obj.Value then
				obj.Value = 1
			end
		end
	end
end)

-- ── Hide "Max" badge when item count is inf ───────────────────
task.spawn(function()
	local gui = player:WaitForChild("PlayerGui", 10)
	if not gui then return end

	local ok, maxLabel = pcall(function()
		return gui
			:WaitForChild("Interface", 10)
			:WaitForChild("Frames",    10)
			:WaitForChild("Inventory", 10)
			:WaitForChild("Top",       10)
			:WaitForChild("Info",      10)
			:WaitForChild("Max",       10)
	end)

	if not ok or not maxLabel then return end

	local function checkAndHide()
		if maxLabel.Visible then
			maxLabel.Visible = false
		end
	end

	checkAndHide()
	maxLabel:GetPropertyChangedSignal("Visible"):Connect(checkAndHide)
end)

-- ── Destroy crate popup / auto unbox UI ───────────────────────
local BLOCKED_UI = { ["CratePopups"] = true, ["Auto Unbox"] = true }
task.spawn(function()
	local gui = player:WaitForChild("PlayerGui", 10)
	if not gui then return end
	local interface = gui:WaitForChild("Interface", 10)
	if not interface then return end
	for _, child in ipairs(interface:GetChildren()) do
		if BLOCKED_UI[child.Name] then child:Destroy() end
	end
	interface.ChildAdded:Connect(function(child)
		if BLOCKED_UI[child.Name] then child:Destroy() end
	end)
end)

-- ── Helper to resolve dropdown value ──────────────────────────
local function resolve(v)
	if type(v) == "table" then return v[1] else return v end
end

-- ┌──────────────────────────────────────────────────────────────┐
-- │  Window                                                      │
-- └──────────────────────────────────────────────────────────────┘
local Window = Rayfield:CreateWindow({
	Name     = "DRI",
	ScriptID = "sid_3uf47jwjfd1b",
})


-- ┌──────────────────────────────────────────────────────────────┐
-- │  STATS TAB                                                   │
-- └──────────────────────────────────────────────────────────────┘
local StatsTab = Window:CreateTab("Stats", "bar-chart-2")

StatsTab:CreateSection("Live Stats")

local statRollsLabel    = StatsTab:CreateParagraph({ Title = "Rolls",           Content = "loading..." })
local statGlyphsLabel   = StatsTab:CreateParagraph({ Title = "Glyphs Rolled",   Content = "loading..." })
local statRaritiesLabel = StatsTab:CreateParagraph({ Title = "Rarities Rolled", Content = "loading..." })

task.spawn(function()
	local lastRolls    = 0
	local lastGlyphs   = 0
	local lastRarities = 0
	local lastTime     = tick()

	pcall(function() lastRolls    = player.leaderstats.Rolls.Value end)
	pcall(function() lastGlyphs   = player.Data.Stats["Glyphs Rolled"].Value end)
	pcall(function() lastRarities = player.Data.Stats["Rarities Rolled"].Value end)

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local curRolls, curGlyphs, curRarities = lastRolls, lastGlyphs, lastRarities
		pcall(function() curRolls    = player.leaderstats.Rolls.Value end)
		pcall(function() curGlyphs   = player.Data.Stats["Glyphs Rolled"].Value end)
		pcall(function() curRarities = player.Data.Stats["Rarities Rolled"].Value end)

		local psRolls    = curRolls    - lastRolls
		local psGlyphs   = curGlyphs   - lastGlyphs
		local psRarities = curRarities - lastRarities
		lastRolls    = curRolls
		lastGlyphs   = curGlyphs
		lastRarities = curRarities

		local function line(total, ps)
			return fmtNum(total) .. " total  |  " ..
				fmtNum(ps) .. "/s   " ..
				fmtNum(ps * 60) .. "/min   " ..
				fmtNum(ps * 3600) .. "/h   " ..
				fmtNum(ps * 86400) .. "/d"
		end

		pcall(function() statRollsLabel:Set(   { Title = "Rolls",           Content = line(curRolls,    psRolls)    }) end)
		pcall(function() statGlyphsLabel:Set(  { Title = "Glyphs Rolled",   Content = line(curGlyphs,   psGlyphs)   }) end)
		pcall(function() statRaritiesLabel:Set({ Title = "Rarities Rolled", Content = line(curRarities, psRarities) }) end)
	end
end)

-- ┌──────────────────────────────────────────────────────────────┐
-- │  AUTO TAB                                                    │
-- └──────────────────────────────────────────────────────────────┘
local AutoTab = Window:CreateTab("Auto", "zap")

AutoTab:CreateSection("⚠  Warning")
AutoTab:CreateLabel("Disable AutoRoll (from group) before using Auto Roll (from script)")

AutoTab:CreateSection("Auto Roll Dice")

AutoTab:CreateInput({
	Name                     = "Rolls per second  (min 0.1, max 10)",
	PlaceholderText          = "5",
	RemoveTextAfterFocusLost = false,
	Flag                     = "dice_delay",
	Callback                 = function(v)
		local rps = math.max(0.1, math.min(10, tonumber(v) or 5))
		diceDelay = 1 / rps
	end,
})

local diceStatsLabel
local diceFireCount = 0

local function setDiceStats(text)
	pcall(function()
		diceStatsLabel:Set({ Title = "Roll Rate", Content = text })
	end)
end

AutoTab:CreateToggle({
	Name         = "Auto Roll Dice",
	CurrentValue = false,
	Flag         = "dice_toggle",
	Callback     = function(on)
		diceOn = on
		if on then
			diceFireCount = 0
			diceTh = task.spawn(function()
				local lastFire = 0
				while diceOn do
					local now = tick()
					if now - lastFire >= diceDelay then
						lastFire = now
						rRoll:FireServer()
						diceFireCount += 1
					end
					task.wait(0.01)
				end
			end)
		else
			if diceTh then task.cancel(diceTh); diceTh = nil end
		end
	end,
})

-- paragraph appears below the toggle
diceStatsLabel = AutoTab:CreateParagraph({ Title = "Roll Rate", Content = "-/s   -/min   -/h   -/d   |   0 fires/s" })

-- always-on stats thread: updates every second regardless of toggle state
task.spawn(function()
	local lastVal   = 0
	local lastFires = 0
	local lastTime  = tick()
	pcall(function() lastVal = player.leaderstats.Rolls.Value end)

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local curVal = lastVal
		pcall(function() curVal = player.leaderstats.Rolls.Value end)
		local ps      = curVal - lastVal
		lastVal       = curVal

		local fired   = diceFireCount - lastFires
		lastFires     = diceFireCount
		local realRps = elapsed > 0 and (fired / elapsed) or 0
		local fires   = diceOn and string.format("%.4g", realRps) or "0"

		setDiceStats(
			fmtNum(ps) .. "/s   " ..
			fmtNum(ps * 60) .. "/min   " ..
			fmtNum(ps * 3600) .. "/h   " ..
			fmtNum(ps * 86400) .. "/d   |   " .. fires .. " fires/s"
		)
	end
end)

AutoTab:CreateSection("Auto Click")

AutoTab:CreateInput({
	Name                    = "Delay  (sec, min 0.03)",
	PlaceholderText         = "0.05",
	RemoveTextAfterFocusLost = false,
	Flag                    = "click_delay",
	Callback                = function(v)
		clickDelay = math.max(0.03, tonumber(v) or 0.05)
	end,
})

AutoTab:CreateToggle({
	Name         = "Auto Click",
	CurrentValue = false,
	Flag         = "click_toggle",
	Callback     = function(on)
		clickOn = on
		if on then
			clickTh = task.spawn(function()
				local lastFire = 0
				while clickOn do
					local now = tick()
					if now - lastFire >= clickDelay then
						lastFire = now
						rClick:FireServer(9)
					end
					task.wait(0.01)
				end
			end)
		else
			if clickTh then task.cancel(clickTh); clickTh = nil end
		end
	end,
})

AutoTab:CreateSection("Auto Roll Glyphs")

AutoTab:CreateInput({
	Name                    = "Delay  (sec, min 0.03)",
	PlaceholderText         = "0.05",
	RemoveTextAfterFocusLost = false,
	Flag                    = "glyph_delay",
	Callback                = function(v)
		glyphDelay = math.max(0.03, tonumber(v) or 0.05)
	end,
})

local glyphStatsLabel
local glyphFireCount = 0

local function setGlyphStats(text)
	pcall(function()
		glyphStatsLabel:Set({ Title = "Glyph Rate", Content = text })
	end)
end

AutoTab:CreateToggle({
	Name         = "Auto Roll Glyphs",
	CurrentValue = false,
	Flag         = "glyph_toggle",
	Callback     = function(on)
		glyphOn = on
		if on then
			glyphFireCount = 0
			glyphTh = task.spawn(function()
				local lastFire = 0
				while glyphOn do
					local now = tick()
					if now - lastFire >= glyphDelay then
						lastFire = now
						rGlyph:InvokeServer()
						glyphFireCount += 1
					end
					task.wait(0.01)
				end
			end)
		else
			if glyphTh then task.cancel(glyphTh); glyphTh = nil end
		end
	end,
})

glyphStatsLabel = AutoTab:CreateParagraph({ Title = "Glyph Rate", Content = "-/s   -/min   -/h   -/d   |   0 fires/s" })

task.spawn(function()
	local lastVal   = 0
	local lastFires = 0
	local lastTime  = tick()
	pcall(function() lastVal = player.Data.Stats["Glyphs Rolled"].Value end)

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local curVal = lastVal
		pcall(function() curVal = player.Data.Stats["Glyphs Rolled"].Value end)
		local ps      = curVal - lastVal
		lastVal       = curVal

		local fired   = glyphFireCount - lastFires
		lastFires     = glyphFireCount
		local realRps = elapsed > 0 and (fired / elapsed) or 0
		local fires   = glyphOn and string.format("%.4g", realRps) or "0"

		setGlyphStats(
			fmtNum(ps) .. "/s   " ..
			fmtNum(ps * 60) .. "/min   " ..
			fmtNum(ps * 3600) .. "/h   " ..
			fmtNum(ps * 86400) .. "/d   |   " .. fires .. " fires/s"
		)
	end
end)

AutoTab:CreateSection("Auto Yatzy Roll")

AutoTab:CreateInput({
	Name                     = "Rolls per second  (min 0.1, max 10)",
	PlaceholderText          = "5",
	RemoveTextAfterFocusLost = false,
	Flag                     = "yatzy_delay",
	Callback                 = function(v)
		local rps = math.max(0.1, math.min(10, tonumber(v) or 5))
		yatzyDelay = 1 / rps
	end,
})

local yatzyStatsLabel
local yatzyFireCount = 0

local function setYatzyStats(text)
	pcall(function()
		yatzyStatsLabel:Set({ Title = "Yatzy Roll Rate", Content = text })
	end)
end

AutoTab:CreateToggle({
	Name         = "Auto Yatzy Roll",
	CurrentValue = false,
	Flag         = "yatzy_toggle",
	Callback     = function(on)
		yatzyOn = on
		if on then
			yatzyFireCount = 0
			yatzyTh = task.spawn(function()
				local lastFire = 0
				while yatzyOn do
					local now = tick()
					if now - lastFire >= yatzyDelay then
						lastFire = now
						rYatzy:FireServer()
						yatzyFireCount += 1
					end
					task.wait(0.01)
				end
			end)
		else
			if yatzyTh then task.cancel(yatzyTh); yatzyTh = nil end
		end
	end,
})

yatzyStatsLabel = AutoTab:CreateParagraph({ Title = "Yatzy Roll Rate", Content = "0 fires/s" })

task.spawn(function()
	local lastFires = 0
	local lastTime  = tick()

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local fired   = yatzyFireCount - lastFires
		lastFires     = yatzyFireCount
		local realRps = elapsed > 0 and (fired / elapsed) or 0
		local fires   = yatzyOn and string.format("%.4g", realRps) or "0"

		setYatzyStats(fires .. " fires/s")
	end
end)

AutoTab:CreateSection("Auto Coin Flip")

AutoTab:CreateInput({
	Name                     = "Rolls per second  (min 0.1, max 10)",
	PlaceholderText          = "5",
	RemoveTextAfterFocusLost = false,
	Flag                     = "coin_delay",
	Callback                 = function(v)
		local rps = math.max(0.1, math.min(10, tonumber(v) or 5))
		coinDelay = 1 / rps
	end,
})

local coinStatsLabel
local coinFireCount = 0

local function setCoinStats(text)
	pcall(function()
		coinStatsLabel:Set({ Title = "Coin Flip Rate", Content = text })
	end)
end

AutoTab:CreateToggle({
	Name         = "Auto Coin Flip",
	CurrentValue = false,
	Flag         = "coin_toggle",
	Callback     = function(on)
		coinOn = on
		if on then
			coinFireCount = 0
			coinTh = task.spawn(function()
				local lastFire = 0
				while coinOn do
					local now = tick()
					if now - lastFire >= coinDelay then
						lastFire = now
						rCoinFlip:FireServer()
						coinFireCount += 1
					end
					task.wait(0.01)
				end
			end)
		else
			if coinTh then task.cancel(coinTh); coinTh = nil end
		end
	end,
})

coinStatsLabel = AutoTab:CreateParagraph({ Title = "Coin Flip Rate", Content = "0 fires/s" })

task.spawn(function()
	local lastFires = 0
	local lastTime  = tick()

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local fired   = coinFireCount - lastFires
		lastFires     = coinFireCount
		local realRps = elapsed > 0 and (fired / elapsed) or 0
		local fires   = coinOn and string.format("%.4g", realRps) or "0"

		setCoinStats(fires .. " fires/s")
	end
end)

local selectedQuirkTypes = {}

AutoTab:CreateSection("Auto Roll Quirk")

AutoTab:CreateDropdown({
	Name            = "Quirk Types to Roll",
	Options         = { "Rarities", "Runes", "Rolling", "Cash", "Essence", "Tempo", "XP", "Coins" },
	CurrentOption   = {},
	MultipleOptions = true,
	Flag            = "quirk_types",
	Callback        = function(v)
		selectedQuirkTypes = type(v) == "table" and v or { v }
	end,
})

AutoTab:CreateInput({
	Name                     = "Rolls per second  (min 0.1, max 10)",
	PlaceholderText          = "5",
	RemoveTextAfterFocusLost = false,
	Flag                     = "quirk_delay",
	Callback                 = function(v)
		local rps = math.max(0.1, math.min(10, tonumber(v) or 5))
		quirkDelay = 1 / rps
	end,
})

local quirkStatsLabel
local quirkFireCount = 0

local function setQuirkStats(text)
	pcall(function()
		quirkStatsLabel:Set({ Title = "Quirk Roll Rate", Content = text })
	end)
end

AutoTab:CreateToggle({
	Name         = "Auto Roll Quirk",
	CurrentValue = false,
	Flag         = "quirk_toggle",
	Callback     = function(on)
		quirkOn = on
		if on then
			quirkFireCount = 0
			quirkTh = task.spawn(function()
				local lastFire = 0
				while quirkOn do
					local now = tick()
					if now - lastFire >= quirkDelay then
						lastFire = now
						for _, t in ipairs(selectedQuirkTypes) do
							rRollQuirk:InvokeServer("Roll", t)
						end
						quirkFireCount += 1
					end
					task.wait(0.01)
				end
			end)
		else
			if quirkTh then task.cancel(quirkTh); quirkTh = nil end
		end
	end,
})

quirkStatsLabel = AutoTab:CreateParagraph({ Title = "Quirk Roll Rate", Content = "0 fires/s" })

task.spawn(function()
	local lastFires = 0
	local lastTime  = tick()

	while true do
		task.wait(1)
		local now     = tick()
		local elapsed = now - lastTime
		lastTime      = now

		local fired   = quirkFireCount - lastFires
		lastFires     = quirkFireCount
		local realRps = elapsed > 0 and (fired / elapsed) or 0
		local fires   = quirkOn and string.format("%.4g", realRps) or "0"

		setQuirkStats(fires .. " fires/s")
	end
end)

AutoTab:CreateSection("Auto Claim Mastery")

local masteryOn = false
local masteryTh = nil

AutoTab:CreateToggle({
	Name         = "Auto Claim Mastery",
	CurrentValue = false,
	Flag         = "mastery_toggle",
	Callback     = function(on)
		masteryOn = on
		if on then
			masteryTh = task.spawn(function()
				while masteryOn do
					local names = {}
					pcall(function()
						for _, v in ipairs(player.Data.Mastery:GetChildren()) do
							table.insert(names, v.Name)
						end
					end)
					for _, name in ipairs(names) do
						if not masteryOn then break end
						rClaimMastery:FireServer(name)
						task.wait(0.5)
					end
					task.wait(1)
				end
			end)
		else
			if masteryTh then task.cancel(masteryTh); masteryTh = nil end
		end
	end,
})

AutoTab:CreateSection("Auto Get Points")

AutoTab:CreateToggle({
	Name         = "Auto Get Points",
	CurrentValue = false,
	Flag         = "points_toggle",
	Callback     = function(on)
		pointsOn = on
		if on then
			pointsTh = task.spawn(function()
				while pointsOn do
					rBallLanded:FireServer(1)
					task.wait(0.5)
				end
			end)
		else
			if pointsTh then task.cancel(pointsTh); pointsTh = nil end
		end
	end,
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  ITEMS TAB                                                   │
-- └──────────────────────────────────────────────────────────────┘
local ItemsTab = Window:CreateTab("Items", "package")

ItemsTab:CreateSection("⚠  Notice")
ItemsTab:CreateLabel("Give ∞ Item / Crate only works after having unlocked Essences.")

ItemsTab:CreateSection("Item Selection")

ItemsTab:CreateDropdown({
	Name            = "Select Item",
	Options         = ALL_ITEMS,
	CurrentOption   = { ALL_ITEMS[1] },
	MultipleOptions = false,
	Flag            = "sel_item",
	Callback        = function(v) selItem = resolve(v) end,
})

ItemsTab:CreateSection("Give Infinite Items")

ItemsTab:CreateButton({
	Name     = "Give ∞ of Selected Item",
	Info     = "Gives unlimited of the selected item and displays it as inf in your inventory",
	Callback = function()
		if not selItem then
			Rayfield:Notify({ Title = "Error", Content = "Select an item first!", Duration = 3, Image = 4483362458 })
			return
		end
		rSacrifice:FireServer(selItem, 0/0)
		Rayfield:Notify({ Title = "Done", Content = "Gave ∞  " .. selItem, Duration = 3, Image = 4483362458 })
	end,
})

ItemsTab:CreateSection("Use Item")

ItemsTab:CreateInput({
	Name                     = "Times to Use  (0 = infinite)",
	PlaceholderText          = "100",
	RemoveTextAfterFocusLost = false,
	Flag                     = "use_count",
	Callback                 = function(v)
		useCount = math.max(0, math.floor(tonumber(v) or 100))
	end,
})

ItemsTab:CreateInput({
	Name                     = "Workers  (parallel threads)",
	PlaceholderText          = "1",
	RemoveTextAfterFocusLost = false,
	Flag                     = "use_workers",
	Callback                 = function(v)
		useWorkers = math.max(1, math.floor(tonumber(v) or 1))
	end,
})

ItemsTab:CreateInput({
	Name                     = "Delay per Worker  (sec, min 0.03)",
	PlaceholderText          = "0.15",
	RemoveTextAfterFocusLost = false,
	Flag                     = "use_delay",
	Callback                 = function(v)
		useDelay = math.max(0.03, tonumber(v) or 0.15)
	end,
})

ItemsTab:CreateToggle({
	Name         = "Use Item",
	Info         = "Start / stop using the selected item",
	CurrentValue = false,
	Flag         = "use_toggle",
	Callback     = function(on)
		if on then
			if not selItem then
				Rayfield:Notify({ Title = "Error", Content = "Select an item first!", Duration = 3, Image = 4483362458 })
				return
			end
			local infinite = (useCount == 0)
			local total    = 0
			local done     = 0
			useOn   = true
			usePool = {}
			local item = selItem
			for _ = 1, useWorkers do
				local t = task.spawn(function()
					while useOn do
						if not infinite then
							if total >= useCount then break end
							total += 1
						else
							total += 1
						end
						rUseItem:FireServer(item, false)
						task.wait(useDelay)
					end
					done += 1
					if done >= useWorkers and useOn then
						useOn   = false
						usePool = {}
						Rayfield:Notify({ Title = "Finished", Content = "Used " .. item .. " × " .. total, Duration = 4, Image = 4483362458 })
					end
				end)
				table.insert(usePool, t)
			end
		else
			useOn = false
			for _, t in ipairs(usePool) do task.cancel(t) end
			usePool = {}
		end
	end,
})

ItemsTab:CreateSection("Crate Selection")

ItemsTab:CreateDropdown({
	Name            = "Select Crate",
	Options         = ALL_CRATES,
	CurrentOption   = { ALL_CRATES[1] },
	MultipleOptions = false,
	Flag            = "sel_crate",
	Callback        = function(v) selCrate = resolve(v) end,
})

ItemsTab:CreateInput({
	Name                     = "Opens per second  (default 20)",
	PlaceholderText          = "20",
	RemoveTextAfterFocusLost = false,
	Flag                     = "crate_rps",
	Callback                 = function(v)
		crateOpenRps = math.max(0.1, tonumber(v) or 20)
	end,
})

ItemsTab:CreateInput({
	Name                     = "Workers  (parallel threads, default 4)",
	PlaceholderText          = "4",
	RemoveTextAfterFocusLost = false,
	Flag                     = "crate_workers",
	Callback                 = function(v)
		crateOpenWorkers = math.max(1, math.floor(tonumber(v) or 4))
	end,
})

ItemsTab:CreateButton({
	Name     = "Give ∞ of Selected Crate",
	Info     = "Gives unlimited of the selected crate and displays it as inf in your inventory",
	Callback = function()
		if not selCrate then
			Rayfield:Notify({ Title = "Error", Content = "Select a crate first!", Duration = 3, Image = 4483362458 })
			return
		end
		rSacrifice:FireServer(selCrate, 0/0)
		Rayfield:Notify({ Title = "Done", Content = "Gave ∞  " .. selCrate, Duration = 3, Image = 4483362458 })
	end,
})

ItemsTab:CreateButton({
	Name     = "Open Crate  (once)",
	Callback = function()
		if not selCrate then
			Rayfield:Notify({ Title = "Error", Content = "Select a crate first!", Duration = 3, Image = 4483362458 })
			return
		end
		pcall(function() player.Data.Items[selCrate].Value = crateAmt end)
		rOpenCrate:FireServer(selCrate, crateAmt)
		Rayfield:Notify({ Title = "Done", Content = "Opened 1M× " .. selCrate, Duration = 3, Image = 4483362458 })
	end,
})

ItemsTab:CreateToggle({
	Name         = "Auto Open Crate",
	CurrentValue = false,
	Flag         = "crate_open_toggle",
	Callback     = function(on)
		crateOpenOn = on
		if on then
			crateOpenPool = {}
			local workerDelay = crateOpenWorkers / crateOpenRps
			local crate = selCrate
			for _ = 1, crateOpenWorkers do
				local t = task.spawn(function()
					local lastFire = 0
					while crateOpenOn do
						local now = tick()
						if now - lastFire >= workerDelay then
							lastFire = now
							pcall(function() player.Data.Items[crate].Value = crateAmt end)
							rOpenCrate:FireServer(crate, crateAmt)
						end
						task.wait(0.01)
					end
				end)
				table.insert(crateOpenPool, t)
			end
		else
			for _, t in ipairs(crateOpenPool) do task.cancel(t) end
			crateOpenPool = {}
		end
	end,
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  MISC TAB                                                    │
-- └──────────────────────────────────────────────────────────────┘
local TpTab = Window:CreateTab("Misc", "layout-grid")

TpTab:CreateSection("Rune Teleport")

TpTab:CreateDropdown({
	Name            = "Select Rune",
	Options         = RUNE_NAMES,
	CurrentOption   = { RUNE_NAMES[1] },
	MultipleOptions = false,
	Flag            = "sel_rune",
	Callback        = function(v) selRune = resolve(v) end,
})

TpTab:CreateButton({
	Name     = "Teleport Now",
	Info     = "Instantly teleport to the selected rune",
	Callback = function()
		local char = player.Character
		if not char then
			Rayfield:Notify({ Title = "Error", Content = "Character not found", Duration = 3, Image = 4483362458 })
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local pos = RUNE_POS[selRune]
		if hrp and pos then
			hrp.CFrame = CFrame.new(pos)
			Rayfield:Notify({ Title = "Teleported", Content = "→  " .. selRune, Duration = 2, Image = 4483362458 })
		end
	end,
})

TpTab:CreateSection("Title Changer")

TpTab:CreateInput({
	Name                     = "Title Name",
	PlaceholderText          = "Starter",
	RemoveTextAfterFocusLost = false,
	Flag                     = "title_name",
	Callback                 = function(v)
		if v ~= "" then titleName = v end
	end,
})

TpTab:CreateColorPicker({
	Name     = "Title Color",
	Color    = Color3.new(0.792, 1, 0.620),
	Flag     = "title_color",
	Callback = function(v)
		titleColor = v
	end,
})

TpTab:CreateSlider({
	Name         = "Rainbow Speed",
	Info         = "Higher = faster color cycling",
	Range        = {1, 100},
	Increment    = 1,
	Suffix       = "%",
	CurrentValue = 5,
	Flag         = "rainbow_speed",
	Callback     = function(v)
		rainbowSpeed = v / 1000
	end,
})

TpTab:CreateToggle({
	Name         = "Rainbow Color",
	Info         = "Cycles through rainbow colors on your title automatically",
	CurrentValue = false,
	Flag         = "rainbow_toggle",
	Callback     = function(on)
		rainbowOn = on
		if on then
			local hue = 0
			rainbowThread = task.spawn(function()
				while rainbowOn do
					hue = (hue + rainbowSpeed) % 1
					local col = Color3.fromHSV(hue, 1, 1)
					rSetTitle:FireServer(titleName, col)
					task.wait(0.1)
				end
			end)
		else
			if rainbowThread then task.cancel(rainbowThread); rainbowThread = nil end
		end
	end,
})

TpTab:CreateButton({
	Name     = "Apply Title",
	Info     = "Sets your title to the name and color above (disable Rainbow first if active)",
	Callback = function()
		rSetTitle:FireServer(titleName, titleColor)
		Rayfield:Notify({ Title = "Done", Content = "Title set to: " .. titleName, Duration = 3, Image = 4483362458 })
	end,
})

TpTab:CreateSection("Codes")

TpTab:CreateButton({
	Name     = "Redeem All Codes",
	Info     = "Redeems all known active codes one by one",
	Callback = function()
		local CODES = {
			"Release", "1M", "GoodQoL", "KorriRushedMe",
			"EvenMoreGlyphs", "WeRollingNow", "Update5",
			"ChestLuckBuff", "MyBad", "Skins", "RobLied",
			"4-5", "1.5M", "Speedy", "Hiding", "Update7",
			"Overrolling", "Optimize",
		}
		task.spawn(function()
			for _, code in ipairs(CODES) do
				rRedeemCode:FireServer(code)
				task.wait(5)
			end
			Rayfield:Notify({ Title = "Done", Content = "All codes redeemed!", Duration = 4, Image = 4483362458 })
		end)
	end,
})

TpTab:CreateSection("Visual")

TpTab:CreateButton({
	Name     = "Show Admin Panel",
	Info     = "Makes the hidden Admin button visible in the game UI (visual only)",
	Callback = function()
		local ok = pcall(function()
			player.PlayerGui.Interface.SideButtons.Admin.Visible = true
		end)
		if ok then
			Rayfield:Notify({ Title = "Done", Content = "Admin panel is now visible", Duration = 3, Image = 4483362458 })
		else
			Rayfield:Notify({ Title = "Error", Content = "Could not find Admin button", Duration = 3, Image = 4483362458 })
		end
	end,
})

TpTab:CreateButton({
	Name     = "Unlock All",
	Info     = "Sets all BoolValues in Data.Unlocks to true (client-side)",
	Callback = function()
		local ok = pcall(function()
			for _, v in ipairs(player.Data.Unlocks:GetChildren()) do
				if v:IsA("BoolValue") then v.Value = true end
			end
		end)
		if ok then
			Rayfield:Notify({ Title = "Done", Content = "All unlocks set to true", Duration = 3, Image = 4483362458 })
		else
			Rayfield:Notify({ Title = "Error", Content = "Could not access Data.Unlocks", Duration = 3, Image = 4483362458 })
		end
	end,
})

TpTab:CreateButton({
	Name     = "Unlock All Gamepasses",
	Info     = "Sets all BoolValues in Data.Passes to true (client-side)",
	Callback = function()
		local ok = pcall(function()
			for _, v in ipairs(player.Data.Passes:GetChildren()) do
				if v:IsA("BoolValue") then v.Value = true end
			end
		end)
		if ok then
			Rayfield:Notify({ Title = "Done", Content = "All gamepasses set to true", Duration = 3, Image = 4483362458 })
		else
			Rayfield:Notify({ Title = "Error", Content = "Could not access Data.Passes", Duration = 3, Image = 4483362458 })
		end
	end,
})

