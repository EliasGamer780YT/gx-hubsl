--[[
    Gamers X - Cliente (PAGA)
    Debounce = Missile owner | Desync | Stamina | Dribbles | FFlags
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

local OWNER_ID = 11362947592

local ALLOWED = {
	[11242163323] = true, -- dodegue9
	[1903088035] = true,  -- dodegue
	[984159292] = true,  -- Juanvelriv 
}

if not ALLOWED[player.UserId] then
	print("❌ Gamers X | sin acceso:", player.UserId)
	return
end

print("✅ Gamers X Paga |", player.Name, player.UserId)

local desyncSystem = false
local desyncOn = false
local staminaSystem = false
local infiniteStamina = false
local oldConsume = nil
local selectedDribble = "Rainbow Flick"
local listeningForKey = false

local debounceSystem = false
local debounceActive = false
local debounceMultiplier = 1.3
local debounceCooldown = 0.35
local lastDebounceBoost = 0
local lastDebounceVel = Vector3.zero
local debounceAutoOffTime = 2.5
local debounceToken = 0
local debounceNotifEnabled = true

local showGuiKey = Enum.KeyCode.LeftControl
local staminaKey = Enum.KeyCode.V
local desyncKey = Enum.KeyCode.H
local debounceKey = Enum.KeyCode.G

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "GamersXClientNotif"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 999999
pcall(function()
	notifGui.Parent = gethui and gethui() or CoreGui
end)
if not notifGui.Parent then
	notifGui.Parent = player:WaitForChild("PlayerGui")
end

local function clientNotif(text, color)
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(0, 340, 0, 44)
	n.Position = UDim2.new(0.5, -170, 0, -60)
	n.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	n.BackgroundTransparency = 0.08
	n.Text = text
	n.TextColor3 = color or Color3.fromRGB(255, 220, 100)
	n.TextSize = 15
	n.Font = Enum.Font.GothamBold
	n.Parent = notifGui
	Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 180, 50)
	s.Thickness = 1.5
	s.Parent = n
	TweenService:Create(n, TweenInfo.new(0.25), {
		Position = UDim2.new(0.5, -170, 0, 90)
	}):Play()
	task.delay(3.5, function()
		local tw = TweenService:Create(n, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		})
		tw:Play()
		TweenService:Create(s, TweenInfo.new(0.3), {Transparency = 1}):Play()
		tw.Completed:Wait()
		n:Destroy()
	end)
end

local function markPaid()
	pcall(function()
		player:SetAttribute("GamersXPaid", true)
		player:SetAttribute("GamersXTag", "GX_PAID")
	end)
	local char = player.Character
	if char and not char:FindFirstChild("GamersXPaidMarker") then
		local folder = Instance.new("Folder")
		folder.Name = "GamersXPaidMarker"
		folder.Parent = char
	end
end

markPaid()
player.CharacterAdded:Connect(function()
	task.wait(0.45)
	markPaid()
end)
task.spawn(function()
	while true do
		task.wait(3)
		markPaid()
	end
end)

local function doKill()
	clientNotif("☠️ Owner: KILL", Color3.fromRGB(255, 80, 80))
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
	task.delay(0.8, function()
		pcall(function() player:LoadCharacter() end)
	end)
end

local function doRejoin()
	clientNotif("🔄 Owner: REJOIN", Color3.fromRGB(255, 180, 50))
	task.wait(0.4)
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
end

local function doFling()
	clientNotif("🌀 Owner: FLING", Color3.fromRGB(100, 200, 255))
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.new(12000, 12000, 12000)
		hrp.AssemblyAngularVelocity = Vector3.new(80, 80, 80)
	end
end

local function doKick()
	clientNotif("👢 Owner: KICK", Color3.fromRGB(255, 80, 80))
	task.wait(0.35)
	player:Kick("Gamers X | Acción del owner")
end

local function doFreeze(sec)
	sec = sec or 5
	clientNotif("❄️ Owner: FREEZE " .. sec .. "s", Color3.fromRGB(150, 220, 255))
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	hrp.Anchored = true
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	end
	task.delay(sec, function()
		if hrp then hrp.Anchored = false end
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
	end)
end

local function handleOwnerMessage(msg)
	if typeof(msg) ~= "string" then return end
	local raw = msg
	msg = string.lower(string.gsub(msg, "^%s+", ""))
	msg = string.gsub(msg, "%s+$", "")

	if msg == "!gx kill" then
		doKill()
	elseif msg == "!gx rejoin" then
		doRejoin()
	elseif msg == "!gx fling" then
		doFling()
	elseif msg == "!gx kick" then
		doKick()
	elseif msg == "!gx freeze" then
		doFreeze(5)
	elseif string.sub(msg, 1, 8) == "!gx say " then
		local text = string.sub(raw, 9)
		text = string.gsub(text, "^%s+", "")
		clientNotif("💬 Owner: " .. text, Color3.fromRGB(255, 220, 100))
	end
end

local function bindOwnerChatted(plr)
	if plr.UserId ~= OWNER_ID then return end
	plr.Chatted:Connect(function(msg)
		handleOwnerMessage(msg)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	bindOwnerChatted(plr)
end
Players.PlayerAdded:Connect(bindOwnerChatted)

pcall(function()
	TextChatService.MessageReceived:Connect(function(message)
		local source = message.TextSource
		if not source or source.UserId ~= OWNER_ID then return end
		handleOwnerMessage(message.Text or "")
	end)
end)

local function getFootball()
	for _, obj in ipairs(CollectionService:GetTagged("Football") or {}) do
		if obj:IsA("BasePart") then return obj end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("football")) then
			return obj
		end
	end
	return nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GamersXV2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 999998
screenGui.IgnoreGuiInset = true
pcall(function()
	if gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end
end)
if not screenGui.Parent then
	screenGui.Parent = player:WaitForChild("PlayerGui")
end

local function showNotif(text, color)
	clientNotif(text, color)
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 500)
main.Position = UDim2.new(0.5, -160, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Gamers X"
title.TextColor3 = Color3.fromRGB(255, 180, 50)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
end)

do
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 32)
tabBar.Position = UDim2.new(0, 6, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -90)
content.Position = UDim2.new(0, 10, 0, 88)
content.BackgroundTransparency = 1
content.Parent = main

local function enableInfiniteStamina()
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local StaminaController = Knit.GetController("StaminaController")
		if StaminaController and StaminaController.Consume then
			if not oldConsume then oldConsume = StaminaController.Consume end
			StaminaController.Consume = function(self, amount)
				if infiniteStamina then return true end
				return oldConsume(self, amount)
			end
		end
	end)
end

local function equipDribble(name)
	pcall(function()
		local Attributes = require(ReplicatedStorage.Shared.Attributes)
		player:SetAttribute(Attributes.Player.EquippedDribble, name)
	end)
end

local function applyDesyncCombo()
	pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "True") end)
	task.wait(0.05)
	pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "False") end)
	pcall(function() setfflag("WorldStepMax", "-2147483648") end)
	pcall(function() setfflag("DFIntWorldStepMax", "-2147483648") end)
	pcall(function() setfflag("DFIntDebugDefaultTargetWorldStepsPerFrame", "-2147483648") end)
	pcall(function() setfflag("DFIntMaxMissedWorldStepsRemembered", "-2147483648") end)
	pcall(function() setfflag("DFIntS2PhysicsSenderRate", "1") end)
	pcall(function() setfflag("DFIntWorldStepsOffsetAdjustRate", "2147483647") end)
end

local function resetDesyncCombo()
	pcall(function() setfflag("WorldStepMax", "-1") end)
	pcall(function() setfflag("DFIntWorldStepMax", "-1") end)
	pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "False") end)
	pcall(function() setfflag("DFIntS2PhysicsSenderRate", "15") end)
	pcall(function() setfflag("DFIntDebugDefaultTargetWorldStepsPerFrame", "4") end)
end

task.spawn(function()
	while true do
		if desyncSystem and desyncOn then
			applyDesyncCombo()
		end
		task.wait(1.5)
	end
end)

local tabs, pages = {}, {}

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 58, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(160, 160, 170)
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamBold
	btn.Parent = tabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(255, 160, 40)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = page
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)

	tabs[name] = btn
	pages[name] = page
	btn.MouseButton1Click:Connect(function()
		for n, b in pairs(tabs) do
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
			b.TextColor3 = Color3.fromRGB(160, 160, 170)
			pages[n].Visible = false
		end
		btn.BackgroundColor3 = Color3.fromRGB(255, 160, 40)
		btn.TextColor3 = Color3.fromRGB(20, 20, 25)
		page.Visible = true
	end)
	return page
end

local mainPage = createTab("Main")
local debPage = createTab("Debounce")
local dribblesPage = createTab("Dribbles")
local fflagPage = createTab("FFlags")
local settingsPage = createTab("Settings")

tabs["Debounce"].BackgroundColor3 = Color3.fromRGB(255, 160, 40)
tabs["Debounce"].TextColor3 = Color3.fromRGB(20, 20, 25)
pages["Debounce"].Visible = true
pages["Main"].Visible = false

local function createSection(parent, titleText)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, 0, 0, 0)
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	section.BorderSizePixel = 0
	section.Parent = parent
	Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -12, 0, 26)
	t.Position = UDim2.new(0, 10, 0, 4)
	t.BackgroundTransparency = 1
	t.Text = titleText
	t.TextColor3 = Color3.fromRGB(255, 170, 50)
	t.TextSize = 13
	t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = section

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = section

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 30)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = section
	return section
end

local function createToggle(parent, text, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 32)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 240)
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 48, 0, 24)
	btn.Position = UDim2.new(1, -48, 0.5, -12)
	btn.BackgroundColor3 = default and Color3.fromRGB(255, 160, 40) or Color3.fromRGB(50, 50, 60)
	btn.Text = default and "ON" or "OFF"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local state = default
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.BackgroundColor3 = state and Color3.fromRGB(255, 160, 40) or Color3.fromRGB(50, 50, 60)
		btn.Text = state and "ON" or "OFF"
		callback(state)
	end)
	return function(v)
		state = v
		btn.BackgroundColor3 = v and Color3.fromRGB(255, 160, 40) or Color3.fromRGB(50, 50, 60)
		btn.Text = v and "ON" or "OFF"
	end
end

local function createSlider(parent, text, min, max, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. tostring(default)
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 28)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = frame
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 160, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local dragging = false
	local function update(input)
		local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local val = math.floor((min + (max - min) * rel) * 10 + 0.5) / 10
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = text .. ": " .. tostring(val)
		callback(val)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
end

local function createButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(255, 160, 40)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(20, 20, 25)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.MouseButton1Click:Connect(callback)
end

local function createKeybindRow(parent, name, getKey, setKey)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = name .. ": [" .. getKey().Name .. "]"
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	createButton(parent, "Cambiar " .. name, function()
		if listeningForKey then return end
		listeningForKey = true
		label.Text = name .. ": Presiona tecla..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				setKey(input.KeyCode)
				label.Text = name .. ": [" .. input.KeyCode.Name .. "]"
				listeningForKey = false
				conn:Disconnect()
			end
		end)
	end)
end

-- MAIN
local desyncSec = createSection(mainPage, "Desync Combo")
local desyncStatus = Instance.new("TextLabel")
desyncStatus.Size = UDim2.new(1, 0, 0, 18)
desyncStatus.BackgroundTransparency = 1
desyncStatus.Text = "Sistema: BLOQUEADO | Activo: OFF"
desyncStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
desyncStatus.TextSize = 11
desyncStatus.Font = Enum.Font.Gotham
desyncStatus.TextXAlignment = Enum.TextXAlignment.Left
desyncStatus.Parent = desyncSec

local function refreshDesyncStatus()
	if desyncSystem then
		desyncStatus.Text = "Sistema: ON | Activo: " .. (desyncOn and "ON" or "OFF")
		desyncStatus.TextColor3 = desyncOn and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 200, 80)
	else
		desyncStatus.Text = "Sistema: BLOQUEADO | Activo: OFF"
		desyncStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
	end
end

createToggle(desyncSec, "Habilitar Sistema Desync", false, function(v)
	desyncSystem = v
	if not v then
		desyncOn = false
		resetDesyncCombo()
	end
	refreshDesyncStatus()
end)

local stamSec = createSection(mainPage, "Infinite Stamina")
local stamStatus = Instance.new("TextLabel")
stamStatus.Size = UDim2.new(1, 0, 0, 18)
stamStatus.BackgroundTransparency = 1
stamStatus.Text = "Sistema: BLOQUEADO | Activo: OFF"
stamStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
stamStatus.TextSize = 11
stamStatus.Font = Enum.Font.Gotham
stamStatus.TextXAlignment = Enum.TextXAlignment.Left
stamStatus.Parent = stamSec

local function refreshStamStatus()
	if staminaSystem then
		stamStatus.Text = "Sistema: ON | Activo: " .. (infiniteStamina and "ON" or "OFF")
		stamStatus.TextColor3 = infiniteStamina and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 200, 80)
	else
		stamStatus.Text = "Sistema: BLOQUEADO | Activo: OFF"
		stamStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
	end
end

createToggle(stamSec, "Habilitar Sistema Stamina", false, function(v)
	staminaSystem = v
	if not v then infiniteStamina = false end
	refreshStamStatus()
end)

-- DEBOUNCE (= Missile owner exacto)
local debSec = createSection(debPage, "Ball Debounce")

local debStatus = Instance.new("TextLabel")
debStatus.Size = UDim2.new(1, 0, 0, 20)
debStatus.BackgroundTransparency = 1
debStatus.Text = "Sistema: BLOQUEADO | Debounce: OFF"
debStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
debStatus.TextSize = 12
debStatus.Font = Enum.Font.Gotham
debStatus.TextXAlignment = Enum.TextXAlignment.Left
debStatus.Parent = debSec

local function refreshDebounceStatus()
	if debounceSystem then
		debStatus.Text = "Sistema: ON | Debounce: " .. (debounceActive and "ON (2.5s)" or "OFF")
		debStatus.TextColor3 = debounceActive and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 200, 80)
	else
		debStatus.Text = "Sistema: BLOQUEADO | Debounce: OFF"
		debStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
		debounceActive = false
	end
end

createToggle(debSec, "Habilitar Sistema Debounce", false, function(v)
	debounceSystem = v
	if not v then
		debounceActive = false
		debounceToken += 1
	end
	refreshDebounceStatus()
end)

createToggle(debSec, "Notificaciones Debounce", true, function(v)
	debounceNotifEnabled = v
end)

createSlider(debSec, "Potencia Debounce", 1.2, 5.0, 1.3, function(v)
	debounceMultiplier = v
end)

local function triggerDebounce()
	if not debounceSystem then return end
	debounceToken += 1
	local myToken = debounceToken
	debounceActive = true
	refreshDebounceStatus()
	if debounceNotifEnabled then
		clientNotif("⚡ DEBOUNCE ON (2.5s)", Color3.fromRGB(80, 255, 120))
	end
	task.delay(debounceAutoOffTime, function()
		if myToken == debounceToken and debounceActive then
			debounceActive = false
			refreshDebounceStatus()
			if debounceNotifEnabled then
				clientNotif("❌ DEBOUNCE OFF", Color3.fromRGB(255, 90, 90))
			end
		end
	end)
end

refreshDebounceStatus()

-- DRIBBLES
local dribbleSec = createSection(dribblesPage, "Equipar Dribble")
local dribbleList = {
	"Rainbow Flick", "Step Over", "The Marseille Turn", "Flip", "Float",
	"Super Dodge", "Front Flip", "Penguin Slide", "WC26 Trophy Dribble"
}
local currentDribbleLabel = Instance.new("TextLabel")
currentDribbleLabel.Size = UDim2.new(1, 0, 0, 20)
currentDribbleLabel.BackgroundTransparency = 1
currentDribbleLabel.Text = "Seleccionado: " .. selectedDribble
currentDribbleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
currentDribbleLabel.TextSize = 12
currentDribbleLabel.Font = Enum.Font.Gotham
currentDribbleLabel.TextXAlignment = Enum.TextXAlignment.Left
currentDribbleLabel.Parent = dribbleSec

for _, name in ipairs(dribbleList) do
	createButton(dribbleSec, name, function()
		selectedDribble = name
		currentDribbleLabel.Text = "Seleccionado: " .. name
		equipDribble(name)
	end)
end

-- FFLAGS
local fflagSec = createSection(fflagPage, "FFlag Injector (BETA)")
local fflagInfo = Instance.new("TextLabel")
fflagInfo.Size = UDim2.new(1, 0, 0, 0)
fflagInfo.AutomaticSize = Enum.AutomaticSize.Y
fflagInfo.BackgroundTransparency = 1
fflagInfo.Text = "Ejecuta el injector de FFlags (Masterstrap / Mobilestrap).\nPuede afectar red y físicas del client."
fflagInfo.TextColor3 = Color3.fromRGB(200, 200, 210)
fflagInfo.TextSize = 12
fflagInfo.Font = Enum.Font.Gotham
fflagInfo.TextXAlignment = Enum.TextXAlignment.Left
fflagInfo.TextYAlignment = Enum.TextYAlignment.Top
fflagInfo.TextWrapped = true
fflagInfo.Parent = fflagSec

createButton(fflagSec, "Ejecutar FFlag Injector (BETA)", function()
	local ok, err = pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Masterstrap/Mobilestrap/main/script.lua"))()
	end)
	if ok then
		clientNotif("✅ FFlag injector cargado", Color3.fromRGB(80, 255, 120))
	else
		clientNotif("❌ Error al cargar injector", Color3.fromRGB(255, 90, 90))
		warn("[Gamers X] FFlag injector:", err)
	end
end)

local warnLabel = Instance.new("TextLabel")
warnLabel.Size = UDim2.new(1, 0, 0, 0)
warnLabel.AutomaticSize = Enum.AutomaticSize.Y
warnLabel.BackgroundColor3 = Color3.fromRGB(40, 28, 20)
warnLabel.BackgroundTransparency = 0.25
warnLabel.Text = "⚠️ AVISO\n\nNo nos hacemos responsables de ningún tipo de baneo, sanción o mal funcionamiento.\n\nSi sienten el juego raro, es un ejecutor de FFlags a través de medidas distintas a las normales.\n\nSi después de ejecutar una FFlag que toque network o físicas ven mucho lag, hagan REJOIN 2 o 3 veces hasta que se estabilice."
warnLabel.TextColor3 = Color3.fromRGB(255, 190, 120)
warnLabel.TextSize = 11
warnLabel.Font = Enum.Font.Gotham
warnLabel.TextXAlignment = Enum.TextXAlignment.Left
warnLabel.TextYAlignment = Enum.TextYAlignment.Top
warnLabel.TextWrapped = true
warnLabel.Parent = fflagSec
Instance.new("UICorner", warnLabel).CornerRadius = UDim.new(0, 6)
local warnPad = Instance.new("UIPadding")
warnPad.PaddingTop = UDim.new(0, 8)
warnPad.PaddingBottom = UDim.new(0, 8)
warnPad.PaddingLeft = UDim.new(0, 8)
warnPad.PaddingRight = UDim.new(0, 8)
warnPad.Parent = warnLabel

-- SETTINGS
local setSec = createSection(settingsPage, "Keybinds")
createKeybindRow(setSec, "Menú", function() return showGuiKey end, function(k) showGuiKey = k end)
createKeybindRow(setSec, "Desync", function() return desyncKey end, function(k) desyncKey = k end)
createKeybindRow(setSec, "Inf Stamina", function() return staminaKey end, function(k) staminaKey = k end)
createKeybindRow(setSec, "Debounce", function() return debounceKey end, function(k) debounceKey = k end)

player.CharacterAdded:Connect(function()
	task.wait(0.6)
	if staminaSystem and infiniteStamina then enableInfiniteStamina() end
	if desyncSystem and desyncOn then task.spawn(applyDesyncCombo) end
end)

RunService.Heartbeat:Connect(function()
	if debounceSystem and debounceActive then
		if os.clock() - lastDebounceBoost >= debounceCooldown then
			local ball = getFootball()
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if ball and hrp then
				local vel = ball.AssemblyLinearVelocity
				local speed = vel.Magnitude
				local lastSpeed = lastDebounceVel.Magnitude
				local dist = (ball.Position - hrp.Position).Magnitude
				if dist < 18 and speed > 35 and speed > lastSpeed + 15 then
					pcall(function()
						ball.AssemblyLinearVelocity = vel.Unit * (speed * debounceMultiplier)
					end)
					lastDebounceBoost = os.clock()
				end
				lastDebounceVel = vel
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if UserInputService:GetFocusedTextBox() then return end
	if listeningForKey then return end
	if input.KeyCode == Enum.KeyCode.Unknown then return end

	if input.KeyCode == desyncKey then
		if not desyncSystem then return end
		desyncOn = not desyncOn
		refreshDesyncStatus()
		if desyncOn then
			task.spawn(applyDesyncCombo)
			showNotif("⚡ DESYNC ON", Color3.fromRGB(80, 255, 120))
		else
			resetDesyncCombo()
			showNotif("❌ DESYNC OFF", Color3.fromRGB(255, 90, 90))
		end
		return
	end

	if input.KeyCode == staminaKey then
		if not staminaSystem then return end
		infiniteStamina = not infiniteStamina
		refreshStamStatus()
		if infiniteStamina then enableInfiniteStamina() end
		return
	end

	if input.KeyCode == debounceKey then
		if not debounceSystem then return end
		triggerDebounce()
		return
	end

	if gp then return end
	if input.KeyCode == showGuiKey then
		main.Visible = not main.Visible
	end
end)

task.spawn(function()
	task.wait(2)
	enableInfiniteStamina()
end)

print("✅ Cliente OK")
