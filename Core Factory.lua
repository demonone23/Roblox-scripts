
-- Full final script: Core Factory (Farming, AutoFarm, Misc, Upgrades)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Core Factory",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "By DemonAlt",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "CoreFactory"
   },
})

-- =========================
-- Farming Tab
-- =========================
local FarmingTab = Window:CreateTab("Farming", 4483362458)
local Section = FarmingTab:CreateSection("Auto Farm Features")

local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==============
-- Cleanup TouchInterest on load (non-destructive)
-- ==============
local function cleanupTouchInterest()
   local bases = workspace:FindFirstChild("Bases")
   if not bases then return end

   local playerBase = bases:FindFirstChild(player.Name)
   if not playerBase then return end

   local theCore = playerBase:FindFirstChild("TheCore")
   if not theCore then return end

   local youngCore = theCore:FindFirstChild("YoungCore")
   if youngCore and youngCore:FindFirstChild("Wavey") then
      local touch = youngCore.Wavey:FindFirstChild("TouchInterest")
      if touch then
         pcall(function()
            touch:Destroy()
         end)
      end
   end
end
cleanupTouchInterest()

---------------------------------------------------------------------
-- AUTO COLLECT PARTICLES
---------------------------------------------------------------------
local autoParticles = false
FarmingTab:CreateToggle({
   Name = "Auto Collect Particle",
   CurrentValue = false,
   Flag = "AutoParticles",
   Callback = function(value)
      autoParticles = value
      if value then
         task.spawn(function()
            while autoParticles do
               pcall(function()
                  local character = player.Character or player.CharacterAdded:Wait()
                  local root = character:FindFirstChild("HumanoidRootPart")
                  if not root then return end

                  local particlesFolder = workspace:FindFirstChild("Particles")
                  if not particlesFolder then return end

                  for _, obj in ipairs(particlesFolder:GetChildren()) do
                     if obj:IsA("BasePart") then
                        obj.CFrame = root.CFrame
                     elseif obj:IsA("Model") and obj.PrimaryPart then
                        obj:SetPrimaryPartCFrame(root.CFrame)
                     end
                  end
               end)
               task.wait(0.2)
            end
         end)
      end
   end
})

---------------------------------------------------------------------
-- AUTO CLICK CORE
---------------------------------------------------------------------
local autoCore = false
FarmingTab:CreateToggle({
   Name = "Auto Click Core",
   CurrentValue = false,
   Flag = "AutoClickCore",
   Callback = function(value)
      autoCore = value

      if value then
         task.spawn(function()
            while autoCore do
               pcall(function()
                  local bases = workspace:FindFirstChild("Bases")
                  if not bases then return end

                  local playerBase = bases:FindFirstChild(player.Name)
                  if not playerBase then return end

                  local ok, prompt = pcall(function()
                     return playerBase:WaitForChild("TheCore"):WaitForChild("Core"):WaitForChild("Click")
                  end)

                  if ok and prompt and prompt:IsA("ProximityPrompt") then
                     fireproximityprompt(prompt)
                  end
               end)
               task.wait(0.1)
            end
         end)
      end
   end
})

-- =========================
-- Auto Farm Tab
-- =========================
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local SectionAF = AutoFarmTab:CreateSection("Auto Farm Features")

local autoFarm = false
local selectedZones = {}
local moveMethod = "Walk" -- default movement
local spamJumpEnabled = false
local DEFAULT_WALKSPEED = 25
local currentWalkspeed = DEFAULT_WALKSPEED

-- Helper: get character references
local function getCharacterRefs()
   local char = player.Character
   if not char then return nil end
   local humanoid = char:FindFirstChildWhichIsA("Humanoid")
   local root = char:FindFirstChild("HumanoidRootPart")
   return char, humanoid, root
end

-- Dropdown for selecting zones
AutoFarmTab:CreateDropdown({
   Name = "Select Zones to Farm",
   Options = {
      "AshenFields.Normals","AshenFields.Obverts",
      "FrigidIsle.Normals","FrigidIsle.Obverts",
      "FrostySands.Normals","FrostySands.Obverts",
      "IcyPlains.Normals","IcyPlains.Obverts",
      "SnowyHills.Normals","SnowyHills.Obverts",
      "WinterPines.Normals","WinterPines.Obverts"
   },
   MultiSelect = true,
   CurrentOption = {},
   Flag = "ZonesDropdown",
   Callback = function(selected)
      selectedZones = selected or {}
      if #selectedZones > 0 then
         pcall(function()
            print("[Debug] Selected Zones: "..table.concat(selectedZones, ", "))
         end)
      end
   end
})

-- Helper: find closest mob in selected zones
local function getClosestMob(root)
   if not root then return nil end

   local closestMob = nil
   local closestDist = math.huge

   for _, selZone in ipairs(selectedZones) do
      local parts = selZone:split(".")
      if #parts == 2 then
         local field, category = parts[1], parts[2]

         local fieldFolder = workspace:FindFirstChild("Inverts") and workspace.Inverts:FindFirstChild(field)
         if fieldFolder then
            local mobFolder = fieldFolder:FindFirstChild(category)
            if mobFolder then
               for _, mob in ipairs(mobFolder:GetChildren()) do
                  if mob and mob.Name == "Invert" then
                     local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                     if mobRoot then
                        local hp = mob:GetAttribute("HP") or mob:GetAttribute("Health") or 0
                        if hp > 0 then
                           local dist = (root.Position - mobRoot.Position).Magnitude
                           if dist < closestDist then
                              closestDist = dist
                              closestMob = mob
                           end
                        end
                     end
                  end
               end
            end
         end
      end

      if closestMob then break end
   end

   return closestMob
end

-- Helper: disable collisions only for the specified islands
local function setTweenCollisions(enabled)
   local islands = {
      workspace.Islands.IcyPlains,
      workspace.Islands.FrostySands,
      workspace.Islands.SnowyHills,
      workspace.Islands.WinterPines
   }

   for _, island in ipairs(islands) do
      if island then
         for _, folderName in ipairs({"Decor","Floor","Walls"}) do
            local folder = island:FindFirstChild(folderName)
            if folder then
               if folder:IsA("BasePart") then
                  -- single MeshPart (Floor)
                  pcall(function() folder.CanCollide = enabled end)
               elseif folder:IsA("Folder") or folder:IsA("Model") then
                  for _, obj in ipairs(folder:GetDescendants()) do
                     if obj:IsA("BasePart") then
                        pcall(function() obj.CanCollide = enabled end)
                     end
                  end
               end
            end
         end
      end
   end
end

-- Movement function
local function moveToTarget(root, targetPos, method, speed)
   if not root then return end
   speed = speed or currentWalkspeed

   if root:FindFirstChild("BF_Move") then
      root.BF_Move:Destroy()
   end

   if method == "Walk" then
      -- Restore island collisions if Walk
      setTweenCollisions(true)

      local humanoid = root.Parent:FindFirstChildWhichIsA("Humanoid")
      if humanoid and targetPos then
         humanoid:MoveTo(targetPos)
      end
      return
   end

   if not targetPos then return end

   -- Disable collisions for Tween on islands only
   setTweenCollisions(false)

   local bv = Instance.new("BodyVelocity")
   bv.Name = "BF_Move"
   bv.MaxForce = Vector3.new(1e5,1e5,1e5)
   bv.Velocity = Vector3.new(0,0,0)
   bv.Parent = root

   local conn
   conn = RunService.Heartbeat:Connect(function()
      if not root or not root.Parent or not targetPos then
         conn:Disconnect()
         if bv then bv:Destroy() end
         return
      end

      local direction = (targetPos - root.Position)
      local dist = direction.Magnitude

      if dist < 1 then
         bv.Velocity = Vector3.new(0,0,0)
         conn:Disconnect()
         bv:Destroy()
         return
      end

      direction = direction.Unit
      bv.Velocity = direction * speed
   end)
end

-- Dropdown for movement method (Walk/Tween)
AutoFarmTab:CreateDropdown({
   Name = "Movement Method",
   Options = {"Walk", "Tween"},
   CurrentOption = "Walk",
   Flag = "MovementMethod",
   Callback = function(option)
      local prevMethod = moveMethod
      moveMethod = option
      print("[Debug] Movement method set to:", moveMethod)

      if player.Character then
         local root = player.Character:FindFirstChild("HumanoidRootPart")
         if root and prevMethod == "Tween" and moveMethod ~= "Tween" then
            root.CFrame = root.CFrame + Vector3.new(0,10,0)
         end
      end

      -- Set collisions according to method
      setTweenCollisions(moveMethod ~= "Tween")
   end
})

-- Auto Farm toggle
AutoFarmTab:CreateToggle({
   Name = "Enable Auto Farm",
   CurrentValue = false,
   Flag = "EnableAutoFarm",
   Callback = function(value)
      autoFarm = value

      if value then
         -- Movement loop
         task.spawn(function()
            while autoFarm do
               pcall(function()
                  local char, humanoid, root = getCharacterRefs()
                  if not (char and humanoid and root) then
                     task.wait(0.2)
                     return
                  end

                  local mob = getClosestMob(root)
                  if not mob then
                     task.wait(0.5)
                     return
                  end

                  local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                  if not mobRoot then
                     task.wait(0.2)
                     return
                  end

                  local targetPos = mobRoot.Position - (mobRoot.CFrame.LookVector * 2)
                  if targetPos then
                     moveToTarget(root, targetPos, moveMethod, currentWalkspeed)
                  end
               end)
               task.wait(0.05)
            end
         end)

         -- Attack loop
         task.spawn(function()
            while autoFarm do
               pcall(function()
                  local char, humanoid, root = getCharacterRefs()
                  if not char then return end

                  local tool = player.Backpack:FindFirstChild("Core") or char:FindFirstChild("Core")
                  if tool then
                     if tool.Parent ~= char then
                        pcall(function()
                           char.Humanoid:EquipTool(tool)
                        end)
                     end
                     pcall(function()
                        tool:Activate()
                     end)
                  end
               end)
               task.wait(0.03)
            end
         end)
      end
   end
})

-- =========================
-- Misc Tab (Walkspeed, NoClip, Anti-AFK)
-- =========================
local MiscTab = Window:CreateTab("Misc", 4483362458)
MiscTab:CreateSection("Player Tweaks")

-- Walkspeed
local function applyWalkspeed(value)
   currentWalkspeed = value
   if player.Character and player.Character:FindFirstChild("Humanoid") then
      pcall(function()
         player.Character.Humanoid.WalkSpeed = value
      end)
   end
end

player.CharacterAdded:Connect(function(newChar)
   task.wait(0.1)
   pcall(function()
      newChar:WaitForChild("Humanoid").WalkSpeed = currentWalkspeed
   end)
end)

MiscTab:CreateSlider({
   Name = "Walkspeed",
   Range = {15, 35},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = DEFAULT_WALKSPEED,
   Flag = "WalkspeedSlider",
   Callback = function(value)
      applyWalkspeed(value)
   end
})

-- NoClip toggle
local noclipEnabled = false
MiscTab:CreateToggle({
   Name = "NoClip",
   CurrentValue = false,
   Flag = "NoClipToggle",
   Callback = function(value)
      noclipEnabled = value
   end
})

RunService.Stepped:Connect(function()
   if noclipEnabled and player.Character then
      for _, part in ipairs(player.Character:GetDescendants()) do
         if part:IsA("BasePart") then
            pcall(function()
               part.CanCollide = false
            end)
         end
      end
   end
end)

-- Anti-AFK
MiscTab:CreateSection("Anti-AFK (Unified)")
local AntiAFKEnabled = false
local vu = game:GetService("VirtualUser")

MiscTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = false,
   Flag = "AntiAFKToggle",
   Callback = function(value)
      AntiAFKEnabled = value
   end
})

task.spawn(function()
   while true do
      if AntiAFKEnabled then
         pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
         end)

         pcall(function()
            local args = {0}
            Replicated:WaitForChild("Events"):WaitForChild("System"):WaitForChild("PlayerIdle"):FireServer(unpack(args))
         end)
      end
      task.wait(11)
   end
end)

-- =========================
-- Upgrades Tab
-- =========================
local UpgradeTab = Window:CreateTab("Upgrades", 4483362458)
UpgradeTab:CreateSection("Automatic Machine Upgrades")

local MachinesEvent
do
   local ok, ev = pcall(function()
      return Replicated:WaitForChild("Events"):WaitForChild("Machines"):WaitForChild("UpgMachine")
   end)
   MachinesEvent = ok and ev or nil
end

local machineUpgrades = {
   "Evaluator", "Ranker", "Upgrader", "Classifier", "Molder",
   "Enchanter", "ScorcherGeneration", "ScorcherCapacity", "ScorcherEfficiency",
}

local upgradeToggles = {}

for _, upgradeName in ipairs(machineUpgrades) do
   upgradeToggles[upgradeName] = false

   UpgradeTab:CreateToggle({
      Name = "Auto Upgrade " .. upgradeName,
      CurrentValue = false,
      Flag = "Upgrade_" .. upgradeName,
      Callback = function(value)
         upgradeToggles[upgradeName] = value
      end
   })
end

task.spawn(function()
   while true do
      if MachinesEvent then
         for name, enabled in pairs(upgradeToggles) do
            if enabled then
               pcall(function()
                  MachinesEvent:FireServer(name)
               end)
            end
         end
      end
      task.wait(0.25)
   end
end)

-- =========================
-- Final notify
-- =========================
Rayfield:Notify({
   Title = "Core Factory",
   Content = "Loaded!",
   Duration = 3
})
