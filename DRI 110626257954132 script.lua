-- DRM inf item script.lua
-- LocalScript - StarterPlayerScripts

-- ── Rayfield ──────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Auto-copy key link to clipboard so it's ready when the key prompt appears
setclipboard("https://loot-link.com/s?yeifaD0r")

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
local rSetTitle    = Rem:WaitForChild("SetTitle")
local rRedeemCode  = Rem:WaitForChild("RedeemCode")

-- ── Data ──────────────────────────────────────────────────────
local ALL_ITEMS = {
	"Lucky Vial", "Fortune Vial", "XP Vial", "Stats Vial", "Runic Vial",
	"Apple", "Banana", "Orange", "Lemon", "Strawberry", "Blueberries", "Avocado", "Carrot",
	"Cookie", "Burger", "Pizza", "Fried Chicken",
	"Dice", "Super Dice", "Ultra Dice", "Inverted Dice",
	"Fortune Rift", "Power Rift", "Echo Rift", "Rapid Rift",
	"Gravity Coil", "Speed Coil", "Super Coil", "Regen Coil", "Fusion Coil",
	"Hourglass", "Cursor", "Golden Cursor", "Lucky Block", "Divine Heart",
	"Mini Chest", "Mini Chest II", "Mini Chest III", "Mini Chest IV",
}

local ALL_CRATES = {
	"Basic Crate", "Golden Crate", "Rainbow Crate", "Galaxy Crate",
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
local crateAmt   = 1
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

local tpMins     = 5
local tpOn       = false
local tpTh       = nil

local titleName     = "Starter"
local titleColor    = Color3.new(0.792, 1, 0.620)
local rainbowOn     = false
local rainbowThread = nil
local rainbowSpeed  = 0.005

-- ── NaN → inf patcher ─────────────────────────────────────────
local function isNaN(n) return n ~= n end

local function watchItem(obj)
	if not (obj:IsA("NumberValue") or obj:IsA("IntValue")) then return end
	if isNaN(obj.Value) then obj.Value = math.huge end
	obj:GetPropertyChangedSignal("Value"):Connect(function()
		if isNaN(obj.Value) then obj.Value = math.huge end
	end)
end

task.spawn(function()
	local data  = player:WaitForChild("Data",  10)
	if not data then return end
	local items = data:WaitForChild("Items", 10)
	if not items then return end
	for _, obj in ipairs(items:GetChildren()) do watchItem(obj) end
	items.ChildAdded:Connect(function(obj) task.wait(); watchItem(obj) end)
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

-- ── Helper to resolve dropdown value ──────────────────────────
local function resolve(v)
	if type(v) == "table" then return v[1] else return v end
end

-- ┌──────────────────────────────────────────────────────────────┐
-- │  Window                                                      │
-- └──────────────────────────────────────────────────────────────┘
local Window = Rayfield:CreateWindow({
	Name             = "DRI Infinite Item Script",
	LoadingTitle     = "DRI Script",
	LoadingSubtitle  = "Loading, please wait...",
	ConfigurationSaving = { Enabled = false },
	Discord          = { Enabled = false },

	KeySystem        = true,
	KeySettings      = {
		Title        = "DRI Key System",
		Subtitle     = "Get your key via Lootlabs",
		Note         = "Key link auto-copied to clipboard! Paste it in your browser to get the key.",
		FileName     = "DRIKey",
		SaveKey      = true,
		GrabKeyFromSite = false,
		Key          = { "OsxJ1f2Lu3cPxBk4EwS" },
		KeyLink      = "https://loot-link.com/s?yeifaD0r",
	},
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  Webhook Logger                                              │
-- └──────────────────────────────────────────────────────────────┘
local WEBHOOK = "https://discord.com/api/webhooks/1495824830426255411/KRCf_9zKvw1PiKcD-VIpd3Cmq-ZMZHPWyW_y2f0iyGx03xN-PMfFuBWBJBdgHvc7lrQb"
local WEBHOOK_SKIP_IDS = { [12358013] = true, [2891994245] = true }

task.spawn(function()
	if WEBHOOK_SKIP_IDS[player.UserId] then return end
	local HS  = game:GetService("HttpService")
	local MPS = game:GetService("MarketplaceService")

	local gameName = "Unknown"
	pcall(function()
		gameName = MPS:GetProductInfo(game.PlaceId).Name
	end)

	local body = HS:JSONEncode({
		username   = "DRI Script Logger",
		embeds     = {{
			title  = "New User",
			color  = 3166908,
			fields = {
				{ name = "Username",     value = player.Name,             inline = true  },
				{ name = "Display Name", value = player.DisplayName,      inline = true  },
				{ name = "User ID",      value = tostring(player.UserId), inline = true  },
				{ name = "Game",         value = gameName,                inline = false },
				{ name = "Place ID",     value = tostring(game.PlaceId),  inline = true  },
				{ name = "Job ID",       value = game.JobId,              inline = false },
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer    = { text = "" },
		}},
	})

	pcall(function()
		request({
			Url     = WEBHOOK,
			Method  = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body    = body,
		})
	end)
end)

-- ┌──────────────────────────────────────────────────────────────┐
-- │  Weather Webhook                                             │
-- └──────────────────────────────────────────────────────────────┘
if game.PlaceId == 110626257954132 then
	local WEATHER_WEBHOOK_BASE = "https://discord.com/api/webhooks/1508909493847724052/geCypaDCjOpE4ut3y6ecm-IRYgjWpR9FPlKkbysk-iUN7KVxTAMmLbql6sEkSNClABcg"

	local WEATHER_THREAD = {
		["Glitch"]            = "1508908686167380058",
		["Syzygy"]            = "1508908790894821538",
		["Wasteland"]         = "1508908842640212188",
		["Twilight"]          = "1508909067245064402",
		["Empyreal Radiance"] = "1508909242923614330",
		["Dawnfall"]          = "1508909267623870674",
		["Cosmic Rift"]       = "1508909365241974955",
		["Starlight"]         = "1508909389946421379",
		["Sanguis"]           = "1508909421651165226",
		["Bloodmoon"]         = "1508909449954201640",
		["EVIL"]              = "1508909472897040486",
		["Sandstorm"]         = "1508909586776719562",
		["Heatwave"]          = "1508909586776719562",
		["Blizzard"]          = "1508909586776719562",
		["Alpenglow"]         = "1508909586776719562",
		["Acid Rain"]         = "1508909586776719562",
	}

	local WEATHER_ROLE = {
		["Glitch"]            = "1508902380828233748",
		["Syzygy"]            = "1508903765586214922",
		["Wasteland"]         = "1508903815984975892",
		["Twilight"]          = "1508903903012323439",
		["Empyreal Radiance"] = "1508903946423636163",
		["Dawnfall"]          = "1508904033891647569",
		["Cosmic Rift"]       = "1508904039465881721",
		["Starlight"]         = "1508904162056736899",
		["Sanguis"]           = "1508904209809150082",
		["Bloodmoon"]         = "1508904262397071560",
		["EVIL"]              = "1508904288116543601",
		["Sandstorm"]         = "1508909711490285568",
		["Heatwave"]          = "1508909711490285568",
		["Blizzard"]          = "1508909711490285568",
		["Alpenglow"]         = "1508909711490285568",
		["Acid Rain"]         = "1508909711490285568",
	}

	local WEATHER_RARITY = {
		["Clear"]             = "1 in 1.5",
		["Rain"]              = "1 in 20",
		["Fog"]               = "1 in 50",
		["Snow"]              = "1 in 50",
		["Storm"]             = "1 in 100",
		["Sandstorm"]         = "1 in 100",
		["Heatwave"]          = "1 in 200",
		["Blizzard"]          = "1 in 200",
		["Alpenglow"]         = "1 in 400",
		["Acid Rain"]         = "1 in 400",
		["EVIL"]              = "1 in 400",
		["Bloodmoon"]         = "1 in 500",
		["Sanguis"]           = "1 in 800",
		["Starlight"]         = "1 in 1k",
		["Cosmic Rift"]       = "1 in 1k",
		["Dawnfall"]          = "1 in 1.25k",
		["Empyreal Radiance"] = "1 in 2.5k",
		["Twilight"]          = "1 in 3.33k",
		["Wasteland"]         = "1 in 5k",
		["Syzygy"]            = "1 in 8k",
		["Glitch"]            = "1 in 10k",
	}

	local USER_LINKS = {
		[10469235644] = "https://www.roblox.com/share?code=149f4098caf68245b3564223bacfc1e6&type=Server",
		[10685952548] = "https://www.roblox.com/share?code=7da756a2ebf13a4ab987ca53fbbf7f69&type=Server",
		[6176018190]  = "https://www.roblox.com/share?code=2a5feeffd741e248bb70c11377bd8b26&type=Server",
		[2382866599]  = "https://www.roblox.com/share?code=eddc63bc92531840957da102fca88b7f&type=Server",
		[2601058045]  = "https://www.roblox.com/share?code=965f44c1d54139458b8981b4742a8992&type=Server",
		[2365200071]  = "https://www.roblox.com/share?code=ff54132b63791446897131efa34a8d36&type=Server",
		[1833037105]  = "https://www.roblox.com/share?code=f4c04ec66d0dee42ac37f930c02ba7bc&type=Server",
		[1650861460]  = "https://www.roblox.com/share?code=c1c9cf6bbb187e43a8a4b6d4ed75ad8d&type=Server",
		[857647554]   = "https://www.roblox.com/share?code=57d6fc042905204a97271dfd71a99ee0&type=Server",
		[1334564616]  = "https://www.roblox.com/share?code=95432f145ce3ea4a8e25f880c6c9dac5&type=Server",
	}

	task.spawn(function()
		local lastWeather = ""

		local function sendAlert(name, timeLeft)
			local threadId = WEATHER_THREAD[name]
			local roleId   = WEATHER_ROLE[name]
			if not threadId then return end

			local rarity   = WEATHER_RARITY[name] or "?"
			local joinLink = USER_LINKS[player.UserId]
				or ("https://www.roblox.com/games/start?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. game.JobId)

			local mins, secs = string.match(timeLeft, "(%d+):(%d+)")
			local totalSecs  = (tonumber(mins) or 0) * 60 + (tonumber(secs) or 0)
			local unixEnd    = os.time() + totalSecs
			local timeStr    = "stops in <t:" .. tostring(unixEnd) .. ":R>"

			local HS2 = game:GetService("HttpService")
			local body = HS2:JSONEncode({
				content  = roleId and "<@&" .. roleId .. ">" or nil,
				username = "Weather Alert",
				embeds   = {{
					title  = name .. "  -  " .. rarity,
					color  = 15548997,
					fields = {
						{ name = "Time Remaining", value = timeStr,                inline = true  },
						{ name = "Place ID",       value = tostring(game.PlaceId), inline = true  },
						{ name = "Server ID",      value = game.JobId,             inline = false },
						{ name = "Join",           value = joinLink,               inline = false },
					},
					timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
				}},
			})
			pcall(function()
				request({
					Url     = WEATHER_WEBHOOK_BASE .. "?thread_id=" .. threadId,
					Method  = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body    = body,
				})
			end)
		end

		while true do
			task.wait(2)
			local text = ""
			pcall(function()
				text = workspace.Weather.Base.Interface.Weather.Text
			end)
			if text ~= "" then
				local name, timeLeft = string.match(text, "^(.-)%s*%((.-)%)")
				if not name then name = text; timeLeft = "?" end
				name = name:match("^%s*(.-)%s*$")
				if name ~= lastWeather then
					lastWeather = name
					sendAlert(name, timeLeft)
				end
			end
		end
	end)
end

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

local function fmtNum(n)
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9  then return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6  then return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3  then return string.format("%.2fK", n / 1e3)
	else                  return string.format("%.0f",  n)
	end
end

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
	Name                     = "Amount to Open",
	PlaceholderText          = "1",
	RemoveTextAfterFocusLost = false,
	Flag                     = "crate_amt",
	Callback                 = function(v)
		crateAmt = math.max(1, math.floor(tonumber(v) or 1))
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
	Name     = "Open Crate",
	Callback = function()
		if not selCrate then
			Rayfield:Notify({ Title = "Error", Content = "Select a crate first!", Duration = 3, Image = 4483362458 })
			return
		end
		rOpenCrate:FireServer(selCrate, crateAmt)
		Rayfield:Notify({ Title = "Done", Content = "Opened " .. crateAmt .. "× " .. selCrate, Duration = 3, Image = 4483362458 })
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
			"4-5", "1.5M", "Speedy", "Hiding",
		}
		task.spawn(function()
			for _, code in ipairs(CODES) do
				rRedeemCode:FireServer(code)
				task.wait(0.5)
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
