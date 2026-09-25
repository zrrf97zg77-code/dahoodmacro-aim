--!strict
-- Mobile GUI: Fake Macro + Aimbot
-- LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
	Aimbot = {
		FOV = 150,
		Smoothness = 0.3,
		TargetPart = "Head",
		TeamCheck = true,
		WallCheck = true,
		MaxDistance = 500,
	},
	Macro = {
		GlitchSpeed = 34,
		NormalSpeed = 16,
		GreetAnimName = "Greet",
	},
}

-- ============================================================
-- STATE
-- ============================================================
local aimbotOn = false
local macroOn = false
local speedGlitchOn = false
local currentTarget: BasePart? = nil
local originalWalkSpeed = 16

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

LocalPlayer.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid") :: Humanoid
	originalWalkSpeed = humanoid.WalkSpeed
end)

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "MobileCheatUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 180, 0, 130)
panel.Position = UDim2.new(0, 20, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(80, 80, 120)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "MOBILE MODS"
title.TextColor3 = Color3.fromRGB(200, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = panel

-- ============================================================
-- TOGGLE HELPER
-- ============================================================
local function makeToggle(name: string, yOffset: number, initial: boolean)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 34)
	btn.Position = UDim2.new(0, 10, 0, yOffset)
	btn.BackgroundColor3 = initial and Color3.fromRGB(60, 130, 80) or Color3.fromRGB(50, 50, 60)
	btn.Text = name .. ": " .. (initial and "ON" or "OFF")
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.Parent = panel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local aimbotBtn = makeToggle("Aimbot", 34, false)
local macroBtn = makeToggle("Fake Macro", 74, false)

-- ============================================================
-- CIRCLE BUTTON (speed glitch trigger)
-- ============================================================
local circle = Instance.new("TextButton")
circle.Size = UDim2.new(0, 70, 0, 70)
circle.Position = UDim2.new(1, -90, 1, -170)
circle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
circle.Text = "GLITCH"
circle.TextColor3 = Color3.fromRGB(255, 255, 255)
circle.Font = Enum.Font.GothamBold
circle.TextSize = 12
circle.BorderSizePixel = 0
circle.Visible = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

local circleStroke = Instance.new("UIStroke", circle)
circleStroke.Color = Color3.fromRGB(120, 120, 200)
circleStroke.Thickness = 2

-- ============================================================
-- FOV CIRCLE + TARGET LINE (drawing)
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(180, 180, 255)
fovCircle.Transparency = 0.6
fovCircle.NumSides = 60
fovCircle.Filled = false
fovCircle.Visible = false

local targetLine = Drawing.new("Line")
targetLine.Thickness = 1.5
targetLine.Color = Color3.fromRGB(255, 80, 80)
targetLine.Transparency = 0.9
targetLine.Visible = false

-- ============================================================
-- AIMBOT LOGIC
-- ============================================================
local function isVisible(part: BasePart): boolean
	local origin = Camera.CFrame.Position
	local dir = part.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, Camera }
	local result = workspace:Raycast(origin, dir, params)
	if not result then return true end
	return result.Instance:IsDescendantOf(part.Parent)
end

local function isValidTarget(plr: Player): boolean
	if plr == LocalPlayer then return false end
	if not plr.Character then return false end
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if CONFIG.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team and plr.Team ~= nil then
		return false
	end
	local dist = (plr.Character:GetPivot().Position - Camera.CFrame.Position).Magnitude
	if dist > CONFIG.Aimbot.MaxDistance then return false end
	return true
end

local function getClosestTarget(): (Model?, BasePart?)
	local closest, closestPart = nil, nil
	local shortest = CONFIG.Aimbot.FOV
	local mousePos = UserInputService:GetMouseLocation()

	for _, plr in Players:GetPlayers() do
		if not isValidTarget(plr) then continue end
		local part = plr.Character:FindFirstChild(CONFIG.Aimbot.TargetPart) :: BasePart?
		if not part then continue end

		local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
		if dist >= shortest then continue end
		if CONFIG.Aimbot.WallCheck and not isVisible(part) then continue end

		shortest = dist
		closest = plr.Character
		closestPart = part
	end

	return closest, closestPart
end

-- ============================================================
-- RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	-- FOV circle
	if aimbotOn then
		fovCircle.Position = center
		fovCircle.Radius = CONFIG.Aimbot.FOV
		fovCircle.Visible = true
	else
		fovCircle.Visible = false
		targetLine.Visible = false
		currentTarget = nil
		return
	end

	-- Target
	local _, part = getClosestTarget()
	currentTarget = part

	if part then
		-- Aim
		local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
		Camera.CFrame = Camera.CFrame:Lerp(goal, 1 - CONFIG.Aimbot.Smoothness)

		-- Line
		local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
		if onScreen then
			targetLine.From = center
			targetLine.To = Vector2.new(screenPos.X, screenPos.Y)
			targetLine.Visible = true
		else
			targetLine.Visible = false
		end
	else
		targetLine.Visible = false
	end
end)

-- ============================================================
-- SPEED GLITCH
-- ============================================================
local function isGreetPlaying(): boolean
	local animator = character:FindFirstChildOfClass("Animator")
	if not animator then return false end
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation and track.Animation.Name == CONFIG.Macro.GreetAnimName then
			return true
		end
	end
	return false
end

RunService.Heartbeat:Connect(function()
	if not humanoid or humanoid.Health <= 0 then return end

	if speedGlitchOn then
		humanoid.WalkSpeed = CONFIG.Macro.GlitchSpeed
	else
		humanoid.WalkSpeed = CONFIG.Macro.NormalSpeed
	end
end)

-- ============================================================
-- BUTTON HANDLERS
-- ============================================================
aimbotBtn.MouseButton1Click:Connect(function()
	aimbotOn = not aimbotOn
	aimbotBtn.Text = "Aimbot: " .. (aimbotOn and "ON" or "OFF")
	aimbotBtn.BackgroundColor3 = aimbotOn
		and Color3.fromRGB(60, 130, 80)
		or Color3.fromRGB(50, 50, 60)
end)

macroBtn.MouseButton1Click:Connect(function()
	macroOn = not macroOn
	macroBtn.Text = "Fake Macro: " .. (macroOn and "ON" or "OFF")
	macroBtn.BackgroundColor3 = macroOn
		and Color3.fromRGB(60, 130, 80)
		or Color3.fromRGB(50, 50, 60)
	circle.Visible = macroOn

	-- Reset glitch when hiding
	if not macroOn then
		speedGlitchOn = false
		circle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	end
end)

circle.MouseButton1Click:Connect(function()
	speedGlitchOn = not speedGlitchOn
	circle.BackgroundColor3 = speedGlitchOn
		and Color3.fromRGB(80, 180, 100)
		or Color3.fromRGB(60, 60, 70)
	circle.Text = speedGlitchOn and "GLITCH ON" or "GLITCH"
end)
